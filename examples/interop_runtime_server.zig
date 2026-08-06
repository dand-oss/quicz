//! Runtime-based interop server: uses quicz.runtime.server.Server.
//! External QUIC clients (quic-go/quiche/s2n-quic) connect and echo.
//!
//! Usage: quicz-interop-runtime-server <port> <cert_pem> <key_pem>

const std = @import("std");
const quicz = @import("quicz");
const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;

const alpn = [_][]const u8{"hq-interop"};

/// Read a file into a stack buffer (PEM files are small).
fn readFile(io: std.Io, path: []const u8, buf: []u8) ![]u8 {
    const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
    defer file.close(io);
    const n = try file.readPositionalAll(io, buf, 0);
    return buf[0..n];
}

/// Echo every stream until the connection closes: receive to EOF, echo each
/// chunk back, FIN the echoed stream (QUIC-Interop-Runner echo semantics).
fn echoHandler(conn: ServerConnection) std.Io.Cancelable!void {
    var c = conn;
    var buf: [4096]u8 = undefined;
    while (true) {
        var stream = c.acceptStream() catch |e| {
            switch (e) {
                error.Canceled, error.ConnectionClosed => {},
                else => std.debug.print("runtime interop server: conn {d} acceptStream: {}\n", .{ c.id, e }),
            }
            return;
        };
        while (true) {
            const n = stream.receive(&buf) catch |e| {
                if (e != error.Canceled and e != error.ConnectionClosed) {
                    std.debug.print("runtime interop server: conn {d} stream {d} receive: {}\n", .{ c.id, stream.id, e });
                }
                break;
            };
            if (n == 0) break; // EOF: peer FIN fully consumed.
            stream.send(buf[0..n], false) catch |e| {
                std.debug.print("runtime interop server: conn {d} stream {d} send: {}\n", .{ c.id, stream.id, e });
                break;
            };
        }
        stream.send(&.{}, true) catch {}; // FIN the echoed stream.
    }
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const port = try std.fmt.parseInt(u16, args.next() orelse return error.MissingArgs, 10);
    const cert_pem = args.next() orelse return error.MissingArgs;
    const key_pem = args.next() orelse return error.MissingArgs;

    var cert_pem_buf: [64 * 1024]u8 = undefined;
    const cert_pem_data = try readFile(io, cert_pem, &cert_pem_buf);
    var cert_der_buf: [8192]u8 = undefined;
    const cert_der = try quicz.tls_pem.decodeBlock(cert_pem_data, "CERTIFICATE", &cert_der_buf);

    var key_pem_buf: [64 * 1024]u8 = undefined;
    const key_pem_data = try readFile(io, key_pem, &key_pem_buf);
    var key_der_buf: [512]u8 = undefined;
    const private_key = try quicz.tls_pem.parsePrivateKeyP256(key_pem_data, &key_der_buf);

    // PREFER_CHACHA20=1 negotiates ChaCha20-Poly1305 packet protection.
    const prefer_chacha20 = init.environ_map.get("PREFER_CHACHA20") != null;

    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn,
        .cert_der = cert_der,
        .private_key = &private_key,
        .prefer_chacha20 = prefer_chacha20,
    });
    defer server.deinit();
    try server.serve(&echoHandler);
    std.debug.print("runtime interop server on 127.0.0.1:{d}\n", .{port});

    // Block until killed (serveLoop runs as a concurrent task).
    server.drive_group.await(io) catch {};
}
