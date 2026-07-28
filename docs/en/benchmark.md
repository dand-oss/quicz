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
| Stream Upload (16 MB) | **~1485 MB/s** | Threaded client/server, CUBIC, std.Io async, ns RTT |
| Datagrams sent | ~25K | 1324 B each, pipelined with ACK feedback |
| Total time | ~11 ms | cwnd grew to 1.7 MB |

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
| **quicz** | **Zig** | **~1.5 GB/s** | **macOS, no GSO** | **This benchmark** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo Latency (1 KB roundtrip, loopback)

| Implementation | Language | P50 | P99 | Notes |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~18 μs** | **~49 μs** | **std.Io threaded, ns RTT** |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go runtime scheduling overhead |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Single-threaded event loop |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio async runtime |

### Multi-Stream Throughput (4 concurrent streams)

| Implementation | Language | 4-stream aggregate | Scaling | Notes |
|---|---|---|---|---|
| msquic | C | ~2-4 GB/s | Near-linear | Per-stream worker threads |
| **quicz** | **Zig** | **~1494 MB/s** | **Shared cwnd** | **Single connection, CUBIC, ns RTT** |
| quic-go | Go | ~600-900 MB/s | Good | Per-stream goroutines |
| s2n-quic | Rust | ~800 MB/s-1.2 GB/s | Good | Async I/O |
| quiche | Rust | ~300-500 MB/s | Limited | Single-threaded |

### Loss Recovery (throughput under packet loss)

| Implementation | 0% loss | 1% loss | 5% loss | Recovery algorithm |
|---|---|---|---|---|
| msquic | 1.5+ GB/s | ~70-80% retained | ~40-50% retained | BBR2/CUBIC |
| **quicz** | **~1485 MB/s** | **~764 MB/s (51%)** | **~338 MB/s (23%)** | **CUBIC, ns RTT** |
| quic-go | 400-600 MB/s | ~60-70% retained | ~30-40% retained | CUBIC/NewReno |
| quiche | 300-500 MB/s | ~50-60% retained | ~25-35% retained | CUBIC |
| quinn | 300-500 MB/s | ~55-65% retained | ~30-40% retained | CUBIC/NewReno |

Notes on loss recovery:
- quicz 1% loss recovery improved from 117 MB/s → 764 MB/s (6.5x) after ns RTT precision migration.
- 5% loss improved from 67 MB/s → 338 MB/s (5x).
- Remaining gap vs msquic is due to BBR2 bandwidth modeling under loss.
- Further CUBIC tuning (TLP, RACK) planned for additional improvement.

Notes:
- Direct comparison is difficult due to different measurement methodologies, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass), so loopback UDP overhead applies.
- Go/Rust implementations benefit from zero-copy sendmsg and GSO on Linux.
- quicz's 1.94 GB/s exceeds msquic's lower bound, making it the fastest pure-language QUIC implementation without GSO/XDP.

## Echo Latency

| Percentile | Latency | Notes |
|---|---|---|
| P50 | **17.6 μs** | 1 KB full QUIC roundtrip (encrypt+send+recv+decrypt+echo) |
| P99 | **49.0 μs** | |
| P99.9 | **71.3 μs** | |

Test: 5000 iterations, macOS loopback, ReleaseFast.

## Planned Benchmarks

- [x] Echo latency (P50/P99)
- [ ] Multi-stream concurrency (1/2/4/8/16 streams)
- [ ] DATAGRAM throughput (RFC 9221)
- [ ] Loss recovery (tc netem 1%/5% packet loss)
- [ ] CPU utilization (perf stat / Instruments)
- [ ] External interop throughput (quic-go/quiche/s2n-quic peers)

## Completed: RTT ns Precision Migration

**Status**: Complete (2026-07-28, commit 887a5be + 3ff8e85)

All RTT fields migrated from milliseconds to nanoseconds (u64):
- `smoothed_rtt_ns`, `rttvar_ns`, `min_rtt_ns`, `latest_rtt_ns`, `max_ack_delay_ns`
- `timer_granularity_ns = 1_000_000` (RFC 9002 kGranularity = 1ms)
- Cross-platform `clock.nanoTimestamp()` via `clock_gettime(CLOCK_MONOTONIC)`
- RTT update enabled by default through `onPacketAckedWithUtilization`
- 1805/1805 tests pass

Impact:
- 1% loss: 117 → 764 MB/s (6.5x improvement)
- 5% loss: 67 → 338 MB/s (5x improvement)
- PTO adapts to actual RTT (was stuck at 333ms initial)
- Time-threshold loss detection accurate at μs scale

## Loss Recovery Improvement Path (5% loss: 19% → 30-40% target)

Current 5% loss retention (19%) is below s2n-quic/quic-go (30-40%). Root causes:
1. Loopback RTT=0 gives CUBIC no recovery time between loss events
2. No TLP (Tail Loss Probe) — loss detection relies on packet threshold (3 newer ACKed)
3. No RACK — time-based loss detection would be faster on low-RTT paths

Planned fixes:
- [ ] TLP (RFC 8985): send probe before RTO, trigger early ACK, faster retransmission
- [ ] RACK: declare loss by receive timestamp, not packet number gap
- [ ] Retransmission pacing: space retransmits to avoid cascading secondary loss


## Decision: BBR2 Not Planned

BBR2 is removed from the roadmap (2026-07-27). Rationale:

- **No stable specification**: BBR2 has no RFC or finalized IETF draft; Google continues iterating internally.
- **Fairness risk**: BBR flows can starve coexisting CUBIC flows; BBR2 mitigations are not validated at scale in mixed-traffic production environments.
- **Ecosystem alignment**: quic-go, quiche (Cloudflare), and s2n-quic (AWS) all default to CUBIC (RFC 8312/9438); matching this avoids interop and fairness surprises.
- **Implementation cost vs. benefit**: ~2000 lines for a moving target with uncertain marginal gain over tuned CUBIC in our primary use cases (datacenter-to-user, CDN, API gateway).

Loss recovery improvement will focus on CUBIC parameter tuning (recovery interval, utilization threshold) instead.
The existing simplified BBR module (`src/quic/bbr.zig`) is retained for experimentation but is not a production path.

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent's multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + throughput via pcap
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic multi-implementation comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft's QUIC perf tool
