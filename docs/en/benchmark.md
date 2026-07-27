# quicz Performance Benchmark

## Methodology

secnetperf-style micro-benchmark measuring raw QUIC transport performance over loopback UDP.

- **Protocol**: QUIC v1, 1-RTT installed keys (TLS handshake bypassed for transport-only measurement)
- **Socket**: loopback UDP, 1200-byte datagrams
- **Build**: `zig build-exe -OReleaseFast`
- **Platform**: Apple M-series, macOS, Zig 0.16

## Results

| Metric | Value | Notes |
|---|---|---|
| Stream Upload (64 MB) | **~1444 MB/s (1.86 GB/s)** | Threaded client/server, CUBIC, std.Io async |
| Datagrams sent | ~102K | 1324 B each, pipelined with ACK feedback |
| Total time | ~44 ms | cwnd grew to 1.2 MB |

## Running

```bash
# Build and run
zig build run-quic-bench

# Or build ReleaseFast binary directly
zig build-exe -OReleaseFast --dep quicz \
  -Mroot=examples/quic_bench.zig -Mquicz=src/lib.zig \
  --name quicz-quic-bench -femit-bin=zig-out/bin/quicz-quic-bench
./zig-out/bin/quicz-quic-bench
```

## Comparison Context

### Throughput (single stream, loopback)

| Implementation | Language | Throughput | Platform | Source |
|---|---|---|---|---|
| msquic | C | 1.5-2.5 GB/s | Linux XDP/GSO | secnetperf |
| **quicz** | **Zig** | **~1.86 GB/s** | **macOS, no GSO** | **This benchmark** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo Latency (1 KB roundtrip, loopback)

| Implementation | Language | P50 | P99 | Notes |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~19 μs** | **~55-69 μs** | **std.Io threaded** |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go runtime scheduling overhead |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Single-threaded event loop |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio async runtime |

### Multi-Stream Throughput (4 concurrent streams)

| Implementation | Language | 4-stream aggregate | Scaling | Notes |
|---|---|---|---|---|
| msquic | C | ~2-4 GB/s | Near-linear | Per-stream worker threads |
| **quicz** | **Zig** | **~180-800 MB/s** | **Shared cwnd** | **Single connection, CUBIC** |
| quic-go | Go | ~600-900 MB/s | Good | Per-stream goroutines |
| s2n-quic | Rust | ~800 MB/s-1.2 GB/s | Good | Async I/O |
| quiche | Rust | ~300-500 MB/s | Limited | Single-threaded |

### Loss Recovery (throughput under packet loss)

| Implementation | 0% loss | 1% loss | 5% loss | Recovery algorithm |
|---|---|---|---|---|
| msquic | 1.5+ GB/s | ~70-80% retained | ~40-50% retained | BBR2/CUBIC |
| **quicz** | **~760 MB/s** | **~249 MB/s (33%)** | **~331 MB/s (43%)** | **CUBIC** |
| quic-go | 400-600 MB/s | ~60-70% retained | ~30-40% retained | CUBIC/NewReno |
| quiche | 300-500 MB/s | ~50-60% retained | ~25-35% retained | CUBIC |
| quinn | 300-500 MB/s | ~55-65% retained | ~30-40% retained | CUBIC/NewReno |

Notes on loss recovery:
- quicz loss recovery is conservative (CUBIC with 50% utilization threshold).
- msquic's BBR2 maintains higher throughput under loss by modeling bandwidth.
- quic-go's CUBIC implementation has more aggressive recovery (higher utilization threshold).
- quicz loss recovery can be improved by tuning CUBIC parameters or adding BBR support.

Notes:
- Direct comparison is difficult due to different measurement methodologies, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass), so loopback UDP overhead applies.
- Go/Rust implementations benefit from zero-copy sendmsg and GSO on Linux.
- quicz's 160 MB/s is competitive for a pure-Zig implementation without platform-specific I/O optimization.

## Echo Latency

| Percentile | Latency | Notes |
|---|---|---|
| P50 | **20.2 μs** | 1 KB full QUIC roundtrip (encrypt+send+recv+decrypt+echo) |
| P99 | **62.1 μs** | |
| P99.9 | **85.3 μs** | |

Test: 5000 iterations, macOS loopback, ReleaseFast.

## Planned Benchmarks

- [x] Echo latency (P50/P99)
- [ ] Multi-stream concurrency (1/2/4/8/16 streams)
- [ ] DATAGRAM throughput (RFC 9221)
- [ ] Loss recovery (tc netem 1%/5% packet loss)
- [ ] CPU utilization (perf stat / Instruments)
- [ ] External interop throughput (quic-go/quiche/s2n-quic peers)
- [ ] Full BBR2 implementation (msquic-level loss recovery)

## Future Work: BBR2 Congestion Control

### Goal
Achieve msquic-level loss recovery (70-80% throughput retained at 1% loss) while maintaining
CUBIC-level no-loss throughput (~1.86 GB/s).

### Current State
- Existing BBR module (src/quic/bbr.zig, 380 lines): simplified startup/drain/probe-RTT phases.
- CUBIC with PTO-based recovery interval: 33% retained at 1% loss, 43% at 5% loss.
- BBR current: slightly better loss recovery (266 vs 249 MB/s at 1%) but 5.7x worse no-loss throughput.

### Gap Analysis (vs msquic BBR2)
| Feature | quicz BBR | msquic BBR2 | Impact |
|---|---|---|---|
| Bandwidth estimation | Basic max filter | Delivery rate sampling + windowed max | Throughput accuracy |
| Loss response | Reduces cwnd | inflight_hi/inflight_lo, no cwnd cut | Loss recovery |
| Startup exit | BtlBw plateau | 2-round plateau + loss-based exit | Startup speed |
| ProbeRTT | Fixed interval | Adaptive, skipped if recent low RTT | Latency spikes |
| Pacing | Basic rate | Precise per-packet pacing with timer | Smoothness |
| ECN | Not integrated | CE-based inflight adjustment | Congestion signal |

### Implementation Plan (~2000 lines)
1. **Phase 1: Delivery rate sampling** — track delivered bytes + time per packet, compute delivery rate.
2. **Phase 2: Windowed BtlBw/RTprop** — max filter over 10s (BtlBw) and min filter over 10s (RTprop).
3. **Phase 3: State machine** — Startup → Drain → ProbeBW → ProbeRTT with proper transitions.
4. **Phase 4: Loss-based adaptation** — inflight_hi/inflight_lo (BBR2), no multiplicative decrease.
5. **Phase 5: Pacing engine** — per-packet send timing based on pacing_rate = BtlBw * gain.
6. **Phase 6: Integration** — connect to Connection recovery path, config option, benchmark validation.

### Success Criteria
- 1% loss: retain >= 60% throughput (vs current 33%)
- 5% loss: retain >= 40% throughput (vs current 43%, already met)
- No loss: maintain >= 700 MB/s (vs current 760 MB/s)
- Latency P99: no regression from current 65μs

### References
- RFC 9438 (CUBIC) — current implementation baseline
- BBR2 paper: "BBR: Congestion-Based Congestion Control" (Cardwell et al., 2017)
- BBR2 draft: draft-cardwell-iccrg-bbr-congestion-control-03
- msquic BBR2: github.com/microsoft/msquic/src/core/congestion_control_bbr.c

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent's multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + throughput via pcap
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic multi-implementation comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft's QUIC perf tool
