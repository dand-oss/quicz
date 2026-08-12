# Changelog

## v0.1.0 (2026-08-12) — production-ready

First production-ready release. QUIC v1/v2 + pure-Zig TLS 1.3 + HTTP/3
transport, verified interoperable with three other implementations, with
monitoring, deployment docs, and a green CI.

### Interop (verified against third-party stacks)

- Full QUIC matrix: forward 9/9 + reverse 4/4 against quic-go (Go),
  quiche (Rust), s2n-quic (Rust), quinn (Rust) — handshake, transfer,
  certificate-verified echo, QUIC-Interop-Runner scenarios
  (multiconnect / keyupdate / v2 / chacha20).
- HTTP/3 bidirectional against go quic-go `http3`: forward (go client →
  quicz server) and reverse (quicz client → go server) — GET /,
  GET /stream, POST /echo, dynamic-table QPACK.

### Fixes (cross-implementation validation)

- TLS 1.3: tolerate unsupported key-share groups (RFC 8446 §4.2.8) and
  early_data without PSK (RFC 9001 §4.5).
- QPACK: use the RFC 9204 Appendix A static table (not the HPACK one);
  4-bit literal-name prefix (RFC 9204 §4.5.6).
- Runtime: cap outbound QUIC packets at standard MTU (`send_mtu`, 1350)
  while keeping the 8192-byte receive allowance — jumbo datagrams
  inflated RTT samples into a congestion/pacer feedback loop that
  stalled connections at 256 streams / 64 MB.
- Examples: share one complete loopback certificate; port macOS-only
  benchmarks to Linux.

### Monitoring & ops

- `Server.metricsSnapshot()` aggregates per-connection stats (stream
  bytes, in-flight, smoothed RTT/RTTVAR, congestion window, cumulative
  loss/retransmissions) for monitoring endpoints.
- `GET /metrics` example endpoint on the H3 server.
- Deployment guide (en + zh-CN): certificates, scaling, monitoring,
  troubleshooting.

### CI

- Green on macOS (1883 unit tests) and Linux (interop matrix, HTTP/3
  interop both directions, fuzz regression, stability guard,
  multi-client throughput).
- Interop matrix split per peer with memory diagnostics; leftover-server
  sweep between cases.

### Known limits

- The X25519Kyber768 post-quantum KEM is available as a standalone module
  (`pq_kex.zig`) but is not wired into the TLS 1.3 handshake.
- Linux x86_64: use RSA certificates (Zig 0.16 `std.crypto` has a
  P-256/Ed25519 signature-verification codegen bug on that arch).
- Long high-throughput loopback/container runs progressively slow as
  socket queuing inflates RTT samples (platform characteristic; real
  networks with normal RTT are unaffected).