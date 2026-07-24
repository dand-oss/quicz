<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.svg">
  <img alt="quicz" src="assets/logo-light.svg" width="200">
</picture>

# quicz

[English](README.md) | 简体中文

`quicz` 是一个纯 [Zig](https://ziglang.org/)（0.16）实现的 IETF QUIC 传输协议。
完整实现 RFC 9000/9001/9002，内置纯 Zig TLS 1.3 —— 无 C 依赖、无 OpenSSL、无 BoringSSL。

## 快速开始

### 服务端

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

### 客户端

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

### API 设计

三层 `Endpoint` → `Connection` → `Stream` API 与主流 QUIC 实现采用相同模式：

| 层级 | quicz | quic-go (Go) | s2n-quic (Rust) | endel/quic-zig (Zig) |
| --- | --- | --- | --- | --- |
| 端点 | `Endpoint.listen/bind/connect/accept/poll` | `Transport.Listen/Dial` | `Server::builder().start()` | `Server(Handler).run()` |
| 连接 | `Connection.openStream/acceptStream/close` | `Conn.OpenStream/AcceptStream` | `connection.open_bidirectional_stream` | `Connection.openStream` |
| 流 | `Stream.read/write/reset/close` | `Stream.Read/Write/Close` | `stream.send/receive` | `ReceiveStream.read / SendStream.write` |

调用方不接触 packet number space、traffic secret 或 CRYPTO frame。
allocator 显式传入；close 幂等；所有资源有确定性 deinit 路径。

### 低层 API

需要更精细控制时，内部模块同样公开：

```zig
const quicz = @import("quicz");

// 包级连接状态机（76K 行）
var conn = try quicz.Connection.init(allocator, .client, .{...});

// 纯 Zig TLS 1.3 握手状态机（8K 行）
const tls13 = quicz.tls13;

// 包保护：AES-128-GCM、AES-256-GCM、ChaCha20-Poly1305
const protection = quicz.protection;

// 拥塞控制：NewReno、CUBIC、BBR
const cubic = quicz.cubic;
const bbr = quicz.bbr;

// HTTP/3、QPACK、WebTransport
const h3 = quicz.h3;
const qpack = quicz.qpack;
const webtransport = quicz.webtransport;

// qlog 事件日志
const qlog = quicz.qlog;
```

## 功能覆盖

| 类别 | 覆盖率 |
| --- | --- |
| 传输层（19 项） | 19/19 — QUIC v1+v2、TLS 1.3、0-RTT、迁移、路径验证、Retry、无状态重置、密钥更新、版本协商、DATAGRAM、多路径、ECN、PMTU、GSO/GRO、连接池、qlog、fuzz |
| 拥塞控制（4 项） | 4/4 — NewReno、CUBIC、BBR、报文 pacing |
| 密码套件（5 项） | 5/5 — AES-128-GCM、AES-256-GCM、ChaCha20-Poly1305、X25519、X25519Kyber768（后量子） |
| 应用层 | HTTP/3（基础）、QPACK 静态表、WebTransport（基础） |
| 外部互通 | ✅ quic-go、quiche、s2n-quic — 握手 + 传输全部验证 |
| 测试 | 1696 个单元测试，零泄漏 |

完整对比见[传输任务矩阵](docs/zh-CN/quic_transport_tasks.md)。

## 构建与测试

需要 Zig **0.16.0**。

```sh
zig build                                    # 构建库
zig build test --summary all                 # 1696 个单元测试
zig build run-tls13-udp-loopback             # TLS 1.3 UDP 回环
zig build run-interop-client-standalone      # 互通自测
zig fmt --check build.zig src examples       # 格式检查
```

## 添加依赖

```bash
zig fetch --save git+https://github.com/venjiang/quicz
```

然后在 `build.zig` 中：

```zig
const quicz_dep = b.dependency("quicz", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("quicz", quicz_dep.module("quicz"));
```

## 项目结构

| 路径 | 说明 |
| --- | --- |
| `src/quic/api.zig` | **高层 API** — Endpoint / Connection / Stream |
| `src/quic/connection.zig` | 连接状态机（76K 行） |
| `src/quic/endpoint.zig` | 端点路由、CID 注册、ECN 策略 |
| `src/quic/endpoint_lifecycle.zig` | 连接生命周期管理 |
| `src/quic/udp_event_loop.zig` | UDP socket I/O（IPv4 + IPv6 双栈） |
| `src/tls/tls13.zig` | 纯 Zig TLS 1.3（8K 行，213 测试） |
| `src/tls/pq_kex.zig` | X25519Kyber768 后量子密钥交换 |
| `src/quic/protection.zig` | 包保护（AES-GCM、ChaCha20-Poly1305） |
| `src/quic/recovery.zig` | 丢包检测与恢复（RFC 9002） |
| `src/quic/cubic.zig` / `bbr.zig` | 拥塞控制器 |
| `src/h3/` | HTTP/3、QPACK、WebTransport |
| `src/qlog/` | qlog 事件日志 |
| `examples/` | 可运行示例和互通探针 |
| `docs/en/` / `docs/zh-CN/` | 设计文档和任务矩阵 |

## 许可证

MIT。见 [LICENSE](LICENSE)。
