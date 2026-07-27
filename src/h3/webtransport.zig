//! WebTransport over HTTP/3 (draft-ietf-webtrans-http3).
//!
//! Implements WebTransport session establishment, bidirectional
//! streams, and datagrams over an HTTP/3 connection.

const std = @import("std");
const h3_frame = @import("frame.zig");
const h3_connection = @import("connection.zig");

/// WebTransport session state.
pub const WtSession = struct {
    /// Whether the session has been established (CONNECT accepted).
    established: bool = false,
    /// The QUIC stream ID of the CONNECT request stream.
    connect_stream_id: ?u64 = null,
    /// Session ID (from CONNECT response).
    session_id: ?u64 = null,
    /// Active WebTransport bidi streams.
    bidi_streams: std.ArrayList(WtStream) = .empty,
    /// Active WebTransport uni streams.
    uni_streams: std.ArrayList(WtStream) = .empty,
    /// Datagrams received.
    datagrams_received: u64 = 0,
    /// Datagrams sent.
    datagrams_sent: u64 = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) WtSession {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *WtSession) void {
        self.bidi_streams.deinit(self.allocator);
        self.uni_streams.deinit(self.allocator);
    }

    /// Establish a WebTransport session (client-side CONNECT).
    pub fn establish(self: *WtSession, connect_stream_id: u64) void {
        self.established = true;
        self.connect_stream_id = connect_stream_id;
        self.session_id = connect_stream_id;
    }

    /// Open a WebTransport bidirectional stream.
    pub fn openBidiStream(self: *WtSession, stream_id: u64) !void {
        try self.bidi_streams.append(self.allocator, .{
            .stream_id = stream_id,
            .is_bidi = true,
        });
    }

    /// Open a WebTransport unidirectional stream.
    pub fn openUniStream(self: *WtSession, stream_id: u64) !void {
        try self.uni_streams.append(self.allocator, .{
            .stream_id = stream_id,
            .is_bidi = false,
        });
    }

    /// Get a bidi stream by ID.
    pub fn getBidiStream(self: *WtSession, stream_id: u64) ?*WtStream {
        for (self.bidi_streams.items) |*s| {
            if (s.stream_id == stream_id) return s;
        }
        return null;
    }

    /// Record a datagram sent.
    pub fn recordDatagramSent(self: *WtSession) void {
        self.datagrams_sent += 1;
    }

    /// Record a datagram received.
    pub fn recordDatagramReceived(self: *WtSession) void {
        self.datagrams_received += 1;
    }

    /// Close the session.
    pub fn close(self: *WtSession) void {
        self.established = false;
        for (self.bidi_streams.items) |*s| s.state = .closed;
        for (self.uni_streams.items) |*s| s.state = .closed;
    }
};

/// A WebTransport stream (bidi or uni).
pub const WtStream = struct {
    stream_id: u64,
    is_bidi: bool,
    state: WtStreamState = .open,
    bytes_sent: u64 = 0,
    bytes_received: u64 = 0,
};

/// WebTransport stream state.
pub const WtStreamState = enum {
    open,
    /// FIN sent but not yet acknowledged.
    fin_sent,
    /// FIN received.
    fin_received,
    /// Both directions closed.
    closed,
    /// Reset sent or received.
    reset,
};

/// Encode a WebTransport CONNECT request as H3 HEADERS.
/// Uses the extended CONNECT method with :protocol = webtransport.
pub fn encodeConnectRequest(out: []u8, authority: []const u8, path: []const u8) !usize {
    const qpack = @import("qpack.zig");

    const fields = [_]qpack.HeaderField{
        .{ .name = ":method", .value = "CONNECT" },
        .{ .name = ":protocol", .value = "webtransport" },
        .{ .name = ":scheme", .value = "https" },
        .{ .name = ":authority", .value = authority },
        .{ .name = ":path", .value = path },
    };

    var header_buf: [4096]u8 = undefined;
    const header_len = try qpack.encodeHeaderBlock(&header_buf, &fields);

    // Write HEADERS frame
    var pos: usize = 0;
    out[pos] = 0x01; // HEADERS frame type
    pos += 1;
    // Length varint
    if (header_len <= 63) {
        out[pos] = @intCast(header_len);
        pos += 1;
    } else if (header_len <= 16383) {
        out[pos] = @intCast(0x40 | (header_len >> 8));
        out[pos + 1] = @intCast(header_len & 0xff);
        pos += 2;
    } else {
        return error.HeaderTooLarge;
    }
    @memcpy(out[pos .. pos + header_len], header_buf[0..header_len]);
    pos += header_len;

    return pos;
}

