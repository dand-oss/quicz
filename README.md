<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
  <img alt="quicz" src="assets/logo-light.svg" width="200">
</picture>

# quicz

English | [简体中文](README_zh-CN.md)

A QUIC / HTTP/3 implementation in pure Zig.

> **Current state:** Transport + application layer production-ready (36/37 features, 1793 tests,
> three-implementation interop verified). Full HTTP/3, QPACK, WebTransport, and HTTP Datagrams.
> Public APIs may still evolve.

---

## Features

- **QUIC v1 & v2** (RFC 9000 / RFC 9369) — handshake, streams, flow control, connection migration, path validation, Retry, stateless reset, key update, version negotiation, DATAGRAM, multipath, ECN, PMTUD, GSO/GRO
- **TLS 1.3** (RFC 8446 / RFC 9001) — pure Zig, no C dependencies. ECDSA P-256, X25519, X25519Kyber768 (post-quantum), AES-128-GCM, AES-256-GCM, ChaCha20-Poly1305, 0-RTT, session resumption
- **Loss Detection & Congestion Control** (RFC 9002 / RFC 9438) — NewReno, CUBIC, BBR, packet pacing
- **HTTP/3** (RFC 9114) — full connection management, SETTINGS, GOAWAY, stream state machine, QPACK static + dynamic table
- **WebTransport** (draft-ietf-webtrans-http3) — full session management, uni/bidi framing, CLOSE capsule, datagrams
- **qlog** (draft-ietf-quic-qlog) — QUIC event logging
- **External interop** — verified against quic-go (Go), quiche (Rust), s2n-quic (Rust): handshake + transfer

## Using as a Library

Add to your `build.zig.zon`:

```bash
zig fetch --save git+https://github.com/venjiang/quicz
```

Then in your `build.zig`:

```zig
const quicz_dep = b.dependency("quicz", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("quicz", quicz_dep.module("quicz"));
```

### High-level API (server)

```zig
const std = @import("std");
const quicz = @import("quicz");
const api = quicz.api;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ep = try api.Endpoint.listen(.{
        .allocator = allocator,
        .address = "0.0.0.0",
        .port = 4433,
        .cert_pem = cert_pem_bytes,
        .key_pem = key_pem_bytes,
        .alpn = &.{"hq-interop"},
    });
    defer ep.deinit();

    while (true) {
        _ = try ep.poll(100);
        var conn = (try ep.accept()) orelse continue;

        while (true) {
            var stream = (try conn.acceptStream()) orelse break;
            var buf: [4096]u8 = undefined;
            const n = try stream.read(&buf);
            try stream.write(buf[0..n], .{ .fin = true });
            stream.close();
        }
    }
}
```

### High-level API (client)

```zig
const std = @import("std");
const quicz = @import("quicz");
const api = quicz.api;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var ep = try api.Endpoint.bind(.{ .allocator = allocator });
    defer ep.deinit();

    var conn = try ep.connect(.{
        .address = "127.0.0.1",
        .port = 4433,
        .server_name = "localhost",
        .alpn = &.{"hq-interop"},
    });

    var stream = try conn.openStream();
    try stream.write("GET /index.html", .{ .fin = true });

    var buf: [8192]u8 = undefined;
    const n = try stream.read(&buf);
    std.debug.print("received {d} bytes\n", .{n});

    conn.close(0, "done");
}
```

### EndpointConfig options

| Field | Default | Description |
|---|---|---|
| `address` | `"0.0.0.0"` | Bind address |
| `port` | `0` | Bind port (0 = ephemeral) |
| `cert_pem` / `key_pem` | `null` | TLS certificate and private key (server) |
| `ca_cert_pem` | `null` | CA certificate for verification (client) |
| `insecure_skip_verify` | `false` | Skip certificate verification (testing only) |
| `alpn` | `&.{}` | ALPN protocol identifiers |
| `max_connections` | `0` | Max concurrent connections (0 = unlimited) |
| `max_streams_bidi` | `100` | Max bidirectional streams per connection |
| `max_idle_timeout_ms` | `30000` | Idle timeout in milliseconds |
| `max_datagram_size` | `1350` | Max UDP payload size |
| `initial_max_data` | `1048576` | Connection-level flow control window |
| `initial_max_stream_data` | `262144` | Per-stream flow control window |
| `enable_datagrams` | `false` | Enable QUIC DATAGRAM extension (RFC 9221) |
| `require_retry` | `false` | Require Retry for address validation (server) |
| `ipv6` | `false` | Use IPv6 dual-stack socket |

