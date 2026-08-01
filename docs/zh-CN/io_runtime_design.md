# quicz I/O 运行时设计

## 背景与目标

quicz 当前是**协议状态机库**：`Connection` / `EndpointConnectionLifecycle` / `EndpointConnectionRegistry` 都不持有 socket / I/O / 线程，I/O 由调用方驱动。要成为**完整的 QUIC 库**（对齐 endel/quic-zig、s2n-quic、quic-go、quinn 等参考实现），需要一层 **I/O 运行时**：拥有 socket、驱动连接、管理生命周期、提供应用回调接口。

**定位**：I/O 运行时是**库完整性基础设施**，不是吞吐优化。实测吞吐受单核包处理 CPU 限制（服务端容量 ~900 MB/s），I/O 模型变更（同步/异步/分区）仅 ~1.2x 收益；线性扩展需多核并行包处理（Phase 3，msquic worker 模型）。

## 参考架构（endel/quic-zig `event_loop.zig`，Zig 0.16）

- **Server/Client 运行时**持有 socket + `ConnectionManager`（按 DCID 路由）+ 事件循环（libxev：epoll/kqueue）。
- **tick 循环**：`recvAllPackets → processConnections → tickAndSend → freeDeadEntries`。
- **Handler 回调接口**（comptime 校验）：`onStreamData` / `onDatagram` / `onBidiStream` / `onUniStream` / `onSessionReady` / `onSessionClosed` 等。
- 批量发送（sendmmsg/sendbatch）+ ECN 支持。
- `run()`（阻塞事件循环）/ `tick()`（单步）/ `pollDirect()`（手动 drain）/ `flush()` / `stop()`。

## 主流 QUIC 库 API 设计对比（本地源码实测）

| 库 | I/O 所有者 | 连接入口 | 连接/流 API | 驱动模型 |
|---|---|---|---|---|
| quic-go | `Transport`（持 PacketConn + 发送队列 goroutine） | `ListenAddr`/`DialAddr`；`Listener.Accept(ctx)` | `Conn.AcceptStream/OpenStream` | 阻塞 + context + goroutine |
| quinn | `Endpoint`（持 socket + tokio driver） | `Endpoint.accept()`/`connect()` | `Connection.open_bi/accept_bi` | async/future + tokio |
| endel/quic-zig | `Server`/`Client`（持 socket + xev 事件循环 + ConnectionManager） | `init(handler, config)` + `run()` | Handler 回调（onStreamData 等） | tick 事件循环 + 回调（Zig 无 async） |

**共同模式**（quicz 遵循）：
1. 一个 **I/O 所有者**（Transport/Endpoint/Server）持有 socket + 驱动引擎。
2. 连接通过它**接纳/发起**（Accept/connect）。
3. 连接**暴露流 API**（open/accept stream）。
4. 驱动模型随语言：Go goroutine、Rust tokio、**Zig 用 tick 事件循环 + 回调**（endel/quic-zig 已验证可行）。

quicz 已有 `Tls13ServerEndpoint`/`Tls13ClientEndpoint`（封装握手 + DCID 路由），I/O 运行时即给它们加上 **quic-go 式 Transport 外壳**（socket + tick 循环 + Handler 回调），用 std.Io 而非 libxev。

## quicz 适配

| 组件 | endel/quic-zig | quicz |
|---|---|---|
| 事件循环/I/O | libxev（epoll/kqueue） | **std.Io（跨平台，不引第三方依赖）** |
| 连接状态机 | `connection.Connection` | `Connection`（已有） |
| 连接注册/路由 | `connection_manager.ConnectionManager` | `EndpointConnectionRegistry` + `EndpointConnectionLifecycle`（已有） |
| TLS | `tls13` | `Tls13Backend`（已有） |

quicz 用 std.Io 而非 libxev：保持跨平台（Linux io_uring/sendmmsg、macOS kqueue 由 std.Io 自动适配），不引入第三方依赖。

## API 设计（草案，参考 endel/quic-zig）

```zig
// 应用实现 Handler 回调（comptime 校验，可选实现）
const Handler = struct {
    pub fn onStreamData(self, server, conn_id, stream_id, data, fin) void {}
    pub fn onDatagram(self, server, conn_id, data) void {}
    pub fn onNewConnection(self, server, conn_id) void {}
    pub fn onConnectionClosed(self, server, conn_id) void {}
};

// Server 运行时
const Server = struct {
    pub fn init(alloc, handler, config) !Server;   // 绑定 socket，初始化连接管理
    pub fn run(self) !void;                         // 阻塞事件循环
    pub fn tick(self) !void;                        // 单步（供嵌入其它循环）
    pub fn stop(self) void;                         // 优雅关闭
    // 主动发送（供 Handler 调用）
    pub fn sendStreamData(self, conn_id, stream_id, data, fin) !void;
    pub fn sendDatagram(self, conn_id, data) !void;
};

// Client 运行时
const Client = struct {
    pub fn init(alloc, handler, config) !Client;
    pub fn connect(self) !void;                     // 握手
    pub fn openStream(self) !u64;
    pub fn sendStream(self, stream_id, data, fin) !void;
    pub fn recvStream(self, stream_id, buf) !?usize;
    pub fn run(self) !void;
    pub fn tick(self) !void;
};
```

## tick 循环（核心，参考 endel/quic-zig）

```
1. recvAllPackets：从 socket 收所有待处理 datagram
2. routeAndProcess：按 DCID 路由到连接（EndpointConnectionRegistry/Lifecycle），
   processProtectedShortDatagram 处理；新连接则握手接纳
3. readAndCallback：recvOnStream 读数据，调用 Handler.onStreamData 等
4. pollAndSend：每个连接 pollProtectedShortDatagram 产出包，批量发送
5. serviceTimers：loss detection / PTO / idle timeout
6. freeDead：清理关闭的连接
```

## 实现阶段

- **Phase 0（最小可用）**：单连接 echo server/client，std.Io 驱动 Connection，tick 循环（recv→process→send）。验证运行时尚能驱动 Connection 完成真实握手 + 数据传输。
- **Phase 1（多连接）**：`EndpointConnectionRegistry` 按 DCID 路由，接纳多连接。
- **Phase 2（Handler 接口）**：comptime 校验的回调接口（对齐 endel/quic-zig）。
- **Phase 3（多 worker 分区，追扩展）**：连接分区到多个 std.Io worker 并行**处理包**（msquic 模型）。这是线性扩展的关键，非 I/O 运行时本身。

## 与吞吐的关系（实测结论，避免误区）

- I/O 运行时（异步/分区）仅 ~1.2x 收益（已实测：Group.concurrent vs thread-per-connection）。
- 吞吐受单核包处理 CPU 限制（~900 MB/s 容量）。
- 线性扩展 = Phase 3 多核包处理分区，且 loopback 测试难体现真实收益。