test "WebTransport session lifecycle" {
    var session = WtSession.init(std.testing.allocator);
    defer session.deinit();

    try std.testing.expect(!session.established);

    // Establish session
    session.establish(0);
    try std.testing.expect(session.established);
    try std.testing.expectEqual(@as(?u64, 0), session.session_id);

    // Open bidi streams
    try session.openBidiStream(4);
    try session.openBidiStream(8);
    try std.testing.expectEqual(@as(usize, 2), session.bidi_streams.items.len);

    // Get stream
    const stream = session.getBidiStream(4);
    try std.testing.expect(stream != null);
    try std.testing.expect(stream.?.is_bidi);
    try std.testing.expectEqual(WtStreamState.open, stream.?.state);

    // Datagrams
    session.recordDatagramSent();
    session.recordDatagramSent();
    session.recordDatagramReceived();
    try std.testing.expectEqual(@as(u64, 2), session.datagrams_sent);
    try std.testing.expectEqual(@as(u64, 1), session.datagrams_received);

    // Close session
    session.close();
    try std.testing.expect(!session.established);
    try std.testing.expectEqual(WtStreamState.closed, session.bidi_streams.items[0].state);
}

test "WebTransport uni streams" {
    var session = WtSession.init(std.testing.allocator);
    defer session.deinit();

    session.establish(0);
    try session.openUniStream(3);
    try session.openUniStream(7);

    try std.testing.expectEqual(@as(usize, 2), session.uni_streams.items.len);
    try std.testing.expect(!session.uni_streams.items[0].is_bidi);
}

test "WebTransport CONNECT request encoding" {
    var buf: [4096]u8 = undefined;
    const len = try encodeConnectRequest(&buf, "example.com", "/wt");

    try std.testing.expect(len > 0);
    // First byte should be HEADERS frame type (0x01)
    try std.testing.expectEqual(@as(u8, 0x01), buf[0]);
}

test "WebTransport stream state transitions" {
    var stream = WtStream{
        .stream_id = 4,
        .is_bidi = true,
    };

    try std.testing.expectEqual(WtStreamState.open, stream.state);

    stream.state = .fin_sent;
    try std.testing.expectEqual(WtStreamState.fin_sent, stream.state);

    stream.state = .closed;
    try std.testing.expectEqual(WtStreamState.closed, stream.state);
}

// ---------------------------------------------------------------------------
// WebTransport framing (draft-ietf-webtrans-http3 §4-5)
// ---------------------------------------------------------------------------

/// WebTransport unidirectional stream types (draft §4.3).
pub const WtUniStreamType = enum(u64) {
    /// WebTransport uni stream: Session ID varint follows.
    webtransport_uni = 0x54,
    _,
};

/// Encode a WebTransport uni stream header.
/// Format: Stream Type (0x54) + Session ID (varint).
pub fn encodeUniStreamHeader(out: []u8, session_id: u64) !usize {
    var pos: usize = 0;
    out[pos] = 0x54; // WT uni stream type
    pos += 1;
    pos += try encodeWtVarint(out[pos..], session_id);
    return pos;
}

/// Decode a WebTransport uni stream header.
/// Returns the session ID and bytes consumed.
pub fn decodeUniStreamHeader(data: []const u8) !struct { session_id: u64, consumed: usize } {
    if (data.len < 2) return error.IncompleteWtHeader;
    if (data[0] != 0x54) return error.InvalidWtStreamType;
    const result = try decodeWtVarint(data[1..]);
    return .{ .session_id = result.value, .consumed = 1 + result.consumed };
}

/// Encode a WebTransport bidi stream prefix.
/// Format: Session ID (varint) at the start of the bidi stream.
pub fn encodeBidiStreamPrefix(out: []u8, session_id: u64) !usize {
    return encodeWtVarint(out, session_id);
}

/// Decode a WebTransport bidi stream prefix.
pub fn decodeBidiStreamPrefix(data: []const u8) !struct { session_id: u64, consumed: usize } {
    const result = try decodeWtVarint(data);
    return .{ .session_id = result.value, .consumed = result.consumed };
}

