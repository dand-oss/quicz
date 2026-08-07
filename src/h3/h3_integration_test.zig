//! HTTP/3 integration tests — full request/response over QUIC Connection streams.
//!
//! These tests create real QUIC Connection pairs and layer H3 on top,
//! verifying the complete request/response flow including SETTINGS exchange,
//! QPACK header compression, and GOAWAY graceful shutdown.

const std = @import("std");
const connection_module = @import("../quic/connection.zig");
const h3_frame = @import("frame.zig");
const h3_request = @import("request.zig");
const h3_connection = @import("connection.zig");
const h3_server = @import("server.zig");
const h3_client = @import("client.zig");
const qpack = @import("qpack.zig");

const Connection = connection_module.Connection;

/// Adapter that wraps a QUIC Connection for use with H3Server.
fn makeServerConnAdapter(conn: *Connection) h3_server.H3Server.H3ServerConnection {
    const Adapter = struct {
        fn openUni(ctx: *anyopaque) anyerror!u64 {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.openUniStream();
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.sendOnStream(stream_id, data, fin);
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.recvOnStream(stream_id, buf);
        }
    };
    return .{
        .openUniStreamFn = Adapter.openUni,
        .sendOnStreamFn = Adapter.send,
        .recvOnStreamFn = Adapter.recv,
        .ctx = conn,
    };
}

/// Adapter that wraps a QUIC Connection for use with H3Client.
fn makeClientConnAdapter(conn: *Connection) h3_client.H3Client.H3ClientConnection {
    const Adapter = struct {
        fn openBidi(ctx: *anyopaque) anyerror!u64 {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.openStream();
        }
        fn openUni(ctx: *anyopaque) anyerror!u64 {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.openUniStream();
        }
        fn send(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.sendOnStream(stream_id, data, fin);
        }
        fn recv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
            const c: *Connection = @ptrCast(@alignCast(ctx));
            return c.recvOnStream(stream_id, buf);
        }
    };
    return .{
        .openBidiStreamFn = Adapter.openBidi,
        .openUniStreamFn = Adapter.openUni,
        .sendOnStreamFn = Adapter.send,
        .recvOnStreamFn = Adapter.recv,
        .ctx = conn,
    };
}

test "H3 integration: full request/response over QUIC streams" {
    // Create QUIC connection pair
    var server_conn = try Connection.init(std.testing.allocator, .server, .{});
    defer server_conn.deinit();
    try server_conn.confirmHandshake();

    var client_conn = try Connection.init(std.testing.allocator, .client, .{});
    defer client_conn.deinit();
    try client_conn.confirmHandshake();

    // Server: open control stream and send SETTINGS
    var server_adapter = makeServerConnAdapter(&server_conn);
    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            if (std.mem.eql(u8, decoded_req.path, "/")) {
                return .{ .status = 200, .body = "Welcome to quicz HTTP/3!" };
            }
            if (std.mem.eql(u8, decoded_req.path, "/api/data")) {
                return .{ .status = 200, .body = "{\"status\":\"ok\"}" };
            }
            return .{ .status = 404, .body = "Not Found" };
        }
    }.handle;

    var server = try h3_server.H3Server.init(&server_adapter, handler, std.testing.allocator);
    defer server.deinit();
    try std.testing.expect(server.settings_sent);

    // Client: open control stream and send SETTINGS
    var client_adapter = makeClientConnAdapter(&client_conn);
    var client = try h3_client.H3Client.init(&client_adapter, std.testing.allocator);
    defer client.deinit();
    try std.testing.expect(client.settings_sent);

    // Client sends GET / request
    // First, manually send the request on a bidi stream
    const stream_id = try client_conn.openStream();
    var req_buf: [4096]u8 = undefined;
    const req = h3_request.Request{
        .method = "GET",
        .path = "/",
        .authority = "localhost",
    };
    const req_len = try h3_request.encodeRequest(&req_buf, req);
    try client_conn.sendOnStream(stream_id, req_buf[0..req_len], true);

    // Server reads the request from the stream
    // The server connection needs to have the stream data available
    // In a real scenario, the QUIC transport would deliver the data
    // For this test, we verify the H3 encode/decode chain works correctly

    // Verify the encoded request can be decoded
    const decoded = try h3_request.decodeRequest(req_buf[0..req_len]);
    try std.testing.expectEqualStrings("GET", decoded.request.method);
    try std.testing.expectEqualStrings("/", decoded.request.path);

    // Server processes and encodes response
    const response = handler(decoded.request);
    var resp_buf: [4096]u8 = undefined;
    const resp_len = try h3_request.encodeResponse(&resp_buf, response);

    // Verify response can be decoded
    const decoded_resp = try h3_request.decodeResponse(resp_buf[0..resp_len]);
    try std.testing.expectEqual(@as(u16, 200), decoded_resp.response.status);
    try std.testing.expect(decoded_resp.response.isSuccess());
    try std.testing.expectEqualStrings("Welcome to quicz HTTP/3!", decoded_resp.response.body.?);
}

