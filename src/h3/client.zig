//! HTTP/3 client handler (RFC 9114 §4-6).
//!
//! Sends H3 requests over QUIC streams and receives responses.
//! Works with any QUIC Connection that provides stream I/O.

const std = @import("std");
const h3_frame = @import("frame.zig");
const h3_request = @import("request.zig");
const h3_connection = @import("connection.zig");
const qpack = @import("qpack.zig");

/// HTTP/3 client state machine over a QUIC connection.
pub const H3Client = struct {
    conn: *H3ClientConnection,
    allocator: std.mem.Allocator,
    control_stream_id: ?u64 = null,
    settings_sent: bool = false,
    settings_received: bool = false,
    next_request_stream_id: u64 = 0,
    goaway_received: bool = false,

    /// Client's encoder table for requests. Produces Insert/Duplicate/SetCapacity
    /// instructions sent on the QPACK encoder stream (type 0x02) to the server.
    enc_table: ?qpack.DynamicTable = null,
    /// Mirror of the server's encoder table for responses. Updated by consuming
    /// the server's encoder stream instructions via processPeerEncoderStream.
    dec_table: ?qpack.DynamicTable = null,
    /// Client's QPACK encoder stream (type 0x02).
    enc_stream_id: ?u64 = null,
    /// Client's QPACK decoder stream (type 0x03).
    dec_stream_id: ?u64 = null,
    /// Required Insert Count of each dynamic section sent on a stream, keyed by
    /// stream ID, so peer Section Acknowledgment can raise Known Received Count.
    pending_sections: ?std.AutoHashMap(u64, u64) = null,
    /// Number of peer insertions this decoder has already acknowledged via
    /// Insert Count Increment, for emitting only the outstanding delta.
    decoder_known_insert_count: u64 = 0,

    pub const H3ClientConnection = struct {
        /// Open a locally-initiated bidirectional stream.
        openBidiStreamFn: *const fn (ctx: *anyopaque) anyerror!u64,
        /// Open a locally-initiated unidirectional stream.
        openUniStreamFn: *const fn (ctx: *anyopaque) anyerror!u64,
        /// Send data on a stream.
        sendOnStreamFn: *const fn (ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void,
        /// Receive data from a stream. Returns null if no data available.
        recvOnStreamFn: *const fn (ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize,
        /// Opaque context pointer.
        ctx: *anyopaque,

        pub fn openBidiStream(self: *H3ClientConnection) !u64 {
            return self.openBidiStreamFn(self.ctx);
        }
        pub fn openUniStream(self: *H3ClientConnection) !u64 {
            return self.openUniStreamFn(self.ctx);
        }
        pub fn sendOnStream(self: *H3ClientConnection, stream_id: u64, data: []const u8, fin: bool) !void {
            return self.sendOnStreamFn(self.ctx, stream_id, data, fin);
        }
        pub fn recvOnStream(self: *H3ClientConnection, stream_id: u64, buf: []u8) !?usize {
            return self.recvOnStreamFn(self.ctx, stream_id, buf);
        }
    };

    /// Initialize the client and send SETTINGS on the control stream.
    pub fn init(conn: *H3ClientConnection, allocator: std.mem.Allocator) !H3Client {
        var client = H3Client{
            .conn = conn,
            .allocator = allocator,
        };
        try client.sendSettings();
        return client;
    }

    /// Release QPACK dynamic table resources.
    pub fn deinit(self: *H3Client) void {
        if (self.enc_table) |*t| t.deinit();
        if (self.dec_table) |*t| t.deinit();
        if (self.pending_sections) |*m| m.deinit();
    }

    /// Enable QPACK dynamic table compression (RFC 9204).
    /// Opens QPACK encoder (0x02) and decoder (0x03) unidirectional streams,
    /// initializes both tables, and advertises capacity to the peer via a
    /// Set Capacity instruction on the encoder stream.
    pub fn enableQpackDynamic(self: *H3Client, capacity: usize) !void {
        self.enc_table = qpack.DynamicTable.init(self.allocator);
        self.dec_table = qpack.DynamicTable.init(self.allocator);
        self.pending_sections = std.AutoHashMap(u64, u64).init(self.allocator);
        self.enc_table.?.setCapacity(capacity);
        self.dec_table.?.setCapacity(capacity);

        // Open encoder stream (type 0x02) and send Set Capacity.
        self.enc_stream_id = try self.conn.openUniStream();
        var enc_buf: [32]u8 = undefined;
        var pos: usize = 0;
        enc_buf[pos] = 0x02;
        pos += 1;
        pos += try qpack.encodeEncoderInstruction(enc_buf[pos..], .{ .set_capacity = capacity });
        try self.conn.sendOnStream(self.enc_stream_id.?, enc_buf[0..pos], false);

        // Open decoder stream (type 0x03).
        self.dec_stream_id = try self.conn.openUniStream();
        var dec_buf: [4]u8 = undefined;
        dec_buf[0] = 0x03;
        try self.conn.sendOnStream(self.dec_stream_id.?, dec_buf[0..1], false);
    }

    /// Feed peer (server) encoder stream data into the decoder-side dynamic
    /// table so subsequent response header blocks with dynamic references
    /// resolve correctly (RFC 9204 §4.3).
    pub fn processPeerEncoderStream(self: *H3Client, data: []const u8) !void {
        if (self.dec_table) |*dt| {
            _ = try qpack.decodeEncoderStreamInstructions(data, dt);
        }
    }

    /// Feed peer (server) decoder stream data into the encoder-side table so
    /// Section Acknowledgment / Insert Count Increment advance the Known
    /// Received Count (RFC 9204 §4.4).
    pub fn processPeerDecoderStream(self: *H3Client, data: []const u8) !void {
        if (self.enc_table) |*et| {
            if (self.pending_sections) |*ps| {
                _ = try qpack.decodeDecoderStreamInstructions(data, et, ps);
            }
        }
    }

    /// Emit Section Acknowledgment (when the decoded section used dynamic
    /// references) and any outstanding Insert Count Increment on the QPACK
    /// decoder stream (RFC 9204 §4.4).
    fn sendSectionAcknowledgement(self: *H3Client, stream_id: u64, required_insert_count: u64) !void {
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

    /// Open the client control stream and send SETTINGS.
    fn sendSettings(self: *H3Client) !void {
        const stream_id = try self.conn.openUniStream();
        self.control_stream_id = stream_id;

        var buf: [128]u8 = undefined;
        var pos: usize = 0;

        // Stream type: control (0x00)
        buf[pos] = 0x00;
        pos += 1;

        // SETTINGS frame
        var settings_payload: [16]u8 = undefined;
        const settings = h3_connection.Settings{ .max_field_section_size = 8192 };
        const sp_len = try settings.encodePayload(&settings_payload);

        buf[pos] = 0x04; // SETTINGS frame type
        pos += 1;
        buf[pos] = @intCast(sp_len);
        pos += 1;
        @memcpy(buf[pos .. pos + sp_len], settings_payload[0..sp_len]);
        pos += sp_len;

        try self.conn.sendOnStream(stream_id, buf[0..pos], false);
        self.settings_sent = true;
    }

    /// Send an HTTP request and receive the response.
    /// Opens a new bidi stream, sends the request, and reads the response.
    pub fn sendRequest(self: *H3Client, request: h3_request.Request) !h3_request.DecodedResponse {
        // Open bidi stream for request
        const stream_id = try self.conn.openBidiStream();
        self.next_request_stream_id = stream_id + 4;

        // Encode and send request
        var req_buf: [8192]u8 = undefined;
        const req_len = try h3_request.encodeRequest(&req_buf, request);
        try self.conn.sendOnStream(stream_id, req_buf[0..req_len], true);

        // Read response
        var resp_buf: [8192]u8 = undefined;
        var total_read: usize = 0;

        while (total_read < resp_buf.len) {
            const n = try self.conn.recvOnStream(stream_id, resp_buf[total_read..]) orelse break;
            total_read += n;
            // Try to decode - if successful, we have a complete response
            if (total_read > 0) {
                const result = h3_request.decodeResponse(resp_buf[0..total_read]) catch continue;
                return result.response;
            }
        }

        if (total_read == 0) return error.NoResponse;

        const result = try h3_request.decodeResponse(resp_buf[0..total_read]);
        return result.response;
    }

    /// Send an HTTP request using QPACK dynamic table compression (RFC 9204).
    /// Encodes the request with dynamic insertions, sends encoder stream
    /// instructions on the QPACK encoder stream, then sends the request on
    /// a new bidi stream. Returns the stream ID for later response retrieval
    /// via receiveResponseDynamic.
    ///
    /// The caller must ensure the peer receives and processes the encoder
    /// stream instructions before decoding the request. Likewise, before
    /// calling receiveResponseDynamic, the caller must feed any peer encoder
    /// stream data via processPeerEncoderStream.
    pub fn sendRequestDynamic(self: *H3Client, request: h3_request.Request) !u64 {
        const stream_id = try self.conn.openBidiStream();
        self.next_request_stream_id = stream_id + 4;

        var req_buf: [8192]u8 = undefined;
        var enc_instr: [4096]u8 = undefined;
        const enc = try h3_request.encodeRequestWithDynamic(&req_buf, request, &self.enc_table.?, &enc_instr);
        if (self.pending_sections) |*ps| {
            if (enc.required_insert_count > 0) try ps.put(stream_id, enc.required_insert_count);
        }

        // Send encoder stream instructions before the request so the peer's
        // decoder table is synchronized when it decodes the header block.
        if (enc.encoder_stream_len > 0) {
            try self.conn.sendOnStream(self.enc_stream_id.?, enc_instr[0..enc.encoder_stream_len], false);
        }
        try self.conn.sendOnStream(stream_id, req_buf[0..enc.len], true);
        return stream_id;
    }

    /// Read and decode a response using QPACK dynamic table.
    /// The caller must ensure peer encoder stream data has been processed via
    /// processPeerEncoderStream before calling this, so the decoder-side table
    /// matches the server's encoder table state.
    pub fn receiveResponseDynamic(self: *H3Client, stream_id: u64) !h3_request.DecodedResponse {
        var resp_buf: [8192]u8 = undefined;
        var total_read: usize = 0;

        while (total_read < resp_buf.len) {
            const n = try self.conn.recvOnStream(stream_id, resp_buf[total_read..]) orelse break;
            total_read += n;
            if (total_read > 0) {
                if (h3_request.decodeResponseWithDynamic(resp_buf[0..total_read], &self.dec_table.?)) |result| {
                    try self.sendSectionAcknowledgement(stream_id, result.required_insert_count);
                    return result.response;
                } else |_| {}
            }
        }

        if (total_read == 0) return error.NoResponse;
        const result = try h3_request.decodeResponseWithDynamic(resp_buf[0..total_read], &self.dec_table.?);
        try self.sendSectionAcknowledgement(stream_id, result.required_insert_count);
        return result.response;
    }

    /// Whether the client is ready to send requests.
    pub fn isReady(self: *const H3Client) bool {
        return self.settings_sent;
    }
};

test "H3Client sends SETTINGS on control stream" {
    const MockCtx = struct {
        sent_data: std.ArrayList(u8) = .empty,
        sent_stream_id: ?u64 = null,
        next_uni_id: u64 = 2, // client-initiated uni

        fn openBidi(ctx: *anyopaque) !u64 {
            _ = ctx;
            return 0;
        }
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

    var conn = H3Client.H3ClientConnection{
        .openBidiStreamFn = MockCtx.openBidi,
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };

    var client = try H3Client.init(&conn, std.testing.allocator);
    defer client.deinit();
    try std.testing.expect(client.settings_sent);
    try std.testing.expect(client.isReady());
    try std.testing.expectEqual(@as(?u64, 2), client.control_stream_id);
    // Control stream: stream_type(0x00) + SETTINGS frame(0x04)
    try std.testing.expect(mock.sent_data.items.len > 2);
    try std.testing.expectEqual(@as(u8, 0x00), mock.sent_data.items[0]);
    try std.testing.expectEqual(@as(u8, 0x04), mock.sent_data.items[1]);
}

test "H3Client sends request and receives response" {
    // Pre-encode a response that the mock will return
    var resp_wire: [4096]u8 = undefined;
    const resp = h3_request.Response{
        .status = 200,
        .body = "Hello from server!",
    };
    const resp_len = try h3_request.encodeResponse(&resp_wire, resp);

    const MockCtx = struct {
        response_wire: []const u8,
        response_pos: usize = 0,
        request_data: std.ArrayList(u8) = .empty,
        request_stream_id: ?u64 = null,
        next_bidi_id: u64 = 0,

        fn openBidi(ctx: *anyopaque) !u64 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const id = self.next_bidi_id;
            self.next_bidi_id += 4;
            return id;
        }
        fn openUni(ctx: *anyopaque) !u64 {
            _ = ctx;
            return 2;
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) !void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = fin;
            if (stream_id != 2) { // not control stream
                self.request_stream_id = stream_id;
                try self.request_data.appendSlice(std.testing.allocator, data);
            }
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) !?usize {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            _ = stream_id;
            if (self.response_pos >= self.response_wire.len) return null;
            const available = self.response_wire[self.response_pos..];
            const n = @min(buf.len, available.len);
            @memcpy(buf[0..n], available[0..n]);
            self.response_pos += n;
            return n;
        }
    };

    var mock = MockCtx{ .response_wire = resp_wire[0..resp_len] };
    defer mock.request_data.deinit(std.testing.allocator);

    var conn = H3Client.H3ClientConnection{
        .openBidiStreamFn = MockCtx.openBidi,
        .openUniStreamFn = MockCtx.openUni,
        .sendOnStreamFn = MockCtx.send,
        .recvOnStreamFn = MockCtx.recv,
        .ctx = &mock,
    };

    var client = try H3Client.init(&conn, std.testing.allocator);
    defer client.deinit();

    const request = h3_request.Request{
        .method = "GET",
        .path = "/test",
        .authority = "example.com",
    };

    const response = try client.sendRequest(request);
    try std.testing.expectEqual(@as(u16, 200), response.status);
    try std.testing.expect(response.isSuccess());
    try std.testing.expectEqualStrings("Hello from server!", response.body.?);

    // Verify the request was sent on stream 0
    try std.testing.expectEqual(@as(?u64, 0), mock.request_stream_id);
    // Verify request can be decoded
    const decoded_req = try h3_request.decodeRequest(mock.request_data.items);
    try std.testing.expectEqualStrings("GET", decoded_req.request.method);
    try std.testing.expectEqualStrings("/test", decoded_req.request.path);
}
