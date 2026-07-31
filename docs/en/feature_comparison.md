## Feature comparison with other QUIC implementations

Updated: 2026-07-28. Sources: project READMEs, source code inspection, RFC compliance tracking.

| Feature | RFC | quic-go | quiche | s2n-quic | quicz | Gap |
| --- | --- | --- | --- | --- | --- | --- |
| QUIC v1 transport | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| QUIC v2 | 9369 | ✅ | ❌ | ❌ | ✅ | quiche/s2n-quic only V1 |
| TLS 1.3 | 9001 | ✅(Go crypto/tls) | ✅(BoringSSL) | ✅(s2n-tls/rustls) | ✅(pure Zig) | — |
| 0-RTT (early data) | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| Loss detection & recovery | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| Connection migration | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| Path validation | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| Retry + address validation | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| Stateless reset | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| Key update | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| Version negotiation | 9368 | ✅ | ✅ | ✅ | ✅ | — |
| DATAGRAM extension | 9221 | ✅ | ✅ | ✅(unstable) | ✅ | — |
| Multipath | draft | ✅ | ❌ | ❌ | ✅ | — |
| ECN | 9000 | ✅ | ⚠️ rx only | ✅ | ✅ | quiche 不发送 ECN |
| PMTU discovery | 8899 | ✅ | ✅ | ✅ | ✅ | — |
| GSO/GRO | — | ✅ | ❌ | ✅ | ✅ | quiche 委托应用层 I/O |
| Connection pool | — | ✅ | ❌ | ❌ | ✅ | — |
| qlog | draft | ✅ | ✅(feature-gated) | ❌(event subscriber) | ✅ | — |
| Fuzz targets | — | ✅(OSS-Fuzz) | ✅ | ✅ | ✅ | — |
| NewReno | 9002 | ✅ | ✅ | ❌ | ✅ | s2n-quic 仅 CUBIC+BBR |
| CUBIC | 9438 | ✅ | ✅ | ✅ | ✅ | — |
| BBR | — | ✅ | ✅ | ✅ | ✅ | — |
| HyStart++ | draft | ❌ | ❌ | ✅ | ✅ | 慢启动 RTT 监测提前退出 |
| PTO jitter | 9002 | ❌ | ❌ | ✅ | ✅ | 防止超时同步化 |
| Fast retransmission | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| App-limited (RFC 8312 §5.8) | 8312 | ✅ | ✅ | ✅ | ✅ | 3×MTU 阈值 |
| Packet pacing | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| AES-128-GCM | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| AES-256-GCM | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| ChaCha20-Poly1305 | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| X25519 ECDH | 8446 | ✅ | ✅ | ✅ | ✅ | — |
| X25519Kyber768 (PQ) | draft | ✅ | ✅ | ✅ | ✅ | — |
| HTTP/3 | 9114 | ✅ | ✅ | ❌ | ✅ | 完整连接管理、Settings、GOAWAY、stream 状态机 |
| QPACK static table | 9204 | ✅ | ✅ | ❌ | ✅ | — |
| QPACK dynamic table | 9204 | ✅ | ✅ | ❌ | ✅ | 动态表 + encoder/decoder instructions + header block |
| HTTP Datagrams | 9297 | ✅ | ❌ | ❌ | ✅ | Quarter Stream ID + payload 帧格式 |
| WebTransport | draft | ✅ | ❌ | ❌ | ✅ | 完整会话管理、uni/bidi 帧、CLOSE capsule、datagram |
| Stream reset partial delivery | draft | ✅ | ❌ | ❌ | ✅ | opt-in enable_reset_partial_delivery |
| External interop | — | — | — | — | ✅ all three | — |
| Pure-language TLS (no C) | — | ✅ | ❌ | ❌ | ✅ | — |
| FIPS 140-3 | — | ✅(Go 1.26+) | ❌ | ❌ | ❌ | 仅 quic-go |
| XDP zero-copy I/O | — | ❌ | ❌ | ✅(unstable) | ❌ | 仅 s2n-quic |