/// CLOSE_WEBTRANSPORT_SESSION capsule type (draft §5.2).
pub const close_capsule_type: u64 = 0x2843;

/// Encode a CLOSE_WEBTRANSPORT_SESSION capsule.
/// Format: Capsule Type (varint) + Length (varint) + Error Code (varint) + Reason (bytes).
pub fn encodeCloseCapsule(out: []u8, error_code: u32, reason: []const u8) !usize {
    var pos: usize = 0;

    // Capsule type
    pos += try encodeWtVarint(out[pos..], close_capsule_type);

    // Capsule length = error_code varint + 4 bytes (we use 4-byte encoding) + reason
    const error_code_len: usize = 4;
    const capsule_len = error_code_len + reason.len;
    pos += try encodeWtVarint(out[pos..], capsule_len);

    // Error code as 4 bytes (network order)
    if (pos + 4 > out.len) return error.BufferTooSmall;
    out[pos] = @intCast(error_code >> 24);
    out[pos + 1] = @intCast((error_code >> 16) & 0xff);
    out[pos + 2] = @intCast((error_code >> 8) & 0xff);
    out[pos + 3] = @intCast(error_code & 0xff);
    pos += 4;

    // Reason phrase
    if (pos + reason.len > out.len) return error.BufferTooSmall;
    @memcpy(out[pos .. pos + reason.len], reason);
    pos += reason.len;

    return pos;
}

/// Decode a CLOSE_WEBTRANSPORT_SESSION capsule.
pub fn decodeCloseCapsule(data: []const u8) !struct { error_code: u32, reason: []const u8, consumed: usize } {
    var pos: usize = 0;

    // Capsule type
    const type_result = try decodeWtVarint(data[pos..]);
    if (type_result.value != close_capsule_type) return error.InvalidCapsuleType;
    pos += type_result.consumed;

    // Capsule length
    const len_result = try decodeWtVarint(data[pos..]);
    pos += len_result.consumed;
    const capsule_len: usize = @intCast(len_result.value);

    if (pos + capsule_len > data.len) return error.IncompleteCapsule;
    if (capsule_len < 4) return error.InvalidCapsule;

    // Error code (4 bytes)
    const error_code: u32 = (@as(u32, data[pos]) << 24) |
        (@as(u32, data[pos + 1]) << 16) |
        (@as(u32, data[pos + 2]) << 8) |
        @as(u32, data[pos + 3]);
    pos += 4;

    // Reason
    const reason = data[pos .. pos + capsule_len - 4];
    pos += capsule_len - 4;

    return .{ .error_code = error_code, .reason = reason, .consumed = pos };
}

/// Encode a WebTransport datagram (RFC 9297 + WT session association).
/// Uses the HTTP Datagram format with the CONNECT stream's Quarter Stream ID.
pub fn encodeWtDatagram(out: []u8, session_stream_id: u64, payload: []const u8) !usize {
    const datagram = @import("datagram.zig");
    return datagram.encodeHttpDatagram(out, session_stream_id, payload);
}

/// Decode a WebTransport datagram.
pub fn decodeWtDatagram(data: []const u8) !struct { session_stream_id: u64, payload: []const u8 } {
    const datagram = @import("datagram.zig");
    const result = try datagram.decodeHttpDatagram(data);
    return .{ .session_stream_id = result.stream_id, .payload = result.payload };
}

/// Validate WebTransport stream state transition.
pub fn isValidWtTransition(from: WtStreamState, to: WtStreamState) bool {
    return switch (from) {
        .open => to == .fin_sent or to == .fin_received or to == .reset or to == .closed,
        .fin_sent => to == .closed or to == .reset or to == .fin_received,
        .fin_received => to == .closed or to == .reset or to == .fin_sent,
        .closed => false,
        .reset => false,
    };
}

/// Encode a QUIC varint into a buffer. Returns bytes written.
fn encodeWtVarint(out: []u8, value: u64) !usize {
    if (value <= 63) {
        out[0] = @intCast(value);
        return 1;
    } else if (value <= 16383) {
        out[0] = @intCast(0x40 | (value >> 8));
        out[1] = @intCast(value & 0xff);
        return 2;
    } else if (value <= 1073741823) {
        out[0] = @intCast(0x80 | (value >> 24));
        out[1] = @intCast((value >> 16) & 0xff);
        out[2] = @intCast((value >> 8) & 0xff);
        out[3] = @intCast(value & 0xff);
        return 4;
    } else {
        out[0] = @intCast(0xc0 | (value >> 56));
        out[1] = @intCast((value >> 48) & 0xff);
        out[2] = @intCast((value >> 40) & 0xff);
        out[3] = @intCast((value >> 32) & 0xff);
        out[4] = @intCast((value >> 24) & 0xff);
        out[5] = @intCast((value >> 16) & 0xff);
        out[6] = @intCast((value >> 8) & 0xff);
        out[7] = @intCast(value & 0xff);
        return 8;
    }
}

