//! QPACK header compression (RFC 9204) — minimal implementation.
//!
//! Implements the QPACK static table and basic header field
//! encoding/decoding for HTTP/3 header blocks.

const std = @import("std");
const huffman = @import("huffman.zig");

/// QPACK static table entry (RFC 9204 Appendix A).
pub const StaticEntry = struct {
    name: []const u8,
    value: []const u8,
};

/// QPACK static table (RFC 9204 Appendix A, all 99 entries). Note this is
/// NOT the HPACK static table (RFC 7541): QPACK uses its own traffic-derived
/// table, indexed from 0.
pub const static_table = [_]StaticEntry{
    .{ .name = ":authority", .value = "" },
    .{ .name = ":path", .value = "/" },
    .{ .name = "age", .value = "0" },
    .{ .name = "content-disposition", .value = "" },
    .{ .name = "content-length", .value = "0" },
    .{ .name = "cookie", .value = "" },
    .{ .name = "date", .value = "" },
    .{ .name = "etag", .value = "" },
    .{ .name = "if-modified-since", .value = "" },
    .{ .name = "if-none-match", .value = "" },
    .{ .name = "last-modified", .value = "" },
    .{ .name = "link", .value = "" },
    .{ .name = "location", .value = "" },
    .{ .name = "referer", .value = "" },
    .{ .name = "set-cookie", .value = "" },
    .{ .name = ":method", .value = "CONNECT" },
    .{ .name = ":method", .value = "DELETE" },
    .{ .name = ":method", .value = "GET" },
    .{ .name = ":method", .value = "HEAD" },
    .{ .name = ":method", .value = "OPTIONS" },
    .{ .name = ":method", .value = "POST" },
    .{ .name = ":method", .value = "PUT" },
    .{ .name = ":scheme", .value = "http" },
    .{ .name = ":scheme", .value = "https" },
    .{ .name = ":status", .value = "103" },
    .{ .name = ":status", .value = "200" },
    .{ .name = ":status", .value = "304" },
    .{ .name = ":status", .value = "404" },
    .{ .name = ":status", .value = "503" },
    .{ .name = "accept", .value = "*/*" },
    .{ .name = "accept", .value = "application/dns-message" },
    .{ .name = "accept-encoding", .value = "gzip, deflate, br" },
    .{ .name = "accept-ranges", .value = "bytes" },
    .{ .name = "access-control-allow-headers", .value = "cache-control" },
    .{ .name = "access-control-allow-headers", .value = "content-type" },
    .{ .name = "access-control-allow-origin", .value = "*" },
    .{ .name = "cache-control", .value = "max-age=0" },
    .{ .name = "cache-control", .value = "max-age=2592000" },
    .{ .name = "cache-control", .value = "max-age=604800" },
    .{ .name = "cache-control", .value = "no-cache" },
    .{ .name = "cache-control", .value = "no-store" },
    .{ .name = "cache-control", .value = "public, max-age=31536000" },
    .{ .name = "content-encoding", .value = "br" },
    .{ .name = "content-encoding", .value = "gzip" },
    .{ .name = "content-type", .value = "application/dns-message" },
    .{ .name = "content-type", .value = "application/javascript" },
    .{ .name = "content-type", .value = "application/json" },
    .{ .name = "content-type", .value = "application/x-www-form-urlencoded" },
    .{ .name = "content-type", .value = "image/gif" },
    .{ .name = "content-type", .value = "image/jpeg" },
    .{ .name = "content-type", .value = "image/png" },
    .{ .name = "content-type", .value = "text/css" },
    .{ .name = "content-type", .value = "text/html; charset=utf-8" },
    .{ .name = "content-type", .value = "text/plain" },
    .{ .name = "content-type", .value = "text/plain;charset=utf-8" },
    .{ .name = "range", .value = "bytes=0-" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000; includesubdomains" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000; includesubdomains; preload" },
    .{ .name = "vary", .value = "accept-encoding" },
    .{ .name = "vary", .value = "origin" },
    .{ .name = "x-content-type-options", .value = "nosniff" },
    .{ .name = "x-xss-protection", .value = "1; mode=block" },
    .{ .name = ":status", .value = "100" },
    .{ .name = ":status", .value = "204" },
    .{ .name = ":status", .value = "206" },
    .{ .name = ":status", .value = "302" },
    .{ .name = ":status", .value = "400" },
    .{ .name = ":status", .value = "403" },
    .{ .name = ":status", .value = "421" },
    .{ .name = ":status", .value = "425" },
    .{ .name = ":status", .value = "500" },
    .{ .name = "accept-language", .value = "" },
    .{ .name = "access-control-allow-credentials", .value = "FALSE" },
    .{ .name = "access-control-allow-credentials", .value = "TRUE" },
    .{ .name = "access-control-allow-headers", .value = "*" },
    .{ .name = "access-control-allow-methods", .value = "get" },
    .{ .name = "access-control-allow-methods", .value = "get, post, options" },
    .{ .name = "access-control-allow-methods", .value = "options" },
    .{ .name = "access-control-expose-headers", .value = "content-length" },
    .{ .name = "access-control-request-headers", .value = "content-type" },
    .{ .name = "access-control-request-method", .value = "get" },
    .{ .name = "access-control-request-method", .value = "post" },
    .{ .name = "alt-svc", .value = "clear" },
    .{ .name = "authorization", .value = "" },
    .{ .name = "content-security-policy", .value = "script-src 'none'; object-src 'none'; base-uri 'none'" },
    .{ .name = "early-data", .value = "1" },
    .{ .name = "expect-ct", .value = "" },
    .{ .name = "forwarded", .value = "" },
    .{ .name = "if-range", .value = "" },
    .{ .name = "origin", .value = "" },
    .{ .name = "purpose", .value = "prefetch" },
    .{ .name = "server", .value = "" },
    .{ .name = "timing-allow-origin", .value = "*" },
    .{ .name = "upgrade-insecure-requests", .value = "1" },
    .{ .name = "user-agent", .value = "" },
    .{ .name = "x-forwarded-for", .value = "" },
    .{ .name = "x-frame-options", .value = "deny" },
    .{ .name = "x-frame-options", .value = "sameorigin" },
};

/// An HTTP header field.
pub const HeaderField = struct {
    name: []const u8,
    value: []const u8,
};

/// Find a static table index for an exact name+value match.
pub fn findStaticIndex(name: []const u8, value: []const u8) ?u64 {
    for (static_table, 0..) |entry, i| {
        if (std.mem.eql(u8, entry.name, name) and std.mem.eql(u8, entry.value, value)) {
            return @intCast(i);
        }
    }
    return null;
}

/// Find a static table index for a name-only match.
pub fn findStaticNameIndex(name: []const u8) ?u64 {
    for (static_table, 0..) |entry, i| {
        if (std.mem.eql(u8, entry.name, name)) {
            return @intCast(i);
        }
    }
    return null;
}

/// Encode a header block (sequence of header fields) into a caller-provided buffer.
/// Uses indexed representation for static table matches, literal otherwise.
/// Returns the number of bytes written.
pub fn encodeHeaderBlock(out: []u8, fields: []const HeaderField) !usize {
    var pos: usize = 0;

    // Required Insert Count = 0 (no dynamic table)
    out[pos] = 0x00;
    pos += 1;
    // Delta Base = 0
    out[pos] = 0x00;
    pos += 1;

    for (fields) |field| {
        if (findStaticIndex(field.name, field.value)) |idx| {
            // Indexed Field Line (static): 1TXXXXXX, T=1 for static
            // Index uses 6-bit prefix; values >= 63 use multi-byte varint
            if (idx < 63) {
                out[pos] = @intCast(0xc0 | idx);
                pos += 1;
            } else {
                out[pos] = 0xff; // 0xc0 | 0x3f (all 1s in 6-bit prefix)
                pos += 1;
                pos = encodeVarintToBuf(out, pos, idx - 63);
            }
        } else if (findStaticNameIndex(field.name)) |name_idx| {
            // Literal with Name Reference (static): 01NTXXXX
            // Name Index uses 4-bit prefix; values >= 15 use multi-byte varint
            if (name_idx < 15) {
                out[pos] = @intCast(0x50 | name_idx);
                pos += 1;
            } else {
                out[pos] = 0x5f; // 0x50 | 0x0f (all 1s in 4-bit prefix)
                pos += 1;
                pos = encodeVarintToBuf(out, pos, name_idx - 15);
            }
            pos = try encodeStringToBuf(out, pos, field.value);
        } else {
            // Literal without Name Reference: 001N + 4-bit-prefix name string
            pos = try encodeStringToBuf4(out, pos, field.name);
            pos = try encodeStringToBuf(out, pos, field.value);
        }
    }

    return pos;
}

/// Encode a varint continuation (RFC 7541 §5.1) after a prefix of all 1s.
/// The value passed is already reduced by the prefix maximum.
fn encodeVarintToBuf(out: []u8, pos: usize, value: u64) usize {
    var p = pos;
    var v = value;
    while (v >= 128) {
        out[p] = @intCast(0x80 | (v & 0x7f));
        p += 1;
        v >>= 7;
    }
    out[p] = @intCast(v);
    p += 1;
    return p;
}

/// Decode a varint continuation (RFC 7541 §5.1) after a prefix of all 1s.
/// Returns the decoded value (already added to prefix_max by caller).
fn decodeVarintFromBuf(data: []const u8, pos: usize) !struct { value: u64, end: usize } {
    var p = pos;
    var result: u64 = 0;
    var shift: u6 = 0;
    while (true) {
        if (p >= data.len) return error.IncompleteString;
        const byte = data[p];
        p += 1;
        result |= @as(u64, byte & 0x7f) << shift;
        if (byte & 0x80 == 0) break;
        shift += 7;
        if (shift >= 63) return error.InvalidVarint;
    }
    return .{ .value = result, .end = p };
}

/// Encode a length-prefixed string into a buffer. When Huffman encoding is
/// smaller than the raw bytes (and the value fits a single-byte length prefix),
/// it is emitted with H=1; otherwise the raw literal is used (H=0). This matches
/// quiche's encoder behavior.
/// Encode a 4-bit-prefix string literal (RFC 9204 §4.5.6): the literal field
/// name in a "Literal Field Line with Literal Name" uses H in bit 3 and a
/// 3-bit length prefix (bits 2-0), unlike the 8-bit-prefix value strings.
fn encodeStringToBuf4(out: []u8, pos: usize, s: []const u8) !usize {
    var p = pos;
    var huffman_buf: [16384]u8 = undefined;
    const huffman_len = huffman.encode(s, &huffman_buf) catch 0;
    const use_huffman = huffman_len != 0 and huffman_len < s.len and s.len < 8;
    if (s.len < 8) {
        const payload_len = if (use_huffman) huffman_len else s.len;
        out[p] = 0x20 | @as(u8, if (use_huffman) 0x08 else 0x00) | @as(u8, @intCast(payload_len));
        p += 1;
    } else {
        out[p] = 0x27; // 001N + 3-bit prefix all 1s
        p += 1;
        var remaining = s.len - 7;
        while (remaining >= 128) : (remaining -= 128) {
            out[p] = 0x80 | 127;
            p += 1;
        }
        out[p] = @intCast(remaining);
        p += 1;
    }
    if (use_huffman) {
        @memcpy(out[p .. p + huffman_len], huffman_buf[0..huffman_len]);
        p += huffman_len;
    } else {
        @memcpy(out[p .. p + s.len], s);
        p += s.len;
    }
    return p;
}

