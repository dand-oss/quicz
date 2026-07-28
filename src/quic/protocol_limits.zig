/// Largest value encodable as a QUIC variable-length integer.
pub const max_quic_varint: u64 = (@as(u64, 1) << 62) - 1;

/// Largest valid QUIC stream count.
pub const max_stream_count: u64 = @as(u64, 1) << 60;

/// RFC 9000 connection IDs are encoded on at most 20 bytes.
pub const max_connection_id_len: usize = 20;

/// Client Initial packets must use at least an 8-byte destination connection ID.
pub const min_initial_destination_connection_id_len: usize = 8;

/// Client Initial UDP datagrams must be padded to at least 1200 bytes.
pub const min_initial_udp_datagram_len: usize = 1200;

/// QUIC endpoints must allow at least two active connection IDs.
pub const min_active_connection_id_limit: u64 = 2;

/// Closing and draining states last for three PTO periods.
pub const close_state_pto_multiplier: u64 = 3;

/// RFC path validation sends at most three PATH_CHALLENGE attempts here.
pub const max_path_challenge_transmissions: u8 = 3;

/// Packet-threshold loss marks packets three packet numbers behind.
pub const packet_threshold_loss_gap: u64 = 3;

/// Server anti-amplification budget is three times received bytes.
pub const anti_amplification_multiplier: usize = 3;

// ---------------------------------------------------------------------------
// Timing constants (RFC 9000 / RFC 9002)
// ---------------------------------------------------------------------------

const Duration = @import("../time/duration.zig").Duration;

/// RFC 9002 §6.2.2: Initial RTT estimate before any measurement.
/// "When no previous RTT is available, the initial RTT SHOULD be set to
/// 333 milliseconds."
pub const initial_rtt: Duration = Duration.fromMillis(333);

/// RFC 9000 §13.2.1: Default max_ack_delay transport parameter.
/// "If this transport parameter is absent, a value of 25 milliseconds
/// is assumed."
pub const default_max_ack_delay: Duration = Duration.fromMillis(25);

/// RFC 9002 §6.1.2: Timer granularity (kGranularity).
/// "The RECOMMENDED value of the timer granularity is 1 millisecond."
pub const timer_granularity: Duration = Duration.fromMillis(1);

/// Minimum trackable RTT: 1μs.
/// Prevents zero-RTT samples from collapsing the estimator on loopback.
pub const min_trackable_rtt: Duration = Duration.fromMicros(1);

/// RFC 9002 §7.6.1: Persistent congestion threshold multiplier.
/// "(smoothed_rtt + max(4*rttvar, kGranularity) + max_ack_delay) *
/// kPersistentCongestionThreshold"
pub const persistent_congestion_threshold: u64 = 3;

/// RFC 9002 §6.1.2: Time threshold numerator/denominator (9/8).
/// "max(kTimeThreshold * max(smoothed_rtt, latest_rtt), kGranularity)"
pub const time_threshold_numerator: u64 = 9;
pub const time_threshold_denominator: u64 = 8;
