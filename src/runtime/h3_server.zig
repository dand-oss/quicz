//! HTTP/3 server driver over `runtime.Server` (std.Io.Threaded).
//!
//! Wraps the transport-agnostic `h3.H3Server` state machine in a per-connection
//! event loop. It polls every active stream non-blockingly, routes peer
//! unidirectional streams (control / QPACK encoder / QPACK decoder) by their
//! type prefix, buffers request streams until a complete HEADERS frame, and
//! feeds the state machine. It parks on `waitStreamActivity` so it never
//! blocks on a single stream and starves the QPACK control flow, matching the
//! event-driven shape of quic-zig's `poll()` and zttp's `pumpAll()`.

const std = @import("std");
const runtime_server = @import("server.zig");
const h3_server = @import("../h3/server.zig");
const h3_frame = @import("../h3/frame.zig");
const qpack = @import("../h3/qpack.zig");

const Server = runtime_server.Server;
const H3State = h3_server.H3Server;
const log = std.log.scoped(.h3_runtime_server);

pub const H3Server = struct {
    allocator: std.mem.Allocator,
    server: *Server,
    conn_id: u64,
    handler: h3_server.RequestHandler,
    qpack_max_table_capacity: u64,
    qpack_blocked_streams: u64,
    adapter: H3State.H3ServerConnection = undefined,
    h3: H3State = undefined,
    h3_started: bool = false,
    /// Peer unidirectional stream type, once the first byte arrived.
    uni_types: std.AutoHashMap(u64, u8),
    /// Buffered bytes per peer unidirectional stream (frames and QPACK
    /// instructions may span datagrams).
    uni_buffers: std.AutoHashMap(u64, std.ArrayList(u8)),
    /// Buffered bytes per bidi request stream until a complete HEADERS frame.
    request_buffers: std.AutoHashMap(u64, std.ArrayList(u8)),
    /// Bidi streams already served or abandoned; later bytes are ignored.
    served: std.AutoHashMap(u64, void),
    buf: [8192]u8 = undefined,
    control_wire: [8192]u8 = undefined,
    stream_ids: [128]u64 = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        server: *Server,
        conn_id: u64,
        handler: h3_server.RequestHandler,
        qpack_max_table_capacity: u64,
        qpack_blocked_streams: u64,
    ) H3Server {
        return .{
            .allocator = allocator,
            .server = server,
            .conn_id = conn_id,
            .handler = handler,
            .qpack_max_table_capacity = qpack_max_table_capacity,
            .qpack_blocked_streams = qpack_blocked_streams,
            .uni_types = std.AutoHashMap(u64, u8).init(allocator),
            .uni_buffers = std.AutoHashMap(u64, std.ArrayList(u8)).init(allocator),
            .request_buffers = std.AutoHashMap(u64, std.ArrayList(u8)).init(allocator),
            .served = std.AutoHashMap(u64, void).init(allocator),
        };
    }

    pub fn deinit(self: *H3Server) void {
        if (self.h3_started) self.h3.deinit();
        self.uni_types.deinit();
        var it = self.uni_buffers.valueIterator();
        while (it.next()) |b| b.deinit(self.allocator);
        self.uni_buffers.deinit();
        var rit = self.request_buffers.valueIterator();
        while (rit.next()) |b| b.deinit(self.allocator);
        self.request_buffers.deinit();
        self.served.deinit();
    }

    /// Run the per-connection HTTP/3 serve loop until the connection closes or
    /// the runtime cancels the handler task.
    pub fn run(self: *H3Server) std.Io.Cancelable!void {
        self.runInternal() catch |e| {
            if (e != error.Canceled and e != error.ConnectionClosed and e != error.NoConnection) {
                log.err("connection {d}: h3 serve: {}", .{ self.conn_id, e });
            }
        };
    }

    fn runInternal(self: *H3Server) !void {
        self.adapter = .{
            .openUniStreamFn = Adapter.openUni,
            .sendOnStreamFn = Adapter.send,
            .recvOnStreamFn = Adapter.recv,
            .ctx = self,
        };
        self.h3 = try H3State.init(&self.adapter, self.handler, self.allocator, self.qpack_max_table_capacity, self.qpack_blocked_streams);
        self.h3_started = true;
        // Enable dynamic QPACK before any request. The encoder capacity starts
        // at zero until the peer SETTINGS raise it (RFC 9204 §3.2.3).
        try self.h3.enableQpackDynamic(@intCast(self.qpack_max_table_capacity));
        while (true) {
            var activity = false;
            // Drain the per-stream accept queue so registrations do not grow
            // unbounded; reading is driven by connStreamIds below.
            while (try self.server.tryAcceptStreamId(self.conn_id)) |_| {}
            const n = self.server.connStreamIds(self.conn_id, &self.stream_ids);
            for (self.stream_ids[0..n]) |sid| {
                activity = (try self.pollStream(sid)) or activity;
            }
            if (!activity) {
                self.server.waitStreamActivity(self.conn_id) catch return;
            }
        }
    }

    fn pollStream(self: *H3Server, sid: u64) !bool {
        var did = false;
        while (true) {
            const r = try self.server.tryReceiveStreamData(self.conn_id, sid, &self.buf);
            if (r == null) break;
            did = true;
            if (r.? == 0) {
                try self.finishStream(sid);
                break;
            }
            if ((sid & 2) != 0) {
                try self.feedUni(sid, self.buf[0..r.?]);
            } else {
                try self.feedRequest(sid, self.buf[0..r.?]);
            }
        }
        return did;
    }

    fn feedUni(self: *H3Server, sid: u64, data: []const u8) !void {
        if (data.len == 0) return;
        const gop = try self.uni_buffers.getOrPut(sid);
        if (!gop.found_existing) gop.value_ptr.* = std.ArrayList(u8).empty;
        try gop.value_ptr.appendSlice(self.allocator, data);
        if (!self.uni_types.contains(sid)) {
            const utype = gop.value_ptr.items[0];
            try self.uni_types.put(sid, utype);
            _ = gop.value_ptr.orderedRemove(0);
        }
        switch (self.uni_types.get(sid).?) {
            0x00 => try self.processControl(sid),
            0x02 => try self.processEncoderStream(sid),
            0x03 => try self.processDecoderStream(sid),
            else => {}, // push (0x01) and unknown types are discarded
        }
    }

    fn processControl(self: *H3Server, sid: u64) !void {
        const buf = self.uni_buffers.getPtr(sid).?;
        while (true) {
            const frame = h3_frame.decodeFrame(buf.items) catch |e| switch (e) {
                error.IncompleteFrame => return,
                else => return e,
            };
            // Feed one complete control frame (prefixed with the stream type)
            // so the state machine applies SETTINGS/GOAWAY without re-parsing.
            if (1 + frame.consumed > self.control_wire.len) return error.ControlFrameTooLarge;
            self.control_wire[0] = 0x00;
            @memcpy(self.control_wire[1 .. 1 + frame.consumed], buf.items[0..frame.consumed]);
            try self.h3.processPeerControlStream(self.control_wire[0 .. 1 + frame.consumed]);
            if (frame.consumed == buf.items.len) {
                buf.clearRetainingCapacity();
                return;
            }
            std.mem.copyForwards(u8, buf.items[0 .. buf.items.len - frame.consumed], buf.items[frame.consumed..]);
            buf.shrinkRetainingCapacity(buf.items.len - frame.consumed);
        }
    }

    fn processEncoderStream(self: *H3Server, sid: u64) !void {
        const buf = self.uni_buffers.getPtr(sid).?;
        const consumed = qpack.encoderStreamConsumedLength(buf.items) catch |e| switch (e) {
            error.IncompleteString => return,
            else => return e,
        };
        if (consumed == 0) return;
        try self.h3.processPeerEncoderStream(buf.items[0..consumed]);
        if (consumed == buf.items.len) {
            buf.clearRetainingCapacity();
        } else {
            std.mem.copyForwards(u8, buf.items[0 .. buf.items.len - consumed], buf.items[consumed..]);
            buf.shrinkRetainingCapacity(buf.items.len - consumed);
        }
    }

    fn processDecoderStream(self: *H3Server, sid: u64) !void {
        const buf = self.uni_buffers.getPtr(sid).?;
        const consumed = qpack.decoderStreamConsumedLength(buf.items) catch |e| switch (e) {
            error.IncompleteString => return,
            else => return e,
        };
        if (consumed == 0) return;
        try self.h3.processPeerDecoderStream(buf.items[0..consumed]);
        if (consumed == buf.items.len) {
            buf.clearRetainingCapacity();
        } else {
            std.mem.copyForwards(u8, buf.items[0 .. buf.items.len - consumed], buf.items[consumed..]);
            buf.shrinkRetainingCapacity(buf.items.len - consumed);
        }
    }

    fn feedRequest(self: *H3Server, sid: u64, data: []const u8) !void {
        if (self.served.contains(sid)) return;
        const gop = try self.request_buffers.getOrPut(sid);
        if (!gop.found_existing) gop.value_ptr.* = std.ArrayList(u8).empty;
        try gop.value_ptr.appendSlice(self.allocator, data);
        try self.tryServeRequest(sid);
    }

    fn tryServeRequest(self: *H3Server, sid: u64) !void {
        if (self.served.contains(sid)) return;
        const buf = self.request_buffers.getPtr(sid) orelse return;
        const frame = h3_frame.decodeFrame(buf.items) catch |e| switch (e) {
            error.IncompleteFrame => return,
            else => return e,
        };
        if (frame.frame.frame_type != @intFromEnum(h3_frame.FrameType.headers)) {
            return error.ExpectedHeadersFrame;
        }
        _ = try self.h3.feedRequestBytes(sid, buf.items[0..frame.consumed]);
        try self.served.put(sid, {});
        buf.deinit(self.allocator);
        _ = self.request_buffers.remove(sid);
    }

    fn finishStream(self: *H3Server, sid: u64) !void {
        if ((sid & 2) != 0) return; // peer uni streams stay open in H3
        try self.tryServeRequest(sid);
    }
};

const Adapter = struct {
    fn openUni(ctx: *anyopaque) anyerror!u64 {
        const self: *H3Server = @ptrCast(@alignCast(ctx));
        return self.server.openUniStreamRequest(self.conn_id);
    }
    fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
        const self: *H3Server = @ptrCast(@alignCast(ctx));
        return self.server.sendStreamData(self.conn_id, stream_id, data, fin);
    }
    fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
        const self: *H3Server = @ptrCast(@alignCast(ctx));
        return self.server.tryReceiveStreamData(self.conn_id, stream_id, buf);
    }
};