/// Decode a QUIC varint from a buffer.
fn decodeWtVarint(data: []const u8) !struct { value: u64, consumed: usize } {
    if (data.len == 0) return error.IncompleteWtHeader;
    const first = data[0];
    const prefix = first >> 6;
    const len: usize = @as(usize, 1) << @intCast(prefix);
    if (data.len < len) return error.IncompleteWtHeader;
    var value: u64 = first & 0x3f;
    for (1..len) |i| {
        value = (value << 8) | data[i];
    }
    return .{ .value = value, .consumed = len };
}

// ---------------------------------------------------------------------------
// WebTransport framing tests
// ---------------------------------------------------------------------------

test "WebTransport uni stream header encode/decode" {
    var buf: [32]u8 = undefined;
    const len = try encodeUniStreamHeader(&buf, 42);

    const result = try decodeUniStreamHeader(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 42), result.session_id);
    try std.testing.expectEqual(len, result.consumed);
}

test "WebTransport uni stream header invalid type" {
    const data = [_]u8{ 0x55, 0x00 }; // wrong type
    try std.testing.expectError(error.InvalidWtStreamType, decodeUniStreamHeader(&data));
}

test "WebTransport bidi stream prefix encode/decode" {
    var buf: [16]u8 = undefined;
    const len = try encodeBidiStreamPrefix(&buf, 100);

    const result = try decodeBidiStreamPrefix(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 100), result.session_id);
}

test "WebTransport CLOSE capsule encode/decode" {
    var buf: [128]u8 = undefined;
    const len = try encodeCloseCapsule(&buf, 0x01, "session ended");

    const result = try decodeCloseCapsule(buf[0..len]);
    try std.testing.expectEqual(@as(u32, 0x01), result.error_code);
    try std.testing.expectEqualStrings("session ended", result.reason);
    try std.testing.expectEqual(len, result.consumed);
}

test "WebTransport CLOSE capsule empty reason" {
    var buf: [64]u8 = undefined;
    const len = try encodeCloseCapsule(&buf, 0xff, "");

    const result = try decodeCloseCapsule(buf[0..len]);
    try std.testing.expectEqual(@as(u32, 0xff), result.error_code);
    try std.testing.expectEqual(@as(usize, 0), result.reason.len);
}

test "WebTransport CLOSE capsule invalid type" {
    var buf: [64]u8 = undefined;
    const len = try encodeCloseCapsule(&buf, 0, "x");
    buf[0] = 0x99; // corrupt type
    try std.testing.expectError(error.InvalidCapsuleType, decodeCloseCapsule(buf[0..len]));
}

test "WebTransport datagram encode/decode" {
    var buf: [256]u8 = undefined;
    const payload = "wt-datagram-payload";
    const len = try encodeWtDatagram(&buf, 0, payload);

    const result = try decodeWtDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 0), result.session_stream_id);
    try std.testing.expectEqualStrings(payload, result.payload);
}

test "WebTransport stream state transition validation" {
    try std.testing.expect(isValidWtTransition(.open, .fin_sent));
    try std.testing.expect(isValidWtTransition(.open, .fin_received));
    try std.testing.expect(isValidWtTransition(.open, .reset));
    try std.testing.expect(isValidWtTransition(.fin_sent, .closed));
    try std.testing.expect(isValidWtTransition(.fin_received, .fin_sent));
    try std.testing.expect(!isValidWtTransition(.closed, .open));
    try std.testing.expect(!isValidWtTransition(.reset, .open));
    try std.testing.expect(!isValidWtTransition(.closed, .reset));
}

test "WebTransport large session ID in headers" {
    var buf: [32]u8 = undefined;
    // Session ID 100000 needs 4-byte varint
    const len = try encodeUniStreamHeader(&buf, 100000);

    const result = try decodeUniStreamHeader(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 100000), result.session_id);
}
