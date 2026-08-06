#!/bin/bash
# Reverse interop: quicz runtime server vs external QUIC clients.
# Each external client (quic-go / quiche / s2n-quic / rustls) connects to the
# quicz-interop-runtime-server, verifies the CA-signed leaf cert, and echoes a
# stream. This validates the production server API path (Server.init/serve).
#
# Usage: ./examples/interop/run_reverse_interop.sh [go|quiche|s2n|rust|all] [port]
set -u

IMPL=${1:-all}
PORT=${2:-4433}
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
CERT_DIR="$DIR/testdata"
BIN="$ROOT/zig-out/bin"

if [ ! -f "$CERT_DIR/cert.pem" ]; then
    echo "Generate test certificates first (run run_external_interop.sh or the openssl steps)."
    exit 2
fi
CA="$CERT_DIR/quicz-echo-ca.pem"
CERT="$CERT_DIR/cert.pem"
KEY="$CERT_DIR/key.pem"

FAILURES=0

# run_client <name> <port> <client_cmd...>
run_client() {
    local name="$1" port="$2"; shift 2
    echo ""
    echo "--- $name -> quicz runtime server (port $port) ---"
    pkill -9 -f "quicz-interop-runtime-server" 2>/dev/null; sleep 1
    "$BIN/quicz-interop-runtime-server" "$port" "$CERT" "$KEY" >/tmp/reverse_${name}_server.log 2>&1 &
    local server_pid=$!
    sleep 1.5
    if ! kill -0 "$server_pid" 2>/dev/null; then
        echo "FAIL: quicz server did not start (/tmp/reverse_${name}_server.log)"
        FAILURES=$((FAILURES + 1))
        return
    fi
    if "$@" >/tmp/reverse_${name}_client.log 2>&1; then
        echo "PASS: $name -> quicz [echo]"
    else
        echo "FAIL: $name -> quicz (client log: /tmp/reverse_${name}_client.log)"
        tail -3 "/tmp/reverse_${name}_client.log"
        FAILURES=$((FAILURES + 1))
    fi
    kill -9 "$server_pid" 2>/dev/null
    wait "$server_pid" 2>/dev/null
    sleep 1
}

run_impl() {
    local impl="$1"
    case "$impl" in
        go)
            run_client go $PORT \
                "$DIR/go_echo_client/go_echo_client" -addr 127.0.0.1:$PORT -ca "$CA" -alpn hq-interop
            ;;
        quiche)
            run_client quiche $PORT \
                "$DIR/quiche_echo_client/target/release/quicz-quiche-echo-client" 127.0.0.1:$PORT "$CA" localhost
            ;;
        s2n)
            run_client s2n $PORT \
                "$DIR/s2n_echo_client/target/release/quicz-s2n-echo-client" 127.0.0.1:$PORT "$CA" localhost
            ;;
        rust)
            run_client rust $PORT \
                "$DIR/rust_echo_client/target/release/quicz-rust-echo-client" 127.0.0.1:$PORT "$CA" localhost
            ;;
        *)
            echo "Unknown impl: $impl"; exit 2
            ;;
    esac
}

case "$IMPL" in
    all)
        for i in go quiche s2n rust; do run_impl "$i"; done
        ;;
    go|quiche|s2n|rust)
        run_impl "$IMPL"
        ;;
    *)
        echo "Usage: $0 [go|quiche|s2n|rust|all] [port]"; exit 2
        ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "=== ALL PASS: reverse interop ==="
else
    echo "=== $FAILURES FAILURE(S): reverse interop ==="
    exit 1
fi