fn encodeStringToBuf(out: []u8, pos: usize, s: []const u8) !usize {
    var p = pos;
    var huffman_buf: [16384]u8 = undefined;
    const huffman_len = huffman.encode(s, &huffman_buf) catch 0;
    const use_huffman = huffman_len != 0 and huffman_len < s.len and s.len < 128;
    if (s.len < 128) {
        const payload_len = if (use_huffman) huffman_len else s.len;
        out[p] = @as(u8, if (use_huffman) 0x80 else 0x00) | @as(u8, @intCast(payload_len));
        p += 1;
    } else {
        out[p] = 0x7f;
        p += 1;
        var remaining = s.len - 127;
        while (remaining >= 128) : (remaining -= 128) {
            out[p] = 0x80 | 127;
            p += 1;
        }
        out[p] = @intCast(remaining);
        p += 1;
    }
    if (use_huffman) {
        @memcpy(out[p .. p + huffman_len], huffman_buf[0..huffman_len]);
        p += huffman_len;
    } else {
        @memcpy(out[p .. p + s.len], s);
        p += s.len;
    }
    return p;
}

test "QPACK static table lookup" {
    // RFC 9204 Table: :method GET = 17, :status 200 = 25, :scheme https = 23, :path / = 1
    try std.testing.expectEqual(@as(?u64, 17), findStaticIndex(":method", "GET"));
    try std.testing.expectEqual(@as(?u64, 25), findStaticIndex(":status", "200"));
    try std.testing.expectEqual(@as(?u64, 23), findStaticIndex(":scheme", "https"));
    try std.testing.expectEqual(@as(?u64, 1), findStaticIndex(":path", "/"));
    // Unknown
    try std.testing.expect(findStaticIndex("x-custom", "value") == null);
}

test "QPACK static name lookup" {
    // RFC 9204 Table: :method first occurrence at 15, :authority at 0
    try std.testing.expectEqual(@as(?u64, 15), findStaticNameIndex(":method"));
    try std.testing.expectEqual(@as(?u64, 0), findStaticNameIndex(":authority"));
    try std.testing.expect(findStaticNameIndex("x-custom") == null);
}

test "QPACK encode header block with static entries" {
    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":path", .value = "/" },
        .{ .name = ":scheme", .value = "https" },
        .{ .name = ":authority", .value = "example.com" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlock(&encoded, &fields);

    // First 2 bytes: Required Insert Count (0) + Delta Base (0)
    try std.testing.expectEqual(@as(u8, 0x00), encoded[0]);
    try std.testing.expectEqual(@as(u8, 0x00), encoded[1]);
    // RFC 9204: :method GET = 0xc0 | 17 = 0xd1
    try std.testing.expectEqual(@as(u8, 0xd1), encoded[2]);
    // :path / = 0xc0 | 1 = 0xc1
    try std.testing.expectEqual(@as(u8, 0xc1), encoded[3]);
    // :scheme https = 0xc0 | 23 = 0xd7
    try std.testing.expectEqual(@as(u8, 0xd7), encoded[4]);
    // :authority with literal value (name ref index 0): 0x50 | 0 = 0x50
    try std.testing.expectEqual(@as(u8, 0x50), encoded[5]);
    try std.testing.expect(len > 6);
}

test "QPACK encode header block with custom headers" {
    const fields = [_]HeaderField{
        .{ .name = "x-custom-header", .value = "custom-value" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlock(&encoded, &fields);

    // Literal without name reference: 001N + 4-bit-prefix name string.
    // "x-custom-header" (15 bytes) exceeds the 3-bit length prefix, so the
    // field-header byte is 001N + all-1s prefix (0x27) + a varint remainder.
    try std.testing.expectEqual(@as(u8, 0x27), encoded[2]);
    try std.testing.expectEqual(@as(u8, 8), encoded[3]); // 15 - 7
    try std.testing.expect(len > 3);
}

/// Decode a QPACK header block into header fields.
/// Returns the number of fields written to `out_fields`.
pub fn decodeHeaderBlock(data: []const u8, out_fields: []HeaderField) !usize {
    if (data.len < 2) return error.InvalidHeaderBlock;

    // Skip Required Insert Count (1 byte) and Delta Base (1 byte)
    var pos: usize = 2;
    var count: usize = 0;

    while (pos < data.len) {
        if (count >= out_fields.len) return error.TooManyFields;
        const first = data[pos];

        if (first & 0x80 != 0) {
            // Indexed Field Line: 1TXXXXXX
            const is_static = (first & 0x40) != 0;
            var index: u64 = first & 0x3f;
            var next_pos = pos + 1;
            if (index == 63) {
                // Multi-byte varint: 6-bit prefix was all 1s
                const varint = try decodeVarintFromBuf(data, next_pos);
                index = 63 + varint.value;
                next_pos = varint.end;
            }
            if (!is_static) return error.DynamicTableUnsupported;
            if (index >= static_table.len) return error.InvalidStaticIndex;
            out_fields[count] = .{
                .name = static_table[index].name,
                .value = static_table[index].value,
            };
            count += 1;
            pos = next_pos;
        } else if (first & 0x40 != 0) {
            // Literal with Name Reference: 01NTXXXX
            const is_static = (first & 0x10) != 0;
            var name_index: u64 = first & 0x0f;
            var next_pos = pos + 1;
            if (name_index == 15) {
                // Multi-byte varint: 4-bit prefix was all 1s
                const varint = try decodeVarintFromBuf(data, next_pos);
                name_index = 15 + varint.value;
                next_pos = varint.end;
            }
            if (!is_static) return error.DynamicTableUnsupported;
            if (name_index >= static_table.len) return error.InvalidStaticIndex;
            const value_result = try decodeString(data, next_pos);
            out_fields[count] = .{
                .name = static_table[name_index].name,
                .value = value_result.value,
            };
            count += 1;
            pos = value_result.end;
        } else if (first & 0x20 != 0) {
            // Literal without Name Reference: the field-header byte carries
            // N + H + 3-bit length (4-bit-prefix name string).
            const name_result = try decodeString4(data, pos);
            const value_result = try decodeString(data, name_result.end);
            out_fields[count] = .{
                .name = name_result.value,
                .value = value_result.value,
            };
            count += 1;
            pos = value_result.end;
        } else {
            return error.UnsupportedRepresentation;
        }
    }

    return count;
}

/// File-scope scratch for Huffman-decoded strings. The returned slice is valid
/// only until the next decode on the same thread; callers consume or copy it
/// immediately. Sized to the max QPACK field (RFC 9114 §4.2 sets a 16 KiB
/// default max field section size).
var huffman_scratch: [16384]u8 = undefined;
var huffman_scratch_pos: usize = 0;

/// Decode a 4-bit-prefix string literal (RFC 9204 §4.5.6): the literal field
/// name in a "Literal Field Line with Literal Name" uses H in bit 3 and a
/// 3-bit length prefix (bits 2-0), unlike the 8-bit-prefix value strings.
fn decodeString4(data: []const u8, start: usize) !struct { value: []const u8, end: usize } {
    if (start >= data.len) return error.IncompleteString;
    const first = data[start];
    const is_huffman = (first & 0x08) != 0;
    var pos = start + 1;
    var len: usize = first & 0x07;
    if (len == 0x07) {
        const v = try decodeVarintFromBuf(data, pos);
        len = 0x07 + @as(usize, v.value);
        pos = v.end;
    }
    if (pos + len > data.len) return error.IncompleteString;
    const raw = data[pos .. pos + len];
    pos += len;
    if (is_huffman) {
        const n = try huffman.decode(raw, huffman_scratch[huffman_scratch_pos..]);
        const value = huffman_scratch[huffman_scratch_pos..][0..n];
        huffman_scratch_pos += n;
        return .{ .value = value, .end = pos };
    }
    return .{ .value = raw, .end = pos };
}

fn decodeString(data: []const u8, start: usize) !struct { value: []const u8, end: usize } {
    if (start >= data.len) return error.IncompleteString;
    const first = data[start];
    const is_huffman = (first & 0x80) != 0;
    var pos = start + 1;
    var len: usize = first & 0x7f;
    if (len == 0x7f) {
        const v = try decodeVarintFromBuf(data, pos);
        len = 0x7f + @as(usize, v.value);
        pos = v.end;
    }
    if (pos + len > data.len) return error.IncompleteString;
    const raw = data[pos .. pos + len];
    pos += len;
    if (is_huffman) {
        const n = try huffman.decode(raw, huffman_scratch[huffman_scratch_pos..]);
        const value = huffman_scratch[huffman_scratch_pos..][0..n];
        huffman_scratch_pos += n;
        return .{ .value = value, .end = pos };
    }
    return .{ .value = raw, .end = pos };
}

test "QPACK decode header block with static entries" {
    // Encode then decode
    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":path", .value = "/" },
        .{ .name = ":scheme", .value = "https" },
    };

    var encoded: [256]u8 = undefined;
    const enc_len = try encodeHeaderBlock(&encoded, &fields);

    var decoded: [16]HeaderField = undefined;
    const dec_count = try decodeHeaderBlock(encoded[0..enc_len], &decoded);

    try std.testing.expectEqual(@as(usize, 3), dec_count);
    try std.testing.expectEqualStrings(":method", decoded[0].name);
    try std.testing.expectEqualStrings("GET", decoded[0].value);
    try std.testing.expectEqualStrings(":path", decoded[1].name);
    try std.testing.expectEqualStrings("/", decoded[1].value);
    try std.testing.expectEqualStrings(":scheme", decoded[2].name);
    try std.testing.expectEqualStrings("https", decoded[2].value);
}

test "QPACK decode header block with literal value" {
    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":authority", .value = "example.com" },
    };

    var encoded: [256]u8 = undefined;
    const enc_len = try encodeHeaderBlock(&encoded, &fields);

    var decoded: [16]HeaderField = undefined;
    const dec_count = try decodeHeaderBlock(encoded[0..enc_len], &decoded);

    try std.testing.expectEqual(@as(usize, 2), dec_count);
    try std.testing.expectEqualStrings(":method", decoded[0].name);
    try std.testing.expectEqualStrings("GET", decoded[0].value);
    try std.testing.expectEqualStrings(":authority", decoded[1].name);
    try std.testing.expectEqualStrings("example.com", decoded[1].value);
}

