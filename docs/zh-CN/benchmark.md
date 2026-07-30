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

### 吞吐量（单流，loopback）

| 实现 | 语言 | 吞吐量 | 平台 | 来源 |
|---|---|---|---|---|
| msquic | C | 1.5-2.5 GB/s | Linux XDP/GSO | secnetperf |
| **quicz** | **Zig** | **~53 MB/s** | **macOS，无 GSO** | **本基准** |
| s2n-quic | Rust | ~800 MB/s | Linux GSO | TQUIC benchmark |
| quic-go | Go | 400-600 MB/s | Linux GSO | TQUIC benchmark |
| quiche | Rust | 300-500 MB/s | Linux | TQUIC benchmark |
| quinn | Rust | 300-500 MB/s | Linux, tokio | ETH thesis |

### Echo 延迟（1 KB 往返，loopback）

| 实现 | 语言 | P50 | P99 | 说明 |
|---|---|---|---|---|
| msquic | C | ~5-15 μs | ~30-50 μs | secnetperf, io_uring |
| **quicz** | **Zig** | **~766 μs** | **~5104 μs** | **std.Io 线程化，ns RTT** |
| s2n-quic | Rust | ~20-40 μs | ~80-150 μs | epoll 异步 |
| quic-go | Go | ~50-100 μs | ~200-500 μs | Go 运行时调度开销 |
| quiche | Rust | ~30-80 μs | ~100-200 μs | 单线程事件循环 |
| quinn | Rust | ~50-100 μs | ~200-400 μs | tokio 异步运行时 |

### 多流吞吐（4 并发流）

| 实现 | 语言 | 4 流聚合 | 扩展性 | 说明 |
|---|---|---|---|---|
| msquic | C | ~2-4 GB/s | 近线性 | 每流工作线程 |
| **quicz** | **Zig** | **~53 MB/s** | **共享 cwnd** | **单连接，CUBIC，ns RTT** |
| quic-go | Go | ~600-900 MB/s | 良好 | 每流 goroutine |
| s2n-quic | Rust | ~800 MB/s-1.2 GB/s | 良好 | 异步 I/O |
| quiche | Rust | ~300-500 MB/s | 有限 | 单线程 |

### 丢包恢复

| 实现 | 0% 丢包 | 1% 丢包 | 5% 丢包 | 恢复算法 |
|---|---|---|---|---|
| msquic | 1.5+ GB/s | 保持 ~70-80% | 保持 ~40-50% | BBR2/CUBIC |
| **quicz** | **~53 MB/s** | **—** | **—** | **CUBIC** |
| quic-go | 400-600 MB/s | 保持 ~60-70% | 保持 ~30-40% | CUBIC/NewReno |
| quiche | 300-500 MB/s | 保持 ~50-60% | 保持 ~25-35% | CUBIC |
| quinn | 300-500 MB/s | 保持 ~55-65% | 保持 ~30-40% | CUBIC/NewReno |

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
历史数据（~2 GB/s）在 nanoTime 使用 mach ticks 作为 ns 时测得（RTT 被低估 41.67x）。
当前吞吐量瓶颈在每包处理开销，需优化 QUIC  packet processing 路径。

## 参考

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — 腾讯多条件 QUIC 基准
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — 互通 + pcap 吞吐
- [KIT 性能全景 (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — 学术多实现对比
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — 微软 QUIC 性能工具
