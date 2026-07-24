#!/bin/bash
# quicz interop endpoint runner for quic-interop-runner
# Env: ROLE=server|client, TESTCASE, REQUESTS, SSLKEYLOGFILE, QLOGDIR

set -e

ROLE=${ROLE:-server}
TESTCASE=${TESTCASE:-handshake}

echo "quicz interop: role=$ROLE testcase=$TESTCASE"

if [ "$ROLE" == "server" ]; then
    exec /usr/local/bin/quicz-interop-server
else
    exec /usr/local/bin/quicz-interop-client
fi
