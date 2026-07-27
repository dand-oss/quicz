## Feature comparison with other QUIC implementations

Updated: 2026-07-24. Sources: project READMEs, source code inspection, RFC compliance tracking.

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
| Congestion (4 items) | 4/4 | 4/4 | 3/4 | 4/4 |
| Cipher suites (5 items) | 5/5 | 5/5 | 5/5 | 5/5 |
| Application layer (6 items) | 6/6 | 3/6 | 0/6 | 6/6 |
| Platform (3 items) | 2/3 | 0/3 | 1/3 | 1/3 |
| **Total (37 items)** | **36/37** | **26/37** | **23/37** | **36/37** |

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
