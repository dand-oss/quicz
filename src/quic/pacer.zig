//! Token bucket pacer (RFC 9002 §7.7, learned from industry implementations).
//!
//! Gates packet emission to spread transmission over time, preventing
//! burst-induced loss on low-RTT paths. Budget replenishes at
//! pacing_rate = congestion_window / smoothed_rtt × 1.25.
//! Max burst = 10 packets (allows initial window to send immediately).

const std = @import("std");

/// Maximum number of packets that can be sent in a single burst.
pub const max_burst_packets: usize = 10;

/// Token bucket pacer for QUIC packet transmission.
pub const Pacer = struct {
    /// Available send budget in bytes.
    budget: usize = 0,
    /// Timestamp (ms) of last packet send.
    last_sent_ms: ?i64 = null,
    /// Maximum datagram size in bytes.
    max_datagram_size: usize,

    pub fn init(max_datagram_size: usize) Pacer {
        var p = Pacer{
            .max_datagram_size = max_datagram_size,
        };
        p.budget = p.maxBurstSize();
        return p;
    }

    /// Maximum burst size in bytes (10 packets or 1ms worth of bandwidth).
    pub fn maxBurstSize(self: *const Pacer) usize {
        return max_burst_packets * self.max_datagram_size;
    }

    /// Calculate pacing rate in bytes/ms from cwnd and smoothed RTT.
    /// pacing_rate = cwnd / smoothed_rtt × 1.25 (25% overhead for RTT variation).
    pub fn pacingRateBytesPerMs(cwnd: usize, smoothed_rtt_ms: u64) usize {
        if (smoothed_rtt_ms == 0) return std.math.maxInt(usize); // no pacing at RTT=0
        // cwnd / rtt × 1.25 = cwnd × 5 / (rtt × 4)
        const rate = (@as(u128, cwnd) * 5) / (@as(u128, smoothed_rtt_ms) * 4);
        return @intCast(@min(rate, std.math.maxInt(usize)));
    }

    /// Get current send budget in bytes, replenished since last send.
    pub fn budgetAt(self: *const Pacer, now_ms: i64, cwnd: usize, smoothed_rtt_ms: u64) usize {
        // RTT=0 means no pacing (loopback): always allow full burst.
        if (smoothed_rtt_ms == 0) return self.maxBurstSize();
        const last = self.last_sent_ms orelse return self.maxBurstSize();
        const delta_ms: u64 = if (now_ms > last) @intCast(now_ms - last) else 0;
        if (delta_ms == 0) return self.budget;

        const rate = pacingRateBytesPerMs(cwnd, smoothed_rtt_ms);
        const added = rate * delta_ms;
        const new_budget = self.budget + added;
        return @min(self.maxBurstSize(), new_budget);
    }

    /// Check if a packet of the given size can be sent now.
    pub fn canSend(self: *const Pacer, now_ms: i64, packet_size: usize, cwnd: usize, smoothed_rtt_ms: u64) bool {
        return self.budgetAt(now_ms, cwnd, smoothed_rtt_ms) >= packet_size;
    }

    /// Record that a packet was sent, deducting from budget.
    pub fn onPacketSent(self: *Pacer, now_ms: i64, packet_size: usize, cwnd: usize, smoothed_rtt_ms: u64) void {
        const current_budget = self.budgetAt(now_ms, cwnd, smoothed_rtt_ms);
        self.budget = if (packet_size >= current_budget) 0 else current_budget - packet_size;
        self.last_sent_ms = now_ms;
    }

    /// Reset pacer state (e.g., after persistent congestion).
    pub fn reset(self: *Pacer) void {
        self.budget = self.maxBurstSize();
        self.last_sent_ms = null;
    }
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "pacer initial budget allows max burst" {
    var p = Pacer.init(1200);
    // Initial budget = 10 * 1200 = 12000
    try std.testing.expectEqual(@as(usize, 12000), p.budget);
    try std.testing.expect(p.canSend(0, 1200, 43200, 333));
}

test "pacer deducts budget on send" {
    var p = Pacer.init(1200);
    p.onPacketSent(0, 1200, 43200, 333);
    try std.testing.expectEqual(@as(usize, 10800), p.budget); // 12000 - 1200
}

test "pacer budget replenishes over time" {
    var p = Pacer.init(1200);
    // Drain budget
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        p.onPacketSent(0, 1200, 43200, 333);
    }
    try std.testing.expectEqual(@as(usize, 0), p.budget);

    // After 100ms with cwnd=43200, rtt=100ms:
    // rate = 43200 * 5 / (100 * 4) = 540 bytes/ms
    // added = 540 * 100 = 54000, capped at max_burst = 12000
    const budget = p.budgetAt(100, 43200, 100);
    try std.testing.expectEqual(@as(usize, 12000), budget); // capped at max burst
}

test "pacer blocks send when budget exhausted" {
    var p = Pacer.init(1200);
    // Drain all budget at time 0
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        p.onPacketSent(0, 1200, 43200, 333);
    }
    // At time 0, no replenishment, can't send
    try std.testing.expect(!p.canSend(0, 1200, 43200, 333));
    // At time 1ms, rate=540 bytes/ms, budget=540 < 1200, still can't
    try std.testing.expect(!p.canSend(1, 1200, 43200, 100));
    // At time 3ms, budget=1620 >= 1200, can send
    try std.testing.expect(p.canSend(3, 1200, 43200, 100));
}

test "pacer zero RTT means no pacing" {
    var p = Pacer.init(1200);
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        p.onPacketSent(0, 1200, 43200, 0);
    }
    // With RTT=0, pacingRate = maxInt, budget replenishes instantly
    try std.testing.expect(p.canSend(0, 1200, 43200, 0));
}

test "pacer reset restores full burst" {
    var p = Pacer.init(1200);
    p.onPacketSent(0, 1200, 43200, 333);
    p.reset();
    try std.testing.expectEqual(@as(usize, 12000), p.budget);
    try std.testing.expect(p.last_sent_ms == null);
}

test "pacing rate calculation" {
    // cwnd=43200, rtt=100ms: rate = 43200*5/(100*4) = 540 bytes/ms
    try std.testing.expectEqual(@as(usize, 540), Pacer.pacingRateBytesPerMs(43200, 100));
    // cwnd=12000, rtt=333ms: rate = 12000*5/(333*4) = 45 bytes/ms
    try std.testing.expectEqual(@as(usize, 45), Pacer.pacingRateBytesPerMs(12000, 333));
    // rtt=0: no pacing
    try std.testing.expectEqual(std.math.maxInt(usize), Pacer.pacingRateBytesPerMs(43200, 0));
}
