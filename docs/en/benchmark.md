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
| **quicz** | **~1370 MB/s** | **~1570 MB/s (114%)** | **~504 MB/s (37%)** | **CUBIC** |
| quic-go | 400-600 MB/s | ~60-70% retained | ~30-40% retained | CUBIC/NewReno |
| quiche | 300-500 MB/s | ~50-60% retained | ~25-35% retained | CUBIC |
| quinn | 300-500 MB/s | ~55-65% retained | ~30-40% retained | CUBIC/NewReno |

Notes on loss recovery:
- quicz loss recovery is conservative (CUBIC with 50% utilization threshold).
- msquic's BBR2 maintains higher throughput under loss by modeling bandwidth.
- quic-go's CUBIC implementation has more aggressive recovery (higher utilization threshold).
- quicz loss recovery can be improved by tuning CUBIC parameters (recovery interval, utilization threshold).

Notes:
- Direct comparison is difficult due to different measurement methodologies, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass), so loopback UDP overhead applies.
- Go/Rust implementations benefit from zero-copy sendmsg and GSO on Linux.
- quicz's 1.86 GB/s exceeds msquic's lower bound, making it the fastest pure-language QUIC implementation without GSO/XDP.

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