test "QPACK decode header block with custom headers" {
    const fields = [_]HeaderField{
        .{ .name = "x-custom", .value = "custom-value" },
    };

    var encoded: [256]u8 = undefined;
    const enc_len = try encodeHeaderBlock(&encoded, &fields);

    var decoded: [16]HeaderField = undefined;
    const dec_count = try decodeHeaderBlock(encoded[0..enc_len], &decoded);

    try std.testing.expectEqual(@as(usize, 1), dec_count);
    try std.testing.expectEqualStrings("x-custom", decoded[0].name);
    try std.testing.expectEqualStrings("custom-value", decoded[0].value);
}

test "QPACK decode :status 200" {
    const fields = [_]HeaderField{
        .{ .name = ":status", .value = "200" },
    };

    var encoded: [256]u8 = undefined;
    const enc_len = try encodeHeaderBlock(&encoded, &fields);

    var decoded: [16]HeaderField = undefined;
    const dec_count = try decodeHeaderBlock(encoded[0..enc_len], &decoded);

    try std.testing.expectEqual(@as(usize, 1), dec_count);
    try std.testing.expectEqualStrings(":status", decoded[0].name);
    try std.testing.expectEqualStrings("200", decoded[0].value);
}

// ---------------------------------------------------------------------------
// Dynamic table (RFC 9204 §3)
// ---------------------------------------------------------------------------

/// QPACK dynamic table entry size overhead (RFC 9204 §3.2.1).
pub const dynamic_entry_overhead: usize = 32;

/// A single dynamic table entry.
pub const DynamicEntry = struct {
    name: []const u8,
    value: []const u8,

    /// Wire size of this entry per RFC 9204 §3.2.1.
    pub fn size(self: DynamicEntry) usize {
        return self.name.len + self.value.len + dynamic_entry_overhead;
    }
};

/// QPACK dynamic table state (RFC 9204 §3).
///
/// The dynamic table is a FIFO structure where new entries are inserted at
/// the front (index 0) and old entries are evicted from the back when the
/// table exceeds its maximum capacity.
pub const DynamicTable = struct {
    allocator: std.mem.Allocator,
    /// Entries ordered from newest (index 0) to oldest.
    entries: std.ArrayList(DynamicEntry) = .empty,
    /// Total number of entries ever inserted (monotonically increasing).
    insert_count: u64 = 0,
    /// Encoder-side Known Received Count (RFC 9204 §2.1.4): the number of
    /// insertions the peer decoder has acknowledged. Only entries with an
    /// absolute index below this count may be referenced without blocking.
    known_received_count: u64 = 0,
    /// Absolute-index prefix protected from eviction because it may be
    /// referenced by an unacknowledged field section (RFC 9204 §2.1.1).
    /// Encoder-side only; the decoder mirror leaves this at zero.
    protected_entries: u64 = 0,
    /// Maximum table capacity in bytes (set by encoder via Set Capacity).
    max_capacity: usize = 0,
    /// Current table size in bytes.
    current_size: usize = 0,

    pub fn init(allocator: std.mem.Allocator) DynamicTable {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *DynamicTable) void {
        for (self.entries.items) |entry| {
            self.allocator.free(entry.name);
            self.allocator.free(entry.value);
        }
        self.entries.deinit(self.allocator);
    }

    /// Set the dynamic table capacity (RFC 9204 §4.3.1).
    /// Evicts entries until current_size <= new_capacity.
    pub fn setCapacity(self: *DynamicTable, new_capacity: usize) void {
        self.max_capacity = new_capacity;
        self.evictToCapacity();
    }

    /// Protect all entries with an absolute index below `insert_count_prefix`
    /// from eviction until the matching field section is acknowledged.
    pub fn protectUpTo(self: *DynamicTable, insert_count_prefix: u64) void {
        self.protected_entries = @max(self.protected_entries, insert_count_prefix);
    }

    /// Set the protected absolute-index prefix exactly (used when pending
    /// sections are acknowledged or cancelled).
    pub fn setProtectedEntries(self: *DynamicTable, count: u64) void {
        self.protected_entries = count;
    }

    /// Insert a new entry at the front of the table.
    /// Evicts oldest entries if necessary to make room.
    pub fn insert(self: *DynamicTable, name: []const u8, value: []const u8) !void {
        _ = try self.insertInternal(name, value, false);
    }

    /// Insert like `insert`, but refuse to evict entries protected by
    /// unacknowledged field sections (RFC 9204 §2.1.1). Returns whether the
    /// entry was inserted; the encoder must not advertise a skipped insertion.
    pub fn tryInsertProtected(self: *DynamicTable, name: []const u8, value: []const u8) !bool {
        return self.insertInternal(name, value, true);
    }

    fn insertInternal(
        self: *DynamicTable,
        name: []const u8,
        value: []const u8,
        respect_protection: bool,
    ) !bool {
        const entry_size = name.len + value.len + dynamic_entry_overhead;

        // If the entry is larger than max_capacity, it cannot be added.
        // Clear the table per RFC 9204 §3.2.1 but do NOT increment insert_count.
        if (entry_size > self.max_capacity) {
            self.clearEntries();
            return false;
        }

        // Evict until there's room
        while (self.current_size + entry_size > self.max_capacity and self.entries.items.len > 0) {
            if (respect_protection and self.oldestIsProtected()) return false;
            self.evictOldest();
        }

        // Insert at front (index 0 = newest)
        const name_copy = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(name_copy);
        const value_copy = try self.allocator.dupe(u8, value);
        errdefer self.allocator.free(value_copy);

        try self.entries.insert(self.allocator, 0, .{
            .name = name_copy,
            .value = value_copy,
        });
        self.current_size += entry_size;
        self.insert_count += 1;
        return true;
    }

    /// Whether the oldest (lowest absolute index) entry is within the protected
    /// prefix and therefore must not be evicted.
    fn oldestIsProtected(self: *const DynamicTable) bool {
        if (self.entries.items.len == 0) return false;
        const oldest_absolute = self.insert_count - 1 - (self.entries.items.len - 1);
        return oldest_absolute < self.protected_entries;
    }

    /// Duplicate an existing entry (RFC 9204 §4.3.4).
    /// The index is relative (0 = newest).
    pub fn duplicate(self: *DynamicTable, relative_index: u64) !void {
        const idx = try self.relativeToAbsolute(relative_index);
        const entry = self.entries.items[idx];
        // Copy before insert: insert() may evict — freeing this very entry's
        // name/value heap — before it dups the caller's slices. Reading the
        // table-owned slice after that is a use-after-free (found by the
        // QPACK dynamic-table fuzz driver at 30k+ iterations).
        const name_copy = try self.allocator.dupe(u8, entry.name);
        errdefer self.allocator.free(name_copy);
        const value_copy = try self.allocator.dupe(u8, entry.value);
        errdefer self.allocator.free(value_copy);
        try self.insert(name_copy, value_copy);
        self.allocator.free(name_copy);
        self.allocator.free(value_copy);
    }

    /// Look up an entry by relative index (0 = newest).
    pub fn lookup(self: *const DynamicTable, relative_index: u64) !DynamicEntry {
        const idx = try self.relativeToAbsolute(relative_index);
        return self.entries.items[idx];
    }

    /// Convert a relative index (0 = newest) to an absolute index into entries.
    fn relativeToAbsolute(self: *const DynamicTable, relative_index: u64) !usize {
        if (relative_index >= self.entries.items.len) return error.InvalidDynamicIndex;
        return @intCast(relative_index);
    }

    /// Convert an absolute dynamic table index to a relative index for encoding.
    /// Absolute index 0 = first entry ever inserted.
    /// Relative index 0 = most recent entry.
    pub fn absoluteToRelative(self: *const DynamicTable, absolute_index: u64) !u64 {
        if (absolute_index >= self.insert_count) return error.InvalidDynamicIndex;
        const entries_ago = self.insert_count - 1 - absolute_index;
        if (entries_ago >= self.entries.items.len) return error.InvalidDynamicIndex;
        return entries_ago;
    }

    /// Get the absolute index for a relative index.
    pub fn getAbsoluteIndex(self: *const DynamicTable, relative_index: u64) !u64 {
        if (relative_index >= self.entries.items.len) return error.InvalidDynamicIndex;
        return self.insert_count - 1 - relative_index;
    }

    /// Raise the Known Received Count toward `count`. The peer cannot
    /// acknowledge more insertions than this encoder has sent.
    pub fn acknowledgeReceived(self: *DynamicTable, count: u64) !void {
        if (count > self.insert_count) return error.KnownReceivedCountBeyondSent;
        if (count > self.known_received_count) self.known_received_count = count;
    }

    /// Whether an entry at the given relative index (0 = newest) may be
    /// referenced in a header block without risking decoder blocking. The
    /// absolute index (insert_count - 1 - relative_index) must be below the
    /// Known Received Count (RFC 9204 §2.2.2).
    pub fn isReferenceable(self: *const DynamicTable, relative_index: u64) bool {
        const known = @min(self.known_received_count, self.insert_count);
        if (known == 0) return false;
        if (relative_index >= self.insert_count) return false;
        return relative_index >= self.insert_count - known;
    }

    /// Evict the oldest entry from the table.
    fn evictOldest(self: *DynamicTable) void {
        if (self.entries.items.len == 0) return;
        const entry = self.entries.orderedRemove(self.entries.items.len - 1);
        self.current_size -= entry.size();
        self.allocator.free(entry.name);
        self.allocator.free(entry.value);
    }

    /// Evict entries until current_size <= max_capacity.
    fn evictToCapacity(self: *DynamicTable) void {
        while (self.current_size > self.max_capacity and self.entries.items.len > 0) {
            self.evictOldest();
        }
    }

    /// Clear all entries.
    fn clearEntries(self: *DynamicTable) void {
        for (self.entries.items) |entry| {
            self.allocator.free(entry.name);
            self.allocator.free(entry.value);
        }
        self.entries.clearRetainingCapacity();
        self.current_size = 0;
    }

    /// Number of entries currently in the table.
    pub fn entryCount(self: *const DynamicTable) usize {
        return self.entries.items.len;
    }

    /// Find a dynamic table entry by name+value (for encoder optimization).
    /// Returns the relative index if found.
    pub fn findExact(self: *const DynamicTable, name: []const u8, value: []const u8) ?u64 {
        for (self.entries.items, 0..) |entry, i| {
            if (std.mem.eql(u8, entry.name, name) and std.mem.eql(u8, entry.value, value)) {
                return @intCast(i);
            }
        }
        return null;
    }

    /// Find a dynamic table entry by name only (for encoder optimization).
    /// Returns the relative index if found.
    pub fn findName(self: *const DynamicTable, name: []const u8) ?u64 {
        for (self.entries.items, 0..) |entry, i| {
            if (std.mem.eql(u8, entry.name, name)) {
                return @intCast(i);
            }
        }
        return null;
    }
};

