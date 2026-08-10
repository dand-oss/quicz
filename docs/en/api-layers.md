# quicz API Layers

quicz exposes four layers. Most applications only touch the top two; the
lower layers exist for custom protocols, benchmarks, and embedding quicz in
a bespoke event loop. This mirrors how the reference QUIC stacks split their
APIs (comparison table at the end).

## Layer 1 — HTTP/3 runtime (turnkey)

`runtime.Server.serveH3` + `runtime.Client` + `runtime.h3_server` /
`runtime.h3_client`. A full HTTP/3 + QPACK service with no transport code.

```zig
var server = try Server.init(allocator, io, .{
    .port = 4433, .alpn = &.{"h3"},
    .cert_der = &certificate_der, .private_key = &server_private_key,
});
defer server.deinit();
try server.serveH3(.{}, handler); // handler: fn (DecodedRequest) Response
```

Handlers return `Response` (bodyless / buffered body / streamed `ResponseBody`),
receive request bodies, and the runtime handles QPACK dynamic tables, control
streams, and flow control. See `getting-started.md` §3–4.

## Layer 2 — runtime transport (custom stream protocols)

`runtime.Server.serve` + `runtime.Client` for non-HTTP protocols over QUIC
streams (std.http per-connection handler model).

```zig
fn echoHandler(conn: runtime_server.ServerConnection) std.Io.Cancelable!void {
    var c = conn;
    while (true) {
        var stream = c.acceptStream() catch return;
        var buf: [65536]u8 = undefined;
        while (true) {
            const n = stream.receive(&buf) catch return;
            if (n == 0) break;
            stream.send(buf[0..n], false) catch return;
        }
    }
}
try server.serve(&echoHandler);
```

Client side: `connect()` → `send`/`receive` on streams, `openUniStream` /
`sendOnStream` for server pushes, `openStream` for bidirectional. See
`getting-started.md` §5 and §7.

## Layer 3 — TLS endpoints (multi-connection handshake)

`Tls13ServerEndpoint` / `Tls13ClientEndpoint` + `Tls13ServerTransport` /
`Tls13ClientTransport`. The TLS 1.3 handshake bound to a multi-connection
endpoint, without the runtime's socket loop. `runtime.Server` is built on
`Tls13ServerEndpoint`; you can drive it directly for a custom event loop that
still wants the full TLS handshake + transport.

## Layer 4 — sans-IO transport

`Connection` + `endpoint_types` + `EndpointConnectionLifecycle` /
`EndpointConnectionRegistry`. Pure QUIC state machines with **no TLS and no
socket I/O**: you feed datagrams and poll output. This is the quiche / zttp
style — the base for interop clients, benchmarks, and XDP/GSO experiments.

```zig
const action = lifecycle.feedDatagram(&scratch, path, data, &[_]u8{}, &.{ .v1 }) catch ...;
switch (action) {
    .accept_initial => |ia| { /* create record, acceptInitialRecord, poll responses */ },
    .routed => { /* receiveDatagramStepWithRoutePath, deliver stream data */ },
}
```

Most `examples/*_loopback.zig` and the interop tools drive this layer.

## Choosing a layer

| Use case | Layer |
|---|---|
| HTTP/3 API server / client | 1 |
| Custom stream protocol (echo, chat, file transfer) | 2 |
| Custom event loop with full TLS handshake | 3 |
| Benchmarks, interop, sans-IO embedding, protocol research | 4 |

## Comparison with reference implementations

| Layer | s2n-quic | quic-go | quinn | quiche | msquic | quic-zig | **quicz** |
|---|---|---|---|---|---|---|---|
| Turnkey H3 | Server + tls provider | `http3.Server/Transport` | — | `tokio-quiche` | — | `event_loop` + Handler | **`runtime.serveH3`** |
| Transport + custom stream | `Connection` + streams | `quic.Transport`/`Conn` | `Endpoint` + `Connection` | `Connection` | `Registration`/`Listener`/`Connection` | `Connection` + manager | **`runtime.serve`/`Client`** |
| Sans-IO | `s2n-quic-core`/`dc` | — | `quinn-proto` | `Config` + `Connection` | top-level objects | `Connection` self-driven | **`Connection` + `endpoint_types` + `EndpointConnectionLifecycle`** |

quicz's layering matches the mainstream: a turnkey HTTP/3 layer on top of a
runtime transport layer, with a sans-IO core underneath. The main difference
from quic-go / quinn / s2n-quic is that quicz's runtime is a single-threaded
event loop (like quiche and quic-zig) rather than a per-connection task
spawner; see `production_tuning.md` "Runtime Deployment".