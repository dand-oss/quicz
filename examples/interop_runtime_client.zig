//! Runtime-based interop client: uses quicz.runtime.client.Client (not the
//! low-level Tls13ClientEndpoint). Validates the production API path against
//! external QUIC servers (quic-go / quiche / s2n-quic).
//!
//! Usage: quicz-interop-runtime-client <server_ip> <server_port> <ca_pem> [server_name]
//! Env:   TESTCASE=handshake|transfer|verified (default transfer)
//!
//! handshake = stop after TLS 1.3 handshake confirmed
//! transfer  = handshake + bidirectional stream echo
//! verified  = handshake + certificate-verified stream echo (same as transfer with CA)

const std = @import("std");
const quicz = @import("quicz");
const Client = quicz.runtime.client.Client;

const alpn = [_][]const u8{"hq-interop"};
const echo_payload = "hello quicz interop";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const server_ip = args.next() orelse return error.MissingArgs;
    const server_port = try std.fmt.parseInt(u16, args.next() orelse return error.MissingArgs, 10);
    const ca_pem = args.next() orelse return error.MissingArgs;
    const server_name = args.next() orelse "localhost";
    if (!std.Io.Dir.path.isAbsolute(ca_pem)) return error.CaPathMustBeAbsolute;

    const testcase = init.environ_map.get("TESTCASE") orelse "transfer";
    const handshake_only = std.mem.eql(u8, testcase, "handshake");

    const server_addr = try std.Io.net.IpAddress.parseIp4(server_ip, server_port);

    // Load CA bundle (caller-owned; must outlive Client).
    const now = std.Io.Clock.real.now(io);
    var ca_bundle: std.crypto.Certificate.Bundle = .empty;
    defer ca_bundle.deinit(allocator);
    try ca_bundle.addCertsFromFilePathAbsolute(allocator, io, now, ca_pem);

    var client = try Client.init(allocator, io, .{
        .server_host = server_addr.ip4.bytes,
        .server_port = server_port,
        .server_name = server_name,
        .alpn = &alpn,
        .ca_bundle = &ca_bundle,
    });
    defer client.deinit();

    try client.connect();

    if (handshake_only) {
        std.debug.print("handshake_done=true certificate_verified=true alpn=hq-interop\n", .{});
        client.close();
        return;
    }

    // transfer / verified: open a stream, send payload with FIN, receive echo.
    const stream_id = try client.send(echo_payload, true);
    var buf: [4096]u8 = undefined;
    var total: usize = 0;
    while (total < echo_payload.len) {
        const n = try client.receive(stream_id, &buf);
        if (n == 0) break;
        if (!std.mem.eql(u8, buf[0..n], echo_payload[total .. total + n])) return error.EchoMismatch;
        total += n;
    }
    if (total != echo_payload.len) return error.MissingStreamEcho;

    std.debug.print("transfer_done=true certificate_verified=true alpn=hq-interop echo_bytes={d} testcase={s}\n", .{ total, testcase });
    client.close();
}
