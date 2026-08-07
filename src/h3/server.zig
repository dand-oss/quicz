//! HTTP/3 server handler (RFC 9114 §4-6).
//!
//! Processes incoming H3 requests over QUIC streams and sends responses.
//! Works with any QUIC Connection that provides stream I/O.

const std = @import("std");
const h3_frame = @import("frame.zig");
const h3_request = @import("request.zig");
const h3_connection = @import("connection.zig");
const qpack = @import("qpack.zig");
const buffer = @import("../quic/buffer.zig");

/// H3 server request handler callback.
/// Receives a decoded request, returns a response to send.
pub const RequestHandler = *const fn (req: h3_request.DecodedRequest) h3_request.Response;

/// HTTP/3 server state machine over a QUIC connection.
pub const H3Server = struct {
    conn: *H3ServerConnection,
    handler: RequestHandler,
    allocator: std.mem.Allocator,
    control_stream_id: ?u64 = null,
    settings_sent: bool = false,
    goaway_sent: bool = false,
    goaway_last_stream_id: ?u64 = null,
    /// Advertised SETTINGS_MAX_FIELD_SECTION_SIZE: the largest field section this
    /// endpoint accepts from the peer (RFC 9114 §7.2.4.1).
    local_max_field_section_size: u64 = 8192,

    /// Server's encoder table for responses. Produces Insert/Duplicate/SetCapacity
    /// instructions sent on the QPACK encoder stream (type 0x02) to the client.
    enc_table: ?qpack.DynamicTable = null,
    /// Mirror of the client's encoder table for requests. Updated by consuming
    /// the client's encoder stream instructions via processPeerEncoderStream.
    dec_table: ?qpack.DynamicTable = null,
    /// Server's QPACK encoder stream (type 0x02).
    enc_stream_id: ?u64 = null,
    /// Server's QPACK decoder stream (type 0x03).
    dec_stream_id: ?u64 = null,
    /// Required Insert Count of each dynamic section sent on a stream, keyed by
    /// stream ID, so peer Section Acknowledgment can raise Known Received Count.
    pending_sections: ?std.AutoHashMap(u64, u64) = null,
    /// Number of peer insertions this decoder has already acknowledged via
    /// Insert Count Increment, for emitting only the outstanding delta.
    decoder_known_insert_count: u64 = 0,
    /// This decoder's advertised SETTINGS_QPACK_MAX_TABLE_CAPACITY, sent in the
    /// control-stream SETTINGS frame (RFC 9204 §3.2.3). The peer encoder must
    /// not exceed it.
    local_qpack_max_table_capacity: u64 = 0,
    /// Peer's advertised SETTINGS_QPACK_MAX_TABLE_CAPACITY. Caps this encoder's
    /// dynamic table; zero means the peer has not advertised one (capacity 0).
    peer_qpack_max_table_capacity: u64 = 0,
    /// Capacity requested via enableQpackDynamic, before peer SETTINGS capping.
    enc_capacity_requested: usize = 0,
    /// Encoded request bytes awaiting QPACK insertions (RFC 9204 §2.2.1), keyed
    /// by stream ID until the encoder stream supplies the Required Insert Count.
    blocked_requests: ?std.AutoHashMap(u64, []u8) = null,
    /// Advertised SETTINGS_QPACK_BLOCKED_STREAMS: the maximum number of streams
    /// this decoder keeps blocked at once (RFC 9204 §2.1.2).
    max_blocked_streams: u64 = 0,

    pub const H3ServerConnection = struct {
        /// Open a locally-initiated unidirectional stream.
        openUniStreamFn: *const fn (ctx: *anyopaque) anyerror!u64,
        /// Send data on a stream.
        sendOnStreamFn: *const fn (ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void,
        /// Receive data from a stream. Returns null if no data available.
        recvOnStreamFn: *const fn (ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize,
        /// Opaque context pointer.
        ctx: *anyopaque,

        pub fn openUniStream(self: *H3ServerConnection) !u64 {
            return self.openUniStreamFn(self.ctx);
        }
        pub fn sendOnStream(self: *H3ServerConnection, stream_id: u64, data: []const u8, fin: bool) !void {
            return self.sendOnStreamFn(self.ctx, stream_id, data, fin);
        }
        pub fn recvOnStream(self: *H3ServerConnection, stream_id: u64, buf: []u8) !?usize {
            return self.recvOnStreamFn(self.ctx, stream_id, buf);
        }
    };

    /// Initialize the server and send SETTINGS on the control stream.
    pub fn init(
        conn: *H3ServerConnection,
        handler: RequestHandler,
        allocator: std.mem.Allocator,
        qpack_max_table_capacity: u64,
        qpack_blocked_streams: u64,
    ) !H3Server {
        var server = H3Server{
            .conn = conn,
            .handler = handler,
            .allocator = allocator,
            .local_qpack_max_table_capacity = qpack_max_table_capacity,
            .max_blocked_streams = qpack_blocked_streams,
        };
        try server.sendSettings();
        return server;
    }

    /// Release QPACK dynamic table resources.
    pub fn deinit(self: *H3Server) void {
        if (self.enc_table) |*t| t.deinit();
        if (self.dec_table) |*t| t.deinit();
        if (self.pending_sections) |*m| m.deinit();
        if (self.blocked_requests) |*m| {
            var it = m.iterator();
            while (it.next()) |entry| self.allocator.free(entry.value_ptr.*);
            m.deinit();
        }
    }

    /// Enable QPACK dynamic table compression (RFC 9204).
    /// Opens QPACK encoder (0x02) and decoder (0x03) unidirectional streams,
    /// initializes both tables, and advertises capacity to the peer via a
    /// Set Capacity instruction on the encoder stream. The encoder capacity is
    /// capped by the peer's advertised SETTINGS_QPACK_MAX_TABLE_CAPACITY; when
    /// the peer has not advertised one, the encoder must stay at capacity zero
    /// and send no encoder instructions (RFC 9204 §3.2.3).
    pub fn enableQpackDynamic(self: *H3Server, capacity: usize) !void {
        self.enc_capacity_requested = capacity;
        const enc_capacity: usize = @intCast(@min(capacity, self.peer_qpack_max_table_capacity));
        self.enc_table = qpack.DynamicTable.init(self.allocator);
        self.dec_table = qpack.DynamicTable.init(self.allocator);
        self.pending_sections = std.AutoHashMap(u64, u64).init(self.allocator);
        self.blocked_requests = std.AutoHashMap(u64, []u8).init(self.allocator);
        self.enc_table.?.setCapacity(enc_capacity);
        self.dec_table.?.setCapacity(@intCast(self.local_qpack_max_table_capacity));

        // Open encoder stream (type 0x02) and send Set Capacity.
        self.enc_stream_id = try self.conn.openUniStream();
        var enc_buf: [32]u8 = undefined;
        var pos: usize = 0;
        enc_buf[pos] = 0x02;
        pos += 1;
        if (enc_capacity > 0) {
            pos += try qpack.encodeEncoderInstruction(enc_buf[pos..], .{ .set_capacity = enc_capacity });
        }
        try self.conn.sendOnStream(self.enc_stream_id.?, enc_buf[0..pos], false);

        // Open decoder stream (type 0x03).
        self.dec_stream_id = try self.conn.openUniStream();
        var dec_buf: [4]u8 = undefined;
        dec_buf[0] = 0x03;
        try self.conn.sendOnStream(self.dec_stream_id.?, dec_buf[0..1], false);
    }

    /// Record the peer's advertised SETTINGS_QPACK_MAX_TABLE_CAPACITY. If the
    /// dynamic table is already enabled and the new limit is lower, reduce the
    /// encoder capacity and re-issue Set Capacity (RFC 9204 §3.2.3).
    pub fn setPeerMaxTableCapacity(self: *H3Server, capacity: u64) !void {
        self.peer_qpack_max_table_capacity = capacity;
        if (self.enc_table) |*et| {
            const effective: usize = @intCast(@min(self.enc_capacity_requested, capacity));
            if (effective != et.max_capacity) {
                et.setCapacity(effective);
                if (effective > 0) {
                    var buf: [16]u8 = undefined;
                    const len = try qpack.encodeEncoderInstruction(&buf, .{ .set_capacity = effective });
                    try self.conn.sendOnStream(self.enc_stream_id.?, buf[0..len], false);
                }
            }
        }
    }

    /// Feed peer (client) encoder stream data into the decoder-side dynamic
    /// table so subsequent request header blocks with dynamic references
    /// resolve correctly (RFC 9204 §4.3).
    pub fn processPeerEncoderStream(self: *H3Server, data: []const u8) !void {
        if (self.dec_table) |*dt| {
            _ = try qpack.decodeEncoderStreamInstructions(data, dt);
            if (dt.max_capacity > self.local_qpack_max_table_capacity) {
                return error.QpackCapacityExceedsSettings;
            }
        }
        try self.unblockBlockedRequests();
    }

    /// Process the peer's control stream: parse SETTINGS and apply the
    /// advertised QPACK table capacity (RFC 9114 §6.2.1 / RFC 9204 §3.2.3).
    pub fn processPeerControlStream(self: *H3Server, data: []const u8) !void {
        var pos: usize = 0;
        if (pos < data.len and data[pos] == 0x00) pos += 1; // stream type
        while (pos < data.len) {
            const frame = try h3_frame.decodeFrame(data[pos..]);
            if (frame.frame.frame_type == @intFromEnum(h3_frame.FrameType.settings)) {
                const settings = try h3_connection.Settings.decodePayload(frame.frame.payload);
                if (settings.qpack_max_table_capacity != 0) {
                    try self.setPeerMaxTableCapacity(settings.qpack_max_table_capacity);
                }
            }
            if (frame.consumed == 0) break;
            pos += frame.consumed;
        }
    }

    /// Feed peer (client) decoder stream data into the encoder-side table so
    /// Section Acknowledgment / Insert Count Increment advance the Known
    /// Received Count (RFC 9204 §4.4).
    pub fn processPeerDecoderStream(self: *H3Server, data: []const u8) !void {
        if (self.enc_table) |*et| {
            if (self.pending_sections) |*ps| {
                _ = try qpack.decodeDecoderStreamInstructions(data, et, ps);
            }
        }
    }

    /// Emit Section Acknowledgment (when the decoded section used dynamic
    /// references) and any outstanding Insert Count Increment on the QPACK
    /// decoder stream (RFC 9204 §4.4).
    fn sendSectionAcknowledgement(self: *H3Server, stream_id: u64, required_insert_count: u64) !void {
        const dec_stream_id = self.dec_stream_id orelse return;
        var buf: [32]u8 = undefined;
        var pos: usize = 0;
        if (required_insert_count > 0) {
            pos += try qpack.encodeDecoderInstruction(buf[pos..], .{ .section_ack = stream_id });
        }
        if (self.dec_table) |*dt| {
            if (dt.insert_count > self.decoder_known_insert_count) {
                const increment = dt.insert_count - self.decoder_known_insert_count;
                pos += try qpack.encodeDecoderInstruction(buf[pos..], .{ .insert_count_increment = increment });
                self.decoder_known_insert_count = dt.insert_count;
            }
        }
        if (pos > 0) try self.conn.sendOnStream(dec_stream_id, buf[0..pos], false);
    }

    /// Open the server control stream and send SETTINGS.
    fn sendSettings(self: *H3Server) !void {
        const stream_id = try self.conn.openUniStream();
        self.control_stream_id = stream_id;

        // Control stream: stream type (0x00) + SETTINGS frame
        var buf: [128]u8 = undefined;
        var pos: usize = 0;

        // Stream type: control (0x00)
        buf[pos] = 0x00;
        pos += 1;

        // SETTINGS frame: max_field_section_size + advertised QPACK capacity.
        var settings_payload: [32]u8 = undefined;
        const settings = h3_connection.Settings{
            .max_field_section_size = self.local_max_field_section_size,
            .qpack_max_table_capacity = self.local_qpack_max_table_capacity,
            .qpack_blocked_streams = self.max_blocked_streams,
        };
        const sp_len = try settings.encodePayload(&settings_payload);

        // Frame type (0x04) + length + payload
        buf[pos] = 0x04; // SETTINGS frame type
        pos += 1;
        buf[pos] = @intCast(sp_len);
        pos += 1;
        @memcpy(buf[pos .. pos + sp_len], settings_payload[0..sp_len]);
        pos += sp_len;

        try self.conn.sendOnStream(stream_id, buf[0..pos], false);
        self.settings_sent = true;
    }

    /// Process an incoming request on a bidi stream.
    /// Reads the request, calls the handler, and sends the response. When the
    /// QPACK decoder lacks the required insertions, the request bytes are
    /// buffered until the peer's encoder stream supplies them (RFC 9204 §2.2.1).
    pub fn handleRequestStream(self: *H3Server, stream_id: u64) !void {
        // Read request data
        var req_buf: [8192]u8 = undefined;
        var total_read: usize = 0;

        // Poll for data
        while (total_read < req_buf.len) {
            const n = try self.conn.recvOnStream(stream_id, req_buf[total_read..]) orelse break;
            total_read += n;
            // Check if we have a complete HEADERS frame
            if (total_read > 0) {
                _ = h3_frame.decodeFrame(req_buf[0..total_read]) catch continue;
                break;
            }
        }

        if (total_read == 0) return;
        const request_frame = try h3_frame.decodeFrame(req_buf[0..total_read]);
        if (request_frame.frame.payload.len > self.local_max_field_section_size) {
            return error.FieldSectionTooLarge;
        }
        if (try self.tryProcessRequest(stream_id, req_buf[0..total_read])) return;

        // Blocked: retain the request and retry after encoder stream progress.
        try self.bufferBlockedRequest(stream_id, req_buf[0..total_read]);
    }

    fn bufferBlockedRequest(self: *H3Server, stream_id: u64, data: []const u8) !void {
        if (self.blocked_requests) |*blocked| {
            if (!blocked.contains(stream_id) and blocked.count() >= self.max_blocked_streams) {
                return error.BlockedStreamLimitExceeded;
            }
            const copy = try self.allocator.dupe(u8, data);
            errdefer self.allocator.free(copy);
            if (blocked.get(stream_id)) |old| self.allocator.free(old);
            try blocked.put(stream_id, copy);
        }
    }

    /// Abandon a request stream: drop any buffered blocked data and tell the
    /// peer encoder that its references on this stream are no longer
    /// outstanding (RFC 9204 §4.4.2).
    pub fn cancelStream(self: *H3Server, stream_id: u64) !void {
        if (self.blocked_requests) |*blocked| {
            if (blocked.fetchRemove(stream_id)) |removed| {
                self.allocator.free(removed.value);
            }
        }
        const dec_stream_id = self.dec_stream_id orelse return;
        var buf: [16]u8 = undefined;
        const len = try qpack.encodeDecoderInstruction(&buf, .{ .stream_cancellation = stream_id });
        try self.conn.sendOnStream(dec_stream_id, buf[0..len], false);
    }

    /// Decode and serve a request. Returns false when the QPACK decoder still
    /// needs insertions from the peer's encoder stream (blocked stream).
    fn tryProcessRequest(self: *H3Server, stream_id: u64, request_data: []const u8) !bool {
        var request_required_insert_count: u64 = 0;
        const decoded = if (self.dec_table) |*dt| blk: {
            const result = h3_request.decodeRequestWithDynamic(request_data, dt) catch |err| {
                if (err == error.BlockedByQpack) return false;
                return err;
            };
            request_required_insert_count = result.required_insert_count;
            break :blk result.request;
        } else (try h3_request.decodeRequest(request_data)).request;

        try self.sendSectionAcknowledgement(stream_id, request_required_insert_count);

        // Call handler
        const response = self.handler(decoded);

        // Encode and send response.
        if (self.enc_table) |*et| {
            var resp_buf: [8192]u8 = undefined;
            var enc_instr: [4096]u8 = undefined;
            const enc = try h3_request.encodeResponseWithDynamic(&resp_buf, response, et, &enc_instr);
            if (self.pending_sections) |*ps| {
                if (enc.required_insert_count > 0) {
                    try ps.put(stream_id, enc.required_insert_count);
                    et.protectUpTo(enc.required_insert_count);
                }
            }
            // Send encoder stream instructions before the response so dynamic
            // references in the header block resolve on the peer's decoder.
            if (enc.encoder_stream_len > 0) {
                try self.conn.sendOnStream(self.enc_stream_id.?, enc_instr[0..enc.encoder_stream_len], false);
            }
            try self.conn.sendOnStream(stream_id, resp_buf[0..enc.len], true);
        } else {
            var resp_buf: [8192]u8 = undefined;
            const resp_len = try h3_request.encodeResponse(&resp_buf, response);
            try self.conn.sendOnStream(stream_id, resp_buf[0..resp_len], true);
        }
        return true;
    }

    /// Retry all buffered blocked requests once the decoder table has advanced.
    fn unblockBlockedRequests(self: *H3Server) !void {
        if (self.blocked_requests) |*blocked| {
            if (blocked.count() == 0) return;

            var ids = std.ArrayList(u64).empty;
            defer ids.deinit(self.allocator);
            var it = blocked.iterator();
            while (it.next()) |entry| try ids.append(self.allocator, entry.key_ptr.*);

            for (ids.items) |stream_id| {
                const data = blocked.get(stream_id) orelse continue;
                if (try self.tryProcessRequest(stream_id, data)) {
                    self.allocator.free(data);
                    _ = blocked.remove(stream_id);
                }
            }
        }
    }

    /// Send GOAWAY to initiate graceful shutdown.
    pub fn sendGoaway(self: *H3Server, last_stream_id: u64) !void {
        if (self.goaway_sent) return;
        const control_id = self.control_stream_id orelse return;

        var buf: [16]u8 = undefined;
        var pos: usize = 0;

        // GOAWAY frame: type(0x07) + len + stream_id varint
        buf[pos] = 0x07;
        pos += 1;
        // Encode stream_id as varint
        if (last_stream_id <= 63) {
            buf[pos] = @intCast(last_stream_id);
            pos += 1;
            buf[1] = @intCast(pos - 2); // fix length
        } else {
            buf[pos] = @intCast(0x40 | (last_stream_id >> 8));
            buf[pos + 1] = @intCast(last_stream_id & 0xff);
            pos += 2;
            buf[1] = @intCast(pos - 2);
        }

        try self.conn.sendOnStream(control_id, buf[0..pos], false);
        self.goaway_sent = true;
        self.goaway_last_stream_id = last_stream_id;
    }
};

test "H3Server sends SETTINGS on control stream" {
    // Mock connection that captures sent data
    const MockCtx = struct {
        sent_data: std.ArrayList(u8) = .empty,
        sent_stream_id: ?u64 = null,
        next_uni_id: u64 = 3, // server-initiated uni

        fn openUni(ctx: *anyopaque) !u64 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const id = self.next_uni_id;
            self.next_uni_id += 4;
            return id;
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = fin;
            self.sent_stream_id = stream_id;
            try self.sent_data.appendSlice(std.testing.allocator, data);
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) !?usize {
            _ = ctx;
            _ = stream_id;
            _ = buf;
            return null;
        }
    };

    var mock = MockCtx{};
    defer mock.sent_data.deinit(std.testing.allocator);

    var conn = H3Server.H3ServerConnection{
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };

    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{ .status = 200, .body = "OK" };
        }
    }.handle;

    var server = try H3Server.init(&conn, handler, std.testing.allocator, 4096, 8);
    defer server.deinit();
    try std.testing.expect(server.settings_sent);
    try std.testing.expectEqual(@as(?u64, 3), server.control_stream_id);
    // Control stream should have: stream_type(1) + SETTINGS frame
    try std.testing.expect(mock.sent_data.items.len > 2);
    try std.testing.expectEqual(@as(u8, 0x00), mock.sent_data.items[0]); // control stream type
    try std.testing.expectEqual(@as(u8, 0x04), mock.sent_data.items[1]); // SETTINGS frame type
}