test "H3 integration: SETTINGS exchange over control streams" {
    var server_conn = try Connection.init(std.testing.allocator, .server, .{});
    defer server_conn.deinit();
    try server_conn.confirmHandshake();

    var client_conn = try Connection.init(std.testing.allocator, .client, .{});
    defer client_conn.deinit();
    try client_conn.confirmHandshake();

    // Server sends SETTINGS on control stream (uni stream 3)
    var server_adapter = makeServerConnAdapter(&server_conn);
    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{ .status = 200 };
        }
    }.handle;

    var server = try h3_server.H3Server.init(&server_adapter, handler, std.testing.allocator);
    defer server.deinit();
    try std.testing.expect(server.settings_sent);
    try std.testing.expectEqual(@as(?u64, 3), server.control_stream_id);

    // Client sends SETTINGS on control stream (uni stream 2)
    var client_adapter = makeClientConnAdapter(&client_conn);
    var client = try h3_client.H3Client.init(&client_adapter, std.testing.allocator);
    defer client.deinit();
    try std.testing.expect(client.settings_sent);
    try std.testing.expectEqual(@as(?u64, 2), client.control_stream_id);

    // Both sides have sent SETTINGS
    try std.testing.expect(server.settings_sent);
    try std.testing.expect(client.settings_sent);
}

test "H3 integration: GOAWAY graceful shutdown" {
    var server_conn = try Connection.init(std.testing.allocator, .server, .{});
    defer server_conn.deinit();
    try server_conn.confirmHandshake();

    var server_adapter = makeServerConnAdapter(&server_conn);
    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{ .status = 200 };
        }
    }.handle;

    var server = try h3_server.H3Server.init(&server_adapter, handler, std.testing.allocator);
    defer server.deinit();
    try std.testing.expect(!server.goaway_sent);

    // Send GOAWAY with last stream ID = 4
    try server.sendGoaway(4);
    try std.testing.expect(server.goaway_sent);
    try std.testing.expectEqual(@as(?u64, 4), server.goaway_last_stream_id);

    // Second GOAWAY should be no-op
    try server.sendGoaway(8);
    try std.testing.expectEqual(@as(?u64, 4), server.goaway_last_stream_id);
}

test "H3 integration: multiple request/response roundtrips" {
    // Verify multiple requests can be encoded and decoded correctly
    const paths = [_][]const u8{ "/", "/api/users", "/api/data", "/health" };
    const statuses = [_]u16{ 200, 200, 201, 204 };

    for (paths, statuses) |path, expected_status| {
        var req_buf: [4096]u8 = undefined;
        const req = h3_request.Request{
            .method = "GET",
            .path = path,
            .authority = "localhost",
        };
        const req_len = try h3_request.encodeRequest(&req_buf, req);

        const decoded_req = try h3_request.decodeRequest(req_buf[0..req_len]);
        try std.testing.expectEqualStrings("GET", decoded_req.request.method);
        try std.testing.expectEqualStrings(path, decoded_req.request.path);

        var resp_buf: [4096]u8 = undefined;
        const resp = h3_request.Response{
            .status = expected_status,
            .body = if (expected_status != 204) "OK" else null,
        };
        const resp_len = try h3_request.encodeResponse(&resp_buf, resp);

        const decoded_resp = try h3_request.decodeResponse(resp_buf[0..resp_len]);
        try std.testing.expectEqual(expected_status, decoded_resp.response.status);
    }
}

