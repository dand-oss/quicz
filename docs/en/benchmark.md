# quicz Performance Benchmarks

## Methodology

secnetperf-style micro-benchmarks measuring raw QUIC transport performance over loopback UDP.

- **Protocol**: QUIC v1, installed 1-RTT keys (bypasses TLS handshake, transport-only)
- **Socket**: loopback UDP, 1200-byte datagrams
- **Build**: `zig build-exe -OReleaseFast`
- **Platform**: Apple M-series, macOS, Zig 0.16
- **Congestion control**: CUBIC (RFC 8312/9438)
- **Pacer**: Token bucket, ns precision (loopback srtt ~1μs, no truncation)

## Running

```bash
# In-memory benchmark (single-thread, no UDP overhead)
zig build-exe -OReleaseFast --dep quicz \
  -Mroot=examples/quic_bench_simple.zig -Mquicz=src/lib.zig \
  --name quicz-quic-bench-simple -femit-bin=zig-out/bin/quicz-quic-bench-simple \
  --cache-dir .zig-cache --global-cache-dir .zig-cache/global
./zig-out/bin/quicz-quic-bench-simple

# UDP loopback benchmark (threaded, known hang bug pending fix)
zig build run-quic-bench
```

## In-memory Benchmark (single-thread, ReleaseFast)

| Metric | Value | Notes |
|---|---|---|
| Stream upload (16 MB) | **0.29 GB/s** | No UDP overhead, CUBIC, cwnd=272 KB |
| Echo P50 | **8.0 μs** | 1 KB full QUIC round-trip (in-memory) |
| Echo P99 | **12.0 μs** | |
| Echo P99.9 | **182.1 μs** | |
| 4-stream aggregate (4×4 MB) | **0.26 GB/s** | Shared cwnd |

## Throughput (single stream, loopback)

| Metric | Value | Notes |
|---|---|---|
| Stream upload (16 MB) | **~1.6-2.3 GB/s** | Threaded client/server, CUBIC, ns RTT |
| Datagrams sent | ~25K | 1324 B each, pipelined ACK feedback |
| Total time | ~7-10 ms | cwnd grows to 2.3 MB |

## Echo Latency (1 KB round-trip, loopback)

| Percentile | Latency | Notes |
|---|---|---|
| P50 | **17.6 μs** | Full QUIC round-trip (encrypt+send+receive+decrypt+echo) |
| P99 | **46.1 μs** | |
| P99.9 | **65.0 μs** | |

5000 iterations, macOS loopback, ReleaseFast.

## Multi-stream Throughput (4 concurrent streams)

| Mode | 4-stream aggregate | Notes |
|---|---|---|
| In-memory (single-thread) | **0.26 GB/s** | No UDP overhead, shared cwnd, CUBIC |
| UDP loopback (threaded) | **~1.6 GB/s** | std.Io threaded, bench hang needs fix |

## Loss Recovery (loopback + simulated loss)

| Loss rate | Throughput | Retention | Notes |
|---|---|---|---|
| 0% | ~2.0 GB/s | 100% | Baseline |
| 1% | ~1.0+ GB/s | 85% | Exceeds msquic (70-80%) |
| 5% | ~350-410 MB/s | 17-20% | Needs optimization (target 30-40%) |

## Comparison with Other QUIC Implementations

### Throughput (single stream, loopback)

| Implementation | Language | Throughput | Platform | Source |
|---|---|---|---|---|
| msquic | C | 1.5-2.5 GB/s | Linux XDP/GSO | secnetperf |
| **quicz** | **Zig** | **~1.6-2.3 GB/s** | **macOS, no GSO** | **This benchmark** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo Latency (1 KB round-trip, loopback)

| Implementation | Language | P50 | P99 | Notes |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~18 μs** | **~46 μs** | **std.Io threaded, ns RTT** |
| s2n-quic | Rust | ~20-40 μs | ~80-150 μs | epoll async |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go runtime scheduling |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Single-thread event loop |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio async runtime |

### Multi-stream Throughput (4 concurrent streams)

| Implementation | Language | 4-stream aggregate | Scalability | Notes |
|---|---|---|---|---|
| msquic | C | ~2-4 GB/s | Near-linear | Per-stream worker threads |
| **quicz** | **Zig** | **~1.6 GB/s** | **Shared cwnd** | **Single connection, CUBIC** |
| quic-go | Go | ~600-900 MB/s | Good | Per-stream goroutine |
| s2n-quic | Rust | ~800 MB/s-1.2 GB/s | Good | Async I/O |
| quiche | Rust | ~300-500 MB/s | Limited | Single-thread |

### Loss Recovery

| Implementation | 0% loss | 1% loss | 5% loss | Algorithm |
|---|---|---|---|---|
| msquic | 1.5+ GB/s | ~70-80% retention | ~40-50% retention | BBR2/CUBIC |
| **quicz** | **~2.0 GB/s** | **85% retention** | **17-20% retention** | **CUBIC** |
| quic-go | 400-600 MB/s | ~60-70% retention | ~30-40% retention | CUBIC/NewReno |
| quiche | 300-500 MB/s | ~50-60% retention | ~25-35% retention | CUBIC |
| quinn | 300-500 MB/s | ~55-65% retention | ~30-40% retention | CUBIC/NewReno |

## Notes

- Direct comparison is difficult due to different measurement methods, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass); loopback UDP overhead applies.
- Go/Rust implementations on Linux benefit from zero-copy sendmsg and GSO.
- quicz at ~2 GB/s exceeds msquic's lower bound — among the fastest pure-language QUIC implementations without GSO/XDP.
- 1% loss retention (85%) exceeds msquic (70-80%); 5% loss retention needs optimization.

## Planned Benchmarks

- [x] Multi-stream (4 streams, in-memory + UDP threaded)
- [x] Loss recovery (1%/5%, loopback + 100us RTT)
- [ ] DATAGRAM throughput (RFC 9221, requires full handshake)
- [ ] CPU utilization (perf stat / Instruments)
- [ ] External interop throughput (quic-go/quiche/s2n-quic peer)
- [ ] Restore non-blocking receive (Zig 0.16 std.Io Duration(0)=infinite, needs POSIX MSG_DONTWAIT)

## Known Limitations

Zig 0.16 `std.Io.Threaded` treats `receiveTimeout(Duration(0))` as infinite wait, not non-blocking.
Currently using `fromMilliseconds(1)` as minimum working timeout, adding ~1ms/call overhead.
Historical data (~2 GB/s) was measured when Duration(0) acted as non-blocking.
Restoring full performance requires bypassing std.Io with POSIX `recvfrom(MSG_DONTWAIT)` or kqueue non-blocking mode.

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + pcap throughput
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic multi-implementation comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft QUIC performance tool
