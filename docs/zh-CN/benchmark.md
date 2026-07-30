# quicz 性能基准测试

## 测试方法

secnetperf 风格微基准，测量 loopback UDP 上的原始 QUIC 传输性能。

- **协议**：QUIC v1，安装 1-RTT 密钥（绕过 TLS 握手，仅测传输层）
- **套接字**：loopback UDP，1200 字节 datagram
- **构建**：`zig build-exe -OReleaseFast`
- **平台**：Apple M 系列，macOS，Zig 0.16
- **拥塞控制**：CUBIC（RFC 8312/9438）
- **Pacer**：Token bucket，ns 精度（loopback 下 srtt ~1μs 不截断）

## 运行方式

```bash
# 内存直连基准（单线程，无 UDP 开销）
zig build-exe -OReleaseFast --dep quicz \
  -Mroot=examples/quic_bench_simple.zig -Mquicz=src/lib.zig \
  --name quicz-quic-bench-simple -femit-bin=zig-out/bin/quicz-quic-bench-simple \
  --cache-dir .zig-cache --global-cache-dir .zig-cache/global
./zig-out/bin/quicz-quic-bench-simple

# UDP loopback 基准（线程化，已知 hang bug 待修复）
zig build run-quic-bench
```

## 内存直连基准（单线程，ReleaseFast）

| 指标 | 数值 | 说明 |
|---|---|---|
| 单流上传（16 MB） | **0.29 GB/s** | 无 UDP 开销，CUBIC，cwnd=272 KB |
| Echo P50 | **8.0 μs** | 1 KB 完整 QUIC 往返（内存直连） |
| Echo P99 | **12.0 μs** | |
| Echo P99.9 | **182.1 μs** | |
| 4 流聚合（4×4 MB） | **0.26 GB/s** | 共享 cwnd |

## 吞吐量（单流，loopback）

| 指标 | 数值 | 说明 |
|---|---|---|
| 流上传（16 MB） | **~53 MB/s** | 线程化 client/server，CUBIC，ns RTT |
| 发送 datagram 数 | ~25K | 每个 1324 B，流水线 ACK 反馈 |
| 总耗时 | ~300 ms | cwnd 增长至 1.6 MB |

## Echo 延迟（1 KB 往返，loopback）

| 百分位 | 延迟 | 说明 |
|---|---|---|
| P50 | **766 μs** | 1 KB 完整 QUIC 往返（加密+发送+接收+解密+回显） |
| P99 | **5104 μs** | |
| P99.9 | **33382 μs** | |

测试：5000 次迭代，macOS loopback，ReleaseFast。

## 多流吞吐（4 并发流）

| 模式 | 4 流聚合 | 说明 |
|---|---|---|
| 内存直连（单线程） | **0.26 GB/s** | 无 UDP 开销，共享 cwnd，CUBIC |
| UDP loopback（线程化） | **~53 MB/s** | std.Io 线程化，Duration(0) 非阻塞 |

## 丢包恢复（loopback + 模拟丢包）

| 丢包率 | 吞吐量 | 保持率 | 说明 |
|---|---|---|---|
| 0% | ~53 MB/s | 100% | 基线 |
| 1% | ~5.6 MB/s | — | loopback |
| 5% | ~3.0 MB/s | — | loopback |

## 与其他 QUIC 实现对比

### 测试条件差异说明

各实现的基准测试条件差异极大，直接对比数字需谨慎：

| 因素 | 影响 |
|---|---|
| GSO/GRO（Linux） | 吞吐提升 3-10x，批量系统调用 |
| XDP（Linux 内核旁路） | 吞吐提升 2-5x，绕过内核网络栈 |
| loopback vs 物理网络 | loopback 无丢包/抖动，RTT ~1μs |
| 单线程 vs 多线程 | 多核可线性扩展 |
| 平台（macOS vs Linux） | macOS 无 GSO/XDP，系统调用开销更高 |

### 单流吞吐量

| 实现 | 语言 | 吞吐量 | 条件 | 来源 |
|---|---|---|---|---|
| msquic | C | **~7-8 Gbps** | Windows, XDP, 单连接 | msquic dashboard |
| msquic | C | **~3 Gbps** | Linux, 无 XDP, 单连接 | Aalto 2025 thesis |
| msquic | C | **~1 Gbps** | macOS, loopback | secnetperf |
| **quicz** | **Zig** | **~53 MB/s (0.4 Gbps)** | **macOS, loopback, 无 GSO** | **本基准** |
| quic-go | Go | **~1.1 Gbps** | Linux, GSO, 单流 | quic-go#3670 |
| quic-go | Go | **~4 Gbps** | Linux, GSO, 多流配对 | KIT 2025 |
| s2n-quic | Rust | **~800 MB/s** | Linux, GSO/GRO | TQUIC benchmark |
| quiche | Rust | **~300-500 MB/s** | Linux, 无 GSO | TQUIC benchmark |
| quinn | Rust | **~300-500 MB/s** | Linux, tokio, 单核受限 | KIT 2025 / ETH thesis |
| TQUIC | Rust | **~1-2 Gbps** | Linux, GSO | TQUIC benchmark |
| lsquic | C | **~2-4 Gbps** | Linux, GSO | KIT 2025 |
| picoquic | C | **~1-2 Gbps** | Linux | KIT 2025 |