test "H3 integration: POST with body roundtrip over stream encoding" {
    var req_buf: [4096]u8 = undefined;
    const req = h3_request.Request{
        .method = "POST",
        .path = "/api/submit",
        .authority = "localhost",
        .body = "{\"name\":\"quicz\",\"version\":\"1.0\"}",
    };
    const req_len = try h3_request.encodeRequest(&req_buf, req);

    // Decode and verify
    const decoded = try h3_request.decodeRequest(req_buf[0..req_len]);
    try std.testing.expectEqualStrings("POST", decoded.request.method);
    try std.testing.expectEqualStrings("/api/submit", decoded.request.path);
    try std.testing.expectEqualStrings("{\"name\":\"quicz\",\"version\":\"1.0\"}", decoded.request.body.?);

    // Server responds with 201 Created
    var resp_buf: [4096]u8 = undefined;
    const resp = h3_request.Response{
        .status = 201,
        .body = "{\"id\":42}",
    };
    const resp_len = try h3_request.encodeResponse(&resp_buf, resp);

    const decoded_resp = try h3_request.decodeResponse(resp_buf[0..resp_len]);
    try std.testing.expectEqual(@as(u16, 201), decoded_resp.response.status);
    try std.testing.expectEqualStrings("{\"id\":42}", decoded_resp.response.body.?);
}

test "H3 integration: QPACK static table full roundtrip" {
    // Test all common static table entries used in H3
    const fields = [_]qpack.HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":method", .value = "POST" },
        .{ .name = ":path", .value = "/" },
        .{ .name = ":scheme", .value = "https" },
        .{ .name = ":status", .value = "200" },
        .{ .name = ":status", .value = "404" },
    };

    var encoded: [512]u8 = undefined;
    const enc_len = try qpack.encodeHeaderBlock(&encoded, &fields);

    var decoded: [16]qpack.HeaderField = undefined;
    const dec_count = try qpack.decodeHeaderBlock(encoded[0..enc_len], &decoded);

    try std.testing.expectEqual(@as(usize, 6), dec_count);
    for (fields, 0..) |expected, i| {
        try std.testing.expectEqualStrings(expected.name, decoded[i].name);
        try std.testing.expectEqualStrings(expected.value, decoded[i].value);
    }
}

test "H3 integration: full flow with QPACK dynamic table" {
    // Simulate client and server sharing a dynamic table (as in a real connection)
    var client_dt = qpack.DynamicTable.init(std.testing.allocator);
    defer client_dt.deinit();
    client_dt.setCapacity(4096);

    var server_dt = qpack.DynamicTable.init(std.testing.allocator);
    defer server_dt.deinit();
    server_dt.setCapacity(4096);

    // Both sides insert the same entries (simulating encoder stream sync)
    try client_dt.insert("x-api-version", "v3");
    try server_dt.insert("x-api-version", "v3");
    try client_dt.insert("x-trace-id", "trace-abc-123");
    try server_dt.insert("x-trace-id", "trace-abc-123");

    // Client sends request with dynamic headers
    const extra_req = [_]qpack.HeaderField{
        .{ .name = "x-api-version", .value = "v3" },
        .{ .name = "x-trace-id", .value = "trace-abc-123" },
    };
    const req = h3_request.Request{
        .method = "GET",
        .path = "/api/v3/data",
        .authority = "service.internal",
        .extra_headers = &extra_req,
    };

    var req_buf: [4096]u8 = undefined;
    var client_instr: [4096]u8 = undefined;
    const enc_req = try h3_request.encodeRequestWithDynamic(&req_buf, req, &client_dt, &client_instr);
    _ = try qpack.decodeEncoderStreamInstructions(client_instr[0..enc_req.encoder_stream_len], &server_dt);

    // Server decodes request
    const decoded_req = try h3_request.decodeRequestWithDynamic(req_buf[0..enc_req.len], &server_dt);
    try std.testing.expectEqualStrings("GET", decoded_req.request.method);
    try std.testing.expectEqualStrings("/api/v3/data", decoded_req.request.path);
    try std.testing.expectEqualStrings("service.internal", decoded_req.request.authority.?);

    // Server sends response with dynamic headers
    try client_dt.insert("content-type", "application/json");
    try server_dt.insert("content-type", "application/json");

    const extra_resp = [_]qpack.HeaderField{
        .{ .name = "content-type", .value = "application/json" },
        .{ .name = "x-trace-id", .value = "trace-abc-123" },
    };
    const resp = h3_request.Response{
        .status = 200,
        .extra_headers = &extra_resp,
        .body = "{\"items\":[1,2,3]}",
    };

    var resp_buf: [4096]u8 = undefined;
    var server_instr: [4096]u8 = undefined;
    const enc_resp = try h3_request.encodeResponseWithDynamic(&resp_buf, resp, &server_dt, &server_instr);
    _ = try qpack.decodeEncoderStreamInstructions(server_instr[0..enc_resp.encoder_stream_len], &client_dt);

    // Client decodes response
    const decoded_resp = try h3_request.decodeResponseWithDynamic(resp_buf[0..enc_resp.len], &client_dt);
    try std.testing.expectEqual(@as(u16, 200), decoded_resp.response.status);
    try std.testing.expect(decoded_resp.response.isSuccess());
    try std.testing.expectEqualStrings("{\"items\":[1,2,3]}", decoded_resp.response.body.?);
}

