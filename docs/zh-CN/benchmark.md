# quicz 性能基准测试

## 测试方法

secnetperf 风格微基准，测量 loopback UDP 上的原始 QUIC 传输性能。

- **协议**：QUIC v1，安装 1-RTT 密钥（绕过 TLS 握手，仅测传输层）
- **套接字**：loopback UDP，1200 字节 datagram
- **构建**：`zig build-exe -OReleaseFast`
- **平台**：Apple M 系列，macOS，Zig 0.16

## 测试结果

| 指标 | 数值 | 说明 |
|---|---|---|
| 流上传（64 MB） | **~1444 MB/s (1.4 GB/s)** | 线程化 client/server，CUBIC，std.Io 异步 |
| 发送 datagram 数 | ~102K | 每个 1324 B，流水线 ACK 反馈 |
| 总耗时 | ~44 ms | cwnd 增长至 1.2 MB |

## 运行方式

```bash
# 构建并运行
zig build run-quic-bench

# 或直接构建 ReleaseFast 二进制
zig build-exe -OReleaseFast --dep quicz \
  -Mroot=examples/quic_bench.zig -Mquicz=src/lib.zig \
  --name quicz-quic-bench -femit-bin=zig-out/bin/quicz-quic-bench
./zig-out/bin/quicz-quic-bench
```

## 对比参考

### 吞吐量（单流，loopback）

| 实现 | 语言 | 吞吐量 | 平台 | 来源 |
|---|---|---|---|---|
| msquic | C | 1.5-2.5 GB/s | Linux XDP/GSO | secnetperf |
| **quicz** | **Zig** | **~1.4 GB/s** | **macOS，无 GSO** | **本基准** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo 延迟（1 KB 往返，loopback）

| 实现 | 语言 | P50 | P99 | 说明 |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~19 μs** | **~55-69 μs** | **std.Io 线程化** |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go 运行时调度开销 |
| quiche | Rust | ~30-80 μs | ~100-200 μs | 单线程事件循环 |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio 异步运行时 |

### 多流吞吐（4 并发流）

| 实现 | 语言 | 4 流聚合 | 扩展性 | 说明 |
|---|---|---|---|---|
| msquic | C | ~2-4 GB/s | 近线性 | 每流工作线程 |
| **quicz** | **Zig** | **~180-800 MB/s** | **共享 cwnd** | **单连接，CUBIC** |
| quic-go | Go | ~600-900 MB/s | 良好 | 每流 goroutine |
| s2n-quic | Rust | ~800 MB/s-1.2 GB/s | 良好 | 异步 I/O |
| quiche | Rust | ~300-500 MB/s | 有限 | 单线程 |

### 丢包恢复（丢包下吞吐）

| 实现 | 0% 丢包 | 1% 丢包 | 5% 丢包 | 恢复算法 |
|---|---|---|---|---|
| msquic | 1.5+ GB/s | 保持 ~70-80% | 保持 ~40-50% | BBR2/CUBIC |
| **quicz** | **~760 MB/s** | **~249 MB/s (33%)** | **~331 MB/s (43%)** | **CUBIC** |
| quic-go | 400-600 MB/s | 保持 ~60-70% | 保持 ~30-40% | CUBIC/NewReno |
| quiche | 300-500 MB/s | 保持 ~50-60% | 保持 ~25-35% | CUBIC |
| quinn | 300-500 MB/s | 保持 ~55-65% | 保持 ~30-40% | CUBIC/NewReno |

丢包恢复说明：
- quicz 丢包恢复偏保守（CUBIC + 50% 利用率阈值）。
- msquic 的 BBR2 通过带宽建模在丢包下维持更高吞吐。
- quic-go 的 CUBIC 实现恢复更激进（更高利用率阈值）。
- quicz 可通过调优 CUBIC 参数或添加 BBR 支持改善丢包恢复。

