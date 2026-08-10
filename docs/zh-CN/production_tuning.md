# 生产环境调优指南

更新时间：2026-08-10。

本文档介绍 quicz 在生产环境部署时的推荐配置。所有参数通过
`ConnectionConfig`（`src/quic/connection_config.zig`）设置。

## 快速参考

| 参数 | 默认值 | 生产建议值 | 说明 |
| --- | --- | --- | --- |
| `pto_jitter_percentage` | 0 | 20–30 | 防止大量并发连接 PTO 超时同步化。范围 0–50。默认 0 与上游 QUIC 实现一致；100+ 并发连接的服务器建议开启。 |
| `congestion_algorithm` | `.new_reno` | `.cubic` | CUBIC (RFC 9438) + HyStart++ 在高带宽-延迟积路径下吞吐更优。 |
| `initial_rtt_ns` | 333 ms | 按环境调整 | 数据中心：1–5 ms；广域网：50–100 ms。较低值加速初始窗口增长。 |
| `max_ack_delay_ns` | 25 ms | 25 ms | RFC 9000 默认值；除非对端协商不同值，否则不要修改。 |

## PTO Jitter

PTO jitter 在基础 Probe Timeout 上添加 ±百分比的随机抖动（指数退避之前），
用于打散多连接共享路径时的超时风暴（如 NAT 或负载均衡器后方）。

- **0%（默认）：** 确定性 PTO。适用于单连接、测试、以及不存在超时同步化问题的场景。
- **20–30%（服务器推荐）：** 足以打破同步化，同时不会明显延迟丢包恢复。
- **50%（上限）：** 激进抖动；在高丢包路径上可能延迟丢包恢复。

结果始终钳制到 RFC 9002 kGranularity 下限（1 ms）。

### 示例

```zig
var conn = try Connection.init(allocator, .server, .{
    .congestion_algorithm = .cubic,
    .pto_jitter_percentage = 25,
    .initial_rtt_ns = 5_000_000, // 数据中心 5ms
});
```

## 拥塞控制

### CUBIC + HyStart++（推荐）

CUBIC (RFC 9438) 是大多数生产 QUIC 栈的默认拥塞控制。quicz 的 CUBIC 实现包含：

- **HyStart++ 慢启动：** 监测 RTT 增长提前退出慢启动，避免带宽过冲。
  使用保守慢启动（CSS）阶段，÷4 增长，最多 5 轮后完全退出。
- **快速重传：** 拥塞事件后立即重传，无需等待 PTO。
- **App-limited 检测 (RFC 8312 §5.8)：** 排除应用受限时段对 CUBIC epoch
  的影响。使用 3×MTU 阈值避免 loopback 上的误判。
- **PTO jitter：** 可选的随机化 PTO，打散超时风暴。

### NewReno

NewReno (RFC 9002) 是默认算法。更简单但在高带宽、高延迟路径上效率较低。
适用于低吞吐控制通道或不需要 CUBIC 调优的场景。

### BBR

BBR 可用但尚未生产级加固。生产环境请使用 CUBIC。

## 初始 RTT

`initial_rtt_ns` 参数设置首次测量前的 RTT 估计值。RFC 9002 默认 333 ms。
根据环境调整可加速初始窗口增长：

| 环境 | 推荐 `initial_rtt_ns` |
| --- | --- |
| 数据中心（同机架） | 100_000–500_000（0.1–0.5 ms） |
| 数据中心（跨机架） | 1_000_000–5_000_000（1–5 ms） |
| 城域 / CDN 边缘 | 10_000_000–30_000_000（10–30 ms） |
| 广域网 / 跨洲 | 50_000_000–150_000_000（50–150 ms） |
| 未知 / 公网 | 333_000_000（333 ms，默认） |

## 运行时部署

`runtime.Server` / `runtime.Client`（`std.Io.Threaded`）自动处理报文 I/O、路由与流交付。部署注意：

- **Linux 上发送批量自动生效**：`drainOutgoing` 把排空的报文收集进 `OutgoingMessage[]` 并调用 `socket.sendMany`，Threaded 后端用 `sendmmsg` 实现；macOS 无 `sendmmsg` 保持逐包发送。无需配置。
- **接收缓冲池化**：recv task 从 16 项缓冲池取 buffer（而非每报文分配），耗尽回退分配器。自动生效。
- **SO_RCVBUF 提升到 4 MB**（server + client socket），避免客户端突发在 drive 排空前溢出内核接收缓冲；丢包恢复仍兜底余下丢弃。
- **空闲超时**：`max_idle_timeout_ms`（runtime 默认 30s）关闭停止发送的连接；按 keep-alive 需求调整。
- **并发模型**：每个 `Server` 一个 drive task 串行处理所有连接（单线程事件循环，与 s2n-quic / quiche / quic-zig 相同）。单连接内多流并发已被利用（多流吞吐超过单流）。要跨核扩展多连接聚合吞吐，需在独立 socket/端口跑多个 `Server` 实例（SO_REUSEPORT 未打通 Zig std 的 `IpAddress.bind`，当前用不同端口或负载均衡）。
- **绑定地址**：`Server.Config.bind_addr` 默认 `127.0.0.1`；设 `.{0,0,0,0}` 接受远程客户端。
- **Linux x86_64 证书**：用 RSA 证书（Zig 0.16 `std.crypto` 在 x86_64 有 P-256/P-384/Ed25519 签名验证代码生成 bug）；aarch64 与 macOS 用 ECDSA 正常。

## 相关文档

- [功能对比](feature_comparison.md) — 与其它 QUIC 实现的能力矩阵
- [性能基准](benchmark.md) — 吞吐和延迟数据
- [架构](architecture.md) — 模块布局与设计决策