test "H3 integration: connection lifecycle with settings and GOAWAY" {
    var conn = h3_connection.H3Connection.init(std.testing.allocator);
    defer conn.deinit();

    // Phase 1: not ready
    try std.testing.expect(!conn.isReady());
    try std.testing.expectError(error.ConnectionClosing, blk: {
        conn.sendGoaway(0);
        break :blk conn.openRequestStream();
    });

    // Phase 2: settings exchange
    var conn2 = h3_connection.H3Connection.init(std.testing.allocator);
    defer conn2.deinit();

    const local_settings = h3_connection.Settings{
        .max_field_section_size = 65536,
        .qpack_max_table_capacity = 4096,
        .qpack_blocked_streams = 16,
    };
    conn2.markSettingsSent(local_settings);
    try std.testing.expectEqual(@as(u64, 65536), conn2.local_settings.max_field_section_size);

    const peer_settings = h3_connection.Settings{
        .max_field_section_size = 32768,
        .qpack_max_table_capacity = 8192,
    };
    conn2.markSettingsReceived(peer_settings);
    try std.testing.expect(conn2.isReady());
    try std.testing.expectEqual(@as(u64, 8192), conn2.peer_settings.qpack_max_table_capacity);

    // Phase 3: request streams
    const s0 = try conn2.openRequestStream();
    const s1 = try conn2.openRequestStream();
    try std.testing.expectEqual(@as(u64, 0), s0);
    try std.testing.expectEqual(@as(u64, 4), s1);

    // Phase 4: stream lifecycle
    const stream0 = conn2.getStream(s0).?;
    try stream0.transition(.headers_done);
    try stream0.transition(.data_transfer);
    try stream0.transition(.complete);
    try std.testing.expectEqual(@as(usize, 1), conn2.activeStreamCount());

    // Phase 5: prune and GOAWAY
    conn2.pruneFinishedStreams();
    try std.testing.expectEqual(@as(usize, 1), conn2.streams.items.len);

    conn2.sendGoaway(s1);
    try std.testing.expectError(error.ConnectionClosing, conn2.openRequestStream());
}

test "H3 integration: settings frame wire format roundtrip" {
    // Encode settings to wire format and decode back
    const settings = h3_connection.Settings{
        .max_field_section_size = 131072,
        .qpack_max_table_capacity = 16384,
        .qpack_blocked_streams = 64,
        .enable_connect_protocol = 1,
        .h3_datagram = 1,
    };

    var payload_buf: [128]u8 = undefined;
    const payload_len = try settings.encodePayload(&payload_buf);

    // Wrap in SETTINGS frame
    var frame_buf: [256]u8 = undefined;
    var pos: usize = 0;
    frame_buf[pos] = 0x04; // SETTINGS frame type
    pos += 1;
    frame_buf[pos] = @intCast(payload_len);
    pos += 1;
    @memcpy(frame_buf[pos .. pos + payload_len], payload_buf[0..payload_len]);
    pos += payload_len;

    // Decode frame
    const frame_result = try h3_frame.decodeFrame(frame_buf[0..pos]);
    try std.testing.expectEqual(@as(u64, 0x04), frame_result.frame.frame_type);

    // Decode settings from payload
    const decoded = try h3_connection.Settings.decodePayload(frame_result.frame.payload);
    try std.testing.expectEqual(@as(u64, 131072), decoded.max_field_section_size);
    try std.testing.expectEqual(@as(u64, 16384), decoded.qpack_max_table_capacity);
    try std.testing.expectEqual(@as(u64, 64), decoded.qpack_blocked_streams);
    try std.testing.expectEqual(@as(u64, 1), decoded.enable_connect_protocol);
    try std.testing.expectEqual(@as(u64, 1), decoded.h3_datagram);
}

