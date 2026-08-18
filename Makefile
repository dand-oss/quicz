# quicz Makefile - local development helpers.
#
# `make` lists all targets; `make <target>` runs one.

NAME := quicz
ZIG ?= zig
QUICZ := cli/zig-out/bin/quicz
CLI_DIR := cli

URL ?= https://cloudflare-quic.com/
TIMEOUT_MS ?= 25000
DIR ?= .
PORT ?= 4433
FUZZ_LIMIT ?= 20000

help: # Show all targets
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: quicz
quicz: # Build the quicz CLI
	cd $(CLI_DIR) && $(ZIG) build
	@echo "built: $(QUICZ)"

.PHONY: quicz-h3
quicz-h3: quicz # Fetch a URL over HTTP/3 (URL=..., default cloudflare-quic.com)
	./$(QUICZ) h3 $(URL) -k --timeout-ms $(TIMEOUT_MS)

.PHONY: quicz-serve
quicz-serve: quicz # Serve DIR over HTTP/3 (DIR=., PORT=4433)
	./$(QUICZ) serve --dir $(DIR) --port $(PORT)

.PHONY: quicz-test
quicz-test: # Run CLI unit tests
	cd $(CLI_DIR) && $(ZIG) build test

.PHONY: test
test: # Run library unit tests
	$(ZIG) build test

.PHONY: io-echo
io-echo: # Run I/O runtime async streaming echo demo
	$(ZIG) build run-io-echo

.PHONY: h3-loopback
h3-loopback: # Run HTTP/3 + QPACK on the production std.Io runtime
	$(ZIG) build run-h3-runtime-loopback

.PHONY: h3-live
h3-live: quicz # Run live H3 verification (cloudflare + fastly + local round trip)
	scripts/cli_h3_live_test.sh

.PHONY: udp-echo
udp-echo: # Run UDP echo loopback demo
	$(ZIG) build run-udp-echo-loopback

.PHONY: codec
codec: # Run QUIC codec roundtrip example
	$(ZIG) build run-codec

.PHONY: fuzz
fuzz: # Run QUIC fuzz harness (FUZZ_LIMIT=..., default 20000)
	$(ZIG) build run-fuzz -- $(FUZZ_LIMIT)

.PHONY: fmt
fmt: # Check Zig formatting (build.zig, src, examples)
	$(ZIG) fmt --check build.zig src examples

.PHONY: check
check: fmt test quicz-test h3-loopback # Quick battery: fmt + tests + H3 loopback
