//! QUIC transport benchmark — pipelined batch mode.
//!
//! Usage:
//!   zig build run-quic-bench
//!
//! Sends multiple packets per round (up to congestion window),
//! then batch-processes ACKs. Measures real pipelined throughput.

const std = @import("std");
const quicz = @import("quicz");

const max_datagram_size: usize = 1324;
const transfer_size: usize = 16 * 1024 * 1024; // 16 MB
const client_dcid = [_]u8{ 0x10, 0x20, 0x30, 0x40 };
const server_dcid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };

fn nanoTime() u64 {
    return std.c.mach_absolute_time();
}

fn recvTimeout() std.Io.Timeout {
    return .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(2) } };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== quicz QUIC Transport Benchmark (pipelined) ===\n", .{});
    std.debug.print("Transfer: {d} MB | Datagram: {d} B | CUBIC\n\n", .{
        transfer_size / (1024 * 1024),
        max_datagram_size,
    });

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var client_socket = try bindLoopback(io);
    defer client_socket.close(io);
    var server_socket = try bindLoopback(io);
    defer server_socket.close(io);

    const original_dcid = [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 };
    const secrets = try quicz.protection.deriveInitialSecrets(.v1, &original_dcid);

    var client = try quicz.Connection.init(allocator, .client, .{
        .initial_max_data = 64 * 1024 * 1024,
        .initial_max_stream_data = 64 * 1024 * 1024,
        .congestion_algorithm = .new_reno,
    });
    defer client.deinit();
    var server = try quicz.Connection.init(allocator, .server, .{
        .initial_max_data = 64 * 1024 * 1024,
        .initial_max_stream_data = 64 * 1024 * 1024,
    });
    defer server.deinit();

    try client.installOneRttTrafficSecrets(.{ .local = secrets.client.secret, .peer = secrets.server.secret });
    try server.installOneRttTrafficSecrets(.{ .local = secrets.server.secret, .peer = secrets.client.secret });
    try client.confirmHandshake();
    try server.confirmHandshake();
    try server.validatePeerAddress();

    const stream_id = try client.openStream();
    var payload: [max_datagram_size]u8 = undefined;
    @memset(&payload, 'X');
    var recv_buf: [1500]u8 = undefined;

    var total_sent: usize = 0;
    var pn: i64 = 0;
    var rounds: usize = 0;
    var total_packets: usize = 0;

    const start_ns = nanoTime();

    while (total_sent < transfer_size) {
        // 1. Feed stream buffer (multiple chunks)
        var fed: usize = 0;
        while (total_sent < transfer_size and fed < 64) : (fed += 1) {
            const chunk = @min(payload.len, transfer_size - total_sent);
            const fin = total_sent + chunk >= transfer_size;
            client.sendOnStream(stream_id, payload[0..chunk], fin) catch break;
            total_sent += chunk;
        }

        // 2. Client: send ALL pending datagrams (cwnd-limited)
        var round_pkts: usize = 0;
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), &server_dcid) catch break orelse break;
            defer allocator.free(dg);
            pn += 1;
            round_pkts += 1;
            client_socket.send(io, &server_socket.address, dg) catch break;
        }
        total_packets += round_pkts;

        // 3. Server: receive ALL pending datagrams
        while (true) {
            const received = server_socket.receiveTimeout(io, &recv_buf, recvTimeout()) catch break;
            _ = server.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), client_dcid.len, received.data) catch {};
        }

        // 4. Server: send ALL ACKs
        while (true) {
            const ack_dg = server.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), &client_dcid) catch break orelse break;
            defer allocator.free(ack_dg);
            pn += 1;
            server_socket.send(io, &client_socket.address, ack_dg) catch break;
        }

        // 5. Client: process ALL ACKs (grows cwnd)
        while (true) {
            const ack_received = client_socket.receiveTimeout(io, &recv_buf, recvTimeout()) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), server_dcid.len, ack_received.data) catch {};
        }

        rounds += 1;
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
    std.debug.print("  {s:20} {d} rounds, {d} packets, avg {d:.1} pkts/round\n", .{
        "Pipeline stats",
        rounds,
        total_packets,
        if (rounds > 0) @as(f64, @floatFromInt(total_packets)) / @as(f64, @floatFromInt(rounds)) else 0,
    });
    std.debug.print("  {s:20} cwnd={d} bytes, bif={d} bytes\n", .{
        "Final state",
        client.recovery_state.congestion_window,
        client.bytesInFlight(.application),
    });

    std.debug.print("\n=== Benchmark complete ===\n", .{});
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}
