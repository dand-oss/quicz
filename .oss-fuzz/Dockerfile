# OSS-Fuzz base image for quicz. Provides the sanitizer + libFuzzer toolchain
# and the Zig compiler needed to build the pure-Zig fuzz driver.
FROM gcr.io/oss-fuzz-base/base-builder

# Zig 0.16.0 is shipped per-arch; pick the tarball matching the builder arch.
RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        wget xz-utils ca-certificates; \
    case "$(uname -m)" in \
        x86_64) ZIG_ARCH=x86_64 ;; \
        aarch64) ZIG_ARCH=aarch64 ;; \
        *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    wget -q "https://ziglang.org/download/0.16.0/zig-linux-${ZIG_ARCH}-0.16.0.tar.xz" -O /tmp/zig.tar.xz; \
    tar -xJf /tmp/zig.tar.xz -C /opt; \
    ln -s /opt/zig-*/zig /usr/local/bin/zig; \
    zig version

COPY . $SRC/quicz
WORKDIR $SRC/quicz
COPY .oss-fuzz/build.sh $SRC/build.sh