## 与其它 QUIC 实现的功能对比

更新时间：2026-07-27。来源：各项目 README、源码审查、RFC 合规追踪。

| 功能 | RFC | quic-go | quiche | s2n-quic | quicz | 差距 |
| --- | --- | --- | --- | --- | --- | --- |
| QUIC v1 传输 | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| QUIC v2 | 9369 | ✅ | ❌ | ❌ | ✅ | quiche/s2n-quic 仅 V1 |
| TLS 1.3 | 9001 | ✅(Go crypto/tls) | ✅(BoringSSL) | ✅(s2n-tls/rustls) | ✅(纯 Zig) | — |
| 0-RTT（早期数据） | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| 丢包检测与恢复 | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| 连接迁移 | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| 路径验证 | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| Retry + 地址验证 | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| 无状态重置 | 9000 | ✅ | ✅ | ✅ | ✅ | — |
| 密钥更新 | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| 版本协商 | 9368 | ✅ | ✅ | ✅ | ✅ | — |
| DATAGRAM 扩展 | 9221 | ✅ | ✅ | ✅(unstable) | ✅ | — |
| 多路径 | draft | ✅ | ❌ | ❌ | ✅ | — |
| ECN | 9000 | ✅ | ⚠️ 仅接收 | ✅ | ✅ | quiche 不发送 ECN |
| PMTU 发现 | 8899 | ✅ | ✅ | ✅ | ✅ | — |
| GSO/GRO | — | ✅ | ❌ | ✅ | ✅ | quiche 委托应用层 I/O |
| 连接池 | — | ✅ | ❌ | ❌ | ✅ | — |
| qlog | draft | ✅ | ✅(feature-gated) | ❌(event subscriber) | ✅ | — |
| Fuzz 目标 | — | ✅(OSS-Fuzz) | ✅ | ✅ | ✅ | — |
| NewReno | 9002 | ✅ | ✅ | ❌ | ✅ | s2n-quic 仅 CUBIC+BBR |
| CUBIC | 9438 | ✅ | ✅ | ✅ | ✅ | — |
| BBR | — | ✅ | ✅ | ✅ | ✅ | — |
| 报文 pacing | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| AES-128-GCM | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| AES-256-GCM | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| ChaCha20-Poly1305 | 9001 | ✅ | ✅ | ✅ | ✅ | — |
| X25519 ECDH | 8446 | ✅ | ✅ | ✅ | ✅ | — |
| X25519Kyber768（后量子） | draft | ✅ | ✅ | ✅ | ✅ | — |
| HTTP/3 | 9114 | ✅ | ✅ | ❌ | ✅ | 完整连接管理、Settings、GOAWAY、stream 状态机 |
| QPACK 静态表 | 9204 | ✅ | ✅ | ❌ | ✅ | — |
| QPACK 动态表 | 9204 | ✅ | ✅ | ❌ | ✅ | 动态表 + encoder/decoder instructions + header block |
| HTTP Datagrams | 9297 | ✅ | ❌ | ❌ | ✅ | Quarter Stream ID + payload 帧格式 |
| WebTransport | draft | ✅ | ❌ | ❌ | ✅ | 完整会话管理、uni/bidi 帧、CLOSE capsule、datagram |
| 流重置部分交付 | draft | ✅ | ❌ | ❌ | ✅ | opt-in enable_reset_partial_delivery |
| 外部互通 | — | — | — | — | ✅ 全部通过 | — |
| 纯语言 TLS（无 C 依赖） | — | ✅ | ❌ | ❌ | ✅ | — |
| FIPS 140-3 | — | ✅(Go 1.26+) | ❌ | ❌ | ❌ | 仅 quic-go |
| XDP 零拷贝 I/O | — | ❌ | ❌ | ✅(unstable) | ❌ | 仅 s2n-quic |

### 覆盖率汇总

| 指标 | quic-go | quiche | s2n-quic | quicz |
| --- | --- | --- | --- | --- |
| 传输层（19 项） | 19/19 | 14/19 | 14/19 | 19/19 |
| 拥塞控制（4 项） | 4/4 | 4/4 | 3/4 | 4/4 |
| 密码套件（5 项） | 5/5 | 5/5 | 5/5 | 5/5 |
| 应用层（6 项） | 6/6 | 3/6 | 0/6 | 6/6 |
| 平台（3 项） | 2/3 | 0/3 | 1/3 | 1/3 |
| **合计（37 项）** | **36/37** | **26/37** | **23/37** | **36/37** |

### 差距分析

**必补差距（三库都有）— 已全部关闭：**

1. ~~AES-256-GCM~~ — 已完成 (675e7ca)
2. ~~X25519Kyber768~~ — 已完成 (675e7ca)

**建议差距（2/3 有）：**

3. ~~QPACK 动态表~~ — 已完成 (c8e605c)
4. ~~完整 HTTP/3 连接管理~~ — 已完成 (a15d22d)

**可选差距（1/3 或更少）：**

5. ~~HTTP Datagrams (RFC 9297)~~ — 已完成 (da6a670)
6. ~~完整 WebTransport 会话~~ — 已完成 (a961f3e)
7. ~~流重置部分交付~~ — 已完成 (8d0ef2c)
8. FIPS 140-3 — 仅 quic-go
9. XDP 零拷贝 I/O — 仅 s2n-quic


完整传输任务矩阵见 [quic_transport_tasks.md](quic_transport_tasks.md)。

## 性能对比

测试条件：loopback UDP，单流上传，ReleaseFast 构建。

| 实现 | 语言 | 吞吐量 | 平台 | 备注 |
| --- | --- | --- | --- | --- |
| msquic | C | 1.5-2.5 GB/s | Linux | XDP/GSO，内核旁路 |
| **quicz** | **Zig** | **1.4 GB/s** | **macOS** | **线程化 std.Io，CUBIC，无 GSO** |
| s2n-quic | Rust | ~800 MB/s | Linux | GSO/GRO |
| quic-go | Go | ~400-600 MB/s | Linux | GSO |
| quiche | Rust | ~300-500 MB/s | Linux | — |
| quinn | Rust | ~300-500 MB/s | Linux | tokio async |

说明：
- quicz 在 macOS loopback（无 GSO/XDP）下达到 1.4 GB/s，接近 msquic 在 Linux 最优条件下的水平。
- msquic 的 2.5 GB/s 依赖 Linux XDP 内核旁路 + UDP_SEGMENT (GSO)，macOS 无此能力。
- 在 Linux + GSO 条件下，quicz 预期可进一步提升（sendmmsg + UDP_SEGMENT）。
- 测试方法：64 MB 单流上传，client/server 分线程，CUBIC 拥塞控制，cwnd 增长至 1.2 MB。
- 运行：`zig build run-quic-bench`
