const std = @import("std");

/// HyStart++ — Hybrid Slow Start for high-bandwidth, long-distance networks.
///
/// Monitors RTT increases during slow start to exit early and avoid
/// overshooting the available bandwidth. Constants follow the IETF
/// draft-ietf-tcpm-hystartplusplus recommendations and the Linux
/// tcp_cubic.c implementation.
///
/// Two modes:
/// - Classic HyStart: exits slow start immediately when delay increase
///   exceeds threshold and cwnd >= LOW_SSTHRESH.
/// - HyStart++ (default): enters a Conservative Slow Start (CSS) phase
///   with reduced growth (÷4) for up to CSS_ROUNDS before exiting.

// ── Constants ──────────────────────────────────────────────────────────

/// Minimum slow start threshold in multiples of max_datagram_size.
/// "hystart_low_window" in tcp_cubic.c.
const LOW_SSTHRESH: f32 = 16.0;

/// RTT divisor for delay threshold: RttThresh = lastRoundMinRTT / 8.
const THRESHOLD_DIVIDEND: u32 = 8;

/// Number of RTT samples per round before checking delay increase.
/// "HYSTART_MIN_SAMPLES" in tcp_cubic.c.
const N_SAMPLING: usize = 8;

/// Minimum delay increase to consider (4 ms in ns).
const MIN_DELAY_THRESHOLD_NS: u64 = 4_000_000;

/// Maximum delay increase to consider (16 ms in ns).
const MAX_DELAY_THRESHOLD_NS: u64 = 16_000_000;

/// Growth divisor during CSS phase.
const CSS_GROWTH_DIVISOR: f32 = 4.0;

/// Maximum CSS rounds before exiting slow start.
const CSS_ROUNDS: usize = 5;

// ── State ──────────────────────────────────────────────────────────────

