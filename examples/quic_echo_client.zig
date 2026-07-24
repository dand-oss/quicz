//! QUIC echo client — connects to quic_echo_server and echoes stream data.
//!
//! Usage:
//!   zig build run-quic-echo-client
//!
//! Connects to 127.0.0.1:4433, sends "hello quicz" on a bidirectional
//! stream, prints the echo response, then closes.
//! Demonstrates: Tls13ClientEndpoint handshake, stream I/O, close.

const std = @import("std");
const quicz = @import("quicz");

const endpoint = quicz.endpoint;
const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;

const max_datagram_size: usize = 8192;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    const server_port: u16 = 4433;

    // Bind UDP socket
    var client_address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    var socket = try client_address.bind(io, .{ .mode = .dgram, .protocol = .udp });
    defer socket.close(io);

    var server_address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = .{ 127, 0, 0, 1 }, .port = server_port } };

    const local_bytes = socket.address.ip4.bytes;
    const local_port = socket.address.ip4.port;
    const remote_bytes = [_]u8{ 127, 0, 0, 1 };

    const client_path = endpoint.Udp4Tuple{
        .local = endpoint.Udp4Address.init(local_bytes, local_port),
        .remote = endpoint.Udp4Address.init(remote_bytes, server_port),
    };
    const original_dcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
    const client_scid = [_]u8{ 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28 };
    const alpn = [_][]const u8{"hq-interop"};

    var client = try Tls13ClientEndpoint.init(
        allocator,
        1,
        client_path,
        .{ .active_migration_disabled = true },
        .{
            .initial_max_data = 1_048_576,
            .initial_max_stream_data = 1_048_576,
            .initial_max_streams_bidi = 128,
            .initial_max_streams_uni = 128,
            .max_datagram_size = max_datagram_size,
        },
        .{ .alpn = &alpn, .server_name = "localhost", .skip_cert_verify = true },
        original_dcid,
        client_scid,
    );
    defer client.deinit();

    // Begin handshake
    var scratch: [8192]u8 = undefined;
    const begin_result = try client.beginWithRoutePath(0, &scratch);
    try socket.send(io, &server_address, begin_result.datagram);
    allocator.free(begin_result.datagram);
    std.debug.print("Initial sent, waiting for handshake...\n", .{});

    // Handshake loop
    var recv_buf: [max_datagram_size]u8 = undefined;
    var handshake_done = false;
    var attempts: usize = 0;
    while (!handshake_done and attempts < 20) : (attempts += 1) {
        const n = blk: {
            const timeout = std.Io.Timeout{ .duration = .{
                .clock = .awake,
                .raw = std.Io.Duration.fromMilliseconds(5000),
            } };
            const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            break :blk received.data.len;
        };
        const result = client.receiveWithRoutePath(0, &scratch, recv_buf[0..n]) catch continue;
        if (result.outbound_initial) |o| {
            socket.send(io, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }
        if (result.outbound_handshake) |o| {
            socket.send(io, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }
        if (client.handshakeConfirmed()) {
            handshake_done = true;
            std.debug.print("handshake confirmed\n", .{});
        }
    }
    if (!handshake_done) {
        std.debug.print("handshake failed\n", .{});
        return error.HandshakeFailed;
    }

    // Open stream and send data
    const stream_id = try client.openStream();
    var send_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
    const send_result = try client.sendStreamWithRoutePathAndDrainDatagrams(
        stream_id,
        "hello quicz",
        true,
        0,
        &send_out,
    );
    for (send_out[0..send_result.drain.datagrams_written]) |o| {
        try socket.send(io, &server_address, o.datagram);
        allocator.free(o.datagram);
    }
    std.debug.print("sent 'hello quicz' on stream {d}\n", .{stream_id});

    // Wait for echo
    var got_echo = false;
    var echo_attempts: usize = 0;
    while (!got_echo and echo_attempts < 20) : (echo_attempts += 1) {
        const n = blk: {
            const timeout = std.Io.Timeout{ .duration = .{
                .clock = .awake,
                .raw = std.Io.Duration.fromMilliseconds(5000),
            } };
            const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            break :blk received.data.len;
        };
        _ = client.receiveWithRoutePath(0, &scratch, recv_buf[0..n]) catch continue;
        var stream_buf: [4096]u8 = undefined;
        if (try client.recvStream(stream_id, &stream_buf)) |len| {
            if (len > 0) {
                std.debug.print("echo received: '{s}'\n", .{stream_buf[0..len]});
                got_echo = true;
            }
        }
    }

    if (got_echo) {
        std.debug.print("quic_echo_client: SUCCESS\n", .{});
    } else {
        std.debug.print("quic_echo_client: no echo received\n", .{});
    }

    // Close
    const close_dgram = client.close(0, 0, "done", 0) catch null;
    if (close_dgram) |dgram| {
        socket.send(io, &server_address, dgram) catch {};
        allocator.free(dgram);
    }
}
