# H3 Runtime Wiring Design

Status: 已完成（2026-08-08：runtime 接线 + 完整数据路径，`zig build run-h3-runtime-loopback` round1-4 + 1883/1883 单测通过）
Scope: 把 HTTP/3 + QPACK 接到生产 I/O runtime（`runtime.Server` / `runtime.Client`，底层 `std.Io.Threaded`），并补齐请求体读取 + 流式响应数据路径。

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

## 数据路径：请求体读取 + 流式响应（续11-13，2026-08-08）

早期接线只做到"等一个完整 HEADERS 帧 → 同步 handler 返回固定 `Response` → 一次 `sendOnStream(fin=true)` 整段发出"：请求体 DATA 帧被丢弃、响应不可分块。本轮补齐为完整 HTTP/3 数据路径，参照 quic-zig/zttp/quiche/quic-go 四家统一"HEADERS 先出 → body 帧/块流式 → fin 收尾"三段式。

### 请求体读取（server）

- `H3Server.feedRequestData(sid, data, fin)` 是流式主入口：headers 阶段累积 `RequestStream.wire` 直到完整 HEADERS 帧，QPACK 解码（blocked 时 `rs.blocked` 累积 wire，encoder 流推进后 `unblockBlockedRequests` 重试）；body 阶段把 DATA 帧 payload 聚合进 `rs.body`（跨 feed 的半帧存 `body_wire`），超 `max_request_body_size`（1 MiB）返回 `RequestBodyTooLarge` → runtime 回 413 + STOP_SENDING(H3_EXCESSIVE_LOAD)。
- runtime 驱动 `feedRequest` 按 `consumed` 收缩自己的 `request_buffers`，EOF(0) 喂空数据 + fin。

### 流式/分块响应（server）

- `Response.body_stream: ?ResponseBody`（vtable pull 迭代器 `{ctx, next_fn, deinit_fn}`，提供 `fromChunks`/`fromRepeating`）优先于 `body`。
- `startResponse` 只发 HEADERS（`encodeResponseHeaders(/WithDynamic)`，bodyless 时 fin=true 直发），有 body 注册 `ResponseStream`。
- `pumpResponses` 遍历响应，每流每次 ≤ `max_chunks_per_pump`(8) 个 ≤ `max_response_chunk_payload`(8 KiB) DATA 帧；`FlowControlBlocked` 时 static 块不推进 offset 下次重试；body 耗尽后空帧 fin 收尾并 `streamDone` 释放请求条目。

### client 对称

- 收响应：`feedResponseData` 聚合多 DATA 帧（镜像 server `feedRequestData`），`releaseResponse` 释放；runtime `receiveResponse` 走它。
- 发请求体：`sendRequestStreamed(request, body)` 发 HEADERS(fin=false) + 分块 DATA，`FlowControlBlocked` 存 `pending_sends`，`pumpSends` 重试并空帧 fin；runtime 透传并阻塞等 body 发完（credit 到达后重试）。

### 前置 bug 修复

- `runtime.Server.drainOutgoing` 对 `Connection.sendOnStream` 返回 `FlowControlBlocked` 时**无条件清空队列（丢数据）** → 保留队列 + 保持 `send_pending`，MAX_STREAM_DATA 到达（入站 datagram 唤醒 drive）后重试。

### GREASE / unknown frame interop (2026-08-18)

- Request/response streams may legitimately start with GREASE frames before
  the first HEADERS frame (RFC 9114 §7.2.8); Cloudflare's quiche edge does
  this in production. Unknown extension frame types must also be ignored
  (RFC 9114 §9).
- `feedResponseData` (client) and `feedRequestData` (server) now skip reserved
  and unknown frame types while scanning for the initial HEADERS frame; known
  frame types such as DATA still fail as `ExpectedHeadersFrame` when seen
  before HEADERS.
- Regression tests: `H3Client skips GREASE frames before response HEADERS` and
  `H3Server skips GREASE frames before request HEADERS`.
- Live E2E: `scripts/cli_h3_live_test.sh` verifies `HTTP/3 200` on
  `cloudflare-quic.com` and `www.fastly.com`, then a local serve round trip.

### 设计要点

- 状态机自持全部请求/响应字节副本（`wire`/`body_wire`/`body`），runtime 驱动只当字节搬运工，按 `consumed` 收缩自己的缓冲。
- handler 仍是同步回调（`fn(DecodedRequest) Response`），`next_fn` 必须非阻塞；`deinit_fn` 由状态机在发完或 cancel 时调用——为未来异步（producer-task）body 留 seam。
- `DecodedRequest/Response` 借用状态机缓冲，释放锚定在响应 fin 之后（`streamDone`），不可提前。

## 不变量（不得破坏）

- 既有 `runtime.Server` / `runtime.Client` 的 echo/multi-conn 成功路径不变；新增方法不改变现有 API 语义。
- 状态机侧的 SETTINGS 先行、QPACK capacity 协商、blocked stream 限额、section ack/KRC 推进全部保留。
- 每连接仍单 owner；H3 驱动在 handler 任务内同步驱动，不新增引用计数。
- 写路径只经 runtime 的 `sendStreamData` / `openUniStreamRequest` / drive 任务，不绕过 runtime 直接操作 connection。

## 验证矩阵

- `zig build test --summary all`：全量单测（1883/1883）。
- `zig build run-h3-runtime-loopback`：`runtime.Server` + `runtime.Client` 真实 UDP，round1-4 全 200（GET 动态 QPACK、POST echo 流式请求体、GET /stream 65536B 分块响应）、KRC 追平、pending/protected 归零。
- `zig build run-h3-loopback`：低层 UDP pump 回归。
- `zig build run-fuzz`：100000 iterations no crashes。
- `zig fmt --check build.zig src examples`：格式。
