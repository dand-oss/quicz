# Linux GSO/GRO Optimization Design

## Goal

Reduce per-packet syscall overhead from ~5-6μs/pkt to ~0.5-1μs/pkt by batching
multiple QUIC packets into single syscalls using Linux UDP segmentation offload.

Expected improvement: 3-10x throughput (442 MB/s → 1.5-4 GB/s on Linux).

## Background

Current bottleneck (macOS loopback profiling):
- UDP sendto: 5,340 ns/pkt (29.1% of total time)
- UDP recvfrom: 6,293 ns/pkt (32.5% of total time)
- AES-GCM encrypt/decrypt: 9,172 ns/pkt (47.4%, hardware accelerated)

On Linux, GSO/GRO reduces syscall count by batching:
- GSO (send): pack N packets into one sendmsg() with UDP_SEGMENT cmsg
- GRO (receive): kernel aggregates N packets into one recvmsg() buffer
- sendmmsg: send M datagrams in a single syscall (complementary to GSO)

## Architecture

### Platform Abstraction Layer

```
┌─────────────────────────────────────────────────┐
│              Connection (unchanged)              │
├─────────────────────────────────────────────────┤
│           BatchSendBuffer (new)                  │
│  - Accumulates QUIC packets into GSO segments   │
│  - Coalesces same-dest packets into sendmsg()   │
│  - Falls back to per-packet send on macOS       │
├─────────────────────────────────────────────────┤
│           PlatformSocket (new trait)             │
│  - Linux: sendmsg + UDP_SEGMENT + GRO           │
│  - macOS: std.Io.Threaded (current, unchanged)  │
├─────────────────────────────────────────────────┤
│              OS Kernel                           │
│  - Linux: UDP_SEGMENT splits into MTU segments  │
│  - Linux: GRO aggregates incoming packets       │
└─────────────────────────────────────────────────┘
```

### GSO Send Path

```zig
/// Batch multiple QUIC packets into a single sendmsg() with UDP_SEGMENT.
/// Requires: Linux 4.18+, same destination for all segments.
pub const GsoSendBuffer = struct {
    /// Accumulation buffer (up to 64KB = ~48 QUIC packets at 1350B).
    buf: [65536]u8,
    /// Current write position in buf.
    pos: usize = 0,
    /// Segment size (gso_size) for UDP_SEGMENT cmsg.
    segment_size: u16,
    /// Destination address (all segments must share same dest).
    dest: std.net.Address,

    /// Append one QUIC packet to the GSO buffer.
    /// Returns false if buffer is full (caller must flush first).
    pub fn append(self: *GsoSendBuffer, packet: []const u8) bool {
        if (self.pos + packet.len > self.buf.len) return false;
        if (self.pos > 0 and packet.len != self.segment_size) {
            // GSO requires all segments except last to be same size.
            // Flush before appending different-sized packet.
            return false;
        }
        @memcpy(self.buf[self.pos..][0..packet.len], packet);
        self.pos += packet.len;
        self.segment_size = @intCast(packet.len);
        return true;
    }

    /// Flush accumulated packets via sendmsg() with UDP_SEGMENT cmsg.
    /// Single syscall sends all accumulated segments.
    pub fn flush(self: *GsoSendBuffer, fd: i32) !void {
        if (self.pos == 0) return;
        // sendmsg with:
        //   iov[0] = buf[0..pos]
        //   cmsg: SOL_UDP / UDP_SEGMENT / segment_size
        // Kernel splits into pos/segment_size datagrams.
        try sendmsgGso(fd, self.buf[0..self.pos], self.segment_size, self.dest);
        self.pos = 0;
    }
};
```

### GRO Receive Path

```zig
/// Receive multiple QUIC packets in a single recvmsg() using GRO.
/// Kernel aggregates incoming packets into a large buffer.
/// Returns a slice that may contain multiple QUIC packets.
pub fn recvGro(fd: i32, buf: []u8) ![]const u8 {
    // recvmsg with:
    //   iov[0] = buf (64KB buffer)
    //   cmsg: SOL_UDP / UDP_GRO (receive buffer)
    // Returns total bytes received (may be multiple packets).
    // Use gso_size from cmsg to determine segment boundaries.
    return recvmsgGro(fd, buf);
}

/// Parse a GRO buffer into individual QUIC packets.
/// gso_size indicates the segment size; last segment may be smaller.
pub fn parseGroBuffer(buf: []const u8, gso_size: u16) []const []const u8 {
    // Split buf into segments of gso_size (last may be smaller).
    // Each segment is one QUIC packet.
}
```

