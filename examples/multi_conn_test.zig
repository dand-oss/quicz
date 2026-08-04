//! quicz I/O runtime — multi-connection test (std.http model).
//!
//! Follows std.http.Server's design: an accept loop spawns an independent
//! handler task per connection; each handler processes its connection without
//! blocking the accept loop or other connections.
const std = @import("std");
const quicz = @import("quicz");
const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;
const Client = quicz.runtime.client.Client;
const port: u16 = 4455;
const num_conns: usize = 3;
const streams_per_conn: usize = 2;
const stream_payload_len: usize = 512 * 1024;
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
const alpn = [_][]const u8{"hq-interop"};

/// Per-connection handler (std.http model): handles one connection's echo,
/// runs as its own task so it never blocks the accept loop or other conns.
fn handleConnection(conn: ServerConnection) std.Io.Cancelable!void {
    // std.http per-connection handler: read request data, write response.
    var c = conn;
    std.debug.print("[handler {d}] waiting for {d} streams...\n", .{ c.id, streams_per_conn });
    var si: usize = 0;
    while (si < streams_per_conn) : (si += 1) {
        var stream = c.acceptStream() catch |e| {
            std.debug.print("[handler {d}] acceptStream err {}\n", .{ c.id, e });
            return;
        };
        var buf: [65536]u8 = undefined;
        var total: usize = 0;
        while (true) {
            const n = stream.receive(&buf) catch break;
            if (n == 0) break; // EOF: peer FIN received and drained.
            stream.send(buf[0..n], false) catch break;
            total += n;
        }
        stream.send(&.{}, true) catch {}; // FIN the echoed stream.
        std.debug.print("[handler {d}] stream {d} echoed {d} bytes\n", .{ c.id, stream.id, total });
    }
}

/// Abrupt-close session: open a stream, send partial data WITHOUT a FIN,
/// then close the connection. The server handler must wake up with
/// error.ConnectionClosed instead of blocking on the stream forever.
fn abruptSession(allocator: std.mem.Allocator, io: std.Io) std.Io.Cancelable!void {
    runAbruptSession(allocator, io) catch |e| {
        std.debug.print("[client abrupt] session FAILED: {}\n", .{e});
    };
}

fn runAbruptSession(allocator: std.mem.Allocator, io: std.Io) !void {
    var client = try Client.init(allocator, io, .{ .server_port = port, .server_name = "localhost", .alpn = &alpn });
    defer client.deinit();
    try client.connect();
    var payload: [1024]u8 = undefined;
    @memset(&payload, 'Y');
    _ = try client.send(&payload, false);
    client.close();
    std.Io.sleep(io, std.Io.Duration.fromMilliseconds(50), .awake) catch {};
    std.debug.print("[client abrupt] closed connection without FIN\n", .{});
}

/// Concurrent-task wrapper: run one echo session, record failure in
/// `failed` (transport errors do not fit the Cancelable error set).
fn clientSession(allocator: std.mem.Allocator, io: std.Io, ci: usize, failed: *bool) std.Io.Cancelable!void {
    runClientSession(allocator, io, ci) catch |e| {
        std.debug.print("[client {d}] session FAILED: {}\n", .{ ci, e });
        @atomicStore(bool, failed, true, .release);
    };
}

/// One full client echo session; all sessions run concurrently.
fn runClientSession(allocator: std.mem.Allocator, io: std.Io, ci: usize) !void {
    std.debug.print("[client {d}] init+connect...\n", .{ci});
    var client = try Client.init(allocator, io, .{ .server_port = port, .server_name = "localhost", .alpn = &alpn });
    defer client.deinit();
    try client.connect();
    std.debug.print("[client {d}] connected\n", .{ci});
    const payload = try allocator.alloc(u8, stream_payload_len);
    defer allocator.free(payload);
    @memset(payload, 'X');
    var stream_ids: [streams_per_conn]u64 = undefined;
    for (0..streams_per_conn) |si| {
        stream_ids[si] = try client.send(payload, true);
    }
    var recv_buf: [65536]u8 = undefined;
    for (stream_ids) |sid| {
        var total: usize = 0;
        var got_eof = false;
        while (!got_eof) {
            const n = try client.receive(sid, &recv_buf);
            if (n == 0) {
                got_eof = true;
            } else {
                total += n;
            }
        }
        std.debug.print("[client {d}] stream {d} received {d}/{d} bytes eof={}\n", .{ ci, sid, total, payload.len, got_eof });
        if (total != payload.len) return error.EchoMismatch;
    }
    client.close();
    // Stay alive briefly so a lost close frame can be retransmitted by PTO
    // before the client endpoint is destroyed.
    std.Io.sleep(io, std.Io.Duration.fromMilliseconds(50), .awake) catch {};
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    var server = try Server.init(allocator, io, .{ .port = port, .alpn = &alpn, .cert_der = &certificate_der, .private_key = &server_private_key });
    defer server.deinit();
    try server.serve(&handleConnection);
    std.debug.print("server on 127.0.0.1:{d} (std.http per-connection handler model)\n", .{port});
    var session_failed: bool = false;
    var client_group: std.Io.Group = .init;
    for (0..num_conns) |ci| {
        try client_group.concurrent(io, clientSession, .{ allocator, io, ci, &session_failed });
    }
    try client_group.concurrent(io, abruptSession, .{ allocator, io });
    try client_group.await(io);
    if (@atomicLoad(bool, &session_failed, .acquire)) return error.EchoMismatch;
    // Give the drive task a few loops to observe the closes and reclaim
    // connection state, then assert nothing leaked.
    std.Io.sleep(io, std.Io.Duration.fromMilliseconds(300), .awake) catch {};
    while (!server.mutex.tryLock()) std.atomic.spinLoopHint();
    const live = server.conns.count();
    server.mutex.unlock();
    std.debug.print("[server] live connections after reap window: {d}\n", .{live});
    if (live != 0) return error.ConnectionLeak;
    std.debug.print("multi-connection test done\n", .{});
    server.stop();
}
