//! HTTP Datagrams (RFC 9297).
//!
//! HTTP Datagrams use QUIC DATAGRAM frames (RFC 9221) with a
//! Quarter Stream ID prefix to associate datagrams with H3 streams.
//! The format is: Quarter Stream ID (varint) + HTTP Datagram Payload.

const std = @import("std");

/// Encode an HTTP Datagram payload (RFC 9297 §2).
/// Prepends the Quarter Stream ID as a varint to the payload.
///
/// The Quarter Stream ID is the stream ID divided by 4 (since H3
/// only uses client-initiated bidi streams: 0, 4, 8, ...).
pub fn encodeHttpDatagram(out: []u8, stream_id: u64, payload: []const u8) !usize {
    const quarter_id = stream_id / 4;
    var pos: usize = 0;

    // Encode Quarter Stream ID as QUIC varint
    if (quarter_id <= 63) {
        out[pos] = @intCast(quarter_id);
        pos += 1;
    } else if (quarter_id <= 16383) {
        out[pos] = @intCast(0x40 | (quarter_id >> 8));
        out[pos + 1] = @intCast(quarter_id & 0xff);
        pos += 2;
    } else if (quarter_id <= 1073741823) {
        out[pos] = @intCast(0x80 | (quarter_id >> 24));
        out[pos + 1] = @intCast((quarter_id >> 16) & 0xff);
        out[pos + 2] = @intCast((quarter_id >> 8) & 0xff);
        out[pos + 3] = @intCast(quarter_id & 0xff);
        pos += 4;
    } else {
        out[pos] = @intCast(0xc0 | (quarter_id >> 56));
        out[pos + 1] = @intCast((quarter_id >> 48) & 0xff);
        out[pos + 2] = @intCast((quarter_id >> 40) & 0xff);
        out[pos + 3] = @intCast((quarter_id >> 32) & 0xff);
        out[pos + 4] = @intCast((quarter_id >> 24) & 0xff);
        out[pos + 5] = @intCast((quarter_id >> 16) & 0xff);
        out[pos + 6] = @intCast((quarter_id >> 8) & 0xff);
        out[pos + 7] = @intCast(quarter_id & 0xff);
        pos += 8;
    }

    if (pos + payload.len > out.len) return error.BufferTooSmall;
    @memcpy(out[pos .. pos + payload.len], payload);
    pos += payload.len;

    return pos;
}

/// Decode an HTTP Datagram payload (RFC 9297 §2).
/// Returns the stream ID (Quarter Stream ID * 4) and the payload slice.
pub fn decodeHttpDatagram(data: []const u8) !struct { stream_id: u64, payload: []const u8 } {
    if (data.len == 0) return error.IncompleteDatagram;

    const first = data[0];
    const prefix = first >> 6;
    const varint_len: usize = @as(usize, 1) << @intCast(prefix);

    if (data.len < varint_len) return error.IncompleteDatagram;

    var quarter_id: u64 = first & 0x3f;
    for (1..varint_len) |i| {
        quarter_id = (quarter_id << 8) | data[i];
    }

    const stream_id = quarter_id * 4;
    return .{
        .stream_id = stream_id,
        .payload = data[varint_len..],
    };
}

/// Maximum HTTP Datagram payload size for a given QUIC max_datagram_frame_size.
/// Accounts for the Quarter Stream ID varint overhead.
pub fn maxPayloadSize(max_datagram_frame_size: usize, stream_id: u64) usize {
    const quarter_id = stream_id / 4;
    const varint_overhead: usize = if (quarter_id <= 63) 1 else if (quarter_id <= 16383) 2 else if (quarter_id <= 1073741823) 4 else 8;
    if (max_datagram_frame_size <= varint_overhead) return 0;
    return max_datagram_frame_size - varint_overhead;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "HTTP Datagram encode/decode roundtrip" {
    const payload = "hello datagram";
    var buf: [256]u8 = undefined;

    // Stream 0 -> Quarter ID 0
    const len = try encodeHttpDatagram(&buf, 0, payload);
    const result = try decodeHttpDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 0), result.stream_id);
    try std.testing.expectEqualStrings(payload, result.payload);
}

test "HTTP Datagram stream ID 4 -> Quarter ID 1" {
    const payload = "data";
    var buf: [64]u8 = undefined;

    const len = try encodeHttpDatagram(&buf, 4, payload);
    // Quarter ID 1 fits in 1 byte
    try std.testing.expectEqual(@as(u8, 1), buf[0]);

    const result = try decodeHttpDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 4), result.stream_id);
    try std.testing.expectEqualStrings(payload, result.payload);
}

test "HTTP Datagram large stream ID" {
    const payload = "x";
    var buf: [64]u8 = undefined;

    // Stream 256 -> Quarter ID 64 (needs 2-byte varint)
    const len = try encodeHttpDatagram(&buf, 256, payload);
    const result = try decodeHttpDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 256), result.stream_id);
    try std.testing.expectEqualStrings(payload, result.payload);
}

test "HTTP Datagram very large stream ID" {
    const payload = "test";
    var buf: [64]u8 = undefined;

    // Stream 100000 -> Quarter ID 25000 (needs 4-byte varint)
    const len = try encodeHttpDatagram(&buf, 100000, payload);
    const result = try decodeHttpDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 100000), result.stream_id);
    try std.testing.expectEqualStrings(payload, result.payload);
}

test "HTTP Datagram empty payload" {
    var buf: [16]u8 = undefined;
    const len = try encodeHttpDatagram(&buf, 0, "");
    try std.testing.expectEqual(@as(usize, 1), len); // just the varint

    const result = try decodeHttpDatagram(buf[0..len]);
    try std.testing.expectEqual(@as(u64, 0), result.stream_id);
    try std.testing.expectEqual(@as(usize, 0), result.payload.len);
}

test "HTTP Datagram decode empty input" {
    try std.testing.expectError(error.IncompleteDatagram, decodeHttpDatagram(&[_]u8{}));
}

test "HTTP Datagram decode truncated varint" {
    // 2-byte varint prefix but only 1 byte
    const data = [_]u8{0x40};
    try std.testing.expectError(error.IncompleteDatagram, decodeHttpDatagram(&data));
}

test "HTTP Datagram maxPayloadSize calculation" {
    // Stream 0: Quarter ID 0, varint = 1 byte
    try std.testing.expectEqual(@as(usize, 1199), maxPayloadSize(1200, 0));
    // Stream 256: Quarter ID 64, varint = 2 bytes
    try std.testing.expectEqual(@as(usize, 1198), maxPayloadSize(1200, 256));
    // Edge: frame size too small
    try std.testing.expectEqual(@as(usize, 0), maxPayloadSize(1, 0));
    try std.testing.expectEqual(@as(usize, 0), maxPayloadSize(0, 0));
}

test "HTTP Datagram buffer too small" {
    var buf: [4]u8 = undefined;
    try std.testing.expectError(error.BufferTooSmall, encodeHttpDatagram(&buf, 0, "too long payload"));
}