### Coverage summary

| Metric | quic-go | quiche | s2n-quic | quicz |
| --- | --- | --- | --- | --- |
| Transport (19 items) | 19/19 | 14/19 | 14/19 | 19/19 |
| Congestion (8 items) | 6/8 | 6/8 | 7/8 | 8/8 |
| Cipher suites (5 items) | 5/5 | 5/5 | 5/5 | 5/5 |
| Application layer (6 items) | 6/6 | 3/6 | 0/6 | 6/6 |
| Platform (3 items) | 2/3 | 0/3 | 1/3 | 1/3 |
| **Total (41 items)** | **38/41** | **28/41** | **27/41** | **41/41** |

### Gap analysis

**Mandatory gaps (all three have) — ALL CLOSED:**

1. ~~AES-256-GCM~~ — DONE (675e7ca)
2. ~~X25519Kyber768~~ — DONE (675e7ca)

**Recommended (2/3 have):**

3. ~~QPACK dynamic table~~ — DONE (c8e605c)
4. ~~Complete HTTP/3 connection management~~ — DONE (a15d22d)

**Optional (1/3 or fewer):**

5. HTTP Datagrams (RFC 9297) — quic-go only
6. Complete WebTransport session — quic-go only
7. Stream reset partial delivery — quic-go only (draft)
8. FIPS 140-3 — quic-go only
9. XDP zero-copy I/O — s2n-quic only


Full transport task matrix: [quic_transport_tasks.md](quic_transport_tasks.md).

## Performance Comparison

Test conditions: loopback UDP, single stream upload, ReleaseFast build, 8.9KB datagram, 100μs timeout.

| Implementation | Language | Throughput | Platform | Notes |
| --- | --- | --- | --- | --- |
| msquic | C | ~7-8 Gbps | Windows, XDP | secnetperf dashboard |
| msquic | C | ~3 Gbps | Linux, no XDP | Aalto 2025 thesis |
| msquic | C | ~1 Gbps | macOS, loopback | secnetperf |
| quic-go | Go | ~4 Gbps | Linux, GSO, multi-stream | KIT 2025 |
| quic-go | Go | ~1.1 Gbps | Linux, GSO | quic-go#3670 |
| s2n-quic | Rust | ~800 MB/s | Linux, GSO/GRO | TQUIC benchmark |
| **quicz** | **Zig** | **~396 MB/s (single) / ~450 MB/s (4-stream)** | **macOS, loopback** | **real handshake, 8.9KB datagram, 100μs timeout, CUBIC, no GSO** |
| quiche | Rust | ~300-500 MB/s | Linux, no GSO | TQUIC benchmark |
| quinn | Rust | ~300-500 MB/s | Linux, tokio | KIT 2025 / ETH thesis |
| TQUIC | Rust | ~1-2 Gbps | Linux, GSO | TQUIC benchmark |
| lsquic | C | ~2-4 Gbps | Linux, GSO | KIT 2025 |
| picoquic | C | ~1-2 Gbps | Linux | KIT 2025 |

Notes:
- quicz reaches ~390 MB/s single-stream on macOS loopback (real handshake, quic-go style multi-iteration, stddev 4.3%; no GSO/XDP).
- The main throughput cost is per-packet QUIC processing CPU (AES-128-GCM hardware accelerated ~4.9 μs/packet + framing/parsing); UDP `sendto` ~3.5–4.7 μs/packet is not dominant.
- quicz multi-stream (~470 MB/s) is comparable to quiche/quinn (300-500 MB/s on Linux).
- Other implementations rely on Linux GSO/GRO (3-10x improvement) or XDP kernel bypass.
- External interop: quic-go + s2n-quic + quiche handshake + cert verify + ALPN + echo PASS.
- Detailed benchmarks: [benchmark.md](benchmark.md)

## Production Tuning

See [Production Tuning Guide](production_tuning.md) for recommended
configuration values, PTO jitter guidance, congestion control selection,
and initial RTT tuning per deployment environment.