### ConnectConfig options

| Field | Default | Description |
|---|---|---|
| `address` | *(required)* | Server address |
| `port` | *(required)* | Server port |
| `server_name` | `"localhost"` | TLS SNI |
| `alpn` | `&.{}` | ALPN protocol identifiers |
| `ca_cert_pem` | `null` | CA certificate for verification |
| `insecure_skip_verify` | `false` | Skip certificate verification |
| `handshake_timeout_ms` | `10000` | Handshake timeout |

### Low-level API (direct connection control)

For applications that need fine-grained control over packet processing,
TLS backend driving, or custom endpoint routing:

```zig
const quicz = @import("quicz");

// Packet-level connection state machine
var conn = try quicz.Connection.init(allocator, .client, .{
    .initial_max_data = 65_536,
    .initial_max_streams_bidi = 16,
});
defer conn.deinit();

// TLS 1.3 handshake state machine (pure Zig)
const tls13 = quicz.tls13;

// TLS-backed transport wrappers
const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;
const Tls13ServerTransport = quicz.Tls13ServerTransport;

// Endpoint routing, CID registry, timers
const EndpointConnectionLifecycle = quicz.EndpointConnectionLifecycle;

// Packet protection: AES-128-GCM, AES-256-GCM, ChaCha20-Poly1305
const protection = quicz.protection;

// Congestion control: NewReno, CUBIC, BBR
const cubic = quicz.cubic;
const bbr = quicz.bbr;

// HTTP/3, QPACK, WebTransport
const h3 = quicz.h3;
const qpack = quicz.qpack;
const webtransport = quicz.webtransport;

// qlog event logging
const qlog = quicz.qlog;
```

The interop server (`interop/server.zig`) and client (`interop/client.zig`)
demonstrate the full low-level wiring: `Tls13ServerEndpoint` for multi-connection
server routing, `Tls13ClientEndpoint` for client handshake and stream I/O.

## Building

Requires **Zig 0.16.0**.

```bash
zig build                                    # build library
zig build test --summary all                 # 1793 unit tests
zig build run-tls13-udp-loopback             # TLS 1.3 UDP loopback
zig build run-interop-client-standalone      # interop self-test
zig fmt --check build.zig src examples       # format check
```

## Interop Testing

quicz passes certificate-verified interop against three major implementations:

```bash
# Run all three (requires Go, Rust toolchains)
examples/interop/run_external_interop.sh all

# Individual
examples/interop/run_external_interop.sh quic-go
examples/interop/run_external_interop.sh quiche
examples/interop/run_external_interop.sh s2n-quic
```

## Project Structure

| Path | Description |
|---|---|
| `src/quic/api.zig` | **High-level API** — Endpoint / Connection / Stream |
| `src/quic/connection.zig` | Connection state machine (76K lines) |
| `src/quic/endpoint.zig` | Endpoint routing, CID registry, ECN policy |
| `src/quic/endpoint_lifecycle.zig` | Connection lifecycle management |
| `src/quic/tls13_client_endpoint.zig` | Client endpoint (handshake + stream I/O) |
| `src/quic/tls13_server_endpoint.zig` | Server endpoint (multi-connection routing) |
| `src/quic/udp_event_loop.zig` | UDP socket I/O (IPv4 + IPv6 dual-stack) |
| `src/tls/tls13.zig` | Pure Zig TLS 1.3 (8K lines, 213 tests) |
| `src/tls/pq_kex.zig` | X25519Kyber768 post-quantum key exchange |
| `src/quic/protection.zig` | Packet protection (AES-GCM, ChaCha20-Poly1305) |
| `src/quic/recovery.zig` | Loss detection and recovery (RFC 9002) |
| `src/quic/cubic.zig` / `bbr.zig` | Congestion controllers |
| `src/h3/` | HTTP/3, QPACK, WebTransport |
| `src/qlog/` | qlog event logging |
| `examples/` | Runnable examples and interop probes |
| `docs/en/` / `docs/zh-CN/` | Design docs and task matrix |

## License

MIT. See [LICENSE](LICENSE).
