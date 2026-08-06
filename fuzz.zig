//! Fuzz harness for QUIC frame codec, packet parser, and transport parameters.
//!
//! Run with: zig build run-fuzz
//! Or standalone: zig build-exe fuzz.zig && ./fuzz

const std = @import("std");
const quicz = @import("quicz");
const frame = quicz.frame;
const packet = quicz.packet;
const buffer = quicz.buffer;

/// Fuzz target: decode arbitrary bytes as a QUIC frame.
pub fn fuzzFrameDecode(data: []const u8) void {
    if (data.len == 0) return;
    var decoded = frame.decodeFrameSlice(data, std.heap.page_allocator) catch return;
    frame.deinitFrame(&decoded.frame, std.heap.page_allocator);
}

/// Fuzz target: parse arbitrary bytes as a QUIC long header.
pub fn fuzzLongHeaderParse(data: []const u8) void {
    if (data.len == 0) return;
    var reader = buffer.fixedReader(data);
    _ = packet.parseLongHeader(reader.reader(), std.heap.page_allocator) catch return;
}

/// Fuzz target: parse arbitrary bytes as a QUIC varint.
pub fn fuzzVarintDecode(data: []const u8) void {
    if (data.len == 0) return;
    var reader = buffer.fixedReader(data);
    _ = packet.decodeVarInt(reader.reader()) catch return;
}

/// Simple coverage-guided fuzz loop for testing.
///
/// Iteration count is configurable so large reproducible sweeps are possible:
///   zig build run-fuzz -- 1000000
pub fn main(init: std.process.Init) !void {
    var args_iter = std.process.Args.Iterator.init(init.minimal.args);
    _ = args_iter.next(); // program name
    const iterations: usize = if (args_iter.next()) |arg|
        (std.fmt.parseInt(usize, arg, 10) catch 100_000)
    else
        100_000;

    var prng = std.Random.DefaultPrng.init(42);
    const random = prng.random();

    var buf: [4096]u8 = undefined;
    var i: usize = 0;

    while (i < iterations) : (i += 1) {
        const len = random.intRangeAtMost(usize, 1, buf.len);
        random.bytes(buf[0..len]);

        fuzzFrameDecode(buf[0..len]);
        fuzzLongHeaderParse(buf[0..len]);
        fuzzVarintDecode(buf[0..len]);
        quicz.fuzz_targets.fuzzDriveConnectionStateMachine(buf[0..len]);
        quicz.fuzz_targets.fuzzDriveQpackDynamicTable(buf[0..len]);
        quicz.fuzz_targets.fuzzDecodeWebTransport(buf[0..len]);
        quicz.fuzz_targets.fuzzDriveH3Connection(buf[0..len]);

        if (i % 10_000 == 0) {
            std.debug.print("fuzz progress: {d}/{d}\n", .{ i, iterations });
        }
    }

    std.debug.print("fuzz complete: {d} iterations, no crashes\n", .{iterations});
}

test "fuzz frame decode with random data does not crash" {
    var prng = std.Random.DefaultPrng.init(123);
    const random = prng.random();
    var buf: [512]u8 = undefined;

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const len = random.intRangeAtMost(usize, 1, buf.len);
        random.bytes(buf[0..len]);
        fuzzFrameDecode(buf[0..len]);
    }
}

test "fuzz long header parse with random data does not crash" {
    var prng = std.Random.DefaultPrng.init(456);
    const random = prng.random();
    var buf: [512]u8 = undefined;

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const len = random.intRangeAtMost(usize, 1, buf.len);
        random.bytes(buf[0..len]);
        fuzzLongHeaderParse(buf[0..len]);
    }
}

test "fuzz varint decode with random data does not crash" {
    var prng = std.Random.DefaultPrng.init(789);
    const random = prng.random();
    var buf: [64]u8 = undefined;

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const len = random.intRangeAtMost(usize, 1, buf.len);
        random.bytes(buf[0..len]);
        fuzzVarintDecode(buf[0..len]);
    }
}
