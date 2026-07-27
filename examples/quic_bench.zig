//! QUIC transport micro-benchmark (secnetperf-style).
//!
//! Usage:
//!   zig build run-quic-bench
//!
//! Measures raw QUIC stream throughput over loopback UDP with installed
//! 1-RTT keys (bypasses TLS handshake for transport-only measurement).
//!
//! Results (Apple M-series, ReleaseFast, loopback):
//!   Stream Upload: ~110-135 MB/s (4 MB single stream)
//!
//! TODO: Echo latency benchmark (requires isolated socket pairs).

const std = @import("std");
const quicz = @import("quicz");

const max_datagram_size: usize = 1200;
const transfer_size: usize = 4 * 1024 * 1024; // 4 MB

/// Monotonic clock (macOS mach_absolute_time).
fn nanoTime() u64 {
    return std.c.mach_absolute_time();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== quicz QUIC Transport Benchmark ===\n", .{});
    std.debug.print("Transfer size: {d} MB | Datagram size: {d} B\n\n", .{
        transfer_size / (1024 * 1024),
        max_datagram_size,
    });

    // Setup loopback UDP sockets
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var client_socket = try bindLoopback(io);
    defer client_socket.close(io);
    var server_socket = try bindLoopback(io);
    defer server_socket.close(io);

    // Setup QUIC connections with installed keys
    const original_dcid = [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 };
    const secrets = try quicz.protection.deriveInitialSecrets(.v1, &original_dcid);

    var client = try quicz.Connection.init(allocator, .client, .{
        .initial_max_data = 16 * 1024 * 1024,
        .initial_max_stream_data = 16 * 1024 * 1024,
    });
    defer client.deinit();
    var server = try quicz.Connection.init(allocator, .server, .{
        .initial_max_data = 16 * 1024 * 1024,
        .initial_max_stream_data = 16 * 1024 * 1024,
    });
    defer server.deinit();

    try client.installOneRttTrafficSecrets(.{ .local = secrets.client.secret, .peer = secrets.server.secret });
    try server.installOneRttTrafficSecrets(.{ .local = secrets.server.secret, .peer = secrets.client.secret });
    try client.confirmHandshake();
    try server.confirmHandshake();
    try server.validatePeerAddress();

    // --- Stream upload throughput ---
    const stream_id = try client.openStream();
    var payload: [max_datagram_size]u8 = undefined;
    @memset(&payload, 'A');

    const start_ns = nanoTime();
    var total_sent: usize = 0;
    var pn: i64 = 0;

    while (total_sent < transfer_size) {
        const chunk = @min(payload.len, transfer_size - total_sent);
        const fin = total_sent + chunk >= transfer_size;
        try client.sendOnStream(stream_id, payload[0..chunk], fin);
        total_sent += chunk;

        // Poll and send datagrams
        while (true) {
            const dg = try client.pollProtectedShortDatagramWithInstalledKeys(pn, &[_]u8{ 0xaa, 0xbb, 0xcc, 0xdd }) orelse break;
            defer allocator.free(dg);
            pn += 1;
            try client_socket.send(io, &server_socket.address, dg);
        }

        // Server receives
        var recv_buf: [1500]u8 = undefined;
        while (true) {
            const received = server_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            _ = server.processProtectedShortDatagramWithInstalledKeys(pn, 8, received.data) catch break;
        }

        // Server sends ACKs back
        while (true) {
            const ack_dg = try server.pollProtectedShortDatagramWithInstalledKeys(pn, &[_]u8{ 0x10, 0x20, 0x30, 0x40 }) orelse break;
            defer allocator.free(ack_dg);
            pn += 1;
            try server_socket.send(io, &client_socket.address, ack_dg);
        }

        // Client processes ACKs
        while (true) {
            const ack_received = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(pn, 8, ack_received.data) catch break;
        }
    }

    const elapsed = nanoTime() - start_ns;
    const seconds = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    const mbps = @as(f64, @floatFromInt(total_sent)) / (1024.0 * 1024.0) / seconds;
    std.debug.print("  {s:20} {d:.2} MB/s  ({d} bytes in {d:.3} ms)\n", .{
        "Stream Upload",
        mbps,
        total_sent,
        @as(f64, @floatFromInt(elapsed)) / 1_000_000.0,
    });

    std.debug.print("\n=== Benchmark complete ===\n", .{});
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}
