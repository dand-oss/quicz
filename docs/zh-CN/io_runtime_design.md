# quicz I/O 运行时设计

## 背景与目标

quicz 的协议层是**状态机库**：`Connection` / `EndpointConnectionLifecycle` / `EndpointConnectionRegistry` 都不持有 socket / I/O / 线程，I/O 由调用方驱动。要成为**完整的 QUIC 库**，需要一层 **I/O 运行时**：拥有 socket、驱动连接、管理生命周期、提供 **streaming 应用接口**。

**定位**：I/O 运行时是**库完整性基础设施**，不是吞吐优化。实测吞吐受单核包处理 CPU 限制（服务端容量 ~900 MB/s），I/O 模型变更（同步/异步/分区）仅 ~1.2x 收益；线性扩展需多核并行包处理（多 worker 分区）。

## 设计

quicz 已有 `Tls13ServerEndpoint`/`Tls13ClientEndpoint`（封装握手 + DCID 路由），I/O 运行时给它们加上 **streaming 外壳**：

- **I/O 层**：std.Io（跨平台，Linux io_uring/sendmmsg、macOS kqueue 自动适配，不引第三方依赖）。
- **驱动模型**：std.Io 异步（`Group.concurrent` 任务 + `Condition` 协调）。
- **应用接口**：**streaming 模型**（accept / receive / send）——应用通过 streaming API 处理连接，**不是 callback 回调**。

### 应用接口（async streaming handler）

应用通过 streaming API 处理连接（异步 I/O 方式）：`accept()` 接纳连接，`receiveStreamData()` 收流数据，`sendStreamData()` 发流数据。这些调用与驱动任务**并发**（std.Io 线程池），通过 `Condition` 协调。这是 quicz 的「handler」——异步 streaming 接口，而非 callback。

## API 设计（async streaming）

```zig
// Server 运行时（std.Io 异步驱动）
const Server = struct {
    pub fn init(alloc, io, config) !Server;        // 绑定 socket，初始化连接管理
    pub fn drive(self) Cancelable!void;            // 连接驱动任务（跑在 Group.concurrent）：
                                                   //   recv → endpoint 处理 → 推队列 → Condition.signal
    // streaming API（应用调用，与 drive 任务并发，Condition 协调）
    pub fn accept(self) !u64;                      // 接纳连接，返回 connection id
    pub fn receiveStreamData(self, conn_id, buf) !usize;   // 收流数据（等待驱动任务推数据）
    pub fn sendStreamData(self, conn_id, stream_id, data) !void;  // 发流数据
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

**协调机制**：驱动任务跑在 `Group.concurrent`（std.Io 线程池），处理包（同步，CPU-bound）后把接纳的连接/流数据推入**按 connection id 分区的队列**并 `Condition.signal`；应用的 `accept`/`receiveStreamData` 在队列上 `Condition.wait`，与驱动任务并发。

## 连接驱动任务（核心）

```
drive()（Group.concurrent 任务，循环）：
1. recv：std.Io receiveTimeout 收 datagram
2. routeAndProcess：feedDatagram 按 DCID 路由；新连接握手接纳，已有连接 process
3. push：recvOnStream 读到的流数据推入对应连接队列，Condition.signal 唤醒应用
4. send：drain 连接的产出包（ACK/数据）发到对端
```

## quicz 组件复用

| 组件 | 来源 |
|---|---|
| I/O | std.Io（跨平台，标准库） |
| 连接状态机 | `Connection`（已有） |
| 连接注册/路由 | `EndpointConnectionRegistry` + `EndpointConnectionLifecycle`（已有） |
| TLS | `Tls13Backend`（已有） |

## 实现阶段

- **Phase 0（已完成）**：async streaming 单连接 server/client（`Server.drive` 驱动任务 + `accept`/`receiveStreamData`/`sendStreamData` streaming API），std.Io 异步。已验证真实握手 + echo。
- **Phase 1（多连接）**：按 connection id 分队列，`EndpointConnectionRegistry` 路由接纳多连接；完整双向 stream handle（receive/send）。
- **Phase 2（多 worker 分区，追扩展）**：连接分区到多个 std.Io worker 并行**处理包**。这是线性扩展的关键，非 I/O 运行时本身。

## 与吞吐的关系（实测结论，避免误区）

- I/O 运行时（异步/分区）仅 ~1.2x 收益（已实测：Group.concurrent vs thread-per-connection）。
- 吞吐受单核包处理 CPU 限制（~900 MB/s 容量）。
- 线性扩展 = 多核包处理分区，且 loopback 测试难体现真实收益。
