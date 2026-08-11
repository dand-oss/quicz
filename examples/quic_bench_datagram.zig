//! QUIC DATAGRAM (RFC 9221) throughput benchmark.
//!
//! Measures unreliable DATAGRAM frame throughput over loopback UDP
//! using installed 1-RTT keys (bypasses TLS handshake, transport-only).
//!
//! Usage:
//!   zig build-exe -OReleaseFast --dep quicz \
//!     -Mroot=examples/quic_bench_datagram.zig -Mquicz=src/lib.zig \
//!     --name quicz-bench-datagram -femit-bin=zig-out/bin/quicz-bench-datagram \
//!     --cache-dir .zig-cache --global-cache-dir .zig-cache/global
//!   ./zig-out/bin/quicz-bench-datagram

const std = @import("std");
const builtin = @import("builtin");
const quicz = @import("quicz");

const max_datagram_size: usize = 8900;
const dgram_payload_size: usize = 1200; // RFC 9221 typical payload
const transfer_size: usize = 16 * 1024 * 1024; // 16 MB
const client_dcid = [_]u8{ 0x10, 0x20, 0x30, 0x40 };
const server_dcid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };

const MachTimebaseInfo = extern struct { numer: u32, denom: u32 };
extern fn mach_timebase_info(info: *MachTimebaseInfo) i32;
var _tb: MachTimebaseInfo = undefined;
var _tb_init: bool = false;
var _t0: u64 = 0;
fn nanoTime() u64 {
    if (comptime builtin.os.tag == .macos) {
        if (!_tb_init) {
            _ = mach_timebase_info(&_tb);
            _t0 = std.c.mach_absolute_time();
            _tb_init = true;
        }
        return (std.c.mach_absolute_time() - _t0) * _tb.numer / _tb.denom;
    } else {
        var ts: std.os.linux.timespec = undefined;
        _ = std.os.linux.clock_gettime(.MONOTONIC, &ts);
        return @intCast(@as(i128, ts.sec) * 1_000_000_000 + ts.nsec);
    }
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
    var recv_buf: [10000]u8 = undefined;
    var have_client_addr = false;

    while (!ctx.done.load(.acquire)) {
        var received_any = false;
        while (true) {
            const received = ctx.socket.receiveTimeout(ctx.io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            if (!have_client_addr) {
                ctx.client_addr = received.from;
                have_client_addr = true;
            }
            _ = ctx.server.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), client_dcid.len, received.data) catch {};
            received_any = true;
        }
        if (!received_any) continue;

        // Drain received DATAGRAM frames
        var dgram_buf: [2048]u8 = undefined;
        while (true) {
            const n = ctx.server.recvDatagram(&dgram_buf) catch break orelse break;
            if (n == 0) break;
            _ = ctx.bytes_received.fetchAdd(n, .monotonic);
        }

        // Send ACKs back
        if (have_client_addr) {
            while (true) {
                const ack_dg = ctx.server.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &client_dcid) catch break orelse break;
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

    std.debug.print("=== quicz DATAGRAM (RFC 9221) Throughput Benchmark ===\n", .{});
    std.debug.print("Transfer: {d} MB | Payload: {d} B | Unreliable | 2 threads\n\n", .{
        transfer_size / (1024 * 1024),
        dgram_payload_size,
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
        .max_datagram_size = max_datagram_size,
        .max_datagram_frame_size = 65535,
    });
    var server = try quicz.Connection.init(allocator, .server, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
        .max_datagram_size = max_datagram_size,
        .max_datagram_frame_size = 65535,
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
        .client_addr = server_addr,
    };

    const srv_thread = try std.Thread.spawn(.{}, serverThread, .{&server_ctx});

    var payload: [dgram_payload_size]u8 = undefined;
    @memset(&payload, 'D');
    var recv_buf: [10000]u8 = undefined;

    var total_sent: usize = 0;
    var total_datagrams: usize = 0;

    const start_ns = nanoTime();

    while (total_sent < transfer_size) {
        // Queue DATAGRAM frames
        var queued: usize = 0;
        while (total_sent < transfer_size and queued < 64) : (queued += 1) {
            const chunk = @min(dgram_payload_size, transfer_size - total_sent);
            client.sendDatagram(payload[0..chunk]) catch break;
            total_sent += chunk;
        }

        // Poll and send datagrams
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &server_dcid) catch break orelse break;
            defer allocator.free(dg);
            total_datagrams += 1;
            client_socket.send(io, &server_addr, dg) catch break;
        }

        // Process ACKs
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), server_dcid.len, ack.data) catch {};
        }
    }

    // Drain
    var wait: usize = 0;
    while (bytes_received.load(.monotonic) < transfer_size and wait < 10_000_000) : (wait += 1) {
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &server_dcid) catch break orelse break;
            defer allocator.free(dg);
            total_datagrams += 1;
            client_socket.send(io, &server_addr, dg) catch break;
        }
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), server_dcid.len, ack.data) catch {};
        }
    }

    const elapsed = nanoTime() - start_ns;
    done.store(true, .release);
    srv_thread.join();

    const received = bytes_received.load(.monotonic);
    const seconds = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    const mbps = @as(f64, @floatFromInt(received)) / (1024.0 * 1024.0) / seconds;

    std.debug.print("  DATAGRAM Throughput: {d:.2} MB/s  ({d}/{d} MB in {d:.3} ms)\n", .{
        mbps,
        received / (1024 * 1024),
        transfer_size / (1024 * 1024),
        @as(f64, @floatFromInt(elapsed)) / 1_000_000.0,
    });
    std.debug.print("  Stats: {d} datagrams sent, {d} B payload each\n", .{ total_datagrams, dgram_payload_size });
    std.debug.print("\n=== DATAGRAM benchmark complete ===\n", .{});
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}
