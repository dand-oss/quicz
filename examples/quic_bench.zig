//! QUIC transport benchmark — threaded async client/server via std.Io.
//!
//! Usage:
//!   zig build run-quic-bench
//!
//! Client and server run in separate threads. Server learns client
//! address from first received datagram and sends ACKs back correctly.
//! Uses std.Io.Threaded for async socket I/O on both sides.

const std = @import("std");
const quicz = @import("quicz");

const max_datagram_size: usize = 1324;
const transfer_size: usize = 16 * 1024 * 1024; // 64 MB
const client_dcid = [_]u8{ 0x10, 0x20, 0x30, 0x40 };
const server_dcid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };

fn nanoTime() u64 {
    return std.c.mach_absolute_time();
}

const ServerContext = struct {
    socket: *std.Io.net.Socket,
    io: std.Io,
    server: *quicz.Connection,
    done: *std.atomic.Value(bool),
    bytes_received: *std.atomic.Value(usize),
    client_addr: std.Io.net.IpAddress,
};

fn serverThread(ctx: *ServerContext) void {
    var recv_buf: [1500]u8 = undefined;
    var read_buf: [65536]u8 = undefined;
    const stream_id: u64 = 0;
    var have_client_addr = false;

    while (!ctx.done.load(.acquire)) {
        // Receive datagrams
        var received_any = false;
        while (true) {
            const received = ctx.socket.receiveTimeout(ctx.io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            // Learn client address from first datagram
            if (!have_client_addr) {
                ctx.client_addr = received.from;
                have_client_addr = true;
            }
            _ = ctx.server.processProtectedShortDatagramWithInstalledKeys(
                @intCast(nanoTime() / 1_000_000),
                client_dcid.len,
                received.data,
            ) catch {};
            received_any = true;
        }

        if (!received_any) continue;

        // Read stream data
        while (true) {
            const n = ctx.server.recvOnStream(stream_id, &read_buf) catch break orelse break;
            if (n == 0) break;
            _ = ctx.bytes_received.fetchAdd(n, .monotonic);
        }

        // Send ACKs back to client
        if (have_client_addr) {
            while (true) {
                const ack_dg = ctx.server.pollProtectedShortDatagramWithInstalledKeys(
                    @intCast(nanoTime() / 1_000_000),
                    &client_dcid,
                ) catch break orelse break;
                defer ctx.server.allocator.free(ack_dg);
                ctx.socket.send(ctx.io, &ctx.client_addr, ack_dg) catch break;
            }
        }
    }
}

pub fn main() !void {
    
    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== quicz QUIC Transport Benchmark (std.Io threaded) ===\n", .{});
    std.debug.print("Transfer: {d} MB | Datagram: {d} B | CUBIC | 2 threads\n\n", .{
        transfer_size / (1024 * 1024),
        max_datagram_size,
    });

    var threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var client_socket = try bindLoopback(io);
    defer client_socket.close(io);
    var server_socket = try bindLoopback(io);
    defer server_socket.close(io);

    const server_addr = server_socket.address;

    const original_dcid = [_]u8{ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 };
    const secrets = try quicz.protection.deriveInitialSecrets(.v1, &original_dcid);

    var client = try quicz.Connection.init(allocator, .client, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
        .congestion_algorithm = .cubic,
    });
    var server = try quicz.Connection.init(allocator, .server, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
    });

    try client.installOneRttTrafficSecrets(.{ .local = secrets.client.secret, .peer = secrets.server.secret });
    try server.installOneRttTrafficSecrets(.{ .local = secrets.server.secret, .peer = secrets.client.secret });
    try client.confirmHandshake();
    try server.confirmHandshake();
    try server.validatePeerAddress();

    var done = std.atomic.Value(bool).init(false);
    var bytes_received = std.atomic.Value(usize).init(0);

    var server_ctx = ServerContext{
        .socket = &server_socket,
        .io = io,
        .server = &server,
        .done = &done,
        .bytes_received = &bytes_received,
        .client_addr = server_addr, // placeholder, updated on first recv
    };

    const srv_thread = try std.Thread.spawn(.{}, serverThread, .{&server_ctx});

    // Client: send data
    const stream_id = try client.openStream();
    var payload: [max_datagram_size]u8 = undefined;
    @memset(&payload, 'X');
    var recv_buf: [1500]u8 = undefined;

    var total_queued: usize = 0;
    var pn: i64 = 0;

    const start_ns = nanoTime();

    while (total_queued < transfer_size) {
        // Feed stream
        var fed: usize = 0;
        while (total_queued < transfer_size and fed < 256) : (fed += 1) {
            const chunk = @min(payload.len, transfer_size - total_queued);
            const fin = total_queued + chunk >= transfer_size;
            client.sendOnStream(stream_id, payload[0..chunk], fin) catch break;
            total_queued += chunk;
        }

        // Send datagrams
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(
                @intCast(nanoTime() / 1_000_000),
                &server_dcid,
            ) catch break orelse break;
            defer allocator.free(dg);
            pn += 1;
            client_socket.send(io, &server_addr, dg) catch break;
        }

        // Process ACKs
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(0) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(
                @intCast(nanoTime() / 1_000_000),
                server_dcid.len,
                ack.data,
            ) catch {};
        }
    }

    // Drain: keep sending until server received everything
    var wait: usize = 0;
    while (bytes_received.load(.monotonic) < transfer_size and wait < 10_000_000) : (wait += 1) {
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(
                @intCast(nanoTime() / 1_000_000),
                &server_dcid,
            ) catch break orelse break;
            defer allocator.free(dg);
            pn += 1;
            client_socket.send(io, &server_addr, dg) catch break;
        }
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(0) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(
                @intCast(nanoTime() / 1_000_000),
                server_dcid.len,
                ack.data,
            ) catch {};
        }
    }

    const elapsed = nanoTime() - start_ns;
    done.store(true, .release);
    srv_thread.join();

    const received = bytes_received.load(.monotonic);
    const seconds = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    const mbps = @as(f64, @floatFromInt(received)) / (1024.0 * 1024.0) / seconds;

    std.debug.print("  {s:20} {d:.2} MB/s  (received {d}/{d} MB in {d:.3} ms)\n", .{
        "Stream Upload",
        mbps,
        received / (1024 * 1024),
        transfer_size / (1024 * 1024),
        @as(f64, @floatFromInt(elapsed)) / 1_000_000.0,
    });
    std.debug.print("  {s:20} {d} pkts, cwnd={d} KB, wait_spins={d}\n", .{
        "Stats",
        pn,
        client.recovery_state.congestion_window / 1024,
        wait,
    });


    // --- Benchmark 2: Echo Latency ---
    std.debug.print("\n  --- Echo Latency (1 KB roundtrip) ---\n", .{});
    {
        const echo_iters: usize = 5000;
        var echo_payload: [1024]u8 = undefined;
        @memset(&echo_payload, 'E');
        var echo_rb: [1500]u8 = undefined;
        var echo_read: [2048]u8 = undefined;
        var echo_pn: i64 = 0;
        const echo_stream = try client.openStream();
        var latencies: [echo_iters]u64 = undefined;

        for (0..echo_iters) |iter| {
            const t0 = nanoTime();
            try client.sendOnStream(echo_stream, &echo_payload, false);
            if (try client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), &server_dcid)) |dg| {
                defer allocator.free(dg);
                echo_pn += 1;
                try client_socket.send(io, &server_addr, dg);
            }
            // Server receives + echoes (inline, same thread for latency accuracy)
            const srv_r = server_socket.receiveTimeout(io, &echo_rb, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(5) } }) catch continue;
            _ = server.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), client_dcid.len, srv_r.data) catch continue;
            _ = server.recvOnStream(echo_stream, &echo_read) catch {};
            try server.sendOnStream(echo_stream, &echo_payload, false);
            if (try server.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), &client_dcid)) |dg| {
                defer allocator.free(dg);
                echo_pn += 1;
                try server_socket.send(io, &client_socket.address, dg);
            }
            // Client receives echo
            const cli_r = client_socket.receiveTimeout(io, &echo_rb, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(5) } }) catch continue;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime() / 1_000_000), server_dcid.len, cli_r.data) catch {};
            _ = client.recvOnStream(echo_stream, &echo_read) catch {};
            latencies[iter] = nanoTime() - t0;
        }

        std.mem.sort(u64, &latencies, {}, std.sort.asc(u64));
        std.debug.print("  {s:20} P50={d:.1}us  P99={d:.1}us  P99.9={d:.1}us  ({d} iters)\n", .{
            "Echo Latency",
            @as(f64, @floatFromInt(latencies[echo_iters * 50 / 100])) / 1000.0,
            @as(f64, @floatFromInt(latencies[echo_iters * 99 / 100])) / 1000.0,
            @as(f64, @floatFromInt(latencies[echo_iters * 999 / 1000])) / 1000.0,
            echo_iters,
        });
    }

    std.debug.print("\n=== Benchmark complete ===\n", .{});
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}
