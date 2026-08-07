//! Cross-platform monotonic clock with nanosecond precision.
//!
//! Uses `clock_gettime(CLOCK.MONOTONIC)` via the raw syscall on Linux (no libc
//! dependency) and `mach_absolute_time` on Darwin (libc is always linked there),
//! so the library builds on Linux without explicitly linking libc.
//! Windows support pending (QueryPerformanceCounter).

const std = @import("std");
const builtin = @import("builtin");

/// Monotonic clock timestamp in nanoseconds.
/// Returns 0 if the clock is unavailable (should never happen on supported platforms).
pub fn nanoTimestamp() u64 {
    switch (builtin.os.tag) {
        .linux => {
            var ts: std.os.linux.timespec = undefined;
            _ = std.os.linux.clock_gettime(.MONOTONIC, &ts);
            return @intCast(@as(i128, ts.sec) * std.time.ns_per_s + ts.nsec);
        },
        .macos, .ios, .watchos, .tvos, .visionos => {
            const MachTimebaseInfo = extern struct { numer: u32, denom: u32 };
            const mt = struct {
                extern fn mach_timebase_info(info: *MachTimebaseInfo) i32;
                extern fn mach_absolute_time() u64;
                var tb: MachTimebaseInfo = undefined;
                var inited: bool = false;
            };
            if (!mt.inited) {
                _ = mt.mach_timebase_info(&mt.tb);
                mt.inited = true;
            }
            return mt.mach_absolute_time() * mt.tb.numer / mt.tb.denom;
        },
        .freebsd, .netbsd, .openbsd, .dragonfly => {
            var ts: std.posix.timespec = undefined;
            _ = std.c.clock_gettime(1, @ptrCast(&ts));
            return @intCast(@as(i128, ts.sec) * std.time.ns_per_s + ts.nsec);
        },
        else => return 0,
    }
}

/// Compute elapsed nanoseconds between two timestamps.
pub fn elapsed(start_ns: u64, end_ns: u64) u64 {
    if (end_ns <= start_ns) return 0;
    return end_ns - start_ns;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "nanoTimestamp returns non-zero on supported platforms" {
    const t1 = nanoTimestamp();
    if (builtin.os.tag == .linux or builtin.os.tag == .macos) {
        try std.testing.expect(t1 > 0);
    }
}

test "nanoTimestamp is monotonic" {
    const t1 = nanoTimestamp();
    const t2 = nanoTimestamp();
    try std.testing.expect(t2 >= t1);
}

test "elapsed computes difference" {
    try std.testing.expectEqual(@as(u64, 100), elapsed(50, 150));
    try std.testing.expectEqual(@as(u64, 0), elapsed(150, 50)); // underflow → 0
}