// ---------------------------------------------------------------------------
// Dynamic table tests
// ---------------------------------------------------------------------------

test "DynamicTable insert and lookup" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(4096);
    try dt.insert(":method", "GET");
    try dt.insert(":path", "/index.html");

    try std.testing.expectEqual(@as(usize, 2), dt.entryCount());
    try std.testing.expectEqual(@as(u64, 2), dt.insert_count);

    // Index 0 = newest = ":path"
    const entry0 = try dt.lookup(0);
    try std.testing.expectEqualStrings(":path", entry0.name);
    try std.testing.expectEqualStrings("/index.html", entry0.value);

    // Index 1 = older = ":method"
    const entry1 = try dt.lookup(1);
    try std.testing.expectEqualStrings(":method", entry1.name);
    try std.testing.expectEqualStrings("GET", entry1.value);
}

test "DynamicTable eviction under capacity pressure" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    // Each entry: name.len + value.len + 32
    // ":method" (7) + "GET" (3) + 32 = 42 bytes
    dt.setCapacity(85); // Room for exactly 2 entries (42 + 43 = 85)

    try dt.insert(":method", "GET"); // 42 bytes, total = 42
    try dt.insert(":method", "POST"); // 43 bytes, total = 85
    try std.testing.expectEqual(@as(usize, 2), dt.entryCount());

    // Insert a third entry: evicts oldest
    try dt.insert(":path", "/"); // ":path"(5) + "/"(1) + 32 = 38 bytes
    // 85 + 38 = 123 > 85, so evict oldest (":method" "GET", 42 bytes)
    // 85 - 42 = 43, 43 + 38 = 81 <= 85, OK
    try std.testing.expectEqual(@as(usize, 2), dt.entryCount());
    try std.testing.expectEqual(@as(u64, 3), dt.insert_count);

    // Newest is ":path" "/"
    const entry0 = try dt.lookup(0);
    try std.testing.expectEqualStrings(":path", entry0.name);

    // Oldest remaining is ":method" "POST"
    const entry1 = try dt.lookup(1);
    try std.testing.expectEqualStrings(":method", entry1.name);
    try std.testing.expectEqualStrings("POST", entry1.value);
}

test "DynamicTable setCapacity evicts" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(4096);
    try dt.insert(":method", "GET");
    try dt.insert(":path", "/");
    try std.testing.expectEqual(@as(usize, 2), dt.entryCount());

    // Shrink capacity to force eviction
    dt.setCapacity(40); // ":path"(5) + "/"(1) + 32 = 38 <= 40, ":method"(7) + "GET"(3) + 32 = 42 > 40
    // current_size = 38 + 42 = 80 > 40, evict oldest (":method" "GET", 42 bytes)
    // 80 - 42 = 38 <= 40, OK
    try std.testing.expectEqual(@as(usize, 1), dt.entryCount());
    const entry = try dt.lookup(0);
    try std.testing.expectEqualStrings(":path", entry.name);
}

test "DynamicTable entry too large clears table" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(50);
    try dt.insert(":method", "GET"); // 42 bytes
    try std.testing.expectEqual(@as(usize, 1), dt.entryCount());

    // Insert entry larger than capacity: clears table
    try dt.insert("x-very-long-header-name", "x-very-long-header-value"); // 23 + 23 + 32 = 78 > 50
    try std.testing.expectEqual(@as(usize, 0), dt.entryCount());
    try std.testing.expectEqual(@as(u64, 1), dt.insert_count); // insert_count does NOT increment for oversized entry
}

test "DynamicTable tryInsertProtected never evicts referenced entries" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    // Capacity for exactly one 36-byte entry.
    dt.setCapacity(36);
    try dt.insert("x-a", "1");
    try dt.acknowledgeReceived(1);
    dt.protectUpTo(1); // absolute index 0 is referenced by a pending section

    // Inserting another entry would evict the protected one, so it is skipped.
    const inserted = try dt.tryInsertProtected("x-b", "2");
    try std.testing.expect(!inserted);
    try std.testing.expectEqual(@as(usize, 1), dt.entryCount());
    const entry = try dt.lookup(0);
    try std.testing.expectEqualStrings("x-a", entry.name);

    // After the section is acknowledged, the entry is evictable again.
    dt.setProtectedEntries(0);
    const inserted2 = try dt.tryInsertProtected("x-b", "2");
    try std.testing.expect(inserted2);
    try std.testing.expectEqual(@as(usize, 1), dt.entryCount());
    const entry2 = try dt.lookup(0);
    try std.testing.expectEqualStrings("x-b", entry2.name);
}

test "DynamicTable duplicate" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(4096);
    try dt.insert(":method", "GET");
    try dt.insert(":path", "/");

    // Duplicate index 1 (":method" "GET")
    try dt.duplicate(1);
    try std.testing.expectEqual(@as(usize, 3), dt.entryCount());
    try std.testing.expectEqual(@as(u64, 3), dt.insert_count);

    // Newest is the duplicate
    const entry0 = try dt.lookup(0);
    try std.testing.expectEqualStrings(":method", entry0.name);
    try std.testing.expectEqualStrings("GET", entry0.value);
}

test "DynamicTable duplicate does not use-after-free when evicting self" {
    // Regression: duplicate() read the table-owned name/value slice, then
    // insert() evicted — freeing that same entry's heap — before duping it.
    // capacity just fits 2 entries; the shared table is full.
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(100); // 2 x (10 + 3 + 32) = 90 <= 100; 3rd forces evict
    try dt.insert("aaaaaaaaaa", "b"); // 10 + 1 + 32 = 43
    try dt.insert("cccccccccc", "d"); // 43
    // Duplicate the oldest (index 1): insert() must evict it to make room.
    try dt.duplicate(1);
    // The duplicate is the newest; the evicted copy is gone.
    try std.testing.expectEqual(@as(usize, 2), dt.entryCount());
    const top = try dt.lookup(0);
    try std.testing.expectEqualStrings("aaaaaaaaaa", top.name);
    try std.testing.expectEqualStrings("b", top.value);
}

test "DynamicTable findExact and findName" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(4096);
    try dt.insert(":method", "GET");
    try dt.insert(":path", "/");
    try dt.insert(":method", "POST");

    // findExact: ":method" "POST" is at index 0 (newest)
    try std.testing.expectEqual(@as(?u64, 0), dt.findExact(":method", "POST"));
    // findExact: ":method" "GET" is at index 2 (oldest)
    try std.testing.expectEqual(@as(?u64, 2), dt.findExact(":method", "GET"));
    // findExact: not found
    try std.testing.expect(dt.findExact(":method", "DELETE") == null);

    // findName: ":method" first match is index 0 (newest)
    try std.testing.expectEqual(@as(?u64, 0), dt.findName(":method"));
    // findName: ":path" is at index 1
    try std.testing.expectEqual(@as(?u64, 1), dt.findName(":path"));
    // findName: not found
    try std.testing.expect(dt.findName(":scheme") == null);
}

test "DynamicTable absolute/relative index conversion" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();

    dt.setCapacity(4096);
    try dt.insert(":method", "GET"); // absolute 0, relative 2
    try dt.insert(":path", "/"); // absolute 1, relative 1
    try dt.insert(":scheme", "https"); // absolute 2, relative 0

    try std.testing.expectEqual(@as(u64, 0), try dt.getAbsoluteIndex(2)); // relative 2 -> absolute 0
    try std.testing.expectEqual(@as(u64, 1), try dt.getAbsoluteIndex(1)); // relative 1 -> absolute 1
    try std.testing.expectEqual(@as(u64, 2), try dt.getAbsoluteIndex(0)); // relative 0 -> absolute 2

    try std.testing.expectEqual(@as(u64, 2), try dt.absoluteToRelative(0)); // absolute 0 -> relative 2
    try std.testing.expectEqual(@as(u64, 1), try dt.absoluteToRelative(1)); // absolute 1 -> relative 1
    try std.testing.expectEqual(@as(u64, 0), try dt.absoluteToRelative(2)); // absolute 2 -> relative 0
}

test "DynamicTable entry size calculation" {
    const entry = DynamicEntry{ .name = ":method", .value = "GET" };
    // ":method" (7) + "GET" (3) + 32 = 42
    try std.testing.expectEqual(@as(usize, 42), entry.size());

    const entry2 = DynamicEntry{ .name = "x-custom", .value = "value" };
    // "x-custom" (8) + "value" (5) + 32 = 45
    try std.testing.expectEqual(@as(usize, 45), entry2.size());
}

// ---------------------------------------------------------------------------
// Encoder stream instructions (RFC 9204 §4.3)
// ---------------------------------------------------------------------------

/// Encoder instruction types (RFC 9204 §4.3).
pub const EncoderInstruction = union(enum) {
    /// §4.3.1: Insert with Name Reference.
    insert_name_ref: struct {
        /// true = static table reference, false = dynamic table reference.
        is_static: bool,
        /// Name index (static or dynamic relative index).
        name_index: u64,
        /// Value string to insert.
        value: []const u8,
    },
    /// §4.3.2: Insert with Literal Name.
    insert_literal: struct {
        name: []const u8,
        value: []const u8,
    },
    /// §4.3.3: Set Dynamic Table Capacity.
    set_capacity: u64,
    /// §4.3.4: Duplicate.
    duplicate: u64,
};

/// Encode an encoder stream instruction into a buffer.
/// Returns the number of bytes written.
pub fn encodeEncoderInstruction(out: []u8, instruction: EncoderInstruction) !usize {
    var pos: usize = 0;
    switch (instruction) {
        .insert_name_ref => |ref| {
            // 1TNNNNNN: 1-bit prefix=1, T bit, 6-bit name index prefix
            const t_bit: u8 = if (ref.is_static) 0x40 else 0x00;
            if (ref.name_index < 63) {
                out[pos] = 0x80 | t_bit | @as(u8, @intCast(ref.name_index));
                pos += 1;
            } else {
                out[pos] = 0x80 | t_bit | 0x3f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, ref.name_index - 63);
            }
            // Value string (H=0, length prefix)
            pos = try encodeStringToBuf(out, pos, ref.value);
        },
        .insert_literal => |lit| {
            // 01NNNNNN: 2-bit prefix=01, H bit + 5-bit name length prefix
            // We encode H=0 (no Huffman)
            if (lit.name.len < 31) {
                out[pos] = 0x40 | @as(u8, @intCast(lit.name.len));
                pos += 1;
            } else {
                out[pos] = 0x40 | 0x1f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, lit.name.len - 31);
            }
            @memcpy(out[pos .. pos + lit.name.len], lit.name);
            pos += lit.name.len;
            // Value string
            pos = try encodeStringToBuf(out, pos, lit.value);
        },
        .set_capacity => |capacity| {
            // 001NNNNN: 3-bit prefix=001, 5-bit capacity prefix
            if (capacity < 31) {
                out[pos] = 0x20 | @as(u8, @intCast(capacity));
                pos += 1;
            } else {
                out[pos] = 0x20 | 0x1f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, capacity - 31);
            }
        },
        .duplicate => |index| {
            // 000NNNNN: 3-bit prefix=000, 5-bit index prefix
            if (index < 31) {
                out[pos] = @intCast(index);
                pos += 1;
            } else {
                out[pos] = 0x1f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, index - 31);
            }
        },
    }
    return pos;
}

