//! Fuzz-resistant tests for H3/QPACK parsing.
//!
//! Verifies that malformed, truncated, and adversarial inputs
//! return errors rather than panicking or reading out of bounds.

const std = @import("std");
const qpack = @import("qpack.zig");
const h3_frame = @import("frame.zig");
const h3_request = @import("request.zig");
const h3_connection = @import("connection.zig");

// ---------------------------------------------------------------------------
// QPACK malformed input tests
// ---------------------------------------------------------------------------

test "fuzz: QPACK decode empty input" {
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.InvalidHeaderBlock, qpack.decodeHeaderBlock(&[_]u8{}, &fields));
    try std.testing.expectError(error.InvalidHeaderBlock, qpack.decodeHeaderBlock(&[_]u8{0x00}, &fields));
}

test "fuzz: QPACK decode truncated header block" {
    // Valid prefix but truncated field data
    const data = [_]u8{ 0x00, 0x00, 0x20, 0x05, 'h', 'e' }; // literal, name_len=5, but only 2 bytes
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.IncompleteString, qpack.decodeHeaderBlock(&data, &fields));
}

test "fuzz: QPACK decode invalid static index" {
    // Indexed field line with index 200 (beyond static table)
    const data = [_]u8{ 0x00, 0x00, 0xff, 0x89, 0x01 }; // 0xc0|0x3f=0xff, varint 137+63=200
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.InvalidStaticIndex, qpack.decodeHeaderBlock(&data, &fields));
}

test "fuzz: QPACK decode unsupported representation" {
    // Byte 0x10 is not a valid representation prefix
    const data = [_]u8{ 0x00, 0x00, 0x10 };
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.UnsupportedRepresentation, qpack.decodeHeaderBlock(&data, &fields));
}

test "fuzz: QPACK dynamic decode with empty table" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);

    // Dynamic indexed reference (0x80) but table is empty
    const data = [_]u8{ 0x01, 0x00, 0x80 };
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.InvalidDynamicIndex, qpack.decodeHeaderBlockWithDynamic(&data, &fields, &dt));
}

test "fuzz: QPACK dynamic decode out-of-bounds index" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);
    try dt.insert("x-a", "1"); // only 1 entry

    // Reference index 5 (only 0 exists)
    const data = [_]u8{ 0x01, 0x00, 0x85 }; // 0x80 | 5
    var fields: [8]qpack.HeaderField = undefined;
    try std.testing.expectError(error.InvalidDynamicIndex, qpack.decodeHeaderBlockWithDynamic(&data, &fields, &dt));
}

test "fuzz: QPACK encoder instruction empty input" {
    try std.testing.expectError(error.IncompleteString, qpack.decodeEncoderInstruction(&[_]u8{}));
}

test "fuzz: QPACK decoder instruction empty input" {
    try std.testing.expectError(error.IncompleteString, qpack.decodeDecoderInstruction(&[_]u8{}));
}

test "fuzz: QPACK encoder instruction truncated varint" {
    // Insert with name ref, static, index prefix all 1s but no continuation
    const data = [_]u8{ 0xff }; // 6-bit prefix all 1s, expects varint continuation
    try std.testing.expectError(error.IncompleteString, qpack.decodeEncoderInstruction(&data));
}

// ---------------------------------------------------------------------------
// H3 frame malformed input tests
// ---------------------------------------------------------------------------

test "fuzz: H3 frame decode empty input" {
    try std.testing.expectError(error.IncompleteFrame, h3_frame.decodeFrame(&[_]u8{}));
}

test "fuzz: H3 frame decode truncated type" {
    // 2-byte varint prefix but only 1 byte
    const data = [_]u8{0x40};
    try std.testing.expectError(error.IncompleteFrame, h3_frame.decodeFrame(&data));
}

test "fuzz: H3 frame decode truncated payload" {
    // type=0, len=100, but no payload bytes
    const data = [_]u8{ 0x00, 0x64 };
    try std.testing.expectError(error.IncompleteFrame, h3_frame.decodeFrame(&data));
}

