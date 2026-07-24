//! Fuzz targets for QUIC packet/frame/QPACK parsing.
//!
//! These functions are designed to be called by a fuzzer with arbitrary
//! byte inputs. They must not crash on any input.

const std = @import("std");
const packet = @import("packet.zig");
const frame = @import("frame.zig");
const protection = @import("protection.zig");
const h3_frame = @import("../h3/frame.zig");
const qpack = @import("../h3/qpack.zig");
const h3_request = @import("../h3/request.zig");
const buffer = @import("buffer.zig");

/// Fuzz target: parse a QUIC long header from arbitrary bytes.
pub fn fuzzParseLongHeader(data: []const u8) void {
    var reader = buffer.fixedReader(data);
    _ = packet.parseLongHeader(reader.reader(), std.heap.page_allocator) catch return;
}

/// Fuzz target: parse a QUIC short header from arbitrary bytes.
pub fn fuzzParseShortHeader(data: []const u8) void {
    for ([_]usize{ 4, 8, 16, 20 }) |dcid_len| {
        var reader = buffer.fixedReader(data);
        _ = packet.parseShortHeader(reader.reader(), std.heap.page_allocator, dcid_len) catch continue;
    }
}

/// Fuzz target: decode a QUIC frame from arbitrary bytes.
pub fn fuzzDecodeFrame(data: []const u8) void {
    _ = frame.decodeFrameSlice(data, std.heap.page_allocator) catch return;
}

/// Fuzz target: peek at a protected long packet from arbitrary bytes.
pub fn fuzzPeekProtectedLong(data: []const u8) void {
    _ = protection.peekProtectedLongPacketInfo(data) catch return;
}

/// Fuzz target: decode an HTTP/3 frame from arbitrary bytes.
pub fn fuzzDecodeH3Frame(data: []const u8) void {
    _ = h3_frame.decodeFrame(data) catch return;
}

/// Fuzz target: decode a QPACK header block from arbitrary bytes.
pub fn fuzzDecodeQpack(data: []const u8) void {
    var fields: [64]qpack.HeaderField = undefined;
    _ = qpack.decodeHeaderBlock(data, &fields) catch return;
}

/// Fuzz target: decode an HTTP/3 request from arbitrary bytes.
pub fn fuzzDecodeH3Request(data: []const u8) void {
    _ = h3_request.decodeRequest(data) catch return;
}

/// Fuzz target: decode an HTTP/3 response from arbitrary bytes.
pub fn fuzzDecodeH3Response(data: []const u8) void {
    _ = h3_request.decodeResponse(data) catch return;
}

// ── Unit tests for fuzz targets ──

test "fuzz targets handle empty input" {
    fuzzParseLongHeader(&.{});
    fuzzParseShortHeader(&.{});
    fuzzPeekProtectedLong(&.{});
    fuzzDecodeH3Frame(&.{});
    fuzzDecodeQpack(&.{});
    fuzzDecodeH3Request(&.{});
    fuzzDecodeH3Response(&.{});
}

test "fuzz targets handle garbage input" {
    const garbage = [_]u8{ 0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8, 0xf7, 0xf6, 0xf5, 0xf4, 0xf3, 0xf2, 0xf1, 0xf0 };
    fuzzParseLongHeader(&garbage);
    fuzzParseShortHeader(&garbage);
    fuzzPeekProtectedLong(&garbage);
    fuzzDecodeH3Frame(&garbage);
    fuzzDecodeQpack(&garbage);
    fuzzDecodeH3Request(&garbage);
    fuzzDecodeH3Response(&garbage);
}

test "fuzz targets handle truncated valid-looking input" {
    const truncated_long = [_]u8{ 0xC0, 0x00, 0x00, 0x00, 0x01 };
    fuzzParseLongHeader(&truncated_long);
    fuzzPeekProtectedLong(&truncated_long);

    const truncated_h3 = [_]u8{ 0x00, 0x64 };
    fuzzDecodeH3Frame(&truncated_h3);

    const truncated_qpack = [_]u8{ 0x00, 0x00, 0xC8 };
    fuzzDecodeQpack(&truncated_qpack);
}

test "fuzz targets handle maximum varint values" {
    const max_varint = [_]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
    fuzzParseLongHeader(&max_varint);
    fuzzDecodeH3Frame(&max_varint);
    fuzzDecodeQpack(&max_varint);
}