说明：
- 直接对比困难，因测量方法、平台、配置不同。
- quicz 使用内存连接模型（无内核旁路），loopback UDP 开销适用。
- Go/Rust 实现在 Linux 上受益于零拷贝 sendmsg 和 GSO。
- quicz 的 160 MB/s 对于纯 Zig 实现（无平台特定 I/O 优化）具有竞争力。

## Echo 延迟

| 百分位 | 延迟 | 说明 |
|---|---|---|
| P50 | **20.2 μs** | 1 KB 完整 QUIC 往返（加密+发送+接收+解密+回显） |
| P99 | **62.1 μs** | |
| P99.9 | **85.3 μs** | |

测试：5000 次迭代，macOS loopback，ReleaseFast。

## 计划中的基准

- [x] Echo 延迟（P50/P99）
- [ ] 多流并发（1/2/4/8/16 流）
- [ ] DATAGRAM 吞吐（RFC 9221）
- [ ] 丢包恢复（tc netem 1%/5% 丢包）
- [ ] CPU 占用（perf stat / Instruments）
- [ ] 外部互通吞吐（quic-go/quiche/s2n-quic peer）
- [ ] 完整 BBR2 实现（msquic 级丢包恢复）

## 后续工作：BBR2 拥塞控制

### 目标
达到 msquic 级丢包恢复（1% 丢包保留 70-80% 吞吐），同时维持 CUBIC 级无丢包吞吐（~1.4 GB/s）。

### 当前状态
- 现有 BBR 模块（src/quic/bbr.zig，380 行）：简化的 startup/drain/probe-RTT 阶段。
- CUBIC + PTO 恢复间隔：1% 丢包保留 33%，5% 丢包保留 43%。
- BBR 当前：丢包恢复略好（266 vs 249 MB/s），但无丢包吞吐差 5.7x。

### 差距分析（vs msquic BBR2）
| 特性 | quicz BBR | msquic BBR2 | 影响 |
|---|---|---|---|
| 带宽估计 | 基础 max 滤波 | 投递速率采样 + 窗口 max | 吞吐精度 |
| 丢包响应 | 缩减 cwnd | inflight_hi/lo，不缩窗 | 丢包恢复 |
| Startup 退出 | BtlBw 平台 | 2 轮平台 + 丢包退出 | 启动速度 |
| ProbeRTT | 固定间隔 | 自适应，近期低 RTT 跳过 | 延迟抖动 |
| Pacing | 基础速率 | 精确逐包 pacing + 定时器 | 平滑性 |
| ECN | 未集成 | CE 信号调整 inflight | 拥塞信号 |

### 实现计划（~2000 行）
1. **阶段 1：投递速率采样** — 跟踪每包 delivered bytes + time，计算 delivery rate。
2. **阶段 2：窗口 BtlBw/RTprop** — 10s max 滤波（BtlBw）+ 10s min 滤波（RTprop）。
3. **阶段 3：状态机** — Startup → Drain → ProbeBW → ProbeRTT，正确转换条件。
4. **阶段 4：丢包自适应** — inflight_hi/inflight_lo（BBR2），不做乘法缩减。
5. **阶段 5：Pacing 引擎** — 逐包发送时序，pacing_rate = BtlBw × gain。
6. **阶段 6：集成** — 接入 Connection recovery 路径，配置选项，benchmark 验证。

### 成功标准
- 1% 丢包：保留 >= 60% 吞吐（当前 33%）
- 5% 丢包：保留 >= 40% 吞吐（当前 43%，已达标）
- 无丢包：维持 >= 700 MB/s（当前 760 MB/s）
- 延迟 P99：不劣于当前 65μs

### 参考
- RFC 9438 (CUBIC) — 当前实现基线
- BBR 论文："BBR: Congestion-Based Congestion Control" (Cardwell et al., 2017)
- BBR2 草案：draft-cardwell-iccrg-bbr-congestion-control-03
- msquic BBR2：github.com/microsoft/msquic/src/core/congestion_control_bbr.c

## 参考

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — 腾讯多条件 QUIC 基准
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — 互通 + pcap 吞吐
- [KIT 性能全景 (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — 学术多实现对比
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — 微软 QUIC 性能工具
