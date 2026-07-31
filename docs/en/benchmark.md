# quicz Performance Benchmarks

## Methodology

secnetperf-style micro-benchmarks measuring raw QUIC transport performance over loopback UDP.

- **Protocol**: QUIC v1, installed 1-RTT keys (bypasses TLS handshake, transport-only)
- **Socket**: loopback UDP, 8900-byte datagrams (macOS UDP limit 9000B)
- **I/O layer**: std.Io.Threaded (cross-platform, Linux auto-enables sendmmsg batching)
- **Build**: `zig build-exe -OReleaseFast`
- **Platform**: Apple M-series macOS / Linux aarch64 (Docker), Zig 0.16
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

## Throughput (single stream, loopback, real handshake)

| Metric | Value | Notes |
|---|---|---|
| Single-stream throughput | **390 MB/s** (stddev 4.3%, min 364 / max 412) | Real TLS 1.3 handshake, quic-go style 5 iterations, mean |
| Handshake time | ~0.6–1.0 ms/iter | TLS 1.3, transport parameters negotiated (RFC 9000 §7.4) |
| Transfer | 16 MB/iter | 8900 B datagram, CUBIC, 100μs receiveTimeout |

> Methodology (`examples/quic_bench_hs.zig`): each iteration creates a fresh connection and performs a real TLS 1.3 handshake (RFC 9000 §7 / RFC 9001 §4, same flow as `examples/interop_client.zig`), measures the end-to-end time to transfer 16 MB until the peer receives it all, and reports mean/stddev across iterations (quic-go `BenchmarkTransfer` model).
> The real handshake ensures transport parameters are negotiated correctly; the installed-keys bypass skips the handshake and thus that negotiation (RFC 9000 §7.4), so it is only used for point latency micro-benchmarks, not throughput.

## Linux Cross-platform Test (Docker OrbStack VM)

| Metric | macOS native | Linux Docker VM | Notes |
|---|---|---|---|
| Single stream | **~390 MB/s** (real handshake) | 44.16 MB/s | VM virtual network overhead ~10x |
| Multi-stream (4x) | ~470 MB/s | 61.99 MB/s | |
| Echo P50 | 18.3 μs | 34.7 μs | |
| Echo P99 | 57.9 μs | 64.1 μs | |

> Linux Docker data is limited by OrbStack VM virtual networking, not representative of bare-metal performance.
> Cross-compile: `zig build-exe -target aarch64-linux-musl -OReleaseFast -lc ...`
> Run: `docker run --rm -v $(pwd):/app -w /app alpine ./zig-out/bin/quicz-quic-bench-linux`

## Cross-platform Architecture

- **No custom Linux GSO layer**: Zig `std.Io.Threaded` already has `sendmmsg` batching on Linux (`Threaded.zig:1971`)
- **std.Io defaults to io_uring on Linux** (`Io.zig:32`); Threaded is the explicitly chosen backend
- **sendMany API only benefits Linux** (sendmmsg); on macOS it adds array-building overhead
- **nanoTime cross-platform**: comptime conditional, macOS `mach_absolute_time` / Linux `clock_gettime(MONOTONIC)`

## Echo Latency (1 KB round-trip, loopback)

| Percentile | Latency | Notes |
|---|---|---|
| P50 | **17.8 μs** | Full QUIC round-trip (encrypt+send+receive+decrypt+echo) |
| P99 | **65.7 μs** | |
| P99.9 | **109.9 μs** | |

5000 iterations, macOS loopback, ReleaseFast.

## Multi-stream Throughput (4 concurrent streams)

> Below uses the installed-keys bypass; pending re-measurement with the real-handshake bench.

| Mode | 4-stream aggregate | Notes |
|---|---|---|
| In-memory (single-thread) | **0.26 GB/s** | No UDP overhead, shared cwnd, CUBIC |
| UDP loopback (threaded) | **~470 MB/s** (measured range 266–532) | std.Io threaded, 8.9KB datagram, 100μs timeout |

## Loss Recovery (loopback + simulated loss)