### Echo 延迟（小请求往返）

| 实现 | 语言 | P50 | P99 | 条件 | 来源 |
|---|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | Linux, io_uring | secnetperf |
| **quicz** | **Zig** | **~766 μs** | **~5104 μs** | **macOS, loopback, std.Io** | **本基准** |
| s2n-quic | Rust | ~20-40 μs | ~80-150 μs | Linux, epoll | 社区基准 |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Linux | 社区基准 |
| quiche | Rust | ~30-80 μs | ~100-200 μs | Linux, 单线程 | 社区基准 |
| quinn | Rust | ~50-100 μs | ~200-400 μs | Linux, tokio | ETH thesis |

### 丢包恢复

| 实现 | 0% 丢包 | 1% 丢包 | 5% 丢包 | 算法 | 来源 |
|---|---|---|---|---|---|
| msquic | ~3 Gbps | 保持 ~70-80% | 保持 ~40-50% | CUBIC/BBR2 | ETH 2024 thesis |
| **quicz** | **~53 MB/s** | **~5.6 MB/s** | **~3.0 MB/s** | **CUBIC** | **本基准** |
| quic-go | ~1.1 Gbps | 保持 ~60-70% | 保持 ~30-40% | CUBIC | 社区基准 |
| quinn | ~300-500 MB/s | msquic 领先 50%+ | — | CUBIC | ETH 2024 thesis |

### 多流扩展

| 实现 | 4 流聚合 | 扩展性 | 来源 |
|---|---|---|---|
| msquic | ~2-4 Gbps | 近线性（每流工作线程） | msquic dashboard |
| **quicz** | **~53 MB/s** | **共享 cwnd** | **本基准** |
| quic-go | ~600-900 MB/s | 良好（每流 goroutine） | 社区基准 |
| s2n-quic | ~800 MB/s-1.2 GB/s | 良好（异步 I/O） | TQUIC benchmark |
| quinn | 单核受限 | 有限 | KIT 2025 |

### quicz 性能差距分析

quicz 当前 ~53 MB/s 与其他实现的 Gbps 级吞吐存在数量级差距，主要原因：

1. **无 GSO/GRO**：Linux 实现的 GSO 批量发送可提升 3-10x 吞吐。macOS 不支持。
2. **std.Io 事件循环开销**：每个 datagram 经过 std.Io.Threaded 的 poll() 事件循环，增加 ~10μs/包。
3. **单连接共享 cwnd**：多流共享一个拥塞窗口，限制并行度。
4. **每包处理路径未优化**：QUIC 包构建/解析、加密、帧编解码的每包 CPU 开销是主要瓶颈。

优化路径（按预期收益排序）：
1. 优化每包处理路径（减少分配、内联热路径）→ 预期 2-5x
2. 批量发送（sendmmsg / 多包合并）→ 预期 2-3x
3. Linux GSO 支持 → 预期 3-10x
4. 多连接/多路径并行 → 预期线性扩展

## 说明

- 直接对比困难，因测量方法、平台、配置不同。
- quicz 使用内存连接模型（无内核旁路），loopback UDP 开销适用。
- Go/Rust 实现在 Linux 上受益于零拷贝 sendmsg 和 GSO。
- quicz 当前 ~53 MB/s（ns 精度 RTT），性能优化进行中。
- 丢包恢复和吞吐量优化是后续重点。

## 待完成基准

- [x] 多流并发（4 流，内存直连 + UDP 线程化）
- [x] 丢包恢复（1%/5%，loopback + 100μs RTT）
- [ ] DATAGRAM 吞吐（RFC 9221，需完整握手）
- [ ] CPU 占用（perf stat / Instruments）
- [ ] 外部互通吞吐（quic-go/quiche/s2n-quic peer）
- [x] 非阻塞 receive（Duration(0) 已验证可用）

## 已知限制

Zig 0.16 的 `std.Io.Threaded` 中 `receiveTimeout(Duration(0))` 使用 `poll(timeout_ms=0)` 实现非阻塞接收。
Benchmark 使用 `Duration(0)` 非阻塞接收，`nanoTime()` 已修复为真正的纳秒精度。
当前吞吐量瓶颈在每包处理开销，需优化 QUIC packet processing 路径。

## 参考

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — 腾讯多条件 QUIC 基准
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — 互通 + pcap 吞吐
- [KIT 性能全景 (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — 学术多实现对比
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — 微软 QUIC 性能工具
