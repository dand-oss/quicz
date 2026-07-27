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

| 实现 | 语言 | Loopback 吞吐（约） | 来源 |
|---|---|---|---|
| quicz | Zig | ~1444 MB/s | 本基准（线程化，macOS loopback） |
| quic-go | Go | ~200-400 MB/s | TQUIC benchmark |
| quiche | Rust | ~300-500 MB/s | TQUIC benchmark |
| s2n-quic | Rust | ~400-800 MB/s | TQUIC benchmark |
| msquic | C | ~1-2 GB/s | secnetperf |

说明：
- 直接对比困难，因测量方法、平台、配置不同。
- quicz 使用内存连接模型（无内核旁路），loopback UDP 开销适用。
- Go/Rust 实现在 Linux 上受益于零拷贝 sendmsg 和 GSO。
- quicz 的 160 MB/s 对于纯 Zig 实现（无平台特定 I/O 优化）具有竞争力。

## 计划中的基准

- [ ] Echo 延迟（P50/P99，需隔离 socket 对）
- [ ] 多流并发（1/2/4/8/16 流）
- [ ] DATAGRAM 吞吐（RFC 9221）
- [ ] 丢包恢复（tc netem 1%/5% 丢包）
- [ ] CPU 占用（perf stat / Instruments）
- [ ] 外部互通吞吐（quic-go/quiche/s2n-quic peer）

## 参考

- [TQUIC Benchmark](https://tquic.net/docs/further_readings/benchmark/) — 腾讯多条件 QUIC 基准
- [QUIC Interop Runner](https://github.com/quic-interop/quic-interop-runner) — 互通 + pcap 吞吐
- [KIT 性能全景 (2025)](https://doc.tm.kit.edu/2025-Examining-the-Heterogeneous-Throughput-Performance-Landscape-of-QUIC-Implementations-Koenig-et-al.pdf) — 学术多实现对比
- [secnetperf](https://github.com/microsoft/msquic/tree/main/src/perf) — 微软 QUIC 性能工具