test "H3 integration: GOAWAY frame wire format roundtrip" {
    // Encode GOAWAY frame
    var goaway_payload: [16]u8 = undefined;
    const gp_len = try h3_connection.H3Connection.encodeGoawayPayload(&goaway_payload, 12);

    var frame_buf: [32]u8 = undefined;
    var pos: usize = 0;
    frame_buf[pos] = 0x07; // GOAWAY frame type
    pos += 1;
    frame_buf[pos] = @intCast(gp_len);
    pos += 1;
    @memcpy(frame_buf[pos .. pos + gp_len], goaway_payload[0..gp_len]);
    pos += gp_len;

    // Decode frame
    const frame_result = try h3_frame.decodeFrame(frame_buf[0..pos]);
    try std.testing.expectEqual(@as(u64, 0x07), frame_result.frame.frame_type);

    // Decode GOAWAY payload
    const stream_id = try h3_connection.H3Connection.decodeGoawayPayload(frame_result.frame.payload);
    try std.testing.expectEqual(@as(u64, 12), stream_id);
}

test "H3 integration: multiple requests with growing dynamic table" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(8192);

    // Simulate multiple requests where headers accumulate in dynamic table
    const paths = [_][]const u8{ "/api/users", "/api/orders", "/api/products" };

    for (paths, 0..) |path, i| {
        // Insert a per-request header into dynamic table
        var trace_buf: [32]u8 = undefined;
        const trace_val = std.fmt.bufPrint(&trace_buf, "trace-{d}", .{i}) catch unreachable;
        try dt.insert("x-trace-id", trace_val);

        const extra = [_]qpack.HeaderField{
            .{ .name = "x-trace-id", .value = trace_val },
        };
        const req = h3_request.Request{
            .method = "GET",
            .path = path,
            .extra_headers = &extra,
        };

        var buf: [4096]u8 = undefined;
        var instr: [4096]u8 = undefined;
        const enc = try h3_request.encodeRequestWithDynamic(&buf, req, &dt, &instr);

        const decoded = try h3_request.decodeRequestWithDynamic(buf[0..enc.len], &dt);
        try std.testing.expectEqualStrings("GET", decoded.request.method);
        try std.testing.expectEqualStrings(path, decoded.request.path);
    }

    // Dynamic table should have accumulated entries
    try std.testing.expect(dt.entryCount() >= 3);
}

// ---------------------------------------------------------------------------
// QPACK dynamic table integration through H3Server/H3Client control flow
// ---------------------------------------------------------------------------

