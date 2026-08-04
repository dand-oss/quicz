//! Runtime-based interop server: uses quicz.runtime.server.Server.
//! External QUIC clients (quic-go/quiche/s2n-quic) connect and echo.
//!
//! Usage: quicz-interop-runtime-server <port> <cert_pem> <key_pem>

const std = @import("std");
const quicz = @import("quicz");
const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;

const alpn = [_][]const u8{"hq-interop"};

/// Load a PEM certificate file and return the DER bytes (into der_buf).
fn loadPemCertificate(io: std.Io, path: []const u8, der_buf: []u8) ![]u8 {
    var pem_buf: [64 * 1024]u8 = undefined;
    const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
    defer file.close(io);
    const bytes_read = try file.readPositionalAll(io, &pem_buf, 0);
    const pem_data = pem_buf[0..bytes_read];
    const begin_marker = "-----BEGIN CERTIFICATE-----";
    const end_marker = "-----END CERTIFICATE-----";
    const begin = std.mem.indexOf(u8, pem_data, begin_marker) orelse return error.InvalidPem;
    const encoded_start = begin + begin_marker.len;
    const encoded_end = std.mem.indexOfPos(u8, pem_data, encoded_start, end_marker) orelse return error.InvalidPem;
    const encoded = std.mem.trim(u8, pem_data[encoded_start..encoded_end], " \t\r\n");
    const decoder = std.base64.standard.decoderWithIgnore("\r\n");
    const der_len = try decoder.decode(der_buf, encoded);
    return der_buf[0..der_len];
}

/// Load a PEM private key file and return the raw 32-byte P-256 key.
fn loadPemPrivateKey(io: std.Io, path: []const u8) ![32]u8 {
    var pem_buf: [64 * 1024]u8 = undefined;
    const file = try std.Io.Dir.openFileAbsolute(io, path, .{});
    defer file.close(io);
    const bytes_read = try file.readPositionalAll(io, &pem_buf, 0);
    const pem_data = pem_buf[0..bytes_read];
    const markers = [_][]const u8{
        "-----BEGIN PRIVATE KEY-----",
        "-----BEGIN EC PRIVATE KEY-----",
    };
    const end_markers = [_][]const u8{
        "-----END PRIVATE KEY-----",
        "-----END EC PRIVATE KEY-----",
    };
    for (markers, end_markers) |begin_marker, end_marker| {
        if (std.mem.indexOf(u8, pem_data, begin_marker)) |begin| {
            const encoded_start = begin + begin_marker.len;
            const encoded_end = std.mem.indexOfPos(u8, pem_data, encoded_start, end_marker) orelse continue;
            const encoded = std.mem.trim(u8, pem_data[encoded_start..encoded_end], " \t\r\n");
            var der_buf: [256]u8 = undefined;
            const decoder = std.base64.standard.decoderWithIgnore("\r\n");
            const der_len = decoder.decode(&der_buf, encoded) catch continue;
            const needle = [_]u8{ 0x02, 0x01, 0x01, 0x04, 0x20 };
            if (std.mem.indexOf(u8, der_buf[0..der_len], &needle)) |idx| {
                const start = idx + needle.len;
                if (start + 32 <= der_len) {
                    var key: [32]u8 = undefined;
                    @memcpy(&key, der_buf[start .. start + 32]);
                    return key;
                }
            }
        }
    }
    return error.InvalidPem;
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

    var cert_der_buf: [8192]u8 = undefined;
    const cert_der = try loadPemCertificate(io, cert_pem, &cert_der_buf);
    const private_key = try loadPemPrivateKey(io, key_pem);

    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn,
        .cert_der = cert_der,
        .private_key = &private_key,
    });
    defer server.deinit();
    try server.serve(&echoHandler);
    std.debug.print("runtime interop server on 127.0.0.1:{d}\n", .{port});

    // Block until killed (serveLoop runs as a concurrent task).
    server.drive_group.await(io) catch {};
}