test "fuzz: H3 frame decode partial payload" {
    // type=0, len=10, but only 3 payload bytes
    const data = [_]u8{ 0x00, 0x0a, 0x01, 0x02, 0x03 };
    try std.testing.expectError(error.IncompleteFrame, h3_frame.decodeFrame(&data));
}

// ---------------------------------------------------------------------------
// H3 request/response malformed input tests
// ---------------------------------------------------------------------------

test "fuzz: H3 request decode empty input" {
    try std.testing.expectError(error.IncompleteFrame, h3_request.decodeRequest(&[_]u8{}));
}

test "fuzz: H3 request decode wrong frame type" {
    // DATA frame (type=0) instead of HEADERS (type=1)
    const data = [_]u8{ 0x00, 0x02, 0x00, 0x00 };
    try std.testing.expectError(error.ExpectedHeadersFrame, h3_request.decodeRequest(&data));
}

test "fuzz: H3 response decode missing status" {
    // Valid HEADERS frame but QPACK block with no :status
    // Header block: RIC=0, DB=0, then :method GET (static 8)
    const data = [_]u8{ 0x01, 0x03, 0x00, 0x00, 0xc8 };
    try std.testing.expectError(error.MissingStatus, h3_request.decodeResponse(&data));
}

test "fuzz: H3 request decode missing method" {
    // Valid HEADERS frame but QPACK block with only :path
    const data = [_]u8{ 0x01, 0x03, 0x00, 0x00, 0xc1 }; // :path / = static 1
    try std.testing.expectError(error.MissingMethod, h3_request.decodeRequest(&data));
}

// ---------------------------------------------------------------------------
// Settings malformed input tests
// ---------------------------------------------------------------------------

test "fuzz: Settings decode empty payload" {
    const settings = try h3_connection.Settings.decodePayload(&[_]u8{});
    // Empty payload = all defaults
    try std.testing.expectEqual(@as(u64, 16384), settings.max_field_section_size);
}

test "fuzz: Settings decode truncated pair" {
    // Key byte present but no value
    const data = [_]u8{0x06};
    try std.testing.expectError(error.IncompleteFrame, h3_connection.Settings.decodePayload(&data));
}

test "fuzz: Settings decode truncated varint key" {
    // 2-byte varint prefix but only 1 byte
    const data = [_]u8{0x40};
    try std.testing.expectError(error.IncompleteFrame, h3_connection.Settings.decodePayload(&data));
}

// ---------------------------------------------------------------------------
// GOAWAY malformed input tests
// ---------------------------------------------------------------------------

test "fuzz: GOAWAY decode empty payload" {
    try std.testing.expectError(error.IncompleteFrame, h3_connection.H3Connection.decodeGoawayPayload(&[_]u8{}));
}

test "fuzz: GOAWAY decode truncated varint" {
    // 4-byte varint prefix but only 2 bytes
    const data = [_]u8{ 0x80, 0x01 };
    try std.testing.expectError(error.IncompleteFrame, h3_connection.H3Connection.decodeGoawayPayload(&data));
}

// ---------------------------------------------------------------------------
// Dynamic table edge cases
// ---------------------------------------------------------------------------

test "fuzz: DynamicTable zero capacity insert" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(0);

    // Insert should clear table (entry > capacity)
    try dt.insert(":method", "GET");
    try std.testing.expectEqual(@as(usize, 0), dt.entryCount());
}

test "fuzz: DynamicTable lookup on empty table" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    dt.setCapacity(4096);

    try std.testing.expectError(error.InvalidDynamicIndex, dt.lookup(0));
    try std.testing.expectError(error.InvalidDynamicIndex, dt.duplicate(0));
}

test "fuzz: DynamicTable rapid insert/evict cycle" {
    var dt = qpack.DynamicTable.init(std.testing.allocator);
    defer dt.deinit();
    // Very small capacity: only 1 entry fits at a time
    // ":a"(2) + "b"(1) + 32 = 35
    dt.setCapacity(35);

    var i: u64 = 0;
    while (i < 100) : (i += 1) {
        try dt.insert(":a", "b");
    }
    // Should never exceed 1 entry
    try std.testing.expectEqual(@as(usize, 1), dt.entryCount());
    try std.testing.expectEqual(@as(u64, 100), dt.insert_count);
}
