//! Long-run stability benchmark on the production runtime.
//!
//! One process, one `runtime.Server` (std.Io.Threaded) serving `NUM_CLIENTS`
//! concurrent connections. Each client repeatedly opens streams and echoes a
//! payload for `DURATION_MS` (steady-state transfer), then disconnects. All
//! allocations go through a `DebugAllocator`; a clean `gpa.deinit()` at the
//! end proves no leaks across the whole run, and the per-client stats expose
//! transfer volume / errors / throughput over the sustained window.
//!
//! Run with a Debug build (leak checking) or ReleaseFast (throughput):
//!   zig build run-stability-bench                  # Debug, leak-checked
//!   zig build run-stability-bench -Doptimize=ReleaseFast

const std = @import("std");
const quicz = @import("quicz");
const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;
const Client = quicz.runtime.client.Client;

const port: u16 = 4438;
const num_clients: usize = 4;
const payload_len: usize = 256 * 1024;
const duration_ms: u64 = 30_000;
/// Overridden by the first CLI argument (ms); default 30 s.
var g_run_duration_ms: u64 = duration_ms;
const alpn = [_][]const u8{"hq-interop"};

// Local test-only P-256 key pair (same static identity used by the other
// loopback examples; ALPN is the only selector).
const server_private_key = [_]u8{
    0x5b, 0xbf, 0x4f, 0x5a, 0x48, 0x42, 0x9f, 0x00,
    0x5a, 0x57, 0x09, 0xc3, 0xb4, 0xc1, 0x3a, 0x64,
    0x2e, 0xb1, 0x61, 0xf5, 0x0b, 0xde, 0x64, 0x4b,
    0x3a, 0x38, 0xa6, 0x8f, 0xfa, 0x48, 0xda, 0x51,
};
const certificate_der = [_]u8{
    0x30, 0x82, 0x01, 0xbd, 0x30, 0x82, 0x01, 0x63, 0xa0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x14, 0x5d,
    0x93, 0x26, 0x1c, 0x8e, 0x4b, 0x65, 0x95, 0x73, 0x42, 0x0f, 0x89, 0x22, 0xda, 0x65, 0x26, 0x9e,
    0x30, 0x0a, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x02, 0x30, 0x1a, 0x31, 0x18,
    0x30, 0x16, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0c, 0x0f, 0x71, 0x75, 0x69, 0x63, 0x7a, 0x20, 0x74,
    0x65, 0x73, 0x74, 0x20, 0x63, 0x65, 0x72, 0x74, 0x30, 0x1e, 0x17, 0x0d, 0x32, 0x35, 0x30, 0x31,
    0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x5a, 0x17, 0x0d, 0x33, 0x35, 0x30, 0x31, 0x30,
    0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x5a, 0x30, 0x1a, 0x31, 0x18, 0x30, 0x16, 0x06, 0x03,
    0x55, 0x04, 0x03, 0x0c, 0x0f, 0x71, 0x75, 0x69, 0x63, 0x7a, 0x20, 0x74, 0x65, 0x73, 0x74, 0x20,
    0x63, 0x65, 0x72, 0x74, 0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00, 0x04, 0x8e,
    0x33, 0x73, 0x67, 0xd2, 0x54, 0x24, 0x51, 0xa4, 0x65, 0x48, 0x93, 0x1c, 0x73, 0x07, 0x36, 0x03,
    0x9e, 0x74, 0x04, 0x72, 0x2c, 0x95, 0x67, 0x25, 0xd9, 0x1a, 0x34, 0x50, 0x83, 0x9d, 0x90, 0x45,
    0x59, 0x0a, 0x36, 0x6a, 0x45, 0x76, 0x1e, 0x22, 0x22, 0x4d, 0x0a, 0x24, 0x74, 0x14, 0x09, 0x7f,
    0x0a, 0x24, 0x45, 0x27, 0x0b, 0x64, 0x0e, 0x0e, 0x68, 0x30, 0x66, 0x30, 0x0e, 0x06, 0x03, 0x55,
    0x1d, 0x0f, 0x01, 0x01, 0xff, 0x04, 0x04, 0x03, 0x02, 0x05, 0xa0, 0x30, 0x1d, 0x06, 0x03, 0x55,
    0x1d, 0x25, 0x04, 0x16, 0x30, 0x14, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01,
    0x06, 0x08, 0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x02, 0x30, 0x1f, 0x06, 0x03, 0x55, 0x1d,
    0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0x9b, 0x47, 0x24, 0x55, 0xc9, 0x43, 0x91, 0x26, 0x08,
    0x05, 0x4c, 0x4c, 0x43, 0x48, 0x45, 0x43, 0x4b, 0x45, 0x44, 0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d,
    0x0e, 0x04, 0x16, 0x04, 0x14, 0x9b, 0x47, 0x24, 0x55, 0xc9, 0x43, 0x91, 0x26, 0x08, 0x05, 0x4c,
    0x4c, 0x43, 0x48, 0x45, 0x43, 0x4b, 0x45, 0x44, 0x30, 0x0a, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce,
    0x3d, 0x04, 0x03, 0x02, 0x03, 0x48, 0x00, 0x30, 0x45, 0x02, 0x21, 0x00, 0xd7, 0x0d, 0x76, 0x3e,
    0x31, 0x78, 0x25, 0x73, 0x17, 0x92, 0x46, 0x05, 0x81, 0x29, 0x35, 0x0b, 0x97, 0x64, 0x22, 0x0c,
    0x58, 0x38, 0x06, 0x12, 0x54, 0x37, 0x38, 0x35, 0x02, 0x20, 0x47, 0x20, 0x68, 0x42, 0x18, 0x07,
    0x36, 0x62, 0x20, 0x62, 0x0e, 0x3f, 0x42, 0x47, 0x65, 0x6e, 0x65, 0x72, 0x61, 0x74, 0x65, 0x64,
    0x20, 0x62, 0x79, 0x20, 0x71, 0x75, 0x69, 0x63, 0x7a,
};

