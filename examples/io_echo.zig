//! quicz I/O runtime — async streaming echo demo (std.Io async).
//!
//! The server driving task runs on std.Io Group.concurrent; the application
//! calls the streaming API accept()/receiveStreamData()/sendStreamData()
//! concurrently. The client runs the async streaming session.
//!
//! Usage: zig build run-io-echo

const std = @import("std");
const test_certs = @import("test_certs.zig");
const quicz = @import("quicz");
const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;
const Client = quicz.runtime.client.Client;

const port: u16 = 4433;

const alpn = [_][]const u8{"hq-interop"};

/// Server-side echo handler: one per connection (server.serve model);
/// accept a stream and echo the first chunk back.
fn echoHandler(conn: ServerConnection) std.Io.Cancelable!void {
    var c = conn;
    var stream = c.acceptStream() catch return;
    var buf: [4096]u8 = undefined;
    const n = stream.receive(&buf) catch return;
    stream.send(buf[0..n], false) catch {};
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var server = try Server.init(allocator, io, .{ .port = port, .alpn = &alpn, .cert_der = &test_certs.cert_der, .private_key = &test_certs.private_key });
    defer server.deinit();
    try server.serve(&echoHandler);
    std.debug.print("async streaming server on 127.0.0.1:{d}\n", .{port});

    var client = try Client.init(allocator, io, .{ .server_port = port, .server_name = "localhost", .alpn = &alpn });
    defer client.deinit();

    const payload = "hello quicz async streaming";
    const ok = try client.runEchoSession(payload);
    std.debug.print("async streaming echo: {s} ('{s}')\n", .{ if (ok) "SUCCESS" else "FAILED", payload });
}
