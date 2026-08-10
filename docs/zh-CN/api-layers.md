# quicz API 分层

quicz 暴露四层 API。大多数应用只用到最上面两层；底层用于自定义协议、基准测试，以及把 quicz 嵌入自建事件循环。这与主流 QUIC 库（s2n-quic / quic-go / quinn / quiche / msquic / quic-zig）的分层方式一致（文末对照表）。

## 层 1 — HTTP/3 运行时（开箱即用）

`runtime.Server.serveH3` + `runtime.Client` + `runtime.h3_server` /
`runtime.h3_client`。完整 HTTP/3 + QPACK 服务，无需任何传输层代码。

```zig
var server = try Server.init(allocator, io, .{
    .port = 4433, .alpn = &.{"h3"},
    .cert_der = &certificate_der, .private_key = &server_private_key,
});
defer server.deinit();
try server.serveH3(.{}, handler); // handler: fn (DecodedRequest) Response
```

handler 返回 `Response`（无 body / 缓冲 body / 流式 `ResponseBody`），接收请求体，运行时处理 QPACK 动态表、控制流与流控。见 `getting-started.md` §3–4。

## 层 2 — 运行时传输（自定义流协议）

`runtime.Server.serve` + `runtime.Client` 用于非 HTTP 协议（std.http 每连接 handler 模型）。

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

客户端：`connect()` → 流上 `send`/`receive`、`openUniStream` / `sendOnStream`（服务端推送）、`openStream`（双向）。见 `getting-started.md` §5 和 §7。

## 层 3 — TLS 端点（多连接握手）

`Tls13ServerEndpoint` / `Tls13ClientEndpoint` + `Tls13ServerTransport` /
`Tls13ClientTransport`。绑定到多连接端点的 TLS 1.3 握手，不含运行时的 socket 循环。`runtime.Server` 构建在 `Tls13ServerEndpoint` 之上；可在自建事件循环中直接驱动它，仍获得完整 TLS 握手 + 传输。

## 层 4 — sans-IO 传输

`Connection` + `endpoint_types` + `EndpointConnectionLifecycle` /
`EndpointConnectionRegistry`。纯 QUIC 状态机，**无 TLS、无 socket I/O**：你喂入数据报、轮询输出。这是 quiche / zttp 风格——interop 客户端、基准测试、XDP/GSO 实验的基础。

```zig
const action = lifecycle.feedDatagram(&scratch, path, data, &[_]u8{}, &.{ .v1 }) catch ...;
switch (action) {
    .accept_initial => |ia| { /* create record, acceptInitialRecord, poll responses */ },
    .routed => { /* receiveDatagramStepWithRoutePath, deliver stream data */ },
}
```

大多数 `examples/*_loopback.zig` 与 interop 工具驱动这一层。

## 选择层

| 使用场景 | 层 |
|---|---|
| HTTP/3 API 服务端 / 客户端 | 1 |
| 自定义流协议（echo、聊天、文件传输） | 2 |
| 需完整 TLS 握手的自建事件循环 | 3 |
| 基准测试、interop、sans-IO 嵌入、协议研究 | 4 |

## 与参考实现对照

| 层 | s2n-quic | quic-go | quinn | quiche | msquic | quic-zig | **quicz** |
|---|---|---|---|---|---|---|---|
| 开箱 H3 | Server + tls provider | `http3.Server/Transport` | — | `tokio-quiche` | — | `event_loop` + Handler | **`runtime.serveH3`** |
| 传输 + 自定义流 | `Connection` + streams | `quic.Transport`/`Conn` | `Endpoint` + `Connection` | `Connection` | `Registration`/`Listener`/`Connection` | `Connection` + manager | **`runtime.serve`/`Client`** |
| sans-IO | `s2n-quic-core`/`dc` | — | `quinn-proto` | `Config` + `Connection` | 顶层对象 | `Connection` 自驱 | **`Connection` + `endpoint_types` + `EndpointConnectionLifecycle`** |

quicz 的分层符合主流：开箱 HTTP/3 层叠在运行时传输层之上，底层是 sans-IO 核心。与 quic-go / quinn / s2n-quic 的主要差异是 quicz 运行时为单线程事件循环（同 quiche 与 quic-zig），而非每连接 task 生成器；见 `production_tuning.md`“运行时部署”。