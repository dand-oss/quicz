## 与其它 QUIC 实现的功能对比

更新时间：2026-07-30。来源：各项目 README、源码审查、RFC 合规追踪。

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
| HyStart++ | draft | ❌ | ❌ | ✅ | ✅ | 慢启动 RTT 监测提前退出 |
| PTO jitter | 9002 | ❌ | ❌ | ✅ | ✅ | 防止超时同步化 |
| 快速重传 | 9002 | ✅ | ✅ | ✅ | ✅ | — |
| App-limited (RFC 8312 §5.8) | 8312 | ✅ | ✅ | ✅ | ✅ | 3×MTU 阈值 |
| 报文 pacing | 9002 | ✅ | ✅ | ✅ | ✅ | ns 精度 token bucket |
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
| 拥塞控制（8 项） | 6/8 | 6/8 | 7/8 | 8/8 |
| 密码套件（5 项） | 5/5 | 5/5 | 5/5 | 5/5 |
| 应用层（6 项） | 6/6 | 3/6 | 0/6 | 6/6 |
| 平台（3 项） | 2/3 | 0/3 | 1/3 | 1/3 |
| **合计（41 项）** | **38/41** | **28/41** | **27/41** | **41/41** |

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

测试条件：loopback UDP，单流上传，ReleaseFast 构建，ns 精度计时。

| 实现 | 语言 | 吞吐量 | 平台 | 备注 |
| --- | --- | --- | --- | --- |
| msquic | C | ~7-8 Gbps | Windows, XDP | secnetperf dashboard |
| msquic | C | ~3 Gbps | Linux, 无 XDP | Aalto 2025 thesis |
| msquic | C | ~1 Gbps | macOS, loopback | secnetperf |
| **quicz** | **Zig** | **75 MB/s (0.6 Gbps)** | **macOS, loopback** | **std.Io 线程化，CUBIC，无快照帧处理，无 GSO** |
| quic-go | Go | ~1.1 Gbps | Linux, GSO | quic-go#3670 |
| quic-go | Go | ~4 Gbps | Linux, GSO, 多流 | KIT 2025 |
| s2n-quic | Rust | ~800 MB/s | Linux, GSO/GRO | TQUIC benchmark |
| quiche | Rust | ~300-500 MB/s | Linux, 无 GSO | TQUIC benchmark |
| quinn | Rust | ~300-500 MB/s | Linux, tokio | KIT 2025 / ETH thesis |
| TQUIC | Rust | ~1-2 Gbps | Linux, GSO | TQUIC benchmark |
| lsquic | C | ~2-4 Gbps | Linux, GSO | KIT 2025 |
| picoquic | C | ~1-2 Gbps | Linux | KIT 2025 |

说明：
- quicz 当前 75 MB/s，瓶颈在 UDP 系统调用开销（sendto/recvfrom），无 GSO 批量发送。
- 其他实现的高吞吐依赖 Linux GSO/GRO（3-10x 提升）或 XDP 内核旁路。
- macOS 不支持 GSO/XDP，msquic 在 macOS loopback 下约 1 Gbps。
- 优化路径：sendmmsg 批量发送（2-3x）→ Linux GSO（3-10x）→ 多连接并行。
- 详细对比见 [benchmark.md](benchmark.md)。

## 生产环境调优

详见[生产环境调优指南](production_tuning.md)，包含推荐配置值、
PTO jitter 使用建议、拥塞控制算法选择和初始 RTT 环境调优。
