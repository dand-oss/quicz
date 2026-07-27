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
| Stream Upload (64 MB) | **~1444 MB/s (1.4 GB/s)** | Threaded client/server, CUBIC, std.Io async |
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

| Implementation | Language | Loopback throughput (approx) | Source |
|---|---|---|---|
| quicz | Zig | ~1444 MB/s | This benchmark (threaded, macOS loopback) |
| quic-go | Go | ~200-400 MB/s | TQUIC benchmark (varies by config) |
| quiche | Rust | ~300-500 MB/s | TQUIC benchmark |
| s2n-quic | Rust | ~400-800 MB/s | TQUIC benchmark |
| msquic | C | ~1-2 GB/s | secnetperf |

Notes:
- Direct comparison is difficult due to different measurement methodologies, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass), so loopback UDP overhead applies.
- Go/Rust implementations benefit from zero-copy sendmsg and GSO on Linux.
- quicz's 160 MB/s is competitive for a pure-Zig implementation without platform-specific I/O optimization.

## Planned Benchmarks

- [ ] Echo latency (P50/P99, requires isolated socket pairs)
- [ ] Multi-stream concurrency (1/2/4/8/16 streams)
- [ ] DATAGRAM throughput (RFC 9221)
- [ ] Loss recovery (tc netem 1%/5% packet loss)
- [ ] CPU utilization (perf stat / Instruments)
- [ ] External interop throughput (quic-go/quiche/s2n-quic peers)

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent's multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + throughput via pcap
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic multi-implementation comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft's QUIC perf tool