/// Decode an encoder stream instruction from a buffer.
/// Returns the instruction and number of bytes consumed.
pub fn decodeEncoderInstruction(data: []const u8) !struct { instruction: EncoderInstruction, consumed: usize } {
    if (data.len == 0) return error.IncompleteString;
    const first = data[0];

    if (first & 0x80 != 0) {
        // Insert with Name Reference: 1TNNNNNN
        const is_static = (first & 0x40) != 0;
        var name_index: u64 = first & 0x3f;
        var pos: usize = 1;
        if (name_index == 63) {
            const varint = try decodeVarintFromBuf(data, pos);
            name_index = 63 + varint.value;
            pos = varint.end;
        }
        const value_result = try decodeString(data, pos);
        return .{
            .instruction = .{ .insert_name_ref = .{
                .is_static = is_static,
                .name_index = name_index,
                .value = value_result.value,
            } },
            .consumed = value_result.end,
        };
    } else if (first & 0x40 != 0) {
        // Insert with Literal Name: 01HNNNNN
        const h_bit = (first & 0x20) != 0;
        if (h_bit) return error.HuffmanNotSupported;
        var name_len: u64 = first & 0x1f;
        var pos: usize = 1;
        if (name_len == 31) {
            const varint = try decodeVarintFromBuf(data, pos);
            name_len = 31 + varint.value;
            pos = varint.end;
        }
        const name_len_usize: usize = @intCast(name_len);
        if (pos + name_len_usize > data.len) return error.IncompleteString;
        const name = data[pos .. pos + name_len_usize];
        pos += name_len_usize;
        const value_result = try decodeString(data, pos);
        return .{
            .instruction = .{ .insert_literal = .{
                .name = name,
                .value = value_result.value,
            } },
            .consumed = value_result.end,
        };
    } else if (first & 0x20 != 0) {
        // Set Dynamic Table Capacity: 001NNNNN
        var capacity: u64 = first & 0x1f;
        var pos: usize = 1;
        if (capacity == 31) {
            const varint = try decodeVarintFromBuf(data, pos);
            capacity = 31 + varint.value;
            pos = varint.end;
        }
        return .{
            .instruction = .{ .set_capacity = capacity },
            .consumed = pos,
        };
    } else {
        // Duplicate: 000NNNNN
        var index: u64 = first & 0x1f;
        var pos: usize = 1;
        if (index == 31) {
            const varint = try decodeVarintFromBuf(data, pos);
            index = 31 + varint.value;
            pos = varint.end;
        }
        return .{
            .instruction = .{ .duplicate = index },
            .consumed = pos,
        };
    }
}

// ---------------------------------------------------------------------------
// Decoder stream instructions (RFC 9204 §4.4)
// ---------------------------------------------------------------------------

/// Decoder instruction types (RFC 9204 §4.4).
pub const DecoderInstruction = union(enum) {
    /// §4.4.1: Section Acknowledgment.
    section_ack: u64,
    /// §4.4.2: Stream Cancellation.
    stream_cancellation: u64,
    /// §4.4.3: Insert Count Increment.
    insert_count_increment: u64,
};

/// Consume a run of encoder stream instructions from `data` and apply them to
/// `dynamic_table` (RFC 9204 §4.3). This is what a QPACK decoder runs before
/// decoding a header block: it replicates the encoder's insertions so the
/// block's dynamic references and Required Insert Count resolve. Returns the
/// number of bytes consumed. A malformed/truncated instruction is a protocol
/// error.
pub fn decodeEncoderStreamInstructions(
    data: []const u8,
    dynamic_table: *DynamicTable,
) !usize {
    var pos: usize = 0;
    while (pos < data.len) {
        const decoded = try decodeEncoderInstruction(data[pos..]);
        switch (decoded.instruction) {
            .insert_name_ref => |ins| {
                const name = if (ins.is_static)
                    static_table[@intCast(ins.name_index)].name
                else
                    (try dynamic_table.lookup(ins.name_index)).name;
                try dynamic_table.insert(name, ins.value);
            },
            .insert_literal => |ins| try dynamic_table.insert(ins.name, ins.value),
            .set_capacity => |cap| dynamic_table.setCapacity(@intCast(cap)),
            .duplicate => |idx| try dynamic_table.duplicate(idx),
        }
        if (decoded.consumed == 0) break;
        pos += decoded.consumed;
    }
    return pos;
}

/// Return the length of the longest prefix of `data` that consists entirely of
/// complete encoder-stream instructions, without applying them. The runtime
/// driver uses this to decide how much buffered encoder-stream data can be fed
/// to `processPeerEncoderStream` when bytes arrive split across datagrams.
pub fn encoderStreamConsumedLength(data: []const u8) !usize {
    var pos: usize = 0;
    while (pos < data.len) {
        const decoded = try decodeEncoderInstruction(data[pos..]);
        if (decoded.consumed == 0) break;
        pos += decoded.consumed;
    }
    return pos;
}

/// Encode a decoder stream instruction into a buffer.
/// Returns the number of bytes written.
pub fn encodeDecoderInstruction(out: []u8, instruction: DecoderInstruction) !usize {
    var pos: usize = 0;
    switch (instruction) {
        .section_ack => |stream_id| {
            // 1NNNNNNN: 1-bit prefix=1, 7-bit stream ID prefix
            if (stream_id < 127) {
                out[pos] = 0x80 | @as(u8, @intCast(stream_id));
                pos += 1;
            } else {
                out[pos] = 0xff;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, stream_id - 127);
            }
        },
        .stream_cancellation => |stream_id| {
            // 01NNNNNN: 2-bit prefix=01, 6-bit stream ID prefix
            if (stream_id < 63) {
                out[pos] = 0x40 | @as(u8, @intCast(stream_id));
                pos += 1;
            } else {
                out[pos] = 0x7f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, stream_id - 63);
            }
        },
        .insert_count_increment => |increment| {
            // 00NNNNNN: 2-bit prefix=00, 6-bit increment prefix
            if (increment < 63) {
                out[pos] = @intCast(increment);
                pos += 1;
            } else {
                out[pos] = 0x3f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, increment - 63);
            }
        },
    }
    return pos;
}

/// Decode a decoder stream instruction from a buffer.
/// Returns the instruction and number of bytes consumed.
pub fn decodeDecoderInstruction(data: []const u8) !struct { instruction: DecoderInstruction, consumed: usize } {
    if (data.len == 0) return error.IncompleteString;
    const first = data[0];

    if (first & 0x80 != 0) {
        // Section Acknowledgment: 1NNNNNNN
        var stream_id: u64 = first & 0x7f;
        var pos: usize = 1;
        if (stream_id == 127) {
            const varint = try decodeVarintFromBuf(data, pos);
            stream_id = 127 + varint.value;
            pos = varint.end;
        }
        return .{
            .instruction = .{ .section_ack = stream_id },
            .consumed = pos,
        };
    } else if (first & 0x40 != 0) {
        // Stream Cancellation: 01NNNNNN
        var stream_id: u64 = first & 0x3f;
        var pos: usize = 1;
        if (stream_id == 63) {
            const varint = try decodeVarintFromBuf(data, pos);
            stream_id = 63 + varint.value;
            pos = varint.end;
        }
        return .{
            .instruction = .{ .stream_cancellation = stream_id },
            .consumed = pos,
        };
    } else {
        // Insert Count Increment: 00NNNNNN
        var increment: u64 = first & 0x3f;
        var pos: usize = 1;
        if (increment == 63) {
            const varint = try decodeVarintFromBuf(data, pos);
            increment = 63 + varint.value;
            pos = varint.end;
        }
        return .{
            .instruction = .{ .insert_count_increment = increment },
            .consumed = pos,
        };
    }
}

/// Consume a run of decoder stream instructions from `data` and apply them to
/// the local encoder-side table (RFC 9204 §4.4). `pending_sections` records the
/// Required Insert Count of each dynamic section this encoder sent, keyed by
/// stream ID, so a Section Acknowledgment can raise the Known Received Count.
/// Returns the number of bytes consumed. A malformed/truncated instruction, a
/// duplicate Section Acknowledgment, or an increment beyond what this encoder
/// sent is a protocol error (QPACK_DECODER_STREAM_ERROR).
pub fn decodeDecoderStreamInstructions(
    data: []const u8,
    dynamic_table: *DynamicTable,
    pending_sections: *std.AutoHashMap(u64, u64),
) !usize {
    var pos: usize = 0;
    while (pos < data.len) {
        const decoded = try decodeDecoderInstruction(data[pos..]);
        switch (decoded.instruction) {
            .section_ack => |stream_id| {
                const required_insert_count = pending_sections.fetchRemove(stream_id) orelse
                    return error.DuplicateSectionAck;
                try dynamic_table.acknowledgeReceived(required_insert_count.value);
                try recomputeProtectedEntries(dynamic_table, pending_sections);
            },
            .stream_cancellation => |stream_id| {
                _ = pending_sections.fetchRemove(stream_id);
                try recomputeProtectedEntries(dynamic_table, pending_sections);
            },
            .insert_count_increment => |increment| {
                if (increment == 0) return error.ZeroInsertCountIncrement;
                try dynamic_table.acknowledgeReceived(dynamic_table.known_received_count + increment);
            },
        }
        if (decoded.consumed == 0) break;
        pos += decoded.consumed;
    }
    return pos;
}

/// Return the length of the longest prefix of `data` that consists entirely of
/// complete decoder-stream instructions, without applying them. Used by the
/// runtime driver to feed only complete decoder instructions to the state
/// machine when bytes arrive split across datagrams.
pub fn decoderStreamConsumedLength(data: []const u8) !usize {
    var pos: usize = 0;
    while (pos < data.len) {
        const decoded = try decodeDecoderInstruction(data[pos..]);
        if (decoded.consumed == 0) break;
        pos += decoded.consumed;
    }
    return pos;
}

/// Recompute the protected eviction prefix from the pending sections' Required
/// Insert Counts after an acknowledgment or cancellation changes the set.
fn recomputeProtectedEntries(
    dynamic_table: *DynamicTable,
    pending_sections: *std.AutoHashMap(u64, u64),
) !void {
    var max_required_insert_count: u64 = 0;
    var it = pending_sections.iterator();
    while (it.next()) |entry| {
        max_required_insert_count = @max(max_required_insert_count, entry.value_ptr.*);
    }
    dynamic_table.setProtectedEntries(max_required_insert_count);
}

