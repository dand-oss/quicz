//! C ABI fuzz driver for OSS-Fuzz / libFuzzer.
//!
//! Exports a single C entry point that dispatches a byte blob to every fuzz
//! target in `src/quic/fuzz_targets.zig`, including the 1-RTT connection
//! state-machine driver. The first byte selects the target; the remainder is
//! the fuzz payload. This mirrors the `zttp_fuzz_drive` pattern so a single
//! fuzzer binary covers the parse layer *and* the interactive state machine.
//!
//! Build (see .oss-fuzz/build.sh) compiles this with the C ABI stub below and
//! links libFuzzer + ASan/UBSan via the OSS-Fuzz toolchain.

const std = @import("std");
const quicz = @import("quicz");
const fuzz_targets = quicz.fuzz_targets;

/// C ABI entry consumed by the fuzzer. `mode` selects the target:
///   0 = QUIC long header parse
///   1 = QUIC short header parse
///   2 = QUIC frame decode
///   3 = protected long packet peek
///   4 = H3 frame decode
///   5 = QPACK header block decode
///   6 = H3 request decode
///   7 = H3 response decode
///   8 = connection state-machine driver (handshake/transfer/stream/key-update)
///   9 = QPACK dynamic-table state machine (insert/duplicate/evict/lookup)
///   otherwise = drain through all targets.
pub export fn quicz_fuzz_drive(mode: c_uint, data: [*]const u8, size: usize) callconv(.c) void {
    const slice = data[0..size];
    switch (mode) {
        0 => fuzz_targets.fuzzParseLongHeader(slice),
        1 => fuzz_targets.fuzzParseShortHeader(slice),
        2 => fuzz_targets.fuzzDecodeFrame(slice),
        3 => fuzz_targets.fuzzPeekProtectedLong(slice),
        4 => fuzz_targets.fuzzDecodeH3Frame(slice),
        5 => fuzz_targets.fuzzDecodeQpack(slice),
        6 => fuzz_targets.fuzzDecodeH3Request(slice),
        7 => fuzz_targets.fuzzDecodeH3Response(slice),
        8 => fuzz_targets.fuzzDriveConnectionStateMachine(slice),
        9 => fuzz_targets.fuzzDriveQpackDynamicTable(slice),
        else => {
            fuzz_targets.fuzzParseLongHeader(slice);
            fuzz_targets.fuzzParseShortHeader(slice);
            fuzz_targets.fuzzDecodeFrame(slice);
            fuzz_targets.fuzzPeekProtectedLong(slice);
            fuzz_targets.fuzzDecodeH3Frame(slice);
            fuzz_targets.fuzzDecodeQpack(slice);
            fuzz_targets.fuzzDecodeH3Request(slice);
            fuzz_targets.fuzzDecodeH3Response(slice);
            fuzz_targets.fuzzDriveConnectionStateMachine(slice);
            fuzz_targets.fuzzDriveQpackDynamicTable(slice);
        },
    }
}
