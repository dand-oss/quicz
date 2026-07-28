# Production Tuning Guide

Updated: 2026-07-28.

This document covers recommended configuration for deploying quicz in
production environments. All parameters are set via `ConnectionConfig`
(`src/quic/connection_config.zig`).

## Quick Reference

| Parameter | Default | Recommended (production) | Notes |
| --- | --- | --- | --- |
| `pto_jitter_percentage` | 0 | 20–30 | Prevents synchronized PTO timeouts across many concurrent connections. Range 0–50. Default 0 matches upstream QUIC stacks; enable for servers with 100+ concurrent connections. |
| `congestion_algorithm` | `.new_reno` | `.cubic` | CUBIC (RFC 9438) with HyStart++ provides better throughput on high-BDP paths. |
| `initial_rtt_ns` | 333 ms | Per-environment | Data center: 1–5 ms; WAN: 50–100 ms. Lower values speed up initial window growth. |
| `max_ack_delay_ns` | 25 ms | 25 ms | RFC 9000 default; do not change unless peer negotiates differently. |

## PTO Jitter

PTO jitter adds ±percentage random variation to the base Probe Timeout before
exponential backoff. This decorrelates timeout storms when many connections
share a path (e.g., behind a NAT or load balancer).

- **0% (default):** Deterministic PTO. Suitable for single connections, tests,
  and environments where timeout synchronization is not a concern.
- **20–30% (recommended for servers):** Sufficient to break synchronization
  without meaningfully delaying loss recovery.
- **50% (maximum):** Aggressive jitter; may delay loss recovery on lossy paths.

The result is always clamped to the RFC 9002 kGranularity floor (1 ms).

### Example

```zig
var conn = try Connection.init(allocator, .server, .{
    .congestion_algorithm = .cubic,
    .pto_jitter_percentage = 25,
    .initial_rtt_ns = 5_000_000, // 5ms for data center
});
```

## Congestion Control

### CUBIC + HyStart++ (recommended)

CUBIC (RFC 9438) is the default congestion control in most production QUIC
stacks. quicz implements CUBIC with:

- **HyStart++ slow start:** Monitors RTT increases to exit slow start early,
  avoiding bandwidth overshoot. Uses Conservative Slow Start (CSS) with
  ÷4 growth for up to 5 rounds before full exit.
- **Fast retransmission:** Immediate retransmit on congestion event without
  waiting for PTO.
- **App-limited detection (RFC 8312 §5.8):** Excludes application-limited
  periods from CUBIC epoch calculation. Uses 3×MTU threshold to avoid
  false positives on loopback.
- **PTO jitter:** Optional randomized PTO to decorrelate timeout storms.

### NewReno

NewReno (RFC 9002) is the default algorithm. Simpler but less efficient on
high-bandwidth, high-latency paths. Suitable for low-throughput control
channels or environments where CUBIC tuning is not needed.

### BBR

BBR is available but not yet production-hardened. Use CUBIC for production.

## Initial RTT

The `initial_rtt_ns` parameter sets the RTT estimate before any measurement.
RFC 9002 defaults to 333 ms. Tuning this for your environment speeds up
initial window growth:

| Environment | Recommended `initial_rtt_ns` |
| --- | --- |
| Data center (same rack) | 100_000–500_000 (0.1–0.5 ms) |
| Data center (cross-rack) | 1_000_000–5_000_000 (1–5 ms) |
| Metro / CDN edge | 10_000_000–30_000_000 (10–30 ms) |
| WAN / intercontinental | 50_000_000–150_000_000 (50–150 ms) |
| Unknown / public internet | 333_000_000 (333 ms, default) |

## Related Documents

- [Feature Comparison](feature_comparison.md) — capability matrix vs other QUIC stacks
- [Benchmark](benchmark.md) — throughput and latency numbers
- [Architecture](architecture.md) — module layout and design decisions