// ---------------------------------------------------------------------------
// Encoder/Decoder instruction tests
// ---------------------------------------------------------------------------

test "Encoder instruction: insert with static name reference" {
    var buf: [64]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{
        .insert_name_ref = .{
            .is_static = true,
            .name_index = 8, // :method
            .value = "PATCH",
        },
    });

    // Decode and verify
    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .insert_name_ref => |ref| {
            try std.testing.expect(ref.is_static);
            try std.testing.expectEqual(@as(u64, 8), ref.name_index);
            try std.testing.expectEqualStrings("PATCH", ref.value);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Encoder instruction: insert with dynamic name reference" {
    var buf: [64]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{
        .insert_name_ref = .{
            .is_static = false,
            .name_index = 2, // dynamic relative index 2
            .value = "custom-value",
        },
    });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .insert_name_ref => |ref| {
            try std.testing.expect(!ref.is_static);
            try std.testing.expectEqual(@as(u64, 2), ref.name_index);
            try std.testing.expectEqualStrings("custom-value", ref.value);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Encoder instruction: insert with literal name" {
    var buf: [128]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{ .insert_literal = .{
        .name = "x-custom-header",
        .value = "custom-value",
    } });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .insert_literal => |lit| {
            try std.testing.expectEqualStrings("x-custom-header", lit.name);
            try std.testing.expectEqualStrings("custom-value", lit.value);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Encoder instruction: set capacity" {
    var buf: [16]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{ .set_capacity = 4096 });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .set_capacity => |cap| {
            try std.testing.expectEqual(@as(u64, 4096), cap);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Encoder instruction: duplicate" {
    var buf: [16]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{ .duplicate = 5 });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .duplicate => |idx| {
            try std.testing.expectEqual(@as(u64, 5), idx);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Decoder instruction: section acknowledgment" {
    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .section_ack = 4 });

    const result = try decodeDecoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .section_ack => |stream_id| {
            try std.testing.expectEqual(@as(u64, 4), stream_id);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Decoder instruction: stream cancellation" {
    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .stream_cancellation = 8 });

    const result = try decodeDecoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .stream_cancellation => |stream_id| {
            try std.testing.expectEqual(@as(u64, 8), stream_id);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Decoder instruction: insert count increment" {
    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .insert_count_increment = 3 });

    const result = try decodeDecoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .insert_count_increment => |inc| {
            try std.testing.expectEqual(@as(u64, 3), inc);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "decoder stream: section ack advances Known Received Count" {
    var enc_table = DynamicTable.init(std.testing.allocator);
    defer enc_table.deinit();
    enc_table.setCapacity(4096);
    try enc_table.insert("x-a", "1");
    try enc_table.insert("x-b", "2");

    var pending = std.AutoHashMap(u64, u64).init(std.testing.allocator);
    defer pending.deinit();
    try pending.put(4, 2);

    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .section_ack = 4 });
    try std.testing.expectEqual(@as(u64, 0), enc_table.known_received_count);
    _ = try decodeDecoderStreamInstructions(buf[0..len], &enc_table, &pending);
    try std.testing.expectEqual(@as(u64, 2), enc_table.known_received_count);
    try std.testing.expectEqual(@as(usize, 0), pending.count());
}

test "decoder stream: insert count increment advances Known Received Count" {
    var enc_table = DynamicTable.init(std.testing.allocator);
    defer enc_table.deinit();
    enc_table.setCapacity(4096);
    try enc_table.insert("x-a", "1");
    try enc_table.insert("x-b", "2");

    var pending = std.AutoHashMap(u64, u64).init(std.testing.allocator);
    defer pending.deinit();

    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .insert_count_increment = 2 });
    _ = try decodeDecoderStreamInstructions(buf[0..len], &enc_table, &pending);
    try std.testing.expectEqual(@as(u64, 2), enc_table.known_received_count);

    // An increment beyond what this encoder sent is a decoder stream error.
    const len2 = try encodeDecoderInstruction(&buf, .{ .insert_count_increment = 1 });
    try std.testing.expectError(
        error.KnownReceivedCountBeyondSent,
        decodeDecoderStreamInstructions(buf[0..len2], &enc_table, &pending),
    );
}

test "decoder stream: stream cancellation drops pending section without advancing count" {
    var enc_table = DynamicTable.init(std.testing.allocator);
    defer enc_table.deinit();
    enc_table.setCapacity(4096);
    try enc_table.insert("x-a", "1");

    var pending = std.AutoHashMap(u64, u64).init(std.testing.allocator);
    defer pending.deinit();
    try pending.put(8, 1);

    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .stream_cancellation = 8 });
    _ = try decodeDecoderStreamInstructions(buf[0..len], &enc_table, &pending);
    try std.testing.expectEqual(@as(u64, 0), enc_table.known_received_count);
    try std.testing.expectEqual(@as(usize, 0), pending.count());
}

test "decoder stream: duplicate section ack is a protocol error" {
    var enc_table = DynamicTable.init(std.testing.allocator);
    defer enc_table.deinit();
    enc_table.setCapacity(4096);
    try enc_table.insert("x-a", "1");

    var pending = std.AutoHashMap(u64, u64).init(std.testing.allocator);
    defer pending.deinit();

    var buf: [16]u8 = undefined;
    const len = try encodeDecoderInstruction(&buf, .{ .section_ack = 4 });
    try std.testing.expectError(
        error.DuplicateSectionAck,
        decodeDecoderStreamInstructions(buf[0..len], &enc_table, &pending),
    );
}

test "Encoder instruction: large name index (>= 63)" {
    var buf: [64]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{
        .insert_name_ref = .{
            .is_static = true,
            .name_index = 72, // :status 204
            .value = "",
        },
    });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .insert_name_ref => |ref| {
            try std.testing.expect(ref.is_static);
            try std.testing.expectEqual(@as(u64, 72), ref.name_index);
        },
        else => return error.UnexpectedInstruction,
    }
}

test "Encoder instruction: large capacity (>= 31)" {
    var buf: [16]u8 = undefined;
    const len = try encodeEncoderInstruction(&buf, .{ .set_capacity = 65536 });

    const result = try decodeEncoderInstruction(buf[0..len]);
    switch (result.instruction) {
        .set_capacity => |cap| {
            try std.testing.expectEqual(@as(u64, 65536), cap);
        },
        else => return error.UnexpectedInstruction,
    }
}

// ---------------------------------------------------------------------------
// Header block with dynamic table references (RFC 9204 §4.5)
// ---------------------------------------------------------------------------

pub const DynamicEncodeInfo = struct {
    len: usize,
    required_insert_count: u64,
};

/// Selected wire representation for a header field (RFC 9204 §4.5).
const FieldRepresentation = union(enum) {
    dynamic_indexed: u64,
    static_indexed: u64,
    dynamic_name_ref: struct { relative_index: u64, value: []const u8 },
    static_name_ref: struct { name_index: u64, value: []const u8 },
    literal: struct { name: []const u8, value: []const u8 },
};

/// Choose the smallest representation for `field`. Dynamic references are only
/// chosen when the entry is within the Known Received Count (RFC 9204 §2.2.2),
/// so a peer that has not yet acknowledged the entry is never forced to block.
fn selectFieldRepresentation(
    field: HeaderField,
    dynamic_table: *const DynamicTable,
) FieldRepresentation {
    if (dynamic_table.findExact(field.name, field.value)) |rel_idx| {
        if (dynamic_table.isReferenceable(rel_idx)) return .{ .dynamic_indexed = rel_idx };
    }
    if (findStaticIndex(field.name, field.value)) |idx| return .{ .static_indexed = idx };
    if (dynamic_table.findName(field.name)) |rel_idx| {
        if (dynamic_table.isReferenceable(rel_idx)) {
            return .{ .dynamic_name_ref = .{ .relative_index = rel_idx, .value = field.value } };
        }
    }
    if (findStaticNameIndex(field.name)) |name_idx| {
        return .{ .static_name_ref = .{ .name_index = name_idx, .value = field.value } };
    }
    return .{ .literal = .{ .name = field.name, .value = field.value } };
}

/// Encode a header block using dynamic table references when beneficial and
/// safe. Delta Base is always 0 (Base = Required Insert Count).
pub fn encodeHeaderBlockWithDynamicInfo(
    out: []u8,
    fields: []const HeaderField,
    dynamic_table: *const DynamicTable,
) !DynamicEncodeInfo {
    // RFC 9204 §4.5.1: Required Insert Count is the largest absolute index of
    // any dynamic entry referenced by this section, plus one.
    var req_insert_count: u64 = 0;
    for (fields) |field| {
        switch (selectFieldRepresentation(field, dynamic_table)) {
            .dynamic_indexed => |rel_idx| {
                req_insert_count = @max(req_insert_count, try dynamic_table.getAbsoluteIndex(rel_idx) + 1);
            },
            .dynamic_name_ref => |ref| {
                req_insert_count = @max(req_insert_count, try dynamic_table.getAbsoluteIndex(ref.relative_index) + 1);
            },
            else => {},
        }
    }

    var pos: usize = 0;

    // Required Insert Count: 8-bit prefix integer.
    if (req_insert_count < 255) {
        out[pos] = @intCast(req_insert_count);
        pos += 1;
    } else {
        out[pos] = 0xff;
        pos += 1;
        pos = encodeVarintToBuf(out, pos, req_insert_count - 255);
    }

    // Delta Base: sign bit (0 = positive) + 7-bit prefix, value = 0
    out[pos] = 0x00;
    pos += 1;

    for (fields) |field| {
        switch (selectFieldRepresentation(field, dynamic_table)) {
            .dynamic_indexed => |rel_idx| {
                // Indexed Field Line (dynamic): 1TXXXXXX, T=0
                if (rel_idx < 63) {
                    out[pos] = @intCast(0x80 | rel_idx);
                    pos += 1;
                } else {
                    out[pos] = 0xbf; // 0x80 | 0x3f
                    pos += 1;
                    pos = encodeVarintToBuf(out, pos, rel_idx - 63);
                }
            },
            .static_indexed => |idx| {
                // Indexed Field Line (static): 1TXXXXXX, T=1
                if (idx < 63) {
                    out[pos] = @intCast(0xc0 | idx);
                    pos += 1;
                } else {
                    out[pos] = 0xff;
                    pos += 1;
                    pos = encodeVarintToBuf(out, pos, idx - 63);
                }
            },
            .dynamic_name_ref => |ref| {
                // Literal with Name Reference (dynamic): 01NTXXXX, T=0, N=0
                if (ref.relative_index < 15) {
                    out[pos] = @intCast(0x40 | ref.relative_index);
                    pos += 1;
                } else {
                    out[pos] = 0x4f; // 0x40 | 0x0f
                    pos += 1;
                    pos = encodeVarintToBuf(out, pos, ref.relative_index - 15);
                }
                pos = try encodeStringToBuf(out, pos, ref.value);
            },
            .static_name_ref => |ref| {
                // Literal with Name Reference (static): 01NTXXXX, T=1, N=0
                if (ref.name_index < 15) {
                    out[pos] = @intCast(0x50 | ref.name_index);
                    pos += 1;
                } else {
                    out[pos] = 0x5f;
                    pos += 1;
                    pos = encodeVarintToBuf(out, pos, ref.name_index - 15);
                }
                pos = try encodeStringToBuf(out, pos, ref.value);
            },
            .literal => |lit| {
                // Literal without Name Reference: 001N + 4-bit-prefix name
                pos = try encodeStringToBuf4(out, pos, lit.name);
                pos = try encodeStringToBuf(out, pos, lit.value);
            },
        }
    }

    return .{ .len = pos, .required_insert_count = req_insert_count };
}

