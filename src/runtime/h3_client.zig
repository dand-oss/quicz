//! HTTP/3 client driver over `runtime.Client` (std.Io.Threaded).
//!
//! Wraps the transport-agnostic `h3.H3Client` state machine. It runs the
//! control / QPACK streams, waits for the peer SETTINGS, sends requests, and
//! receives responses while interleaving the server's unidirectional streams
//! (control / QPACK encoder / QPACK decoder) so blocked header blocks get the
//! insertions they need without blocking on one stream.
const std = @import("std");
const runtime_client = @import("client.zig");
const h3_client = @import("../h3/client.zig");
const h3_frame = @import("../h3/frame.zig");
const h3_request = @import("../h3/request.zig");
const qpack = @import("../h3/qpack.zig");

const Client = runtime_client.Client;
const H3State = h3_client.H3Client;
const log = std.log.scoped(.h3_runtime_client);

pub const H3Client = struct {
    allocator: std.mem.Allocator,
    client: *Client,
    qpack_max_table_capacity: u64,
    qpack_blocked_streams: u64,
    adapter: H3State.H3ClientConnection = undefined,
    h3: H3State = undefined,
    h3_started: bool = false,
    /// Peer (server) unidirectional stream type, once the first byte arrived.
    uni_types: std.AutoHashMap(u64, u8),
    /// Buffered bytes per peer unidirectional stream (may span datagrams).
    uni_buffers: std.AutoHashMap(u64, std.ArrayList(u8)),
    /// Buffered bytes per response stream until a complete HEADERS frame.
    response_buffers: std.AutoHashMap(u64, std.ArrayList(u8)),
    /// Response streams already decoded (their buffer is kept as backing).
    served: std.AutoHashMap(u64, void),
    buf: [8192]u8 = undefined,
    control_wire: [8192]u8 = undefined,
    stream_ids: [128]u64 = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        client: *Client,
        qpack_max_table_capacity: u64,
        qpack_blocked_streams: u64,
    ) H3Client {
        return .{
            .allocator = allocator,
            .client = client,
            .qpack_max_table_capacity = qpack_max_table_capacity,
            .qpack_blocked_streams = qpack_blocked_streams,
            .uni_types = std.AutoHashMap(u64, u8).init(allocator),
            .uni_buffers = std.AutoHashMap(u64, std.ArrayList(u8)).init(allocator),
            .response_buffers = std.AutoHashMap(u64, std.ArrayList(u8)).init(allocator),
            .served = std.AutoHashMap(u64, void).init(allocator),
        };
    }

    pub fn deinit(self: *H3Client) void {
        if (self.h3_started) self.h3.deinit();
        self.uni_types.deinit();
        var it = self.uni_buffers.valueIterator();
        while (it.next()) |b| b.deinit(self.allocator);
        self.uni_buffers.deinit();
        var rit = self.response_buffers.valueIterator();
        while (rit.next()) |b| b.deinit(self.allocator);
        self.response_buffers.deinit();
        self.served.deinit();
    }

    /// Initialize the HTTP/3 layer (control + QPACK streams) and wait until
    /// the server's SETTINGS have been received.
    pub fn run(self: *H3Client) !void {
        self.client.enableH3();
        self.adapter = .{
            .openBidiStreamFn = Adapter.openBidi,
            .openUniStreamFn = Adapter.openUni,
            .sendOnStreamFn = Adapter.send,
            .recvOnStreamFn = Adapter.recv,
            .ctx = self,
        };
        self.h3 = try H3State.init(&self.adapter, self.allocator, self.qpack_max_table_capacity, self.qpack_blocked_streams);
        self.h3_started = true;
        try self.h3.enableQpackDynamic(@intCast(self.qpack_max_table_capacity));
        try self.waitForPeerSettings();
    }

    /// Send an HTTP request with dynamic QPACK compression; returns the stream
    /// id to pass to `receiveResponse`.
    pub fn sendRequest(self: *H3Client, request: h3_request.Request) !u64 {
        return self.h3.sendRequestDynamic(request);
    }

    /// Send an HTTP request with a streamed (chunked) body, blocking until the
    /// body has fully drained (retrying flow-control-blocked chunks as fresh
    /// MAX_STREAM_DATA credit arrives). Returns the stream id for
    /// `receiveResponse`.
    pub fn sendRequestStreamed(self: *H3Client, request: h3_request.Request, body: h3_request.ResponseBody) !u64 {
        const sid = try self.h3.sendRequestStreamed(request, body);
        while (self.h3.pending_sends != null and self.h3.pending_sends.?.count() > 0) {
            _ = try self.drainPeerUniStreams();
            try self.h3.pumpSends();
            if (self.h3.pending_sends.?.count() == 0) break;
            try self.client.waitStreamActivity();
        }
        return sid;
    }

    /// Receive and decode the response on `stream_id`, interleaving the
    /// server's control / QPACK streams so blocked header blocks resolve.
    pub fn receiveResponse(self: *H3Client, stream_id: u64) !h3_request.DecodedResponse {
        while (true) {
            _ = try self.drainPeerUniStreams();

            var got = false;
            var eof = false;
            while (true) {
                const r = try self.client.tryReceiveStreamData(stream_id, &self.buf);
                if (r == null) break;
                got = true;
                if (r.? == 0) {
                    eof = true;
                    break;
                }
                const gop = try self.response_buffers.getOrPut(stream_id);
                if (!gop.found_existing) gop.value_ptr.* = std.ArrayList(u8).empty;
                try gop.value_ptr.appendSlice(self.allocator, self.buf[0..r.?]);
            }

            if (self.response_buffers.getPtr(stream_id)) |buf| {
                if (buf.items.len > 0 or eof) {
                    // Feed the buffered response bytes (HEADERS + DATA) and any
                    // EOF into the streaming state machine, which aggregates
                    // multiple DATA frames. On completion the returned response
                    // borrows the state machine's backing storage.
                    if (try self.h3.feedResponseData(stream_id, buf.items, eof)) |resp| {
                        return resp;
                    }
                    // Incomplete or blocked: the state machine owns a copy.
                    buf.clearRetainingCapacity();
                }
            }

            if (!got) {
                try self.client.waitStreamActivity();
            }
        }
    }

    /// Drain the server's unidirectional control / QPACK streams once. Used
    /// after a response to let decoder-stream acknowledgments catch up.
    pub fn drain(self: *H3Client) !void {
        _ = try self.drainPeerUniStreams();
    }

    fn waitForPeerSettings(self: *H3Client) !void {
        while (!self.h3.settings_received) {
            _ = try self.drainPeerUniStreams();
            if (self.h3.settings_received) return;
            try self.client.waitStreamActivity();
        }
    }

    fn drainPeerUniStreams(self: *H3Client) !bool {
        var did = false;
        const n = self.client.streamIds(&self.stream_ids);
        for (self.stream_ids[0..n]) |sid| {
            // Server-initiated unidirectional streams have type bits 0b11.
            if ((sid & 3) != 3) continue;
            did = (try self.pollUni(sid)) or did;
        }
        return did;
    }

    fn pollUni(self: *H3Client, sid: u64) !bool {
        var did = false;
        while (true) {
            const r = try self.client.tryReceiveStreamData(sid, &self.buf);
            if (r == null) break;
            did = true;
            if (r.? == 0) break;
            const gop = try self.uni_buffers.getOrPut(sid);
            if (!gop.found_existing) gop.value_ptr.* = std.ArrayList(u8).empty;
            try gop.value_ptr.appendSlice(self.allocator, self.buf[0..r.?]);
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
        return did;
    }

    fn processControl(self: *H3Client, sid: u64) !void {
        const buf = self.uni_buffers.getPtr(sid).?;
        while (true) {
            const frame = h3_frame.decodeFrame(buf.items) catch |e| switch (e) {
                error.IncompleteFrame => return,
                else => return e,
            };
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

    fn processEncoderStream(self: *H3Client, sid: u64) !void {
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

    fn processDecoderStream(self: *H3Client, sid: u64) !void {
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
};

const Adapter = struct {
    fn openBidi(ctx: *anyopaque) anyerror!u64 {
        const self: *H3Client = @ptrCast(@alignCast(ctx));
        return self.client.openStream();
    }
    fn openUni(ctx: *anyopaque) anyerror!u64 {
        const self: *H3Client = @ptrCast(@alignCast(ctx));
        return self.client.openUniStream();
    }
    fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
        const self: *H3Client = @ptrCast(@alignCast(ctx));
        return self.client.sendOnStream(stream_id, data, fin);
    }
    fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
        const self: *H3Client = @ptrCast(@alignCast(ctx));
        return self.client.tryReceiveStreamData(stream_id, buf);
    }
};