test "H3Server handles request and sends response" {
    // Encode a GET request
    var req_buf: [4096]u8 = undefined;
    const req = h3_request.Request{
        .method = "GET",
        .path = "/hello",
        .authority = "test.com",
    };
    const req_len = try h3_request.encodeRequest(&req_buf, req);

    const MockCtx = struct {
        request_data: []const u8,
        request_pos: usize = 0,
        response_data: std.ArrayList(u8) = .empty,
        response_stream_id: ?u64 = null,

        fn openUni(ctx: *anyopaque) !u64 {
            _ = ctx;
            return 3;
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = fin;
            if (stream_id != 3) { // not control stream
                self.response_stream_id = stream_id;
                try self.response_data.appendSlice(std.testing.allocator, data);
            }
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) !?usize {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = stream_id;
            if (self.request_pos >= self.request_data.len) return null;
            const available = self.request_data[self.request_pos..];
            const n = @min(buf.len, available.len);
            @memcpy(buf[0..n], available[0..n]);
            self.request_pos += n;
            return n;
        }
    };

    var mock = MockCtx{ .request_data = req_buf[0..req_len] };
    defer mock.response_data.deinit(std.testing.allocator);

    var conn = H3Server.H3ServerConnection{
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };

    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            if (std.mem.eql(u8, decoded_req.path, "/hello")) {
                return .{ .status = 200, .body = "Hello, World!" };
            }
            return .{ .status = 404, .body = "Not Found" };
        }
    }.handle;

    var server = try H3Server.init(&conn, handler, std.testing.allocator, 4096, 8);
    defer server.deinit();
    try server.handleRequestStream(0); // client bidi stream 0

    // Verify response
    try std.testing.expectEqual(@as(?u64, 0), mock.response_stream_id);
    const resp_result = try h3_request.decodeResponse(mock.response_data.items);
    try std.testing.expectEqual(@as(u16, 200), resp_result.response.status);
    try std.testing.expectEqualStrings("Hello, World!", resp_result.response.body.?);
}