/// Encode a header block using dynamic table references when beneficial.
pub fn encodeHeaderBlockWithDynamic(
    out: []u8,
    fields: []const HeaderField,
    dynamic_table: *const DynamicTable,
) !usize {
    return (try encodeHeaderBlockWithDynamicInfo(out, fields, dynamic_table)).len;
}

/// Encode a header block with dynamic-table insertion (RFC 9204 §4.3).
///
/// Unlike `encodeHeaderBlockWithDynamic`, this encoder actively maintains the
/// dynamic table: fields not already representable by a static/dynamic index
/// are queued for insertion. The Insert instructions are written to
/// `encoder_stream_out` (to be sent on the QPACK encoder stream) and applied to
/// the local `dynamic_table` so the emitted Required Insert Count and the
/// reference indexes match what the decoder will have after it consumes the
/// same instructions. Returns the header-block length.
pub const DynamicEncodeResult = struct {
    header_block_len: usize,
    encoder_stream_len: usize,
    required_insert_count: u64,
};

pub fn encodeHeaderBlockWithDynamicInserting(
    out: []u8,
    encoder_stream_out: []u8,
    fields: []const HeaderField,
    dynamic_table: *DynamicTable,
) !DynamicEncodeResult {
    var instr_pos: usize = 0;
    for (fields) |field| {
        // Already exactly representable — no insertion needed.
        if (dynamic_table.findExact(field.name, field.value) != null) continue;
        if (findStaticIndex(field.name, field.value) != null) continue;

        const instr = if (dynamic_table.findName(field.name)) |name_index|
            EncoderInstruction{ .insert_name_ref = .{ .is_static = false, .name_index = name_index, .value = field.value } }
        else if (findStaticNameIndex(field.name)) |name_index|
            EncoderInstruction{ .insert_name_ref = .{ .is_static = true, .name_index = name_index, .value = field.value } }
        else
            EncoderInstruction{ .insert_literal = .{ .name = field.name, .value = field.value } };

        // Apply to the local table first so the header block below references
        // the post-insertion state. Only advertise the insertion on the encoder
        // stream when it actually succeeded: a skipped insertion is encoded as
        // a literal and never sent to the peer (RFC 9204 §2.1.1).
        if (try dynamic_table.tryInsertProtected(field.name, field.value)) {
            try encodeEncoderInstructionToBuffer(encoder_stream_out, &instr_pos, instr);
        }
    }
    const enc = try encodeHeaderBlockWithDynamicInfo(out, fields, dynamic_table);
    return .{
        .header_block_len = enc.len,
        .encoder_stream_len = instr_pos,
        .required_insert_count = enc.required_insert_count,
    };
}

/// Encode an encoder instruction, advancing `pos` and erroring on overflow.
fn encodeEncoderInstructionToBuffer(buf: []u8, pos: *usize, instruction: EncoderInstruction) !void {
    const n = try encodeEncoderInstruction(buf[pos.*..], instruction);
    pos.* += n;
}

pub const DynamicDecodeInfo = struct {
    field_count: usize,
    required_insert_count: u64,
};

/// Decode a header block that may contain dynamic table references.
/// The dynamic table must be in the same state as when the block was encoded.
/// Returns the decoded field count and the block's Required Insert Count so the
/// caller can emit the matching Section Acknowledgment (RFC 9204 §4.4.1).
pub fn decodeHeaderBlockWithDynamicInfo(
    data: []const u8,
    out_fields: []HeaderField,
    dynamic_table: *const DynamicTable,
) !DynamicDecodeInfo {
    if (data.len < 2) return error.InvalidHeaderBlock;

    var pos: usize = 0;

    // Required Insert Count (8-bit prefix integer).
    var required_insert_count: u64 = 0;
    if (data[pos] == 0xff) {
        pos += 1;
        const v = try decodeVarintFromBuf(data, pos);
        required_insert_count = 255 + v.value;
        pos = v.end;
    } else {
        required_insert_count = data[pos];
        pos += 1;
    }

    // Skip Delta Base (sign bit + 7-bit prefix varint). Guard pos: the
    // Required Insert Count 0xff branch (or a short block) can advance pos to
    // data.len, and an attacker-controlled header block must not index past it.
    if (pos >= data.len) return error.IncompleteString;
    if (data[pos] & 0x7f == 0x7f) {
        pos += 1;
        const v = try decodeVarintFromBuf(data, pos);
        pos = v.end;
    } else {
        pos += 1;
    }

    // RFC 9204 §2.2.1: when the header block needs more insertions than the
    // decoder has received, the field section is blocked until the encoder
    // stream catches up, rather than an invalid-reference error.
    if (required_insert_count > dynamic_table.insert_count) {
        return error.BlockedByQpack;
    }

    var field_count: usize = 0;

    while (pos < data.len) {
        const byte = data[pos];

        if (byte & 0x80 != 0) {
            // Indexed Field Line: 1TXXXXXX
            const is_static = (byte & 0x40) != 0;
            var index: u64 = 0;
            if (byte & 0x3f == 0x3f) {
                pos += 1;
                const v = try decodeVarintFromBuf(data, pos);
                index = v.value + 63;
                pos = v.end;
            } else {
                index = byte & 0x3f;
                pos += 1;
            }

            if (is_static) {
                if (index >= static_table.len) return error.InvalidStaticIndex;
                const entry = static_table[@intCast(index)];
                out_fields[field_count] = .{ .name = entry.name, .value = entry.value };
            } else {
                // Dynamic table reference: index is relative (0 = newest)
                const entry = try dynamic_table.lookup(index);
                out_fields[field_count] = .{ .name = entry.name, .value = entry.value };
            }
            field_count += 1;
        } else if (byte & 0xc0 == 0x40) {
            // Literal with Name Reference: 01NTXXXX
            const is_static = (byte & 0x10) != 0;
            var name_index: u64 = 0;
            if (byte & 0x0f == 0x0f) {
                pos += 1;
                const v = try decodeVarintFromBuf(data, pos);
                name_index = v.value + 15;
                pos = v.end;
            } else {
                name_index = byte & 0x0f;
                pos += 1;
            }

            const name: []const u8 = if (is_static) blk: {
                if (name_index >= static_table.len) return error.InvalidStaticIndex;
                break :blk static_table[@intCast(name_index)].name;
            } else blk: {
                const entry = try dynamic_table.lookup(name_index);
                break :blk entry.name;
            };

            const str = try decodeString(data, pos);
            pos = str.end;
            out_fields[field_count] = .{ .name = name, .value = str.value };
            field_count += 1;
        } else if (byte & 0xe0 == 0x20) {
            // Literal without Name Reference: the field-header byte carries
            // N + H + 3-bit length (4-bit-prefix name string).
            const name_str = try decodeString4(data, pos);
            pos = name_str.end;
            const value_str = try decodeString(data, pos);
            pos = value_str.end;
            out_fields[field_count] = .{ .name = name_str.value, .value = value_str.value };
            field_count += 1;
        } else {
            return error.InvalidHeaderBlock;
        }

        if (field_count >= out_fields.len) break;
    }

    return .{
        .field_count = field_count,
        .required_insert_count = required_insert_count,
    };
}

/// Decode a header block that may contain dynamic table references.
pub fn decodeHeaderBlockWithDynamic(
    data: []const u8,
    out_fields: []HeaderField,
    dynamic_table: *const DynamicTable,
) !usize {
    return (try decodeHeaderBlockWithDynamicInfo(data, out_fields, dynamic_table)).field_count;
}

// ---------------------------------------------------------------------------
// Dynamic header block tests
// ---------------------------------------------------------------------------

test "encodeHeaderBlockWithDynamic: dynamic exact match" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-custom", "my-value");
    try dt.acknowledgeReceived(1);

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = "x-custom", .value = "my-value" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    // Prefix: Required Insert Count = 1, Delta Base = 0
    try std.testing.expectEqual(@as(u8, 1), encoded[0]);
    try std.testing.expectEqual(@as(u8, 0), encoded[1]);
    // :method GET = static index 17: 0xc0 | 17 = 0xd1
    try std.testing.expectEqual(@as(u8, 0xd1), encoded[2]);
    // x-custom my-value = dynamic index 0: 0x80 | 0 = 0x80
    try std.testing.expectEqual(@as(u8, 0x80), encoded[3]);
    try std.testing.expectEqual(@as(usize, 4), len);
}

test "encodeHeaderBlockWithDynamic: dynamic name ref" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-token", "abc");
    try dt.acknowledgeReceived(1);

    const fields = [_]HeaderField{
        .{ .name = "x-token", .value = "xyz" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    // Prefix: RIC=1, DB=0
    try std.testing.expectEqual(@as(u8, 1), encoded[0]);
    try std.testing.expectEqual(@as(u8, 0), encoded[1]);
    // Literal with Name Reference (dynamic): 0x40 | 0 = 0x40
    try std.testing.expectEqual(@as(u8, 0x40), encoded[2]);
    // Value "xyz" length = 3
    try std.testing.expectEqual(@as(u8, 3), encoded[3]);
    try std.testing.expectEqual(@as(usize, 7), len); // 2 prefix + 1 instr + 1 len + 3 value
}

test "encodeHeaderBlockWithDynamic: unacknowledged entries are encoded literally" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-custom", "my-value");

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = "x-custom", .value = "my-value" },
    };

    // The peer has not acknowledged the insertion, so no dynamic reference and
    // Required Insert Count stays zero (RFC 9204 §2.2.2).
    var encoded: [256]u8 = undefined;
    const enc = try encodeHeaderBlockWithDynamicInfo(&encoded, &fields, &dt);
    try std.testing.expectEqual(@as(u64, 0), enc.required_insert_count);
    try std.testing.expectEqual(@as(u8, 0), encoded[0]);
    // x-custom is a literal with name reference (static name has no entry):
    // 0x20 literal prefix, not a dynamic 0x80 reference.
    try std.testing.expect(encoded[3] & 0x80 == 0);

    // Once acknowledged, the same encoder emits a dynamic reference.
    try dt.acknowledgeReceived(1);
    const enc2 = try encodeHeaderBlockWithDynamicInfo(&encoded, &fields, &dt);
    try std.testing.expectEqual(@as(u64, 1), enc2.required_insert_count);
    try std.testing.expectEqual(@as(u8, 0x80), encoded[3]);
}