> Below uses the installed-keys bypass; pending re-measurement with the real-handshake bench.

| Loss rate | Throughput | Retention | Notes |
|---|---|---|---|
| 0% | ~390 MB/s | 100% | Baseline (real handshake) |
| 1% | ~455 MB/s | ~95% | loopback, CUBIC fast recovery |
| 5% | ~108 MB/s | ~22% | loopback |

## Comparison with Other QUIC Implementations

### Test Condition Differences

Benchmark conditions vary significantly across implementations. Direct number comparisons require caution:

| Factor | Impact |
|---|---|
| GSO/GRO (Linux) | 3-10x throughput, batch syscalls |
| XDP (Linux kernel bypass) | 2-5x throughput, bypasses kernel network stack |
| loopback vs physical network | loopback has no loss/jitter, RTT ~1μs |
| single-thread vs multi-thread | multi-core scales linearly |
| Platform (macOS vs Linux) | macOS lacks GSO/XDP, higher syscall overhead |

### Single-Stream Throughput

| Implementation | Language | Throughput | Conditions | Source |
|---|---|---|---|---|
| msquic | C | **~7-8 Gbps** | Windows, XDP, single conn | msquic dashboard |
| msquic | C | **~3 Gbps** | Linux, no XDP, single conn | Aalto 2025 thesis |
| msquic | C | **~1 Gbps** | macOS, loopback | secnetperf |
| quic-go | Go | **~4 Gbps** | Linux, GSO, multi-stream | KIT 2025 |
| quic-go | Go | **~1.1 Gbps** | Linux, GSO, single stream | quic-go#3670 |
| lsquic | C | **~2-4 Gbps** | Linux, GSO | KIT 2025 |
| TQUIC | Rust | **~1-2 Gbps** | Linux, GSO | TQUIC benchmark |
| picoquic | C | **~1-2 Gbps** | Linux | KIT 2025 |
| s2n-quic | Rust | **~800 MB/s** | Linux, GSO/GRO | TQUIC benchmark |
| quiche | Rust | **~300-500 MB/s** | Linux, no GSO | TQUIC benchmark |
| quinn | Rust | **~300-500 MB/s** | Linux, tokio, single-core | KIT 2025 / ETH thesis |
| **quicz** | **Zig** | **~390 MB/s** | **macOS, loopback, real handshake, 8.9KB datagram, 100μs timeout, no GSO** | **This benchmark** |

## Echo Latency (small request round-trip)

| Implementation | Language | P50 | P99 | Conditions | Source |
|---|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | Linux, io_uring | secnetperf |
| s2n-quic | Rust | ~20-40 μs | ~80-150 μs | Linux, epoll | community bench |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Linux | community bench |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Linux, single-thread | community bench |
| quinn | Rust | ~50-100 μs | ~200-400 μs | Linux, tokio | ETH thesis |
| **quicz** | **Zig** | **17.8 μs** | **65.7 μs** | **macOS, loopback, std.Io, 100μs timeout** | **This benchmark** |

### Loss Recovery

| Implementation | 0% loss | 1% loss | 5% loss | Algorithm | Source |
|---|---|---|---|---|---|
| msquic | ~3 Gbps | ~70-80% retention | ~40-50% retention | CUBIC/BBR2 | ETH 2024 thesis |
| quic-go | ~1.1 Gbps | ~60-70% retention | ~30-40% retention | CUBIC | community bench |
| quinn | ~300-500 MB/s | msquic leads 50%+ | — | CUBIC | ETH 2024 thesis |
| **quicz** | **~390 MB/s** | **pending real-handshake re-measure** | **pending real-handshake re-measure** | **CUBIC** | **This benchmark** |

### Multi-Stream Scaling

| Implementation | 4-stream aggregate | Scalability | Source |
|---|---|---|---|
| msquic | ~2-4 Gbps | Near-linear (per-stream worker threads) | msquic dashboard |
| quic-go | ~600-900 MB/s | Good (per-stream goroutine) | community bench |
| s2n-quic | ~800 MB/s-1.2 GB/s | Good (async I/O) | TQUIC benchmark |
| quinn | single-core limited | Limited | KIT 2025 |
| **quicz** | **~470 MB/s** | **Shared cwnd (single cwnd per connection, RFC 9000)** | **This benchmark** |