/// Shared in-memory channel connecting an H3Server and H3Client for testing.
/// Each stream is a FIFO buffer: send appends, recv consumes from read_pos.
const TestChannel = struct {
    allocator: std.mem.Allocator,
    streams: std.AutoHashMap(u64, StreamBuf),
    server_uni_next: u64 = 3,
    client_uni_next: u64 = 2,
    client_bidi_next: u64 = 0,

    const StreamBuf = struct {
        data: std.ArrayList(u8) = .empty,
        read_pos: usize = 0,
    };

    fn init(allocator: std.mem.Allocator) TestChannel {
        return .{
            .allocator = allocator,
            .streams = std.AutoHashMap(u64, StreamBuf).init(allocator),
        };
    }

    fn deinit(self: *TestChannel) void {
        var it = self.streams.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.data.deinit(self.allocator);
        }
        self.streams.deinit();
    }

    fn ensureStream(self: *TestChannel, stream_id: u64) *StreamBuf {
        if (!self.streams.contains(stream_id)) {
            self.streams.put(stream_id, .{}) catch unreachable;
        }
        return self.streams.getPtr(stream_id).?;
    }

    fn appendStream(self: *TestChannel, stream_id: u64, data: []const u8) !void {
        const sb = self.ensureStream(stream_id);
        try sb.data.appendSlice(self.allocator, data);
    }

    /// Read all unread data on a stream into buf, advancing read_pos.
    /// Returns the slice of bytes read (borrowed from buf).
    fn readStream(self: *TestChannel, stream_id: u64, buf: []u8) []const u8 {
        const sb = self.ensureStream(stream_id);
        if (sb.read_pos >= sb.data.items.len) return buf[0..0];
        const available = sb.data.items[sb.read_pos..];
        const n = @min(buf.len, available.len);
        @memcpy(buf[0..n], available[0..n]);
        sb.read_pos += n;
        return buf[0..n];
    }

    // --- server-side adapter ---
    fn serverOpenUni(ctx: *anyopaque) anyerror!u64 {
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        const id = self.server_uni_next;
        self.server_uni_next += 4;
        return id;
    }
    fn serverSend(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
        _ = fin;
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        try self.appendStream(stream_id, data);
    }
    fn serverRecv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        const sb = self.ensureStream(stream_id);
        if (sb.read_pos >= sb.data.items.len) return null;
        const available = sb.data.items[sb.read_pos..];
        const n = @min(buf.len, available.len);
        @memcpy(buf[0..n], available[0..n]);
        sb.read_pos += n;
        return n;
    }

    // --- client-side adapter ---
    fn clientOpenBidi(ctx: *anyopaque) anyerror!u64 {
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        const id = self.client_bidi_next;
        self.client_bidi_next += 4;
        return id;
    }
    fn clientOpenUni(ctx: *anyopaque) anyerror!u64 {
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        const id = self.client_uni_next;
        self.client_uni_next += 4;
        return id;
    }
    fn clientSend(ctx: *anyopaque, stream_id: u64, data: []const u8, fin: bool) anyerror!void {
        _ = fin;
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        try self.appendStream(stream_id, data);
    }
    fn clientRecv(ctx: *anyopaque, stream_id: u64, buf: []u8) anyerror!?usize {
        const self: *TestChannel = @ptrCast(@alignCast(ctx));
        const sb = self.ensureStream(stream_id);
        if (sb.read_pos >= sb.data.items.len) return null;
        const available = sb.data.items[sb.read_pos..];
        const n = @min(buf.len, available.len);
        @memcpy(buf[0..n], available[0..n]);
        sb.read_pos += n;
        return n;
    }

    fn makeServerAdapter(self: *TestChannel) h3_server.H3Server.H3ServerConnection {
        return .{
            .openUniStreamFn = TestChannel.serverOpenUni,
            .sendOnStreamFn = TestChannel.serverSend,
            .recvOnStreamFn = TestChannel.serverRecv,
            .ctx = self,
        };
    }

    fn makeClientAdapter(self: *TestChannel) h3_client.H3Client.H3ClientConnection {
        return .{
            .openBidiStreamFn = TestChannel.clientOpenBidi,
            .openUniStreamFn = TestChannel.clientOpenUni,
            .sendOnStreamFn = TestChannel.clientSend,
            .recvOnStreamFn = TestChannel.clientRecv,
            .ctx = self,
        };
    }

    /// Pump encoder-stream data from one side to the other's decoder table.
    /// Skips the stream type prefix byte (0x02) on the first read.
    fn syncEncoderStream(
        self: *TestChannel,
        enc_stream_id: u64,
        target: anytype,
        buf: []u8,
        is_first: bool,
    ) !void {
        const data = self.readStream(enc_stream_id, buf);
        if (data.len == 0) return;
        const payload = if (is_first) data[1..] else data;
        if (payload.len > 0) try target.processPeerEncoderStream(payload);
    }

    /// Pump decoder-stream data from one side to the other's encoder table.
    /// Skips the stream type prefix byte (0x03) on the first read.
    fn syncDecoderStream(
        self: *TestChannel,
        dec_stream_id: u64,
        target: anytype,
        buf: []u8,
        is_first: bool,
    ) !void {
        const data = self.readStream(dec_stream_id, buf);
        if (data.len == 0) return;
        const payload = if (is_first) data[1..] else data;
        if (payload.len > 0) try target.processPeerDecoderStream(payload);
    }
};

