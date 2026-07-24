#!/bin/bash
# External interop test: quicz vs quic-go / quiche / s2n-quic
# Usage: ./examples/interop/run_external_interop.sh [quic-go|quiche|s2n-quic|all] [port]
set -e

IMPL=${1:-quic-go}
PORT=${2:-4433}
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
CERT_DIR="$DIR/testdata"

# Generate test certificates if not present
if [ ! -f "$CERT_DIR/cert.pem" ]; then
    echo "Generating test certificates..."
    mkdir -p "$CERT_DIR"
    openssl ecparam -name prime256v1 -genkey -noout -out "$CERT_DIR/key.pem" 2>/dev/null
    openssl req -x509 -new -sha256 -nodes -days 30 \
        -key "$CERT_DIR/key.pem" -out "$CERT_DIR/cert.pem" \
        -subj "/O=quicz interop test/" 2>/dev/null
    echo "Certificates generated."
fi

# Build quicz interop client
echo "Building quicz interop client..."
cd "$ROOT"
zig build --global-cache-dir .zig-cache/global -Doptimize=ReleaseFast 2>/dev/null || true

run_test() {
    local server_cmd="$1"
    local impl_name="$2"
    echo ""
    echo "=== quicz vs $impl_name (port $PORT) ==="

    # Start server
    eval "$server_cmd" &
    SERVER_PID=$!
    sleep 2

    # Run quicz client
    TESTCASE=handshake REQUESTS="https://127.0.0.1:$PORT/test.txt" \
        CERT="$CERT_DIR/cert.pem" KEY="$CERT_DIR/key.pem" \
        "$ROOT/zig-out/bin/quicz-interop-runner-client" 2>&1
    RESULT=$?

    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null

    if [ $RESULT -eq 0 ]; then
        echo "=== PASS: quicz <-> $impl_name ==="
    else
        echo "=== FAIL: quicz <-> $impl_name ==="
        return 1
    fi
}

case "$IMPL" in
    quic-go)
        cd "$DIR/quic_go_server"
        go build -o /tmp/quic-go-interop-server . 2>/dev/null
        run_test "/tmp/quic-go-interop-server 127.0.0.1:$PORT" "quic-go"
        ;;
    quiche)
        cd "$DIR/quiche_server"
        CERT="$CERT_DIR/cert.pem" KEY="$CERT_DIR/key.pem" \
            cargo build --release 2>/dev/null
        run_test "CERT=$CERT_DIR/cert.pem KEY=$CERT_DIR/key.pem ./target/release/quiche-interop-server 127.0.0.1:$PORT" "quiche"
        ;;
    s2n-quic)
        cd "$DIR/s2n_quic_server"
        CERT="$CERT_DIR/cert.pem" KEY="$CERT_DIR/key.pem" \
            cargo build --release 2>/dev/null
        run_test "CERT=$CERT_DIR/cert.pem KEY=$CERT_DIR/key.pem ./target/release/s2n-quic-interop-server 127.0.0.1:$PORT" "s2n-quic"
        ;;
    all)
        $0 quic-go $PORT
        $0 quiche $PORT
        $0 s2n-quic $PORT
        ;;
    *)
        echo "Usage: $0 [quic-go|quiche|s2n-quic|all] [port]"
        exit 1
        ;;
esac
