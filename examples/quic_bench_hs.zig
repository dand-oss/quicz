//! quicz throughput benchmark with a REAL TLS 1.3 handshake (RFC 9000 §7 / RFC 9001 §4).
//!
//! The installed-keys bypass (quic_bench.zig) skips the handshake and therefore the
//! transport-parameter exchange (RFC 9000 §7.4). This bench does a real handshake each
//! iteration (pattern from examples/interop_client.zig) and measures throughput with the
//! quic-go model: N self-contained iterations (fresh connection + handshake + transfer),
//! end-to-end time each, report mean/stddev.
const std = @import("std");
const builtin = @import("builtin");
const quicz = @import("quicz");

const Connection = quicz.Connection;
const Tls13Backend = quicz.tls13_backend.Tls13Backend;
const protection = quicz.protection;
const EcdsaP256Sha256 = std.crypto.sign.ecdsa.EcdsaP256Sha256;

const original_dcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
const client_scid = [_]u8{ 0x21, 0x22, 0x23, 0x24 };
const server_scid = [_]u8{ 0x31, 0x32, 0x33, 0x34 };

const max_datagram_size: usize = 8900;
const stream_chunk_size: usize = max_datagram_size - 128;
const transfer_size: usize = 16 * 1024 * 1024;
const bench_iters: usize = 5;

fn nanoTime() u64 {
    if (comptime builtin.os.tag == .macos) {
        const MachTimebaseInfo = extern struct { numer: u32, denom: u32 };
        const mt = struct {
            extern fn mach_timebase_info(info: *MachTimebaseInfo) i32;
            extern fn mach_absolute_time() u64;
            var tb: MachTimebaseInfo = undefined;
            var inited: bool = false;
            var t0: u64 = 0;
        };
        if (!mt.inited) {
            _ = mt.mach_timebase_info(&mt.tb);
            mt.t0 = mt.mach_absolute_time();
            mt.inited = true;
        }
        return (mt.mach_absolute_time() - mt.t0) * mt.tb.numer / mt.tb.denom;
    } else {
        var ts: std.os.linux.timespec = undefined;
        _ = std.os.linux.clock_gettime(.MONOTONIC, &ts);
        return @intCast(@as(i128, ts.sec) * 1_000_000_000 + ts.nsec);
    }
}

fn bindLoopback(io: std.Io) !std.Io.net.Socket {
    var address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    return address.bind(io, .{ .mode = .dgram, .protocol = .udp });
}

fn hsRecvTimeout() std.Io.Timeout {
    return .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(2000) } };
}

fn doHandshake(
    allocator: std.mem.Allocator,
    client: *Connection,
    server: *Connection,
    client_socket: *std.Io.net.Socket,
    server_socket: *std.Io.net.Socket,
    io: std.Io,
    client_backend: *Tls13Backend,
    server_backend: *Tls13Backend,
    scratch: []u8,
    recv_buf: []u8,
    secrets: protection.InitialSecrets,
) !void {
    _ = try client.driveCryptoBackendInSpace(.initial, client_backend.cryptoBackend(), scratch);
    const ch = (try client.pollProtectedLongCryptoDatagramInSpace(.initial, 40, &original_dcid, &client_scid, &[_]u8{}, secrets.client)) orelse return error.UnexpectedState;
    defer allocator.free(ch);
    try client_socket.send(io, &server_socket.address, ch);

    const r1 = try server_socket.receiveTimeout(io, recv_buf, hsRecvTimeout());
    try server.processProtectedLongDatagramInSpace(.initial, 41, secrets.client, r1.data);
    const s_prog = try server.driveCryptoBackendInSpace(.initial, server_backend.cryptoBackend(), scratch);
    if (!s_prog.handshake_keys_installed) return error.UnexpectedState;

    const sh = (try server.pollProtectedLongCryptoDatagramInSpace(.initial, 42, &client_scid, &server_scid, &[_]u8{}, secrets.server)) orelse return error.UnexpectedState;
    defer allocator.free(sh);
    try server_socket.send(io, &client_socket.address, sh);
    _ = try server.driveCryptoBackendInSpace(.handshake, server_backend.cryptoBackend(), scratch);
    const sf = (try server.pollProtectedHandshakeDatagramWithInstalledKeys(43, &client_scid, &server_scid)) orelse return error.UnexpectedState;
    defer allocator.free(sf);
    try server_socket.send(io, &client_socket.address, sf);

    const r2 = try client_socket.receiveTimeout(io, recv_buf, hsRecvTimeout());
    try client.processProtectedLongDatagramInSpace(.initial, 44, secrets.server, r2.data);
    _ = try client.driveCryptoBackendInSpace(.initial, client_backend.cryptoBackend(), scratch);

    const r3 = try client_socket.receiveTimeout(io, recv_buf, hsRecvTimeout());
    try client.processProtectedHandshakeDatagramWithInstalledKeys(45, r3.data);
    const c_prog = try client.driveCryptoBackendInSpace(.handshake, client_backend.cryptoBackend(), scratch);
    if (c_prog.outbound_bytes == 0) return error.UnexpectedState;
    const cf = (try client.pollProtectedHandshakeDatagramWithInstalledKeys(46, &server_scid, &client_scid)) orelse return error.UnexpectedState;
    defer allocator.free(cf);
    try client_socket.send(io, &server_socket.address, cf);

    const r4 = try server_socket.receiveTimeout(io, recv_buf, hsRecvTimeout());
    try server.processProtectedHandshakeDatagramWithInstalledKeys(47, r4.data);
    const s_drive = try server.driveCryptoBackendInSpace(.handshake, server_backend.cryptoBackend(), scratch);
    if (!s_drive.handshake_confirmed) return error.UnexpectedState;
}

