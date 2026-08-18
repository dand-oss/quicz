# quicz CLI

`quicz` 是独立于库的日常 QUIC / HTTP/3 开发工具包。它把 quicz 当普通包依赖引用，
库本身不内置该 CLI。

[English](README.md)

## 构建

```bash
cd cli
zig build                  # 产出 cli/zig-out/bin/quicz
zig build run -- --help
zig build test             # CLI 单元测试
```

## 子命令

```bash
# H3 请求客户端：发 GET/POST，输出状态、响应体和连接指标
quicz h3 https://127.0.0.1:4433/hello.txt -k
quicz h3 https://host:4433/api -k -X POST -H 'content-type: application/json' --data '{"ok":true}' --timeout-ms 15000

# H3 静态文件服务：目录 + /metrics
quicz serve --dir ./dist --port 4433
quicz serve --dir ./dist --port 4433 --cert cert.pem --key key.pem

# 原始 QUIC 流 echo：验证 quicz 与外部对端的互通
quicz echo --server --port 4433
quicz echo --client 127.0.0.1 4433 --data "ping"

# 基准：握手延迟 + 单流吞吐（对端是 quicz echo --server）
quicz bench 127.0.0.1 4433 --size 1048576
```

## 边界

- H3 客户端和服务端当前只支持 IPv4 / `localhost`；`--ca` 需要绝对路径 PEM。
- `serve` 默认使用内置 loopback 测试证书；生产用 `--cert` / `--key`（P-256 PEM）。
- `bench` 以 insecure 方式连接 `echo --server`，测的是传输路径而非证书链路。
- 客户端子命令默认 10s 超时（`--timeout-ms`），连不上或服务端卡住会直接失败，不挂死。
