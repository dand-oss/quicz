# H3 Runtime Wiring Design

Status: 已完成（2026-08-07，`zig build run-h3-runtime-loopback` + 1867/1867 单测通过）
Scope: 把 HTTP/3 + QPACK 接到生产 I/O runtime（`runtime.Server` / `runtime.Client`，底层 `std.Io.Threaded`）。

## 参照物差距审计

### quic-zig（endel/quic-zig）

- `H3Connection` 直接持有 `*quic_connection.Connection`，通过函数式事件 API 暴露给调用方。
- 每个 H3 连接维护 `stream_bufs`（per-stream 累积字节），`poll()` 被事件循环反复调用：识别 peer uni 流（首字节 stream type）→ 读 control/QPACK 流 → 读 bidi 请求/响应流 → 产出 `H3Event`；`recvBody()` 按需消费 DATA。
- 发送侧：`sendRequest/sendResponse` 打开 QUIC 流后直接 `stream.send.writeData(HEADERS frame)`，随后 `flushEncoderInstructions()` 把 QPACK encoder 指令发到 encoder 流。
- 关键结论：H3 是“贴着 QUIC connection 的状态机”，由 transport 事件驱动，不自己跑网络循环；跨数据报的流字节在 H3 层按 stream 缓冲。

### zttp（Kludex/zttp）

- `src/core/h3/connection.zig` 同样直接挂 `*quic_conn.Connection`，提供 `pumpAll()`：先快照当前 stream id 列表，再逐流 `pump()`（非阻塞读取、per-stream `RequestStream`/`UniStream` 缓冲、产出 `H3Event` 队列），由 adapter 在每次 transport 推进后调用。
- 明确把“control stream 先收 SETTINGS”“QPACK encoder 流先于引用它的 header block”“blocked stream 缓冲直到 insertions 到达”作为 H3 层状态机职责。
- 关键结论：事件驱动的 pull API 是生产 H3 的正确形态；阻塞在单个流上会饿死并发到达的 QPACK/control 流。

### 本仓库现状

- `src/h3/server.zig` / `src/h3/client.zig` 已经是传输无关状态机（函数指针 `openUniStream/sendOnStream/recvOnStream` + client 的 `openBidiStream`），QPACK 动态表、SETTINGS/GOAWAY、blocked stream、section ack 已闭环。
- `runtime.Server` / `runtime.Client`（`std.Io.Threaded`）已经按连接/按流投递有序字节，但只暴露阻塞式 `receiveStreamData` / `receive`；H3 状态机需要“非阻塞读 + 等任意流活动 + 按流缓冲”的驱动原语。
- `examples/h3_loopback.zig` 用手动 datagram pump 验证协议流，不是生产 runtime 接线。

## 目标

把 H3 server/client 接到生产 runtime：
1. `runtime.Server` 增加非阻塞流读、连接级 `waitStreamActivity`（事件驱动停泊，沿用 `data_sem` + futex 模式）。
2. `runtime.Client` 增加客户端 `openStream`（bidi）/ `openUniStream`（uni）、非阻塞流读、`waitStreamActivity`，drive 任务把 server 发起的 uni 流（control/QPACK）投递到流队列。
3. 新增 `src/runtime/h3_server.zig` / `src/runtime/h3_client.zig` 驱动：识别 peer uni 流类型并路由到 `processPeerControl/Encoder/DecoderStream`；bidi 请求/响应按流缓冲到完整 HEADERS，再喂给状态机的 `feedRequestBytes` / `feedResponseBytes`（blocked 时由状态机缓冲，encoder 流推进后自动重试）。
4. `runtime.Server.serveH3(options, handler)` 作为一层薄便利入口：内部 `serve()` + 每连接创建 runtime H3 驱动，transport 仍由 `runtime.Server` 单份持有。旧的独立低层服务内容已重写为走 runtime 的 `examples/h3_server.zig`（`run-h3-server`，curl 可测）。
5. 新增生产路径示例 `examples/h3_runtime_loopback.zig`，直接用 `runtime.Server` + `runtime.Client`（`std.Io.Threaded`）跑两轮动态 QPACK 请求/响应。

## 不变量（不得破坏）

- 既有 `runtime.Server` / `runtime.Client` 的 echo/multi-conn 成功路径不变；新增方法不改变现有 API 语义。
- 状态机侧的 SETTINGS 先行、QPACK capacity 协商、blocked stream 限额、section ack/KRC 推进全部保留。
- 每连接仍单 owner；H3 驱动在 handler 任务内同步驱动，不新增引用计数。
- 写路径只经 runtime 的 `sendStreamData` / `openUniStreamRequest` / drive 任务，不绕过 runtime 直接操作 connection。

## 验证矩阵

- `zig build test --summary all`：全量单测。
- `zig build run-h3-runtime-loopback`：`runtime.Server` + `runtime.Client` 真实 UDP，两轮 200、KRC 追平、pending/protected 归零。
- `zig fmt --check build.zig src examples`：格式。