pub const HybridSlowStart = struct {
    sample_count: usize = 0,
    last_min_rtt_ns: ?u64 = null,
    cur_min_rtt_ns: ?u64 = null,
    /// Slow start exit threshold (bytes). f32 max = not yet determined.
    threshold: f32 = std.math.floatMax(f32),
    max_datagram_size: u16,
    /// Timestamp (millis) marking the end of the current RTT round.
    rtt_round_end_time: ?i64 = null,
    /// Use HyStart++ CSS phase (true) or classic HyStart (false).
    use_hystart_plus_plus: bool = true,
    /// Slow start cwnd growth divisor (1.0 normal, 4.0 in CSS).
    ss_growth_divisor: f32 = 1.0,
    /// Number of CSS rounds completed.
    css_count: usize = 0,
    /// Baseline min RTT when CSS was entered.
    css_baseline_min_rtt_ns: u64 = 0,
    /// cwnd at which CSS was entered (f32 max = not in CSS).
    css_threshold: f32 = std.math.floatMax(f32),

    pub fn init(max_datagram_size: u16) HybridSlowStart {
        return .{ .max_datagram_size = max_datagram_size };
    }

    /// True once a slow start threshold has been determined.
    pub fn thresholdFound(self: HybridSlowStart) bool {
        return self.threshold < std.math.floatMax(f32);
    }

    /// Called each time the RTT estimate is updated during slow start.
    ///
    /// Parameters:
    /// - `congestion_window`: current cwnd in bytes
    /// - `time_sent_nanos`: send time of the ACKed packet
    /// - `last_sent_time_nanos`: send time of the most recently sent packet
    /// - `rtt_ns`: measured RTT in nanoseconds
    pub fn onRttUpdate(
        self: *HybridSlowStart,
        congestion_window: f32,
        time_sent_nanos: i64,
        last_sent_time_nanos: i64,
        rtt_ns: u64,
    ) void {
        const ss_found = self.thresholdFound();
        // Stop sampling once cwnd reaches threshold, or permanently after
        // first threshold in HyStart++ mode (use traditional SS thereafter).
        if (congestion_window >= self.threshold or (self.use_hystart_plus_plus and ss_found)) {
            return;
        }

        // An RTT round ends when a packet sent after the round-start packet
        // is acknowledged.
        const round_over = if (self.rtt_round_end_time) |end_time|
            time_sent_nanos >= end_time
        else
            true;

        if (round_over) {
            self.last_min_rtt_ns = self.cur_min_rtt_ns;
            self.cur_min_rtt_ns = null;
            self.sample_count = 0;
            self.rtt_round_end_time = last_sent_time_nanos;
        }

        if (self.sample_count < N_SAMPLING) {
            const cur = self.cur_min_rtt_ns orelse rtt_ns;
            self.cur_min_rtt_ns = @min(rtt_ns, cur);
        }
        self.sample_count += 1;

        // Need exactly N_SAMPLING samples and at least 2 rounds to compare.
        if (self.sample_count != N_SAMPLING) return;
        const last_min = self.last_min_rtt_ns orelse return;
        const cur_min = self.cur_min_rtt_ns orelse return;

        if (congestion_window >= self.css_threshold) {
            // ── CSS phase: count rounds, check for recovery ──
            self.css_count += 1;
            if (cur_min < self.css_baseline_min_rtt_ns) {
                // RTT dropped — resume normal slow start
                self.css_threshold = self.threshold;
                self.ss_growth_divisor = 1.0;
                self.css_count = 0;
            }
            if (self.css_count >= CSS_ROUNDS) {
                // Exit slow start
                self.threshold = congestion_window;
                self.css_threshold = std.math.floatMax(f32);
                self.ss_growth_divisor = 1.0;
            }
        } else {
            // ── Detection phase ──
            var delay_threshold = last_min / THRESHOLD_DIVIDEND;
            delay_threshold = @min(delay_threshold, MAX_DELAY_THRESHOLD_NS);
            delay_threshold = @max(delay_threshold, MIN_DELAY_THRESHOLD_NS);

            const delay_over = cur_min >= last_min + delay_threshold;
            const cwnd_above_min = congestion_window >= self.lowSsthresh();

            if (self.use_hystart_plus_plus) {
                if (delay_over) {
                    // Enter CSS phase
                    self.css_threshold = congestion_window;
                    self.css_baseline_min_rtt_ns = cur_min;
                    self.ss_growth_divisor = CSS_GROWTH_DIVISOR;
                    self.css_count = 0;
                }
            } else if (delay_over and cwnd_above_min) {
                self.threshold = congestion_window;
            }
        }
    }

    /// Congestion window increment during slow start.
    ///
    /// In normal slow start this equals `sent_bytes` (doubling per RTT).
    /// In CSS phase it is divided by CSS_GROWTH_DIVISOR.
    pub fn cwndIncrement(self: HybridSlowStart, sent_bytes: usize) f32 {
        return @as(f32, @floatFromInt(sent_bytes)) / self.ss_growth_divisor;
    }

    /// Called on congestion event. Clamps threshold to min(current, ssthresh)
    /// but not below LOW_SSTHRESH * max_datagram_size.
    pub fn onCongestionEvent(self: *HybridSlowStart, ssthresh: f32) void {
        self.threshold = @max(@min(self.threshold, ssthresh), self.lowSsthresh());
        self.ss_growth_divisor = 1.0;
        self.css_threshold = std.math.floatMax(f32);
    }

    fn lowSsthresh(self: HybridSlowStart) f32 {
        return LOW_SSTHRESH * @as(f32, @floatFromInt(self.max_datagram_size));
    }
};

// ── Tests ──────────────────────────────────────────────────────────────

test "initial state has no threshold" {
    const hss = HybridSlowStart.init(1200);
    try std.testing.expect(!hss.thresholdFound());
    try std.testing.expectEqual(@as(f32, 1.0), hss.ss_growth_divisor);
}

test "cwnd increment normal vs CSS" {
    var hss = HybridSlowStart.init(1200);
    try std.testing.expectEqual(@as(f32, 1200.0), hss.cwndIncrement(1200));

    hss.ss_growth_divisor = CSS_GROWTH_DIVISOR;
    try std.testing.expectEqual(@as(f32, 300.0), hss.cwndIncrement(1200));
}

