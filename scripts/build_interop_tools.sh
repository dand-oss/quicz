#!/bin/bash
# Build the external interop tools (quic-go / quiche / s2n-quic servers and
# echo clients) used by the cross-implementation interop matrix. Used by CI;
# can also be run locally (requires Go and Rust toolchains).
set -euo pipefail

DIR="$(cd "$(dirname "$0")/../examples/interop" && pwd)"

# quic-go server (used by run_external_interop.sh)
(cd "$DIR/quic_go_server" && go build -o /tmp/quic-go-interop-server .)

# quic-go echo client (used by run_reverse_interop.sh)
(cd "$DIR/go_echo_client" && go build -o go_echo_client .)

# quiche: interop server + echo client
(cd "$DIR/quiche_server" && cargo build --release)
(cd "$DIR/quiche_echo_client" && cargo build --release)

# s2n-quic: interop server + echo client
(cd "$DIR/s2n_quic_server" && cargo build --release)
(cd "$DIR/s2n_echo_client" && cargo build --release)

# rustls echo client
(cd "$DIR/rust_echo_client" && cargo build --release)

echo "interop tools built: quic-go + quiche + s2n-quic servers, go/quiche/s2n/rust echo clients"