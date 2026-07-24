#!/bin/bash
# External interop test: quicz client vs quic-go server
# Usage: ./interop/external/run_external_interop.sh [port]
set -e

PORT=${1:-4433}
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

echo "=== External interop: quicz vs quic-go ==="

# Build quic-go server
echo "Building quic-go server..."
cd "$DIR"
go build -o /tmp/quic-go-interop-server ./quic_go_server.go 2>/dev/null

# Build quicz interop binaries
echo "Building quicz interop binaries..."
cd "$ROOT"
zig build --global-cache-dir .zig-cache/global -Doptimize=ReleaseFast 2>/dev/null || true

# Start quic-go server
echo "Starting quic-go server on 127.0.0.1:$PORT..."
/tmp/quic-go-interop-server "127.0.0.1:$PORT" &
GO_PID=$!
sleep 1

# Run quicz client
echo "Running quicz interop client..."
TESTCASE=handshake REQUESTS="https://127.0.0.1:$PORT/test.txt" \
    "$ROOT/zig-out/bin/quicz-interop-runner-client" 2>&1
RESULT=$?

# Cleanup
kill $GO_PID 2>/dev/null
wait $GO_PID 2>/dev/null

if [ $RESULT -eq 0 ]; then
    echo "=== PASS: quicz <-> quic-go interop ==="
else
    echo "=== FAIL: quicz <-> quic-go interop ==="
    exit 1
fi