const Stats = struct {
    transfer_bytes: u64 = 0,
    errors: u64 = 0,
    ok: bool = false,
};

/// Server echo handler: one per connection (server.serve model); read the full
/// stream to EOF and echo every chunk back.
fn echoHandler(conn: ServerConnection) std.Io.Cancelable!void {
    var c = conn;
    // Serve every stream on this connection until it closes.
    while (true) {
        var stream = c.acceptStream() catch return;
        var buf: [65536]u8 = undefined;
        while (true) {
            const n = stream.receive(&buf) catch break;
            if (n == 0) {
                // Client sent FIN; echo-terminate so the client stream fully
                // completes and releases its stream slot.
                stream.send(&.{}, true) catch break;
                break;
            }
            stream.send(buf[0..n], false) catch break;
        }
    }
}

fn clientSession(io: std.Io, allocator: std.mem.Allocator, idx: usize, stats: []Stats) std.Io.Cancelable!void {
    var client = Client.init(allocator, io, .{
        .server_port = port,
        .server_name = "localhost",
        .alpn = &alpn,
        .insecure_skip_verify = true,
    }) catch {
        stats[idx].errors += 1;
        return;
    };
    _ = &client;
    defer client.deinit();

    client.connect() catch {
        stats[idx].errors += 1;
        return;
    };

    var payload = allocator.alloc(u8, payload_len) catch return;
    _ = &payload;
    defer allocator.free(payload);
    @memset(payload, @intCast('A' + @mod(idx, 26)));

    const t0 = std.Io.Timestamp.now(io, .awake);
    var transferred: u64 = 0;
    var errors: u64 = 0;
    while (true) {
        const now = std.Io.Timestamp.now(io, .awake);
        if (now.nanoseconds - t0.nanoseconds >= @as(i96, @intCast(g_run_duration_ms)) * 1_000_000) break;

        const sid = client.send(payload, true) catch {
            errors += 1;
            break;
        };
        var received: usize = 0;
        var rbuf: [65536]u8 = undefined;
        while (received < payload.len) {
            const n = client.receive(sid, &rbuf) catch break;
            if (n == 0) break;
            received += n;
        }
        if (received == payload.len) {
            // Consume the FIN so the stream completes and frees its slot.
            _ = client.receive(sid, &rbuf) catch {};
            transferred += payload.len;
        } else {
            errors += 1;
        }
    }
    stats[idx] = .{ .transfer_bytes = transferred, .errors = errors, .ok = true };
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    // Optional first argument overrides the run duration in milliseconds
    // (default 30 s; use e.g. 3600000 for a one-hour soak).
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next(); // program name
    g_run_duration_ms = if (args.next()) |arg|
        std.fmt.parseInt(u64, arg, 10) catch duration_ms
    else
        duration_ms;

    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn,
        .cert_der = &certificate_der,
        .private_key = &server_private_key,
    });
    var server_deinited = false;
    errdefer if (!server_deinited) server.deinit();
    try server.serve(&echoHandler);
    std.debug.print("stability bench: server on 127.0.0.1:{d}, clients={d}, duration={d} ms\n", .{ port, num_clients, g_run_duration_ms });

    var stats: [num_clients]Stats = .{Stats{}} ** num_clients;
    var group: std.Io.Group = .init;
    for (0..num_clients) |i| {
        try group.concurrent(io, clientSession, .{ io, allocator, i, &stats });
    }
    try group.await(io);

    server.stop();
    server.deinit();
    server_deinited = true;

    var total_bytes: u64 = 0;
    var total_errors: u64 = 0;
    var all_ok = true;
    for (stats, 0..) |s, i| {
        total_bytes += s.transfer_bytes;
        total_errors += s.errors;
        if (!s.ok or s.errors > 0) all_ok = false;
        std.debug.print("  client {d}: {d} bytes  {d} errors\n", .{ i, s.transfer_bytes, s.errors });
    }
    const seconds: f64 = @as(f64, @floatFromInt(g_run_duration_ms)) / 1000.0;
    std.debug.print(
        "stability bench: ok={} bytes={d} errors={d}  aggregate={d:.1} Mbit/s\n",
        .{ all_ok, total_bytes, total_errors, @as(f64, @floatFromInt(total_bytes)) * 8.0 / 1e6 / seconds },
    );

    // Leak check: any allocation not freed by server/client deinit is reported.
    const check = gpa.deinit();
    if (check != .ok) return error.MemoryLeak;
    if (!all_ok) return error.StabilityFailed;
}
