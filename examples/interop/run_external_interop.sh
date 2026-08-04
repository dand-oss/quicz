#!/bin/bash
# External interop: quicz client vs quic-go / quiche / s2n-quic servers.
# Cases per implementation:
#   handshake  - TLS 1.3 handshake completes (quicz-interop-client)
#   transfer   - handshake + bidirectional stream echo (quicz-interop-client)
#   verified   - certificate-verified echo on two streams (quicz-interop-runtime-client)
# Usage: ./examples/interop/run_external_interop.sh [quic-go|quiche|s2n-quic|all] [port]
set -u

IMPL=${1:-all}
PORT=${2:-4433}
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
CERT_DIR="$DIR/testdata"
BIN="$ROOT/zig-out/bin"

if [ ! -f "$CERT_DIR/cert.pem" ]; then
    echo "Generating test certificates..."
    mkdir -p "$CERT_DIR"
    openssl ecparam -name prime256v1 -genkey -noout -out "$CERT_DIR/key.pem" 2>/dev/null
    openssl req -x509 -new -sha256 -nodes -days 30 \
        -key "$CERT_DIR/key.pem" -out "$CERT_DIR/cert.pem" \
        -subj "/O=quicz interop test/" 2>/dev/null
fi

FAILURES=0

run_case() {
    local server_cmd="$1" impl="$2" case_name="$3" client_cmd="$4"
    echo ""
    echo "--- quicz vs $impl [$case_name] (port $PORT) ---"
    eval "$server_cmd" >/tmp/interop_server_$impl.log 2>&1 &
    local server_pid=$!
    sleep 2
    if ! kill -0 "$server_pid" 2>/dev/null; then
        echo "FAIL: server did not start (see /tmp/interop_server_$impl.log)"
        FAILURES=$((FAILURES + 1))
        return
    fi
    if eval "$client_cmd" >/tmp/interop_client_${impl}_${case_name}.log 2>&1; then
        echo "PASS: quicz <-> $impl [$case_name]"
    else
        echo "FAIL: quicz <-> $impl [$case_name] (client log: /tmp/interop_client_${impl}_${case_name}.log)"
        tail -5 "/tmp/interop_client_${impl}_${case_name}.log"
        FAILURES=$((FAILURES + 1))
    fi
    kill -9 "$server_pid" 2>/dev/null
    wait "$server_pid" 2>/dev/null
    sleep 1
}

run_impl() {
    local impl="$1" server_cmd="$2"
    local base=$PORT
    for case_name in handshake transfer verified; do
        case "$case_name" in
            handshake) PORT=$base ;;
            transfer) PORT=$((base + 1)) ;;
            verified) PORT=$((base + 2)) ;;
        esac
        run_case "$server_cmd" "$impl" "$case_name" \
            "TESTCASE=$case_name $BIN/quicz-interop-runtime-client 127.0.0.1 $PORT $CERT_DIR/cert.pem localhost"
    done
    PORT=$base
}

case "$IMPL" in
    quic-go)
        run_impl quic-go "CERT=$CERT_DIR/cert.pem KEY=$CERT_DIR/key.pem /tmp/quic-go-interop-server 127.0.0.1:\$PORT"
        ;;
    quiche)
        run_impl quiche "CERT=$CERT_DIR/cert.pem KEY=$CERT_DIR/key.pem $DIR/quiche_server/target/release/quiche-interop-server 127.0.0.1:\$PORT"
        ;;
    s2n-quic)
        run_impl s2n-quic "CERT=$CERT_DIR/cert.pem KEY=$CERT_DIR/key.pem $DIR/s2n_quic_server/target/release/s2n-quic-interop-server 127.0.0.1:\$PORT"
        ;;
    all)
        "$0" quic-go "$PORT"
        pkill -9 -f "interop" 2>/dev/null; sleep 3
        "$0" quiche "$PORT"
        pkill -9 -f "interop" 2>/dev/null; sleep 3
        "$0" s2n-quic "$PORT"
        exit $?
        ;;
    *)
        echo "Usage: $0 [quic-go|quiche|s2n-quic|all] [port]"
        exit 2
        ;;
esac

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "=== ALL PASS: $IMPL ==="
else
    echo "=== $FAILURES FAILURE(S): $IMPL ==="
    exit 1
fi
