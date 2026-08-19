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

## 安装

在仓库根目录构建 Release 二进制并安装到 PATH：

```bash
make install                        # 安装到 /usr/local/bin/quicz
make install PREFIX="$HOME/.local"  # 或任意可写前缀
```

`make install` 使用 `-Doptimize=ReleaseFast` 构建，并把独立二进制安装到
`$(PREFIX)/bin/quicz`。用 `make uninstall` 卸载。

## 子命令

```bash
# H3 请求客户端：发 GET/POST，输出状态、响应体和连接指标
quicz h3 https://127.0.0.1:4433/hello.txt -k
quicz h3 https://host:4433/api -k -X POST -H 'content-type: application/json' --data '{"ok":true}' --timeout-ms 15000
quicz h3 https://host/api -d 'a=1&b=2'             # -d 隐含 POST + 表单 content-type
quicz h3 https://host/api -A 'my-agent/1.0'        # 自定义 User-Agent（默认 quicz/0.1.0）
quicz h3 https://host/api --resolve host:443:127.0.0.1   # 强制 host 指向指定 IPv4
quicz h3 https://host/api -v                      # verbose：DNS/连接/重定向追踪
quicz h3 https://host/api --max-time 30            # 整个请求超时（秒）
quicz h3 https://host/api --connect-timeout 5      # 握手超时（秒）
quicz h3 https://host/api -i -L -s -f -o resp.html # 响应头、重定向、静默、4xx/5xx 失败、保存正文
quicz h3 https://host/api -I                          # HEAD 请求，只要响应头
quicz h3 https://host/api -X POST --data @body.json   # 从文件读取请求体上传
quicz h3 https://host/api -D headers.txt              # 把响应头保存到文件
quicz h3 https://host/api -o -                        # 显式把正文写到 stdout

# H3 静态文件服务：目录 + /metrics + /echo
quicz serve --dir ./dist --port 4433
quicz serve --dir ./dist --port 4433 --cert cert.pem --key key.pem
quicz serve --dir ./dist --index index.htm         # 自定义索引文件（默认 index.html）
quicz h3 https://127.0.0.1:4433/echo -k -d 'ping'    # /echo 回显 method/path/authority/body

# 原始 QUIC 流 echo：验证 quicz 与外部对端的互通
quicz echo --server --port 4433
quicz echo --client 127.0.0.1 4433 --data "ping"

# 基准：握手延迟 + 单流吞吐（对端是 quicz echo --server）
quicz bench 127.0.0.1 4433 --size 1048576
```

## 线上 H3 验证

`h3` 子命令已针对真实线上 HTTP/3 服务器做端到端验证（QUIC 握手 + HTTP/3 + QPACK），
随后再跑一次本地 `serve` 回环：

```bash
../scripts/cli_h3_live_test.sh                  # 线上服务器 + 本地回环
../scripts/cli_h3_live_test.sh --skip-live      # 只跑本地回环
```

线上目标为 `https://cloudflare-quic.com/` 和 `https://www.fastly.com/`；
每次必须返回 `HTTP/3 200` 且正文非空。直接命令效果相同：

```bash
./zig-out/bin/quicz h3 https://cloudflare-quic.com/ --timeout-ms 25000
# HTTP/3 200
# <完整响应正文>
```

Cloudflare 边缘会在请求/响应流的首个 HEADERS 帧前插入 GREASE 帧（RFC 9114 §7.2.8）。
runtime 解析器在扫描 HEADERS 时会跳过保留帧类型与未知帧类型（RFC 9114 §9）。
回归测试覆盖双向：

- `src/h3/client.zig` - "H3Client skips GREASE frames before response HEADERS"
- `src/h3/server.zig` - "H3Server skips GREASE frames before request HEADERS"

## 证书校验

`h3` 默认使用系统 CA 包校验服务器证书。用 `-k` 跳过校验，或用
`--ca /绝对路径.pem` 信任自定义 CA：

```bash
./zig-out/bin/quicz h3 https://cloudflare-quic.com/          # 默认用系统 CA 校验
./zig-out/bin/quicz h3 https://host/api -k                   # 跳过校验
./zig-out/bin/quicz h3 https://host/api --ca /abs/ca.pem     # 信任指定 CA
```

系统 CA 从 `/etc/ssl/cert.pem`（macOS、Debian/Ubuntu）、
`/etc/ssl/certs/ca-certificates.crt` 或 `/etc/pki/tls/certs/ca-bundle.crt` 加载。
找不到系统 CA 时禁用校验并打印警告。

## 请求选项

- `-d` / `--data` 发送请求体并隐含 `POST` 与 `content-type: application/x-www-form-urlencoded`；
  `--data @file` 从文件读取请求体。
- `-A` / `--user-agent` 覆盖默认 `User-Agent: quicz/0.1.0`；会替换任何
  `-H user-agent:` 头。
- `--resolve host:port:addr` 为指定 host/port 覆盖 DNS（仅 IPv4），适合拿真实
  域名测试本地服务。
- `--connect-timeout` / `--connect-timeout-ms` 只限制 QUIC 握手；
  `--max-time` / `--timeout-ms` 限制整个请求（默认 10s）。
- `-v` / `--verbose` 在 stderr 输出 DNS 解析、连接、重定向和请求行。
- `-o -` 把响应体写到 stdout；其他 `-o` 路径写入文件。

`serve` 在子目录没有索引文件时会生成目录列表，`--index FILE` 可指定目录请求
使用的索引文件名。

## 边界

- H3 客户端和服务端当前只支持 IPv4 / `localhost`；`--ca` 需要绝对路径 PEM。
- `serve` 默认使用内置 loopback 测试证书；生产用 `--cert` / `--key`（P-256 PEM）。
- `bench` 以 insecure 方式连接 `echo --server`，测的是传输路径而非证书链路。
- 客户端子命令默认 10s 超时（`--timeout-ms`），连不上或服务端卡住会直接失败，不挂死。