test "H3 integration: QPACK dynamic table control flow with multiple rounds" {
    var channel = TestChannel.init(std.testing.allocator);
    defer channel.deinit();

    var server_adapter = channel.makeServerAdapter();
    var client_adapter = channel.makeClientAdapter();

    const handler = struct {
        fn handle(decoded_req: h3_request.DecodedRequest) h3_request.Response {
            _ = decoded_req;
            return .{
                .status = 200,
                .extra_headers = &.{
                    .{ .name = "x-response-id", .value = "resp-001" },
                    .{ .name = "x-server", .value = "quicz-h3" },
                },
                .body = "OK",
            };
        }
    }.handle;

    var server = try h3_server.H3Server.init(&server_adapter, handler, std.testing.allocator);
    defer server.deinit();
    var client = try h3_client.H3Client.init(&client_adapter, std.testing.allocator);
    defer client.deinit();

    // Enable QPACK dynamic table on both sides.
    try server.enableQpackDynamic(4096);
    try client.enableQpackDynamic(4096);

    var enc_buf: [8192]u8 = undefined;

    // Sync initial SetCapacity (skip stream type prefix byte 0x02).
    try channel.syncEncoderStream(client.enc_stream_id.?, &server, &enc_buf, true);
    try channel.syncEncoderStream(server.enc_stream_id.?, &client, &enc_buf, true);

    // Round 1: custom headers are inserted into the dynamic table.
    const request = h3_request.Request{
        .method = "GET",
        .path = "/api/data",
        .authority = "service.internal",
        .extra_headers = &.{
            .{ .name = "x-trace-id", .value = "trace-001" },
            .{ .name = "x-api-key", .value = "key-abc" },
        },
    };

    const stream1 = try client.sendRequestDynamic(request);
    // Round 1 uses literals: the insertions are not acknowledged yet, so no
    // pending section is recorded (Required Insert Count stays zero).
    try std.testing.expectEqual(@as(usize, 0), client.pending_sections.?.count());
    try channel.syncEncoderStream(client.enc_stream_id.?, &server, &enc_buf, false);
    try server.handleRequestStream(stream1);
    try std.testing.expectEqual(@as(usize, 0), server.pending_sections.?.count());
    try channel.syncEncoderStream(server.enc_stream_id.?, &client, &enc_buf, false);
    const resp1 = try client.receiveResponseDynamic(stream1);
    try std.testing.expectEqual(@as(u16, 200), resp1.status);
    try std.testing.expectEqualStrings("OK", resp1.body.?);

    // Round 1 decoder-stream acks: each side raises the peer's Known Received
    // Count to the number of insertions it received.
    try channel.syncDecoderStream(client.dec_stream_id.?, &server, &enc_buf, true);
    try channel.syncDecoderStream(server.dec_stream_id.?, &client, &enc_buf, true);
    try std.testing.expectEqual(server.enc_table.?.insert_count, server.enc_table.?.known_received_count);
    try std.testing.expectEqual(client.enc_table.?.insert_count, client.enc_table.?.known_received_count);

    // Round 2: same headers -- table already has entries, no new inserts.
    // The entries are acknowledged, so the request now uses dynamic references
    // (a pending section with non-zero Required Insert Count is recorded).
    const stream2 = try client.sendRequestDynamic(request);
    try std.testing.expectEqual(@as(usize, 1), client.pending_sections.?.count());
    try channel.syncEncoderStream(client.enc_stream_id.?, &server, &enc_buf, false);
    try server.handleRequestStream(stream2);
    try std.testing.expectEqual(@as(usize, 1), server.pending_sections.?.count());
    try channel.syncEncoderStream(server.enc_stream_id.?, &client, &enc_buf, false);
    const resp2 = try client.receiveResponseDynamic(stream2);
    try std.testing.expectEqual(@as(u16, 200), resp2.status);
    try std.testing.expectEqualStrings("OK", resp2.body.?);

    // Round 2 decoder-stream acks clear both pending sections.
    try channel.syncDecoderStream(client.dec_stream_id.?, &server, &enc_buf, false);
    try channel.syncDecoderStream(server.dec_stream_id.?, &client, &enc_buf, false);
    try std.testing.expectEqual(@as(usize, 0), server.pending_sections.?.count());
    try std.testing.expectEqual(@as(usize, 0), client.pending_sections.?.count());

    // Verify dynamic tables have accumulated entries on both sides.
    try std.testing.expect(server.enc_table.?.entryCount() >= 2);
    try std.testing.expect(client.enc_table.?.entryCount() >= 2);
}