### sendmmsg (Complementary to GSO)

```zig
/// Send multiple datagrams to DIFFERENT destinations in a single syscall.
/// Use when packets go to different peers (multi-connection server).
pub fn sendmmsg(fd: i32, packets: []const Datagram) !usize {
    // sendmmsg(fd, mmsg_array, len, MSG_DONTWAIT)
    // Each mmsg has its own destination address.
    // Returns number of messages sent.
}
```

## Integration Points

### 1. Connection.pollProtectedShortDatagram (send path)

Current: returns one datagram at a time, caller sends via socket.send().

New: accumulate datagrams in GsoSendBuffer, flush when:
- Buffer full (64KB)
- Different destination (flush before switching dest)
- End of poll cycle (flush remaining)

### 2. Server receive loop (receive path)

Current: receiveTimeout() returns one datagram at a time.

New: recvGro() returns a buffer that may contain multiple packets.
Parse into individual QUIC packets, process each.

### 3. Platform detection

```zig
pub const platform = struct {
    pub const has_gso: bool = @hasDecl(std.os.linux, "UDP_SEGMENT");
    pub const has_gro: bool = @hasDecl(std.os.linux, "UDP_GRO");
    pub const has_sendmmsg: bool = @hasDecl(std.os.linux, "sendmmsg");
};
```

## Expected Performance

| Scenario | Current (macOS) | With GSO (Linux) | Improvement |
|---|---|---|---|
| Single stream | 442 MB/s | 1.5-3 GB/s | 3-7x |
| Multi-stream (4) | 536 MB/s | 3-6 GB/s | 6-11x |
| Echo latency P50 | 17.8 μs | 5-10 μs | 2-3x |

Reference data points:
- msquic (Windows XDP): 7-8 Gbps
- quic-go (Linux GSO): 4 Gbps multi-stream
- s2n-quic (Linux GSO/GRO): 800 MB/s single stream
- Cloudflare (nginx + GSO): 2-3x improvement over per-packet send

## Implementation Plan

### Phase 1: GSO Send (highest ROI)
1. Implement `GsoSendBuffer` with UDP_SEGMENT cmsg
2. Add `sendmsgGso()` syscall wrapper (Linux only)
3. Integrate into benchmark send loop
4. Measure improvement on Linux

### Phase 2: GRO Receive
1. Implement `recvGro()` with UDP_GRO cmsg
2. Implement GRO buffer parser (split into QUIC packets)
3. Integrate into server receive loop
4. Measure improvement

### Phase 3: sendmmsg (multi-connection)
1. Implement `sendmmsg()` wrapper
2. Integrate into multi-connection server
3. Measure multi-connection improvement

### Phase 4: Platform abstraction
1. Create `PlatformSocket` trait
2. Linux: GSO/GRO/sendmmsg path
3. macOS: std.Io.Threaded fallback (current, unchanged)
4. Compile-time platform selection

## Constraints

- GSO requires Linux 4.18+ (UDP_SEGMENT socket option)
- GRO requires Linux 4.18+ (UDP_GRO socket option)
- sendmmsg requires Linux 2.6.33+
- All GSO segments except last must be same size
- GRO requires all packets in a GRO buffer to have same gso_size
- macOS has no equivalent (no GSO/GRO/sendmmsg)
- std.Io.Threaded remains the macOS path (unchanged)

## References

- [Cloudflare: Accelerating UDP packet transmission for QUIC](https://blog.cloudflare.com/accelerating-udp-packet-transmission-for-quic/)
- [quic-go: Optimizations (GSO/GRO)](https://quic-go.net/docs/quic/optimizations/)
- [Linux UDP_SEGMENT man page](https://man7.org/linux/man-pages/man7/udp.7.html)
- [LPC2018: Optimizing UDP for Content Delivery with GSO](https://lpc.events/event/2/contributions/106/attachments/104/128/willemdebruijn-lpc2018-udpgso-presentation-20181113.pdf)
- [Evaluating Pacing Strategies in QUIC Implementations (2025)](https://arxiv.org/html/2505.09222v1)