test "encodeHeaderBlockWithDynamic: roundtrip" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-request-id", "req-123");
    try dt.insert("x-session", "sess-456");

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "POST" },
        .{ .name = ":path", .value = "/api/v1" },
        .{ .name = "x-request-id", .value = "req-123" },
        .{ .name = "x-session", .value = "sess-456" },
        .{ .name = "content-type", .value = "application/json" },
    };

    var encoded: [512]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    var decoded: [16]HeaderField = undefined;
    const count = try decodeHeaderBlockWithDynamic(encoded[0..len], &decoded, &dt);

    try std.testing.expectEqual(@as(usize, 5), count);
    try std.testing.expectEqualStrings(":method", decoded[0].name);
    try std.testing.expectEqualStrings("POST", decoded[0].value);
    try std.testing.expectEqualStrings(":path", decoded[1].name);
    try std.testing.expectEqualStrings("/api/v1", decoded[1].value);
    try std.testing.expectEqualStrings("x-request-id", decoded[2].name);
    try std.testing.expectEqualStrings("req-123", decoded[2].value);
    try std.testing.expectEqualStrings("x-session", decoded[3].name);
    try std.testing.expectEqualStrings("sess-456", decoded[3].value);
    try std.testing.expectEqualStrings("content-type", decoded[4].name);
    try std.testing.expectEqualStrings("application/json", decoded[4].value);
}

test "encodeHeaderBlockWithDynamic: empty dynamic table falls back to static" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":status", .value = "200" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    // Prefix: RIC=0, DB=0
    try std.testing.expectEqual(@as(u8, 0), encoded[0]);
    try std.testing.expectEqual(@as(u8, 0), encoded[1]);
    // :method GET = static 17: 0xd1
    try std.testing.expectEqual(@as(u8, 0xd1), encoded[2]);
    // :status 200 = static 25: 0xc0 | 25 = 0xd9
    try std.testing.expectEqual(@as(u8, 0xd9), encoded[3]);
    try std.testing.expectEqual(@as(usize, 4), len);

    // Decode roundtrip
    var decoded: [4]HeaderField = undefined;
    const count = try decodeHeaderBlockWithDynamic(encoded[0..len], &decoded, &dt);
    try std.testing.expectEqual(@as(usize, 2), count);
    try std.testing.expectEqualStrings(":method", decoded[0].name);
    try std.testing.expectEqualStrings("GET", decoded[0].value);
    try std.testing.expectEqualStrings(":status", decoded[1].name);
    try std.testing.expectEqualStrings("200", decoded[1].value);
}

test "encodeHeaderBlockWithDynamic: large dynamic index (>= 63)" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(65536);

    // Insert 65 entries so we can reference index 64
    var i: u64 = 0;
    while (i < 65) : (i += 1) {
        var name_buf: [32]u8 = undefined;
        var value_buf: [32]u8 = undefined;
        const name = std.fmt.bufPrint(&name_buf, "hdr-{d}", .{i}) catch unreachable;
        const value = std.fmt.bufPrint(&value_buf, "val-{d}", .{i}) catch unreachable;
        try dt.insert(name, value);
    }
    try dt.acknowledgeReceived(65);

    // Reference the oldest entry (relative index 64)
    const fields = [_]HeaderField{
        .{ .name = "hdr-0", .value = "val-0" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    // Decode and verify
    var decoded: [4]HeaderField = undefined;
    const count = try decodeHeaderBlockWithDynamic(encoded[0..len], &decoded, &dt);
    try std.testing.expectEqual(@as(usize, 1), count);
    try std.testing.expectEqualStrings("hdr-0", decoded[0].name);
    try std.testing.expectEqualStrings("val-0", decoded[0].value);
}

test "decodeHeaderBlockWithDynamic: 0xff Required Insert Count prefix does not overrun" {
    // A header block whose Required Insert Count uses the 0xff escape advances
    // pos toward data.len; the Delta Base read must not index past the end.
    // Regression for an out-of-bounds read found by the QPACK dynamic-table
    // fuzz driver (index 5, len 5).
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    var decoded: [4]HeaderField = undefined;
    // [0xff escape][varint=1] -> Required Insert Count consumes the whole
    // block; the Delta Base read must not index past data.len.
    try std.testing.expectError(error.IncompleteString, decodeHeaderBlockWithDynamic(&[_]u8{ 0xff, 0x01 }, &decoded, &dt));
    // Escape with a truncated trailing varint (length guard rejects first).
    try std.testing.expectError(error.InvalidHeaderBlock, decodeHeaderBlockWithDynamic(&[_]u8{0xff}, &decoded, &dt));
}

test "encoder insertion roundtrip: instructions fill decoder table" {
    // Encoder side: a fresh table, first request inserts fields.
    var enc_table = DynamicTable.init(std.testing.allocator);
    defer enc_table.deinit();
    enc_table.setCapacity(4096);

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":path", .value = "/index.html" },
        .{ .name = "x-custom", .value = "my-value" },
    };

    var block: [512]u8 = undefined;
    var instr: [512]u8 = undefined;
    const enc_res = try encodeHeaderBlockWithDynamicInserting(&block, &instr, &fields, &enc_table);
    const block_len = enc_res.header_block_len;
    const instr_len = enc_res.encoder_stream_len;
    // The peer has not acknowledged the insertions yet, so the first block must
    // not reference them (RFC 9204 §2.2.2).
    try std.testing.expectEqual(@as(u64, 0), enc_res.required_insert_count);
    // :method GET is an RFC 9204 static exact match; :path /index.html and
    // x-custom are not in the static table, so both are inserted.
    try std.testing.expectEqual(@as(usize, 2), enc_table.insert_count);

    // Decoder side: consume the encoder stream instructions, then the block.
    var dec_table = DynamicTable.init(std.testing.allocator);
    defer dec_table.deinit();
    dec_table.setCapacity(4096);
    _ = try decodeEncoderStreamInstructions(instr[0..instr_len], &dec_table);

    var decoded: [8]HeaderField = undefined;
    const count = try decodeHeaderBlockWithDynamic(block[0..block_len], &decoded, &dec_table);
    try std.testing.expectEqual(@as(usize, 3), count);
    try std.testing.expectEqualStrings(":method", decoded[0].name);
    try std.testing.expectEqualStrings("GET", decoded[0].value);
    try std.testing.expectEqualStrings("x-custom", decoded[2].name);
    try std.testing.expectEqualStrings("my-value", decoded[2].value);

    // Decoder confirms receipt of both insertions (Insert Count Increment).
    try enc_table.acknowledgeReceived(enc_table.insert_count);

    // Second request: all fields now exactly match the acknowledged dynamic
    // table, so the encoder emits dynamic indexes and no new insert instructions.
    const fields2 = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = ":path", .value = "/index.html" },
        .{ .name = "x-custom", .value = "my-value" },
    };
    var block2: [512]u8 = undefined;
    var instr2: [512]u8 = undefined;
    const enc_res2 = try encodeHeaderBlockWithDynamicInserting(&block2, &instr2, &fields2, &enc_table);
    const block2_len = enc_res2.header_block_len;
    try std.testing.expectEqual(@as(usize, 0), enc_res2.encoder_stream_len); // no instructions needed
    try std.testing.expectEqual(@as(u64, 2), enc_res2.required_insert_count);
    // Insert count unchanged (nothing new inserted).
    try std.testing.expectEqual(@as(usize, 2), enc_table.insert_count);

    var decoded2: [8]HeaderField = undefined;
    const count2 = try decodeHeaderBlockWithDynamic(block2[0..block2_len], &decoded2, &dec_table);
    try std.testing.expectEqual(@as(usize, 3), count2);
    try std.testing.expectEqualStrings(":method", decoded2[0].name);
    try std.testing.expectEqualStrings("GET", decoded2[0].value);
}

test "decodeEncoderStreamInstructions: applies insert/duplicate/set_capacity" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);

    // Insert literal "x-a"="1", then duplicate index 0, then set capacity.
    var buf: [128]u8 = undefined;
    var pos: usize = 0;
    pos += try encodeEncoderInstruction(buf[pos..], .{ .insert_literal = .{ .name = "x-a", .value = "1" } });
    pos += try encodeEncoderInstruction(buf[pos..], .{ .duplicate = 0 });
    pos += try encodeEncoderInstruction(buf[pos..], .{ .set_capacity = 2048 });

    const consumed = try decodeEncoderStreamInstructions(buf[0..pos], &dt);
    try std.testing.expectEqual(pos, consumed);
    try std.testing.expectEqual(@as(usize, 2), dt.entries.items.len);
    try std.testing.expectEqual(@as(usize, 2048), dt.max_capacity);
    // Index 0 is a duplicate of the original "x-a"="1".
    const e0 = try dt.lookup(0);
    try std.testing.expectEqualStrings("x-a", e0.name);
    try std.testing.expectEqualStrings("1", e0.value);
}

test "decodeString decodes Huffman-encoded literal (interop path)" {
    // A QPACK string with H=1 (0x80 | 12) carrying the RFC 7541 Appendix C.1
    // Huffman encoding of "www.example.com". Peers like quic-go/quiche emit
    // H=1 literals, so this must decode.
    const encoded = [_]u8{ 0x8c, 0xf1, 0xe3, 0xc2, 0xe5, 0xf2, 0x3a, 0x6b, 0xa0, 0xab, 0x90, 0xf4, 0xff };
    const result = try decodeString(&encoded, 0);
    try std.testing.expectEqualStrings("www.example.com", result.value);
    try std.testing.expectEqual(@as(usize, 13), result.end);
}

test "encodeStringToBuf then decodeString roundtrip (incl. long string)" {
    for ([_][]const u8{ "GET", "x-custom-value", "this-is-a-very-long-header-value-that-exceeds-127-bytes-" ++ "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }) |s| {
        var buf: [512]u8 = undefined;
        var pos: usize = 0;
        pos = try encodeStringToBuf(&buf, pos, s);
        const result = try decodeString(buf[0..pos], 0);
        try std.testing.expectEqualStrings(s, result.value);
    }
}

test "encodeStringToBuf emits Huffman when smaller, roundtrips" {
    // 'a' repeated is very Huffman-compressible (3 bits each), so the encoder
    // must emit H=1 and the decoder must recover the original string.
    const s = "aaaaaaaaaa";
    var buf: [64]u8 = undefined;
    var pos: usize = 0;
    pos = try encodeStringToBuf(&buf, pos, s);
    // H bit set, length < 10.
    try std.testing.expect((buf[0] & 0x80) != 0);
    try std.testing.expect((buf[0] & 0x7f) < s.len);
    const result = try decodeString(buf[0..pos], 0);
    try std.testing.expectEqualStrings(s, result.value);
}
