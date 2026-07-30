//! QUIC transport benchmark — per-phase profiling.
//! Measures time in each phase to identify the throughput bottleneck.

const std = @import("std");
const quicz = @import("quicz");

const max_datagram_size: usize = 8900;
const stream_chunk_size: usize = max_datagram_size - 128;
const transfer_size: usize = 16 * 1024 * 1024;
const client_dcid = [_]u8{ 0x10, 0x20, 0x30, 0x40 };
const server_dcid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };

const MachTimebaseInfo = extern struct { numer: u32, denom: u32 };
extern fn mach_timebase_info(info: *MachTimebaseInfo) i32;
var _tb: MachTimebaseInfo = undefined;
var _tb_init: bool = false;
var _t0: u64 = 0;
fn nanoTime() u64 {
    if (!_tb_init) {
        _ = mach_timebase_info(&_tb);
        _t0 = std.c.mach_absolute_time();
        _tb_init = true;
    }
    return (std.c.mach_absolute_time() - _t0) * _tb.numer / _tb.denom;
}

const ServerContext = struct {
    socket: *std.Io.net.Socket,
    io: std.Io,
    server: *quicz.Connection,
    done: *std.atomic.Value(bool),
    bytes_received: *std.atomic.Value(usize),
    client_addr: std.Io.net.IpAddress,
    srv_recv_ns: *std.atomic.Value(u64),
    srv_process_ns: *std.atomic.Value(u64),
    srv_read_ns: *std.atomic.Value(u64),
    srv_ack_build_ns: *std.atomic.Value(u64),
    srv_ack_send_ns: *std.atomic.Value(u64),
    srv_packets: *std.atomic.Value(u64),
};

