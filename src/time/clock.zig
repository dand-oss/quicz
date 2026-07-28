//! Cross-platform monotonic clock with nanosecond precision.
//! Reference: endel/quic-zig sys.nanoTimestamp(), s2n-quic Timestamp.
//!
//! Uses clock_gettime(CLOCK.MONOTONIC) on POSIX (Linux, macOS, iOS, FreeBSD...).
//! Windows support pending (QueryPerformanceCounter).

const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const timespec = extern struct {
    sec: isize,
    nsec: isize,
};

extern "c" fn clock_gettime(clk_id: c_int, tp: *timespec) c_int;

const CLOCK_MONOTONIC: c_int = switch (builtin.os.tag) {
    .macos, .ios, .watchos, .tvos, .visionos => 6,
    .linux => 1,
    .freebsd => 4,
    .netbsd => 3,
    .openbsd => 3,
    .dragonfly => 4,
    else => 1,
};

/// Monotonic clock timestamp in nanoseconds.
/// Returns 0 if the clock is unavailable (should never happen on supported platforms).
pub fn nanoTimestamp() u64 {
    switch (builtin.os.tag) {
        .linux, .macos, .ios, .watchos, .tvos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => {},
        .windows => {
            // Windows: QueryPerformanceCounter (TODO)
            return 0;
        },
        else => return 0,
    }
    var ts: timespec = undefined;
    const rc = clock_gettime(CLOCK_MONOTONIC, &ts);
    if (rc != 0) return 0;
    return @intCast(@as(i128, ts.sec) * std.time.ns_per_s + ts.nsec);
}

/// Compute elapsed nanoseconds between two timestamps.
pub fn elapsedNanos(start_ns: u64, end_ns: u64) u64 {
    if (end_ns <= start_ns) return 0;
    return end_ns - start_ns;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "nanoTimestamp returns non-zero on supported platforms" {
    const t1 = nanoTimestamp();
    // On supported platforms, should be non-zero
    if (builtin.os.tag == .linux or builtin.os.tag == .macos) {
        try std.testing.expect(t1 > 0);
    }
}

test "nanoTimestamp is monotonic" {
    const t1 = nanoTimestamp();
    const t2 = nanoTimestamp();
    try std.testing.expect(t2 >= t1);
}

test "elapsedNanos computes difference" {
    try std.testing.expectEqual(@as(u64, 100), elapsedNanos(50, 150));
    try std.testing.expectEqual(@as(u64, 0), elapsedNanos(150, 50)); // underflow → 0
}
