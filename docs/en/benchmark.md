# quicz Performance Benchmark

## Methodology

secnetperf-style micro-benchmark measuring raw QUIC transport performance over loopback UDP.

- **Protocol**: QUIC v1, 1-RTT installed keys (TLS handshake bypassed for transport-only measurement)
- **Socket**: loopback UDP, 1324-byte datagrams
- **Build**: `zig build -Doptimize=ReleaseFast`
- **Platform**: Apple M-series, macOS, Zig 0.16
- **Loss simulation**: xorshift PRNG random drop (not deterministic every-Nth)
- **RTT scenarios**: loopback (~20μs) and 100μs busy-wait delay

## Results (2026-07-28)

| Metric | Value | Notes |
|---|---|---|
| Stream Upload (16 MB) | **~1800-2050 MB/s** | Threaded client/server, CUBIC per-ACK, std.Io async |
| Datagrams sent | ~25K | 1324 B each, pipelined with ACK feedback |
| Echo Latency P50 | **~19 μs** | 1 KB full QUIC roundtrip |
| Echo Latency P99 | **~50 μs** | |
| Multi-Stream (4×) | **~1730-1970 MB/s** | Shared cwnd, single connection |

## Running

```bash
zig build run-quic-bench
```

## Comparison Context

### Throughput (single stream, loopback)

| Implementation | Language | Throughput | Platform | Source |
|---|---|---|---|---|
| msquic | C | 1.5-2.5 GB/s | Linux XDP/GSO | secnetperf |
| **quicz** | **Zig** | **~1.8-2.0 GB/s** | **macOS, no GSO** | **This benchmark** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo Latency (1 KB roundtrip, loopback)

| Implementation | Language | P50 | P99 | Notes |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~19 μs** | **~50 μs** | **std.Io threaded** |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go runtime scheduling |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Single-threaded |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio async |

### Loss Recovery (4 MB transfer, random packet loss)

| Condition | Throughput | cwnd | 5%/1% retention |
|---|---|---|---|
| Loopback, 1% loss | ~215 MB/s | 22 KB | — |
| Loopback, 5% loss | ~173 MB/s | 8 KB | **80.5%** |
| 100μs RTT, 1% loss | ~12.3 MB/s | 13 KB | — |
| 100μs RTT, 5% loss | ~12.0 MB/s | 5 KB | **97.3%** |

Comparison with other implementations (5% loss retention, congestion avoidance phase):

| Implementation | 5% loss retention | Algorithm | Source |
|---|---|---|---|
| **quicz (loopback)** | **80.5%** | **CUBIC per-ACK + W_est** | **This benchmark** |
| **quicz (100μs RTT)** | **97.3%** | **CUBIC per-ACK + W_est** | **This benchmark** |
| msquic | ~40-50% | BBR2/CUBIC | secnetperf |
| s2n-quic | ~30-40% | CUBIC+HyStart++ | TQUIC |
| quic-go | ~30-40% | CUBIC/NewReno | TQUIC |
| quiche | ~25-35% | CUBIC | TQUIC |
| quinn | ~30-40% | CUBIC/NewReno | ETH thesis |

Notes:
- **Retention = 5% loss throughput / 1% loss throughput** (both in congestion avoidance).
- Previous "10% retention" figure compared 5% loss against no-loss slow start (2 GB/s), which is not a meaningful baseline.
- Other implementations' data from TQUIC/secnetperf/ETH papers use varied RTT and loss conditions.
- quicz uses random loss (xorshift PRNG); deterministic every-Nth loss underestimates recovery by ~10%.

## Architecture

### Congestion Control

- **CUBIC** (RFC 9438) with per-ACK window growth
  - TCP-friendly region: W_est(t) = W_max × β + 3(1-β)/(1+β) × (t/RTT)
  - Concave/Convex: per-ACK increment toward W_cubic(t+RTT) target
  - Cap: cwnd + bytes_acked/2 per ACK (Linux behavior)
- **NewReno** fallback
- **HyStart++** slow start exit
- **Explicit 3-state machine**: slow_start → recovery → congestion_avoidance (RFC 9002 §7.3)
- **Recovery exit**: time-based + PN-based dual channel
- **Pacer** integrated with CUBIC epoch
- **PTO** exponential backoff (RFC 9002 §6.2)
- **Persistent congestion** detection (RFC 9002 §7.6)
- **ECN** congestion signal processing

### Time Precision

- All internal timestamps: nanoseconds (i64)
- Conversion constants: `src/time/duration.zig` (`ns_per_us`, `ns_per_ms`, `ns_per_s`)
- Conversion functions: `nanosToMillis()`, `millisToNanos()`, `nanosToSecsF()`
- Protocol boundary conversions (max_ack_delay, pacer) use conversion functions
- Test code uses `* ms` constant expressions

## Decision: BBR2 Not Planned

BBR2 removed from roadmap (2026-07-27). Rationale:

- **No stable specification**: BBR2 has no RFC or finalized IETF draft.
- **Fairness risk**: BBR flows can starve coexisting CUBIC flows.
- **Ecosystem alignment**: quic-go, quiche, s2n-quic all default to CUBIC.
- **Implementation cost vs. benefit**: ~2000 lines for a moving target.

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent's multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + throughput via pcap
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft's QUIC perf tool
