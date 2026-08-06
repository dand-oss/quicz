//! QPACK header compression (RFC 9204) — minimal implementation.
//!
//! Implements the QPACK static table and basic header field
//! encoding/decoding for HTTP/3 header blocks.

const std = @import("std");

/// QPACK static table entry (RFC 9204 Appendix A).
pub const StaticEntry = struct {
    name: []const u8,
    value: []const u8,
};

/// QPACK static table (RFC 9204 Appendix A, all 99 entries).
pub const static_table = [_]StaticEntry{
    .{ .name = ":authority", .value = "" },
    .{ .name = ":path", .value = "/" },
    .{ .name = "age", .value = "0" },
    .{ .name = "content-disposition", .value = "" },
    .{ .name = "content-length", .value = "0" },
    .{ .name = "content-type", .value = "" },
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
    .{ .name = "cache-control", .value = "max-age=0" },
    .{ .name = "cache-control", .value = "max-age=2592000" },
    .{ .name = "cache-control", .value = "max-age=604800" },
    .{ .name = "cache-control", .value = "no-cache" },
    .{ .name = "cache-control", .value = "no-store" },
    .{ .name = "cache-control", .value = "no-transform" },
    .{ .name = "cache-control", .value = "only-if-cached" },
    .{ .name = "cache-control", .value = "private" },
    .{ .name = "cache-control", .value = "proxy-revalidate" },
    .{ .name = "cache-control", .value = "public" },
    .{ .name = "cache-control", .value = "s-maxage=0" },
    .{ .name = "cache-control", .value = "s-maxage=2592000" },
    .{ .name = "cache-control", .value = "s-maxage=604800" },
    .{ .name = "content-encoding", .value = "br" },
    .{ .name = "content-encoding", .value = "gzip" },
    .{ .name = "content-security-policy", .value = "script-src 'none'; object-src 'none'; base-uri 'none'" },
    .{ .name = "content-security-policy", .value = "script-src 'self'; object-src 'none'; base-uri 'none'" },
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
    .{ .name = "date", .value = "" },
    .{ .name = "etag", .value = "" },
    .{ .name = "expect-ct", .value = "" },
    .{ .name = "expires", .value = "" },
    .{ .name = "if-modified-since", .value = "" },
    .{ .name = "if-none-match", .value = "" },
    .{ .name = "last-modified", .value = "" },
    .{ .name = "link", .value = "" },
    .{ .name = "location", .value = "" },
    .{ .name = "referer", .value = "" },
    .{ .name = "set-cookie", .value = "" },
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
    .{ .name = ":status", .value = "405" },
    .{ .name = ":status", .value = "406" },
    .{ .name = ":status", .value = "408" },
    .{ .name = ":status", .value = "409" },
    .{ .name = ":status", .value = "410" },
    .{ .name = ":status", .value = "413" },
    .{ .name = ":status", .value = "414" },
    .{ .name = ":status", .value = "415" },
    .{ .name = ":status", .value = "416" },
    .{ .name = ":status", .value = "417" },
    .{ .name = ":status", .value = "418" },
    .{ .name = ":status", .value = "421" },
    .{ .name = ":status", .value = "425" },
    .{ .name = ":status", .value = "429" },
    .{ .name = ":status", .value = "500" },
    .{ .name = ":status", .value = "502" },
    .{ .name = ":status", .value = "504" },
    .{ .name = ":status", .value = "505" },
    .{ .name = ":status", .value = "506" },
    .{ .name = ":status", .value = "507" },
    .{ .name = ":status", .value = "508" },
    .{ .name = ":status", .value = "510" },
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
            // Literal without Name Reference: 001NXXXX
            out[pos] = 0x20;
            pos += 1;
            pos = try encodeStringToBuf(out, pos, field.name);
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

/// Encode a length-prefixed string into a buffer (no Huffman for simplicity).
fn encodeStringToBuf(out: []u8, pos: usize, s: []const u8) !usize {
    var p = pos;
    if (s.len < 128) {
        out[p] = @intCast(s.len);
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
    @memcpy(out[p .. p + s.len], s);
    p += s.len;
    return p;
}

test "QPACK static table lookup" {
    // :method GET = index 8
    try std.testing.expectEqual(@as(?u64, 8), findStaticIndex(":method", "GET"));
    // :status 200 = index 16
    try std.testing.expectEqual(@as(?u64, 16), findStaticIndex(":status", "200"));
    // :scheme https = index 14
    try std.testing.expectEqual(@as(?u64, 14), findStaticIndex(":scheme", "https"));
    // :path / = index 1
    try std.testing.expectEqual(@as(?u64, 1), findStaticIndex(":path", "/"));
    // Unknown
    try std.testing.expect(findStaticIndex("x-custom", "value") == null);
}

test "QPACK static name lookup" {
    try std.testing.expectEqual(@as(?u64, 6), findStaticNameIndex(":method"));
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
    // :method GET = 0xc0 | 8 = 0xc8
    try std.testing.expectEqual(@as(u8, 0xc8), encoded[2]);
    // :path / = 0xc0 | 1 = 0xc1
    try std.testing.expectEqual(@as(u8, 0xc1), encoded[3]);
    // :scheme https = 0xc0 | 14 = 0xce
    try std.testing.expectEqual(@as(u8, 0xce), encoded[4]);
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

    // Literal without name reference: 0x20
    try std.testing.expectEqual(@as(u8, 0x20), encoded[2]);
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
            // Literal without Name Reference: 001NXXXX
            pos += 1;
            const name_result = try decodeString(data, pos);
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

fn decodeString(data: []const u8, start: usize) !struct { value: []const u8, end: usize } {
    if (start >= data.len) return error.IncompleteString;
    const first = data[start];
    // No Huffman support: H bit (0x80) must be 0
    if (first & 0x80 != 0) return error.HuffmanNotSupported;
    const len: usize = first & 0x7f;
    const value_start = start + 1;
    if (value_start + len > data.len) return error.IncompleteString;
    return .{
        .value = data[value_start .. value_start + len],
        .end = value_start + len,
    };
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

    /// Insert a new entry at the front of the table.
    /// Evicts oldest entries if necessary to make room.
    pub fn insert(self: *DynamicTable, name: []const u8, value: []const u8) !void {
        const entry_size = name.len + value.len + dynamic_entry_overhead;

        // If the entry is larger than max_capacity, it cannot be added.
        // Clear the table per RFC 9204 §3.2.1 but do NOT increment insert_count.
        if (entry_size > self.max_capacity) {
            self.clearEntries();
            return;
        }

        // Evict until there's room
        while (self.current_size + entry_size > self.max_capacity and self.entries.items.len > 0) {
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
    }

    /// Duplicate an existing entry (RFC 9204 §4.3.4).
    /// The index is relative (0 = newest).
    pub fn duplicate(self: *DynamicTable, relative_index: u64) !void {
        const idx = try self.relativeToAbsolute(relative_index);
        const entry = self.entries.items[idx];
        try self.insert(entry.name, entry.value);
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

/// Encode a header block using dynamic table references when beneficial.
/// The dynamic table's insert_count is used as Required Insert Count.
/// Delta Base is always 0 (Base = Required Insert Count).
pub fn encodeHeaderBlockWithDynamic(
    out: []u8,
    fields: []const HeaderField,
    dynamic_table: *const DynamicTable,
) !usize {
    var pos: usize = 0;

    // Header block prefix (RFC 9204 §4.5.1)
    // Required Insert Count: 8-bit prefix
    const req_insert_count = dynamic_table.insert_count;
    if (req_insert_count == 0) {
        out[pos] = 0x00;
        pos += 1;
    } else {
        // Encode with 8-bit prefix varint
        if (req_insert_count < 255) {
            out[pos] = @intCast(req_insert_count);
            pos += 1;
        } else {
            out[pos] = 0xff;
            pos += 1;
            pos = encodeVarintToBuf(out, pos, req_insert_count - 255);
        }
    }

    // Delta Base: sign bit (0 = positive) + 7-bit prefix, value = 0
    out[pos] = 0x00;
    pos += 1;

    for (fields) |field| {
        // Try dynamic table exact match first (smallest encoding)
        if (dynamic_table.findExact(field.name, field.value)) |rel_idx| {
            // Indexed Field Line (dynamic): 1TXXXXXX, T=0
            // 0x80 | index with 6-bit prefix
            if (rel_idx < 63) {
                out[pos] = @intCast(0x80 | rel_idx);
                pos += 1;
            } else {
                out[pos] = 0xbf; // 0x80 | 0x3f
                pos += 1;
                pos = encodeVarintToBuf(out, pos, rel_idx - 63);
            }
        } else if (findStaticIndex(field.name, field.value)) |idx| {
            // Indexed Field Line (static): 1TXXXXXX, T=1
            if (idx < 63) {
                out[pos] = @intCast(0xc0 | idx);
                pos += 1;
            } else {
                out[pos] = 0xff;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, idx - 63);
            }
        } else if (dynamic_table.findName(field.name)) |rel_idx| {
            // Literal with Name Reference (dynamic): 01NTXXXX, T=0, N=0
            // 0x40 | index with 4-bit prefix
            if (rel_idx < 15) {
                out[pos] = @intCast(0x40 | rel_idx);
                pos += 1;
            } else {
                out[pos] = 0x4f; // 0x40 | 0x0f
                pos += 1;
                pos = encodeVarintToBuf(out, pos, rel_idx - 15);
            }
            pos = try encodeStringToBuf(out, pos, field.value);
        } else if (findStaticNameIndex(field.name)) |name_idx| {
            // Literal with Name Reference (static): 01NTXXXX, T=1, N=0
            if (name_idx < 15) {
                out[pos] = @intCast(0x50 | name_idx);
                pos += 1;
            } else {
                out[pos] = 0x5f;
                pos += 1;
                pos = encodeVarintToBuf(out, pos, name_idx - 15);
            }
            pos = try encodeStringToBuf(out, pos, field.value);
        } else {
            // Literal without Name Reference: 001NXXXX, N=0
            out[pos] = 0x20;
            pos += 1;
            pos = try encodeStringToBuf(out, pos, field.name);
            pos = try encodeStringToBuf(out, pos, field.value);
        }
    }

    return pos;
}

/// Decode a header block that may contain dynamic table references.
/// The dynamic table must be in the same state as when the block was encoded.
pub fn decodeHeaderBlockWithDynamic(
    data: []const u8,
    out_fields: []HeaderField,
    dynamic_table: *const DynamicTable,
) !usize {
    if (data.len < 2) return error.InvalidHeaderBlock;

    var pos: usize = 0;

    // Skip Required Insert Count (8-bit prefix varint)
    if (data[pos] == 0xff) {
        pos += 1;
        const v = try decodeVarintFromBuf(data, pos);
        pos = v.end;
    } else {
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
            // Literal without Name Reference: 001NXXXX
            pos += 1;
            const name_str = try decodeString(data, pos);
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

    return field_count;
}

// ---------------------------------------------------------------------------
// Dynamic header block tests
// ---------------------------------------------------------------------------

test "encodeHeaderBlockWithDynamic: dynamic exact match" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-custom", "my-value");

    const fields = [_]HeaderField{
        .{ .name = ":method", .value = "GET" },
        .{ .name = "x-custom", .value = "my-value" },
    };

    var encoded: [256]u8 = undefined;
    const len = try encodeHeaderBlockWithDynamic(&encoded, &fields, &dt);

    // Prefix: Required Insert Count = 1, Delta Base = 0
    try std.testing.expectEqual(@as(u8, 1), encoded[0]);
    try std.testing.expectEqual(@as(u8, 0), encoded[1]);
    // :method GET = static index 8: 0xc0 | 8 = 0xc8
    try std.testing.expectEqual(@as(u8, 0xc8), encoded[2]);
    // x-custom my-value = dynamic index 0: 0x80 | 0 = 0x80
    try std.testing.expectEqual(@as(u8, 0x80), encoded[3]);
    try std.testing.expectEqual(@as(usize, 4), len);
}

test "encodeHeaderBlockWithDynamic: dynamic name ref" {
    var dt = DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-token", "abc");

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
    // :method GET = static 8: 0xc8
    try std.testing.expectEqual(@as(u8, 0xc8), encoded[2]);
    // :status 200 = static 16: 0xd0
    try std.testing.expectEqual(@as(u8, 0xd0), encoded[3]);
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
