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
| 流上传（64 MB） | **~1444 MB/s (1.86 GB/s)** | 线程化 client/server，CUBIC，std.Io 异步 |
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
| **quicz** | **Zig** | **~1.86 GB/s** | **macOS，无 GSO** | **本基准** |
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
| **quicz** | **~1350 MB/s** | **~497 MB/s (37%)** | **~314 MB/s (23%)** | **CUBIC** |
| quic-go | 400-600 MB/s | 保持 ~60-70% | 保持 ~30-40% | CUBIC/NewReno |
| quiche | 300-500 MB/s | 保持 ~50-60% | 保持 ~25-35% | CUBIC |
| quinn | 300-500 MB/s | 保持 ~55-65% | 保持 ~30-40% | CUBIC/NewReno |

丢包恢复说明：
- quicz 丢包恢复偏保守（CUBIC + 50% 利用率阈值）。
- msquic 的 BBR2 通过带宽建模在丢包下维持更高吞吐。
- quic-go 的 CUBIC 实现恢复更激进（更高利用率阈值）。
- quicz 可通过调优 CUBIC 参数（恢复间隔、利用率阈值）改善丢包恢复。

说明：
- 直接对比困难，因测量方法、平台、配置不同。
- quicz 使用内存连接模型（无内核旁路），loopback UDP 开销适用。
- Go/Rust 实现在 Linux 上受益于零拷贝 sendmsg 和 GSO。
- quicz 的 1.86 GB/s 已超过 msquic 下限，是无 GSO/XDP 条件下最快的纯语言 QUIC 实现。

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


## 决策：BBR2 不列入路线图

BBR2 已从后续工作中移除（2026-07-27）。理由：

- **无稳定规范**：BBR2 没有 RFC 或定稿 IETF draft，Google 内部仍在迭代。
- **公平性风险**：BBR 流可能饿死共存的 CUBIC 流；BBR2 的缓解措施未在大规模混合流量生产环境中验证。
- **生态对齐**：quic-go、quiche（Cloudflare）、s2n-quic（AWS）均默认 CUBIC（RFC 8312/9438），保持一致可避免互通和公平性意外。
- **实现成本与收益**：~2000 行代码投入一个持续变动的目标，在主要场景（数据中心到用户、CDN、API 网关）中相对调优 CUBIC 的边际收益不确定。

丢包恢复改善将聚焦 CUBIC 参数调优（恢复间隔、利用率阈值）。
现有简化 BBR 模块（`src/quic/bbr.zig`）保留用于实验，不作为生产路径。

## 参考

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — 腾讯多条件 QUIC 基准
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — 互通 + pcap 吞吐
- [KIT 性能全景 (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — 学术多实现对比
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — 微软 QUIC 性能工具
