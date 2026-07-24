#!/bin/bash
# quicz interop endpoint runner for quic-interop-runner
# Env: ROLE=server|client, TESTCASE, REQUESTS, SSLKEYLOGFILE, QLOGDIR

set -e

ROLE=${ROLE:-server}
TESTCASE=${TESTCASE:-handshake}

# Known testcases
KNOWN_TESTCASES="handshake transfer longrtt chacha20 multiplexing retry resumption zerortt http3 blackhole keyupdate ecn amplificationlimit handshakeloss transferloss"

# Check if testcase is known
is_known=false
for tc in $KNOWN_TESTCASES; do
    if [ "$TESTCASE" == "$tc" ]; then
        is_known=true
        break
    fi
done

if [ "$is_known" == "false" ]; then
    echo "quicz interop: unsupported testcase=$TESTCASE"
    exit 127
fi

echo "quicz interop: role=$ROLE testcase=$TESTCASE"

if [ "$ROLE" == "server" ]; then
    exec /usr/local/bin/quicz-interop-server
else
    exec /usr/local/bin/quicz-interop-client
fi