fn serverThread(ctx: *ServerContext) void {
    var recv_buf: [10000]u8 = undefined;
    var read_buf: [65536]u8 = undefined;
    const stream_id: u64 = 0;
    var have_client_addr = false;

    while (!ctx.done.load(.acquire)) {
        var received_any = false;
        while (true) {
            const t0 = nanoTime();
            const received = ctx.socket.receiveTimeout(ctx.io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            const t1 = nanoTime();
            _ = ctx.srv_recv_ns.fetchAdd(t1 - t0, .monotonic);
            if (!have_client_addr) {
                ctx.client_addr = received.from;
                have_client_addr = true;
            }
            _ = ctx.server.processProtectedShortDatagramWithInstalledKeys(@intCast(t1), client_dcid.len, received.data) catch {};
            const t2 = nanoTime();
            _ = ctx.srv_process_ns.fetchAdd(t2 - t1, .monotonic);
            _ = ctx.srv_packets.fetchAdd(1, .monotonic);
            received_any = true;
        }
        if (!received_any) continue;

        const t3 = nanoTime();
        while (true) {
            const n = ctx.server.recvOnStream(stream_id, &read_buf) catch break orelse break;
            if (n == 0) break;
            _ = ctx.bytes_received.fetchAdd(n, .monotonic);
        }
        const t4 = nanoTime();
        _ = ctx.srv_read_ns.fetchAdd(t4 - t3, .monotonic);

        if (have_client_addr) {
            while (true) {
                const t5 = nanoTime();
                const ack_dg = ctx.server.pollProtectedShortDatagramWithInstalledKeys(@intCast(t5), &client_dcid) catch break orelse break;
                const t6 = nanoTime();
                _ = ctx.srv_ack_build_ns.fetchAdd(t6 - t5, .monotonic);
                defer ctx.server.allocator.free(ack_dg);
                ctx.socket.send(ctx.io, &ctx.client_addr, ack_dg) catch break;
                const t7 = nanoTime();
                _ = ctx.srv_ack_send_ns.fetchAdd(t7 - t6, .monotonic);
            }
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("=== quicz Per-Phase Profiling ===\n", .{});
    std.debug.print("Transfer: {d} MB | Datagram: {d} B | CUBIC\n\n", .{ transfer_size / (1024 * 1024), max_datagram_size });

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
    });
    var server = try quicz.Connection.init(allocator, .server, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
        .max_datagram_size = max_datagram_size,
    });

    try client.installOneRttTrafficSecrets(.{ .local = secrets.client.secret, .peer = secrets.server.secret });
    try server.installOneRttTrafficSecrets(.{ .local = secrets.server.secret, .peer = secrets.client.secret });
    try client.confirmHandshake();
    try server.confirmHandshake();
    try server.validatePeerAddress();

    var done = std.atomic.Value(bool).init(false);
    var bytes_received = std.atomic.Value(usize).init(0);
    var srv_recv_ns = std.atomic.Value(u64).init(0);
    var srv_process_ns = std.atomic.Value(u64).init(0);
    var srv_read_ns = std.atomic.Value(u64).init(0);
    var srv_ack_build_ns = std.atomic.Value(u64).init(0);
    var srv_ack_send_ns = std.atomic.Value(u64).init(0);
    var srv_packets = std.atomic.Value(u64).init(0);

    var server_ctx = ServerContext{
        .socket = &server_socket, .io = io, .server = &server,
        .done = &done, .bytes_received = &bytes_received, .client_addr = server_addr,
        .srv_recv_ns = &srv_recv_ns, .srv_process_ns = &srv_process_ns,
        .srv_read_ns = &srv_read_ns, .srv_ack_build_ns = &srv_ack_build_ns,
        .srv_ack_send_ns = &srv_ack_send_ns, .srv_packets = &srv_packets,
    };

    const srv_thread = try std.Thread.spawn(.{}, serverThread, .{&server_ctx});

    const stream_id = try client.openStream();
    var payload: [stream_chunk_size]u8 = undefined;
    @memset(&payload, 'X');
    var recv_buf: [10000]u8 = undefined;

    var total_queued: usize = 0;
    var pn: i64 = 0;
    var cli_feed_ns: u64 = 0;
    var cli_build_ns: u64 = 0;
    var cli_send_ns: u64 = 0;
    var cli_ack_recv_ns: u64 = 0;
    var cli_ack_process_ns: u64 = 0;
    var cli_packets_sent: u64 = 0;
    var cli_acks_received: u64 = 0;
    var cli_loop_iters: u64 = 0;

    const start_ns = nanoTime();

    while (total_queued < transfer_size) {
        cli_loop_iters += 1;
        const tf0 = nanoTime();
        var fed: usize = 0;
        while (total_queued < transfer_size and fed < 256) : (fed += 1) {
            const chunk = @min(payload.len, transfer_size - total_queued);
            const fin = total_queued + chunk >= transfer_size;
            client.sendOnStream(stream_id, payload[0..chunk], fin) catch break;
            total_queued += chunk;
        }
        cli_feed_ns += nanoTime() - tf0;

        while (true) {
            const tb0 = nanoTime();
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(tb0), &server_dcid) catch break orelse break;
            cli_build_ns += nanoTime() - tb0;
            defer allocator.free(dg);
            pn += 1;
            cli_packets_sent += 1;
            const ts0 = nanoTime();
            client_socket.send(io, &server_addr, dg) catch break;
            cli_send_ns += nanoTime() - ts0;
        }

        while (true) {
            const ta0 = nanoTime();
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            cli_ack_recv_ns += nanoTime() - ta0;
            cli_acks_received += 1;
            const tp0 = nanoTime();
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(tp0), server_dcid.len, ack.data) catch {};
            cli_ack_process_ns += nanoTime() - tp0;
        }
    }

    var wait: usize = 0;
    while (bytes_received.load(.monotonic) < transfer_size and wait < 10_000_000) : (wait += 1) {
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &server_dcid) catch break orelse break;
            defer allocator.free(dg);
            pn += 1;
            cli_packets_sent += 1;
            client_socket.send(io, &server_addr, dg) catch break;
        }
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(1) } }) catch break;
            cli_acks_received += 1;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), server_dcid.len, ack.data) catch {};
        }
    }

    const elapsed = nanoTime() - start_ns;
    done.store(true, .release);
    srv_thread.join();

    const received = bytes_received.load(.monotonic);
    const seconds = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    const mbps = @as(f64, @floatFromInt(received)) / (1024.0 * 1024.0) / seconds;
    const elapsed_f: f64 = @floatFromInt(elapsed);

    std.debug.print("  Throughput: {d:.2} MB/s  ({d:.3} ms)\n", .{ mbps, elapsed_f / 1_000_000.0 });
    std.debug.print("  Packets: {d} sent, {d} ACKs, {d} loop iters\n\n", .{ cli_packets_sent, cli_acks_received, cli_loop_iters });

    std.debug.print("  --- Client ---\n", .{});
    printPhase("  feed (sendOnStream)", cli_feed_ns, elapsed_f);
    printPhase("  build (poll+encrypt)", cli_build_ns, elapsed_f);
    printPhase("  send (UDP sendto)", cli_send_ns, elapsed_f);
    printPhase("  ack recv (UDP recvfrom)", cli_ack_recv_ns, elapsed_f);
    printPhase("  ack process (decrypt)", cli_ack_process_ns, elapsed_f);
    const cli_sum = cli_feed_ns + cli_build_ns + cli_send_ns + cli_ack_recv_ns + cli_ack_process_ns;
    printPhase("  OTHER (scheduling/gaps)", if (elapsed > cli_sum) elapsed - cli_sum else 0, elapsed_f);

    std.debug.print("\n  --- Server ---\n", .{});
    const s_recv = srv_recv_ns.load(.monotonic);
    const s_proc = srv_process_ns.load(.monotonic);
    const s_read = srv_read_ns.load(.monotonic);
    const s_abuild = srv_ack_build_ns.load(.monotonic);
    const s_asend = srv_ack_send_ns.load(.monotonic);
    const s_pkts = srv_packets.load(.monotonic);
    printPhase("  recv (UDP recvfrom)", s_recv, elapsed_f);
    printPhase("  process (decrypt)", s_proc, elapsed_f);
    printPhase("  stream read", s_read, elapsed_f);
    printPhase("  ack build (encrypt)", s_abuild, elapsed_f);
    printPhase("  ack send (UDP sendto)", s_asend, elapsed_f);
    const srv_sum = s_recv + s_proc + s_read + s_abuild + s_asend;
    printPhase("  OTHER (scheduling/gaps)", if (elapsed > srv_sum) elapsed - srv_sum else 0, elapsed_f);

    std.debug.print("\n  Server processed {d} packets\n", .{s_pkts});
    if (cli_packets_sent > 0) {
        std.debug.print("  Per-pkt client: build={d:.0}ns send={d:.0}ns\n", .{
            @as(f64, @floatFromInt(cli_build_ns)) / @as(f64, @floatFromInt(cli_packets_sent)),
            @as(f64, @floatFromInt(cli_send_ns)) / @as(f64, @floatFromInt(cli_packets_sent)),
        });
    }
    if (s_pkts > 0) {
        std.debug.print("  Per-pkt server: recv={d:.0}ns process={d:.0}ns\n", .{
            @as(f64, @floatFromInt(s_recv)) / @as(f64, @floatFromInt(s_pkts)),
            @as(f64, @floatFromInt(s_proc)) / @as(f64, @floatFromInt(s_pkts)),
        });
    }
    std.debug.print("\n  Done.\n", .{});
}

fn printPhase(label: []const u8, ns: u64, total_ns: f64) void {
    const pct = @as(f64, @floatFromInt(ns)) / total_ns * 100.0;
    const ms = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
    std.debug.print("{s:35} {d:10.3} ms  ({d:5.1}%)\n", .{ label, ms, pct });
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}