### quicz Performance Bottleneck Analysis (measured)

The real-handshake bench (`quic_bench_hs.zig`) measures **~390 MB/s** single-stream on macOS loopback (stddev 4.3%). The following are verified by measurement:

1. **Handshake is not a bottleneck**: a real TLS 1.3 handshake takes ~0.6–1.0 ms/iter, negligible vs the ~40 ms 16 MB transfer; transport parameters are negotiated correctly (RFC 9000 §7.4).
2. **Per-packet processing CPU is the main cost**: AES-128-GCM measures 3.5–3.7 GB/s (ARM PMULL hardware accelerated), ~4.9 μs encrypt+decrypt per packet, plus QUIC framing/parsing and per-packet heap allocation. Raw UDP loopback reaches 1.8–2.4 GB/s; QUIC processing brings it to ~390 MB/s.
3. **UDP syscalls are not dominant**: raw UDP loopback `sendto` measures ~3.5–4.7 μs/packet (3 runs: 3.48 / 3.61 / 4.67 μs).
4. **GSO/GRO platform difference**: Linux GSO batch sending yields 3–10x throughput; macOS has no equivalent (no `UDP_SEGMENT`/`sendmmsg`). This is a platform limitation, not a quicz defect. On Linux, `std.Io.Threaded` already provides `sendmmsg`.

### quicz Latency Advantage

quicz Echo P50=17.8 μs under loopback conditions is competitive with most implementations:
- Lower than s2n-quic ~20-40 μs (Linux epoll)
- Lower than quic-go ~50-100 μs
- Close to msquic ~5-15 μs (io_uring)

This benefits from pure Zig with no GC pauses, no runtime scheduling overhead, and ns-precision pacer.

## Notes

- Direct comparison is difficult due to different measurement methods, platforms, and configurations.
- quicz uses an in-memory connection model (no kernel bypass); loopback UDP overhead applies.
- Go/Rust implementations on Linux benefit from zero-copy sendmsg and GSO.
- quicz currently reaches ~390 MB/s single-stream on macOS loopback (real handshake, quic-go style multi-iteration, stddev 4.3%; 8.9KB datagram, 100μs timeout).
- The main throughput cost is per-packet QUIC processing CPU (AES-128-GCM hardware accelerated + framing/parsing); UDP syscalls are not dominant.

## Planned Benchmarks

- [x] Multi-stream (4 streams, in-memory + UDP threaded)
- [x] Loss recovery (1%/5%, loopback + 100us RTT)
- [x] DATAGRAM throughput (RFC 9221, installed keys): **168.78 MB/s** (1200B payload, loopback)
- [x] CPU utilization (/usr/bin/time -l, single-thread in-memory: 12.5% user, 2.5% sys)
- [x] External interop (quic-go): handshake + cert verify + ALPN + 2-stream echo PASS
- [x] External interop (s2n-quic): handshake + cert verify + ALPN + 2-stream echo PASS
- [x] External interop (quiche): handshake + cert verify + ALPN + 2-stream echo PASS
- [x] Non-blocking receive (Duration(0) verified working)

## Known Limitations

Zig 0.16 `std.Io.Threaded` uses `poll(timeout_ms=0)` for non-blocking receive with `Duration(0)`.
Benchmark uses a 100μs `receiveTimeout`; `nanoTime()` is nanosecond-precision (macOS `mach_absolute_time` / Linux `clock_gettime(MONOTONIC)`).
The main throughput cost is per-packet QUIC processing CPU (AES-128-GCM ~4.9 μs/packet, hardware accelerated, plus framing/parsing); UDP `sendto` measures ~3.5–4.7 μs/packet and is not dominant.

## References

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — Tencent multi-condition QUIC benchmark
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — Interop + pcap throughput
- [KIT Performance Landscape (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — Academic multi-implementation comparison
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — Microsoft QUIC performance tool