const SrvCtx = struct {
    socket: *std.Io.net.Socket,
    io: std.Io,
    server: *Connection,
    done: *std.atomic.Value(bool),
    bytes_received: *std.atomic.Value(usize),
    client_addr: std.Io.net.IpAddress,
};

fn serverTransferThread(ctx: *SrvCtx) void {
    var recv_buf: [9000]u8 = undefined;
    var read_buf: [65536]u8 = undefined;
    var have_client_addr = false;
    while (!ctx.done.load(.acquire)) {
        var received_any = false;
        while (true) {
            const received = ctx.socket.receiveTimeout(ctx.io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            if (!have_client_addr) {
                ctx.client_addr = received.from;
                have_client_addr = true;
            }
            _ = ctx.server.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), client_scid.len, received.data) catch {};
            received_any = true;
        }
        if (!received_any) continue;
        while (true) {
            const n = ctx.server.recvOnStream(0, &read_buf) catch break orelse break;
            if (n == 0) break;
            _ = ctx.bytes_received.fetchAdd(n, .monotonic);
        }
        if (have_client_addr) {
            while (true) {
                const ack_dg = ctx.server.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &client_scid) catch break orelse break;
                defer ctx.server.allocator.free(ack_dg);
                ctx.socket.send(ctx.io, &ctx.client_addr, ack_dg) catch break;
            }
        }
    }
}

