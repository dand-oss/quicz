//! HTTP/3 and QPACK resource limits (RFC 9114 §4.6, RFC 9204 §3.2).
//!
//! Centralizes protocol-mandated and implementation-defined limits
//! to prevent resource exhaustion and ensure robust error handling.

const std = @import("std");

/// Maximum number of header fields in a single header block.
/// RFC 9114 does not mandate a specific limit, but implementations
/// must protect against unbounded memory allocation.
pub const max_header_fields: usize = 128;

/// Maximum size of a single header block in bytes.
/// Prevents allocation of unbounded decode buffers.
pub const max_header_block_size: usize = 65536;

/// Maximum size of a single H3 frame payload.
/// Frames larger than this are rejected as protocol violations.
pub const max_frame_payload_size: usize = 16 * 1024 * 1024; // 16 MiB

/// Maximum dynamic table capacity (bytes).
/// RFC 9204 §3.2: encoder sets capacity, decoder may impose a lower limit.
pub const max_dynamic_table_capacity: usize = 65536;

/// Maximum number of entries in the dynamic table.
/// Derived from max_dynamic_table_capacity / minimum_entry_size (33 bytes).
pub const max_dynamic_table_entries: usize = 2048;

/// Maximum length of a single header name.
pub const max_header_name_len: usize = 256;

/// Maximum length of a single header value.
pub const max_header_value_len: usize = 8192;

/// Maximum number of concurrent request streams per connection.
pub const max_concurrent_streams: usize = 256;

/// Maximum number of settings parameters in a SETTINGS frame.
/// RFC 9114 §7.2.4.1: unknown settings are ignored, but we cap total count.
pub const max_settings_params: usize = 32;

/// Maximum Required Insert Count value we accept.
/// Prevents integer overflow in index calculations.
pub const max_required_insert_count: u64 = 1_000_000;

/// Validate a header field against limits.
/// Returns an error if the field violates any constraint.
pub fn validateHeaderField(name: []const u8, value: []const u8) !void {
    if (name.len == 0) return error.EmptyHeaderName;
    if (name.len > max_header_name_len) return error.HeaderNameTooLong;
    if (value.len > max_header_value_len) return error.HeaderValueTooLong;
    // Header names must be lowercase (RFC 9114 §4.2)
    for (name) |c| {
        if (c >= 'A' and c <= 'Z') return error.UppercaseHeaderName;
    }
}

/// Validate a frame payload size against limits.
pub fn validateFrameSize(payload_len: usize) !void {
    if (payload_len > max_frame_payload_size) return error.FrameTooLarge;
}

/// Validate dynamic table capacity against limits.
pub fn validateDynamicTableCapacity(capacity: usize) !void {
    if (capacity > max_dynamic_table_capacity) return error.DynamicTableTooLarge;
}

/// Validate settings parameter count.
pub fn validateSettingsCount(count: usize) !void {
    if (count > max_settings_params) return error.TooManySettings;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "validateHeaderField accepts valid fields" {
    try validateHeaderField(":method", "GET");
    try validateHeaderField("content-type", "application/json");
    try validateHeaderField("x-custom", "");
}

test "validateHeaderField rejects empty name" {
    try std.testing.expectError(error.EmptyHeaderName, validateHeaderField("", "value"));
}

test "validateHeaderField rejects uppercase name" {
    try std.testing.expectError(error.UppercaseHeaderName, validateHeaderField("Content-Type", "text/html"));
    try std.testing.expectError(error.UppercaseHeaderName, validateHeaderField("X-Custom", "val"));
}

test "validateHeaderField rejects oversized name" {
    var long_name: [300]u8 = undefined;
    @memset(&long_name, 'x');
    try std.testing.expectError(error.HeaderNameTooLong, validateHeaderField(&long_name, "val"));
}

test "validateHeaderField rejects oversized value" {
    var long_value: [9000]u8 = undefined;
    @memset(&long_value, 'v');
    try std.testing.expectError(error.HeaderValueTooLong, validateHeaderField("x-hdr", &long_value));
}

test "validateFrameSize accepts normal sizes" {
    try validateFrameSize(0);
    try validateFrameSize(1024);
    try validateFrameSize(max_frame_payload_size);
}

test "validateFrameSize rejects oversized" {
    try std.testing.expectError(error.FrameTooLarge, validateFrameSize(max_frame_payload_size + 1));
}

test "validateDynamicTableCapacity" {
    try validateDynamicTableCapacity(0);
    try validateDynamicTableCapacity(4096);
    try validateDynamicTableCapacity(max_dynamic_table_capacity);
    try std.testing.expectError(error.DynamicTableTooLarge, validateDynamicTableCapacity(max_dynamic_table_capacity + 1));
}

test "validateSettingsCount" {
    try validateSettingsCount(0);
    try validateSettingsCount(5);
    try validateSettingsCount(max_settings_params);
    try std.testing.expectError(error.TooManySettings, validateSettingsCount(max_settings_params + 1));
}

test "limits constants are sane" {
    try std.testing.expect(max_header_fields >= 64);
    try std.testing.expect(max_header_block_size >= 8192);
    try std.testing.expect(max_frame_payload_size >= 1024 * 1024);
    try std.testing.expect(max_dynamic_table_capacity >= 4096);
    try std.testing.expect(max_concurrent_streams >= 16);
    try std.testing.expect(max_required_insert_count >= 10000);
}
