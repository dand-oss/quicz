# quicz CLI

`quicz` is a standalone QUIC / HTTP/3 development tool for daily work. It
references the quicz library as a normal package dependency; the library itself
does not bundle this CLI.

[简体中文](README_zh-CN.md)

## Build

```bash
cd cli
zig build                  # produces cli/zig-out/bin/quicz
zig build run -- --help
zig build test             # CLI unit tests
```

## Subcommands

```bash
# H3 request client: GET/POST, prints status, response body and connection metrics
quicz h3 https://127.0.0.1:4433/hello.txt -k
quicz h3 https://host:4433/api -k -X POST -H 'content-type: application/json' --data '{"ok":true}'

# H3 static file server: directory + /metrics
quicz serve --dir ./dist --port 4433
quicz serve --dir ./dist --port 4433 --cert cert.pem --key key.pem

# Raw QUIC stream echo: verify quicz interop with external peers
quicz echo --server --port 4433
quicz echo --client 127.0.0.1 4433 --data "ping"

# Benchmark: handshake latency + single-stream throughput
# (peer is `quicz echo --server`)
quicz bench 127.0.0.1 4433 --size 1048576
```

## Limits

- The H3 client and server currently support IPv4 literals and `localhost`; `--ca` requires an absolute PEM path.
- `serve` uses a built-in loopback test certificate by default; use `--cert` / `--key` (P-256 PEM) in production.
- `bench` connects to `echo --server` in insecure mode; it measures the transport path, not certificate verification.