/// One self-contained iteration: fresh connections + real handshake + transfer + teardown.
fn runOneIteration(allocator: std.mem.Allocator, io: std.Io) !struct { tp: f64, hs_us: f64 } {
    var client_socket = try bindLoopback(io);
    defer client_socket.close(io);
    var server_socket = try bindLoopback(io);
    defer server_socket.close(io);
    const server_addr = server_socket.address;

    const seed = [_]u8{0x55} ** 32;
    const server_kp = try EcdsaP256Sha256.KeyPair.generateDeterministic(seed);
    const server_priv = server_kp.secret_key.bytes;
    const cert_der = [_]u8{ 0x30, 0x82, 0x01, 0x00, 0xDE, 0xAD, 0xBE, 0xEF };
    const alpn = [_][]const u8{"bench"};
    const secrets = try protection.deriveInitialSecrets(.v1, &original_dcid);

    var client = try Connection.init(allocator, .client, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
        .initial_max_streams_bidi = 8,
        .congestion_algorithm = .cubic,
        .max_datagram_size = max_datagram_size,
    });
    var server = try Connection.init(allocator, .server, .{
        .initial_max_data = 256 * 1024 * 1024,
        .initial_max_stream_data = 256 * 1024 * 1024,
        .initial_max_streams_bidi = 8,
        .max_datagram_size = max_datagram_size,
    });
    try server.validatePeerAddress();

    var client_backend = Tls13Backend.initClient(.{ .alpn = &alpn, .server_name = "example.com", .skip_cert_verify = true });
    var server_backend = Tls13Backend.initServer(.{ .alpn = &alpn, .cert_chain_der = &.{&cert_der}, .private_key_bytes = &server_priv, .private_key_algorithm = .ecdsa_p256_sha256 });

    var scratch: [16384]u8 = undefined;
    var hs_buf: [16384]u8 = undefined;
    try client.setLocalInitialSourceConnectionId(&client_scid);
    try server.setLocalInitialSourceConnectionId(&server_scid);

    const hs_t0 = nanoTime();
    try doHandshake(allocator, &client, &server, &client_socket, &server_socket, io, &client_backend, &server_backend, &scratch, &hs_buf, secrets);
    const hs_us = @as(f64, @floatFromInt(nanoTime() - hs_t0)) / 1000.0;

    var done = std.atomic.Value(bool).init(false);
    var bytes_received = std.atomic.Value(usize).init(0);
    var srv_ctx = SrvCtx{ .socket = &server_socket, .io = io, .server = &server, .done = &done, .bytes_received = &bytes_received, .client_addr = client_socket.address };
    const srv_thread = try std.Thread.spawn(.{}, serverTransferThread, .{&srv_ctx});

    var payload: [stream_chunk_size]u8 = undefined;
    @memset(&payload, 'X');
    var recv_buf: [9000]u8 = undefined;
    const stream_id = try client.openStream();
    var total_queued: usize = 0;

    const start_ns = nanoTime();
    while (total_queued < transfer_size) {
        var fed: usize = 0;
        while (total_queued < transfer_size and fed < 256) : (fed += 1) {
            const chunk = @min(payload.len, transfer_size - total_queued);
            const fin = total_queued + chunk >= transfer_size;
            client.sendOnStream(stream_id, payload[0..chunk], fin) catch break;
            total_queued += chunk;
        }
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &server_scid) catch break orelse break;
            defer allocator.free(dg);
            client_socket.send(io, &server_addr, dg) catch break;
        }
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), server_scid.len, ack.data) catch {};
        }
    }
    var wait: usize = 0;
    while (bytes_received.load(.monotonic) < transfer_size and wait < 10_000_000) : (wait += 1) {
        while (true) {
            const dg = client.pollProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), &server_scid) catch break orelse break;
            defer allocator.free(dg);
            client_socket.send(io, &server_addr, dg) catch break;
        }
        while (true) {
            const ack = client_socket.receiveTimeout(io, &recv_buf, .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMicroseconds(100) } }) catch break;
            _ = client.processProtectedShortDatagramWithInstalledKeys(@intCast(nanoTime()), server_scid.len, ack.data) catch {};
        }
    }
    const elapsed = nanoTime() - start_ns;
    done.store(true, .release);
    srv_thread.join();

    const seconds = @as(f64, @floatFromInt(elapsed)) / 1_000_000_000.0;
    const tp = @as(f64, @floatFromInt(transfer_size)) / (1024.0 * 1024.0) / seconds;
    return .{ .tp = tp, .hs_us = hs_us };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    std.debug.print("=== quicz Throughput Benchmark (REAL handshake, RFC 9000/9001) ===\n", .{});
    std.debug.print("Transfer: {d} MB | Datagram: {d} B | CUBIC | {d} iters\n\n", .{
        transfer_size / (1024 * 1024),
        max_datagram_size,
        bench_iters,
    });

    var tp_samples: [bench_iters]f64 = undefined;
    var it: usize = 0;
    while (it < bench_iters) : (it += 1) {
        const r = try runOneIteration(allocator, io);
        tp_samples[it] = r.tp;
        std.debug.print("  [iter {d}] {d:.2} MB/s  (handshake {d:.0} us)\n", .{ it, r.tp, r.hs_us });
    }

    var mean: f64 = 0;
    for (tp_samples) |s| mean += s;
    mean /= @as(f64, @floatFromInt(bench_iters));
    var var_acc: f64 = 0;
    for (tp_samples) |s| {
        const d = s - mean;
        var_acc += d * d;
    }
    const stddev = @sqrt(var_acc / @as(f64, @floatFromInt(bench_iters)));
    var min_tp = tp_samples[0];
    var max_tp = tp_samples[0];
    for (tp_samples) |s| {
        if (s < min_tp) min_tp = s;
        if (s > max_tp) max_tp = s;
    }
    std.debug.print("\n  {s:20} {d:.2} MB/s  (stddev {d:.1}%, min {d:.0}, max {d:.0}, {d} iters x {d} MB)\n", .{
        "Stream Upload",
        mean,
        stddev * 100.0 / mean,
        min_tp,
        max_tp,
        bench_iters,
        transfer_size / (1024 * 1024),
    });
    std.debug.print("\n=== Benchmark complete ===\n", .{});
}
