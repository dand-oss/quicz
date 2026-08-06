//! Runtime-based interop client: uses quicz.runtime.client.Client (not the
//! low-level Tls13ClientEndpoint). Validates the production API path against
//! external QUIC servers (quic-go / quiche / s2n-quic).
//!
//! Usage: quicz-interop-runtime-client <server_ip> <server_port> <ca_pem> [server_name]
//! Env:   TESTCASE=handshake|transfer|verified|multiconnect|keyupdate|v2 (default transfer)
//!
//! handshake    = stop after TLS 1.3 handshake confirmed
//! transfer     = handshake + bidirectional stream echo
//! verified     = handshake + certificate-verified stream echo (same as transfer with CA)
//! multiconnect = three sequential connections, each handshake + stream echo
//!                (QUIC-Interop-Runner `multiconnect` shape)
//! keyupdate    = handshake + echo on old keys, then a client-initiated 1-RTT
//!                key update (RFC 9001 §6) + echo on the updated keys
//!                (QUIC-Interop-Runner `keyupdate` shape)
//! v2           = QUIC v2 (RFC 9369) handshake + bidirectional stream echo
//!                (QUIC-Interop-Runner `v2` shape)

const std = @import("std");
const quicz = @import("quicz");
const Client = quicz.runtime.client.Client;

const alpn = [_][]const u8{"hq-interop"};
const echo_payload = "hello quicz interop";
/// Sent after the key update; the outgoing STREAM packet carries the new keys.
const post_key_update_payload = "quicz interop after key update";

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
    const keyupdate = std.mem.eql(u8, testcase, "keyupdate");
    const v2 = std.mem.eql(u8, testcase, "v2");
    const connections: usize = if (std.mem.eql(u8, testcase, "multiconnect")) 3 else 1;

    const server_addr = try std.Io.net.IpAddress.parseIp4(server_ip, server_port);

    // Load CA bundle (caller-owned; must outlive every Client).
    const now = std.Io.Clock.real.now(io);
    var ca_bundle: std.crypto.Certificate.Bundle = .empty;
    defer ca_bundle.deinit(allocator);
    try ca_bundle.addCertsFromFilePathAbsolute(allocator, io, now, ca_pem);

    var index: usize = 0;
    while (index < connections) : (index += 1) {
        try runSession(allocator, io, server_addr.ip4.bytes, server_port, server_name, &ca_bundle, handshake_only, keyupdate, v2);
        if (connections > 1) {
            std.debug.print("connection {d}/{d} done\n", .{ index + 1, connections });
        }
    }

    if (connections > 1) {
        std.debug.print("multiconnect_done=true certificate_verified=true alpn=hq-interop connections={d}\n", .{connections});
    }
}

/// One connection: handshake, then (unless handshake-only) a FIN-terminated
/// bidirectional stream echo; closes and deinits the client. With `keyupdate`
/// a second echo runs after a client-initiated 1-RTT key update.
fn runSession(
    allocator: std.mem.Allocator,
    io: std.Io,
    server_host: [4]u8,
    server_port: u16,
    server_name: []const u8,
    ca_bundle: *std.crypto.Certificate.Bundle,
    handshake_only: bool,
    keyupdate: bool,
    v2: bool,
) !void {
    const version: quicz.packet.Version = if (v2) .v2 else .v1;
    var client = try Client.init(allocator, io, .{
        .server_host = server_host,
        .server_port = server_port,
        .server_name = server_name,
        .alpn = &alpn,
        .ca_bundle = ca_bundle,
        .version = version,
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

    if (!keyupdate) {
        if (v2) {
            std.debug.print("v2_done=true certificate_verified=true alpn=hq-interop echo_bytes={d}\n", .{total});
        } else {
            std.debug.print("transfer_done=true certificate_verified=true alpn=hq-interop echo_bytes={d}\n", .{total});
        }
        client.close();
        return;
    }

    // keyupdate: initiate a 1-RTT key update, then run a second echo. The
    // outgoing STREAM packet is protected with the updated keys (that packet
    // carries the flipped key phase to the server), and the echoed bytes must
    // come back protected with the server's updated send keys (RFC 9001 §6.2).
    try client.initiateKeyUpdate();
    const ku_stream_id = try client.send(post_key_update_payload, true);
    var ku_total: usize = 0;
    while (ku_total < post_key_update_payload.len) {
        const n = try client.receive(ku_stream_id, &buf);
        if (n == 0) break;
        if (!std.mem.eql(u8, buf[0..n], post_key_update_payload[ku_total .. ku_total + n])) return error.EchoMismatch;
        ku_total += n;
    }
    if (ku_total != post_key_update_payload.len) return error.MissingStreamEcho;

    std.debug.print("keyupdate_done=true certificate_verified=true alpn=hq-interop echo_bytes={d}\n", .{ total + ku_total });
    client.close();
}