test "H3Server GOAWAY" {
    const MockCtx = struct {
        sent_data: std.ArrayList(u8) = .empty,

        fn openUni(ctx: *anyopaque) !u64 {
            _ = ctx;
            return 3;
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = fin;
            _ = stream_id;
            try self.sent_data.appendSlice(std.testing.allocator, data);
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) !?usize {
            _ = ctx;
            _ = stream_id;
            _ = buf;
            return null;
        }
    };

    var mock = MockCtx{};
    defer mock.sent_data.deinit(std.testing.allocator);

    var conn = H3Server.H3ServerConnection{
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };

    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{ .status = 200 };
        }
    }.handle;

    var server = try H3Server.init(&conn, handler, std.testing.allocator, 4096, 8);
    defer server.deinit();
    try std.testing.expect(!server.goaway_sent);

    try server.sendGoaway(4);
    try std.testing.expect(server.goaway_sent);
    try std.testing.expectEqual(@as(?u64, 4), server.goaway_last_stream_id);
}

test "H3Server applies peer QPACK capacity from control stream" {
    const MockCtx = struct {
        next_uni_id: u64 = 3,

        fn openUni(ctx: *anyopaque) !u64 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const id = self.next_uni_id;
            self.next_uni_id += 4;
            return id;
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) !void {
            _ = ctx;
            _ = stream_id;
            _ = data;
            _ = fin;
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) !?usize {
            _ = ctx;
            _ = stream_id;
            _ = buf;
            return null;
        }
    };

    var mock = MockCtx{};
    var conn = H3Server.H3ServerConnection{
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };
    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{ .status = 200 };
        }
    }.handle;

    var server = try H3Server.init(&conn, handler, std.testing.allocator, 4096, 8);
    defer server.deinit();

    // Control stream: type + SETTINGS with qpack_max_table_capacity=2048.
    var settings_payload: [32]u8 = undefined;
    const settings = h3_connection.Settings{ .qpack_max_table_capacity = 2048 };
    const sp_len = try settings.encodePayload(&settings_payload);
    var control: [64]u8 = undefined;
    control[0] = 0x00;
    control[1] = 0x04; // SETTINGS
    control[2] = @intCast(sp_len);
    @memcpy(control[3 .. 3 + sp_len], settings_payload[0..sp_len]);

    try server.processPeerControlStream(control[0 .. 3 + sp_len]);
    try std.testing.expectEqual(@as(u64, 2048), server.peer_qpack_max_table_capacity);

    // enableQpackDynamic caps the encoder capacity at the peer's value.
    try server.enableQpackDynamic(4096);
    try std.testing.expectEqual(@as(usize, 2048), server.enc_table.?.max_capacity);
}
