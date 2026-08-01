# quicz I/O 运行时设计

## 背景与目标

quicz 当前是**协议状态机库**：`Connection` / `EndpointConnectionLifecycle` / `EndpointConnectionRegistry` 都不持有 socket / I/O / 线程，I/O 由调用方驱动。要成为**完整的 QUIC 库**（对齐 endel/quic-zig、s2n-quic、quic-go、quinn 等参考实现），需要一层 **I/O 运行时**：拥有 socket、驱动连接、管理生命周期、提供 streaming 应用接口（s2n-quic 风格）。

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
| endel/quic-zig | `Server`/`Client`（持 socket + xev 事件循环 + ConnectionManager） | `init(handler, config)` + `run()` | Handler 回调（onStreamData 等） | tick 事件循环 + 回调 |

**共同模式**（quicz 遵循）：
1. 一个 **I/O 所有者**（Transport/Endpoint/Server）持有 socket + 驱动引擎。
2. 连接通过它**接纳/发起**（Accept/connect）。
3. 连接**暴露流 API**（open/accept stream）。
4. 驱动模型随语言：Go goroutine、Rust tokio、**Zig 0.16 用 std.Io 异步**（Group.concurrent + Condition）。应用层 API 三家主流（s2n-quic/quic-go/quinn）都是 **streaming 模型**（accept/open/read/write），quicz 遵循；callback 仅 msquic（C）/endel/quic-zig。

quicz 已有 `Tls13ServerEndpoint`/`Tls13ClientEndpoint`（封装握手 + DCID 路由），I/O 运行时即给它们加上 **s2n-quic 式 streaming 外壳**（socket + std.Io 异步驱动任务 + streaming API），用 std.Io 而非 libxev/tokio。

## quicz 适配

| 组件 | endel/quic-zig | quicz |
|---|---|---|
| 事件循环/I/O | libxev（epoll/kqueue） | **std.Io（跨平台，不引第三方依赖）** |
| 连接状态机 | `connection.Connection` | `Connection`（已有） |
| 连接注册/路由 | `connection_manager.ConnectionManager` | `EndpointConnectionRegistry` + `EndpointConnectionLifecycle`（已有） |
| TLS | `tls13` | `Tls13Backend`（已有） |

quicz 用 std.Io 而非 libxev：保持跨平台（Linux io_uring/sendmmsg、macOS kqueue 由 std.Io 自动适配），不引入第三方依赖。

## API 设计（async streaming，参考 s2n-quic）

```zig
// Server 运行时（std.Io 异步驱动）
const Server = struct {
    pub fn init(alloc, io, config) !Server;        // 绑定 socket，初始化连接管理
    pub fn drive(self) Cancelable!void;            // 连接驱动任务（跑在 Group.concurrent）：
                                                   //   recv → endpoint 处理 → 推队列 → Condition.signal
    // streaming API（应用调用，与 drive 任务并发，Condition 协调）
    pub fn accept(self) !*Connection;              // 接纳连接（等待驱动任务接纳）
    pub fn receiveStreamData(self, buf) !usize;    // 收流数据（等待驱动任务推数据）
    pub fn sendStreamData(self, stream_id, data) !void;  // 发流数据
};

// Client 运行时
const Client = struct {
    pub fn init(alloc, io, config) !Client;
    pub fn connect(self) !void;                    // 握手（std.Io recv/send）
    pub fn send(self, data, fin) !u64;             // 开流并发送，返回 stream id
    pub fn receive(self, stream_id, buf) !?usize;  // 收数据
    pub fn runEchoSession(self, payload) !bool;    // 完整会话（可作为 Group.concurrent 任务）
};
```

**协调机制**：驱动任务跑在 `Group.concurrent`（std.Io 线程池），处理包（同步，CPU-bound）后把接纳的连接/流数据推入队列并 `Condition.signal`；应用的 `accept`/`receiveStreamData` 在队列上 `Condition.wait`，与驱动任务并发（std.Io 线程池调度）。

## 连接驱动任务（核心）

```
drive()（Group.concurrent 任务，循环）：
1. recv：std.Io receiveTimeout 收 datagram
2. routeAndProcess：feedDatagram 按 DCID 路由；新连接握手接纳，已有连接 process
3. push：recvOnStream 读到的流数据推入队列，Condition.signal 唤醒应用
4. send：drain 连接的产出包（ACK/数据）发到对端
```

## 实现阶段

- **Phase 0（已完成）**：async streaming 单连接 server/client（`Server.drive` 驱动任务 + `accept`/`receiveStreamData`/`sendStreamData` streaming API），std.Io 异步。已验证真实握手 + echo（SUCCESS）。
- **Phase 1（多连接）**：按 connection id 分队列，`EndpointConnectionRegistry` 路由接纳多连接；完整双向 stream handle（s2n-quic `BidirectionalStream` receive/send）。
- **Phase 2（多 worker 分区，追扩展）**：连接分区到多个 std.Io worker 并行**处理包**（msquic 模型）。这是线性扩展的关键，非 I/O 运行时本身。

## 与吞吐的关系（实测结论，避免误区）

- I/O 运行时（异步/分区）仅 ~1.2x 收益（已实测：Group.concurrent vs thread-per-connection）。
- 吞吐受单核包处理 CPU 限制（~900 MB/s 容量）。
- 线性扩展 = Phase 3 多核包处理分区，且 loopback 测试难体现真实收益。