test "onCongestionEvent clamps threshold" {
    var hss = HybridSlowStart.init(1200);
    // low_ssthresh = 16 * 1200 = 19200
    hss.onCongestionEvent(50000);
    try std.testing.expectEqual(@as(f32, 50000.0), hss.threshold);

    // Lower event keeps existing threshold
    hss.onCongestionEvent(60000);
    try std.testing.expectEqual(@as(f32, 50000.0), hss.threshold);

    // Very low event clamps to low_ssthresh
    hss.onCongestionEvent(100);
    try std.testing.expectEqual(@as(f32, 19200.0), hss.threshold);
}

test "classic hystart exits on delay increase above low window" {
    var hss = HybridSlowStart.init(1200);
    hss.use_hystart_plus_plus = false;
    const cwnd: f32 = 20 * 1200; // 24000 > low_ssthresh(19200)

    // Round 1: min RTT = 10ms
    var i: usize = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, @intCast(i), 100, 10_000_000);
    }
    try std.testing.expect(!hss.thresholdFound());

    // Round 2: min RTT = 20ms (increase > threshold)
    // threshold = clamp(10ms/8, 4ms, 16ms) = 4ms
    // 20ms >= 10ms + 4ms → true
    i = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, 101 + @as(i64, @intCast(i)), 200, 20_000_000);
    }
    try std.testing.expect(hss.thresholdFound());
    try std.testing.expectEqual(cwnd, hss.threshold);
}

test "hystart++ enters CSS then exits after CSS_ROUNDS" {
    var hss = HybridSlowStart.init(1200);
    hss.use_hystart_plus_plus = true;
    const cwnd: f32 = 20 * 1200;

    // Round 1: min RTT = 10ms
    var i: usize = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, @intCast(i), 100, 10_000_000);
    }

    // Round 2: min RTT = 20ms → enters CSS
    i = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, 101 + @as(i64, @intCast(i)), 200, 20_000_000);
    }
    try std.testing.expectEqual(CSS_GROWTH_DIVISOR, hss.ss_growth_divisor);
    try std.testing.expect(!hss.thresholdFound()); // CSS, not exited yet

    // CSS rounds: each round needs time_sent >= previous rtt_round_end_time
    // and increasing last_sent_time so subsequent rounds start properly.
    var round: usize = 0;
    while (round < CSS_ROUNDS) : (round += 1) {
        const base_time: i64 = 201 + @as(i64, @intCast(round * 100));
        const last_sent: i64 = base_time + 99;
        i = 0;
        while (i < N_SAMPLING) : (i += 1) {
            hss.onRttUpdate(cwnd, base_time + @as(i64, @intCast(i)), last_sent, 20_000_000);
        }
    }
    try std.testing.expect(hss.thresholdFound());
    try std.testing.expectEqual(cwnd, hss.threshold);
    try std.testing.expectEqual(@as(f32, 1.0), hss.ss_growth_divisor);
}

test "hystart++ CSS resumes slow start on RTT drop" {
    var hss = HybridSlowStart.init(1200);
    hss.use_hystart_plus_plus = true;
    const cwnd: f32 = 20 * 1200;

    // Round 1: 10ms, Round 2: 20ms → CSS
    var i: usize = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, @intCast(i), 100, 10_000_000);
    }
    i = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, 101 + @as(i64, @intCast(i)), 200, 20_000_000);
    }
    try std.testing.expectEqual(CSS_GROWTH_DIVISOR, hss.ss_growth_divisor);

    // Next round: RTT drops below baseline → resume normal SS
    i = 0;
    while (i < N_SAMPLING) : (i += 1) {
        hss.onRttUpdate(cwnd, 201 + @as(i64, @intCast(i)), 300, 5_000_000);
    }
    try std.testing.expectEqual(@as(f32, 1.0), hss.ss_growth_divisor);
    try std.testing.expectEqual(@as(usize, 0), hss.css_count);
}
