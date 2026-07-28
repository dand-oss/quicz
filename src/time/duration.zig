//! Duration type with nanosecond precision.
//!
//!
//! Usage:
//!   const rtt = Duration.fromMillis(333);
//!   const delay = Duration.fromMicros(100);
//!   const timeout = Duration.fromSecs(30);

/// Time duration with nanosecond precision (u64 nanoseconds internally).
/// Nanosecond-precision duration for RTT, PTO, and timing calculations.
pub const Duration = struct {
    ns: u64,

    // -- Constructors --

    /// Create from nanoseconds.
    pub fn fromNanos(ns: u64) Duration {
        return .{ .ns = ns };
    }

    /// Create from microseconds (1μs = 1000ns).
    pub fn fromMicros(us: u64) Duration {
        return .{ .ns = us * 1_000 };
    }

    /// Create from milliseconds (1ms = 1_000_000ns).
    pub fn fromMillis(ms: u64) Duration {
        return .{ .ns = ms * 1_000_000 };
    }

    /// Create from seconds (1s = 1_000_000_000ns).
    pub fn fromSecs(s: u64) Duration {
        return .{ .ns = s * 1_000_000_000 };
    }

    // -- Conversions --

    /// Get value in nanoseconds.
    pub fn toNanos(self: Duration) u64 {
        return self.ns;
    }

    /// Get value in microseconds (truncated).
    pub fn toMicros(self: Duration) u64 {
        return self.ns / 1_000;
    }

    /// Get value in milliseconds (truncated).
    pub fn toMillis(self: Duration) u64 {
        return self.ns / 1_000_000;
    }

    /// Get value in seconds (truncated).
    pub fn toSecs(self: Duration) u64 {
        return self.ns / 1_000_000_000;
    }

    // -- Constants --

    /// Zero duration.
    pub const zero = Duration{ .ns = 0 };

    /// 1 microsecond.
    pub const one_micros = Duration{ .ns = 1_000 };

    /// 1 millisecond.
    pub const one_millis = Duration{ .ns = 1_000_000 };

    /// 1 second.
    pub const one_sec = Duration{ .ns = 1_000_000_000 };

    // -- Arithmetic --

    pub fn add(self: Duration, other: Duration) Duration {
        return .{ .ns = self.ns + other.ns };
    }

    pub fn sub(self: Duration, other: Duration) Duration {
        return .{ .ns = if (self.ns > other.ns) self.ns - other.ns else 0 };
    }

    pub fn mul(self: Duration, factor: u64) Duration {
        return .{ .ns = self.ns * factor };
    }

    pub fn div(self: Duration, divisor: u64) Duration {
        return .{ .ns = self.ns / divisor };
    }

    // -- Comparison --

    pub fn gt(self: Duration, other: Duration) bool {
        return self.ns > other.ns;
    }

    pub fn lt(self: Duration, other: Duration) bool {
        return self.ns < other.ns;
    }

    pub fn gte(self: Duration, other: Duration) bool {
        return self.ns >= other.ns;
    }

    pub fn lte(self: Duration, other: Duration) bool {
        return self.ns <= other.ns;
    }

    pub fn eql(self: Duration, other: Duration) bool {
        return self.ns == other.ns;
    }

    pub fn max(self: Duration, other: Duration) Duration {
        return if (self.ns >= other.ns) self else other;
    }

    pub fn min(self: Duration, other: Duration) Duration {
        return if (self.ns <= other.ns) self else other;
    }

    pub fn isZero(self: Duration) bool {
        return self.ns == 0;
    }
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

const std = @import("std");

test "Duration constructors and conversions" {
    const d = Duration.fromMillis(333);
    try std.testing.expectEqual(@as(u64, 333_000_000), d.toNanos());
    try std.testing.expectEqual(@as(u64, 333_000), d.toMicros());
    try std.testing.expectEqual(@as(u64, 333), d.toMillis());
    try std.testing.expectEqual(@as(u64, 0), d.toSecs());
}

test "Duration fromMicros (1μs MIN_RTT)" {
    const min_rtt = Duration.fromMicros(1);
    try std.testing.expectEqual(@as(u64, 1_000), min_rtt.toNanos());
}

test "Duration constants" {
    try std.testing.expectEqual(@as(u64, 1_000), Duration.one_micros.ns);
    try std.testing.expectEqual(@as(u64, 1_000_000), Duration.one_millis.ns);
    try std.testing.expectEqual(@as(u64, 1_000_000_000), Duration.one_sec.ns);
}

test "Duration arithmetic" {
    const a = Duration.fromMillis(100);
    const b = Duration.fromMillis(50);
    try std.testing.expectEqual(@as(u64, 150_000_000), a.add(b).ns);
    try std.testing.expectEqual(@as(u64, 50_000_000), a.sub(b).ns);
    try std.testing.expectEqual(@as(u64, 200_000_000), a.mul(2).ns);
    try std.testing.expectEqual(@as(u64, 50_000_000), a.div(2).ns);
}

test "Duration comparison" {
    const a = Duration.fromMillis(100);
    const b = Duration.fromMicros(50);
    try std.testing.expect(a.gt(b));
    try std.testing.expect(b.lt(a));
    try std.testing.expect(a.eql(Duration.fromNanos(100_000_000)));
    try std.testing.expect(Duration.zero.isZero());
}
