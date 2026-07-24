# quicz

English | [简体中文](README_zh-CN.md)

`quicz` is a production-grade IETF QUIC transport implementation in pure
[Zig](https://ziglang.org/) (0.16). It implements RFC 9000/9001/9002 with a
pure-Zig TLS 1.3 stack — no C dependencies, no OpenSSL, no BoringSSL.

## Quick start

### Server

```zig
const quicz = @import("quicz");
const api = quicz.api;

pub fn main() !void {
    var ep = try api.Endpoint.listen(.{
        .allocator = gpa,
        .address = "0.0.0.0",
        .port = 4433,
        .cert_pem = cert_bytes,
        .key_pem = key_bytes,
        .alpn = &.{"h3"},
    });
    defer ep.deinit();

    while (true) {
        _ = try ep.poll(100);
        var conn = (try ep.accept()) orelse continue;
        var stream = (try conn.acceptStream()) orelse continue;

        var buf: [4096]u8 = undefined;
        const n = try stream.read(&buf);
        try stream.write(buf[0..n], .{ .fin = true });
        stream.close();
    }
}
```

### Client

```zig
const quicz = @import("quicz");
const api = quicz.api;

pub fn main() !void {
    var ep = try api.Endpoint.bind(.{ .allocator = gpa });
    defer ep.deinit();

    var conn = try ep.connect(.{
        .address = "127.0.0.1",
        .port = 4433,
        .server_name = "localhost",
        .alpn = &.{"h3"},
    });

    var stream = try conn.openStream();
    try stream.write("GET /", .{ .fin = true });

    var buf: [4096]u8 = undefined;
    const n = try stream.read(&buf);
    std.debug.print("{s}\n", .{buf[0..n]});

    conn.close(0, "done");
}
```

### API design

The three-layer `Endpoint` → `QuicConn` → `QuicStream` API follows the
same pattern used by mature QUIC implementations:

| Layer | quicz | quic-go (Go) | s2n-quic (Rust) | endel/quic-zig (Zig) |
| --- | --- | --- | --- | --- |
| Endpoint | `Endpoint.listen/bind/connect/accept/poll` | `Transport.Listen/Dial` | `Server::builder().start()` | `Server(Handler).run()` |
| Connection | `QuicConn.openStream/acceptStream/close` | `Conn.OpenStream/AcceptStream` | `connection.open_bidirectional_stream` | `Connection.openStream` |
| Stream | `QuicStream.read/write/reset/close` | `Stream.Read/Write/Close` | `stream.send/receive` | `ReceiveStream.read / SendStream.write` |

Callers never see packet number spaces, traffic secrets, or CRYPTO frames.
Allocator is explicit; close is idempotent; all resources have deterministic
deinit paths.

### Lower-level APIs

For applications that need fine-grained control, the internal modules are
also public:

```zig
const quicz = @import("quicz");

// Packet-level connection state machine (76K lines)
var conn = try quicz.Connection.init(allocator, .client, .{
    .initial_max_data = 65_536,
    .initial_max_streams_bidi = 16,
});

// TLS 1.3 handshake state machine (pure Zig, 8K lines)
const tls13 = quicz.tls13;

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

## Features

| Category | Coverage |
| --- | --- |
| Transport (19 items) | 19/19 — QUIC v1+v2, TLS 1.3, 0-RTT, migration, path validation, Retry, stateless reset, key update, version negotiation, DATAGRAM, multipath, ECN, PMTU, GSO/GRO, connection pool, qlog, fuzz |
| Congestion (4 items) | 4/4 — NewReno, CUBIC, BBR, packet pacing |
| Cipher suites (5 items) | 5/5 — AES-128-GCM, AES-256-GCM, ChaCha20-Poly1305, X25519, X25519Kyber768 (post-quantum) |
| Application layer | HTTP/3 (basic), QPACK static, WebTransport (basic) |
| External interop | ✅ quic-go, quiche, s2n-quic — all handshake + transfer verified |
| Tests | 1696 unit tests, zero leaks |

Full comparison: [transport task matrix](docs/en/quic_transport_tasks.md).

## Build and test

Requires Zig **0.16.0**.

```sh
zig build                                    # build library
zig build test --summary all                 # 1696 unit tests
zig build run-tls13-udp-loopback             # TLS 1.3 UDP loopback
zig build run-interop-client-standalone      # interop self-test
zig fmt --check build.zig src examples       # format check
```

## Adding as a dependency

```zig
// build.zig.zon
.dependencies = .{
    .quicz = .{ .path = "../quicz" },
},

// build.zig
const quicz_dep = b.dependency("quicz", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("quicz", quicz_dep.module("quicz"));
```

## Project structure

| Path | Description |
| --- | --- |
| `src/quic/api.zig` | **High-level API** — Endpoint / QuicConn / QuicStream |
| `src/quic/connection.zig` | Connection state machine (76K lines) |
| `src/quic/endpoint.zig` | Endpoint routing, CID registry, ECN policy |
| `src/quic/endpoint_lifecycle.zig` | Connection lifecycle management |
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
