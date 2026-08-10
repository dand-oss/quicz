//! QUIC DATAGRAM (RFC 9221) echo demo.
//!
//! Usage:
//!   zig build run-datagram-echo -- --server   # terminal 1
//!   zig build run-datagram-echo -- --client   # terminal 2
//!
//! Demonstrates unreliable QUIC DATAGRAM extension (RFC 9221):
//! - Server echoes any received DATAGRAM payload back to the sender.
//! - Client sends "hello datagram" and prints the echoed response.
//!
//! DATAGRAM frames bypass stream reliability — no retransmission, no
//! ordering guarantee, no flow control. Useful for real-time media,
//! gaming state sync, or any latency-sensitive unreliable data.

const std = @import("std");
const test_certs = @import("test_certs.zig");
const quicz = @import("quicz");

const Connection = quicz.Connection;
const Tls13ServerTransport = quicz.Tls13ServerTransport;
const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;
const endpoint = quicz.endpoint;
const quic_packet = quicz.packet;

const max_datagram_size: usize = 8192;

const ServerRecord = struct {
    handle: u64,
    transport: Tls13ServerTransport,
    retry_validated: bool = false,

    fn connectionRef(self: *@This()) *Connection {
        return self.transport.connectionRef();
    }
    fn cryptoBackend(self: *@This()) quicz.CryptoBackend {
        return self.transport.cryptoBackend();
    }
    fn destinationConnectionId(self: *const @This()) []const u8 {
        return self.transport.connection.peerDestinationConnectionId() orelse
            self.transport.peerInitialSourceConnectionId();
    }
    fn sourceConnectionId(self: *const @This()) []const u8 {
        return self.transport.localInitialSourceConnectionId();
    }
    fn initialDestinationConnectionId(self: *const @This()) []const u8 {
        return if (self.retry_validated)
            self.transport.localInitialSourceConnectionId()
        else
            self.transport.originalDestinationConnectionId();
    }
    fn markRetryValidated(self: *@This()) void {
        self.retry_validated = true;
    }
    fn deinit(self: *@This()) void {
        self.transport.deinit();
    }
};

const ServerEndpoint = quicz.Tls13ServerEndpoint(
    ServerRecord,
    ServerRecord.connectionRef,
    ServerRecord.cryptoBackend,
    ServerRecord.destinationConnectionId,
    ServerRecord.sourceConnectionId,
    ServerRecord.initialDestinationConnectionId,
    ServerRecord.markRetryValidated,
    ServerRecord.deinit,
);

fn runServer(allocator: std.mem.Allocator, io: std.Io, stop: *const std.atomic.Value(bool)) !void {
    var address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = .{ 127, 0, 0, 1 }, .port = 4433 } };
    var socket = try address.bind(io, .{ .mode = .dgram, .protocol = .udp });
    defer socket.close(io);
    std.debug.print("datagram echo server: listening on 127.0.0.1:4433\n", .{});

    var server_ep = try ServerEndpoint.initWithCapacity(allocator, 16, .{
        .max_routes = 64,
        .max_stateless_reset_tokens = 64,
    });
    defer server_ep.deinit();

    var recv_buf: [max_datagram_size]u8 = undefined;
    var next_handle: u64 = 1;
    const alpn = [_][]const u8{"hq-interop"};

    while (!stop.load(.acquire)) {
        const timeout = std.Io.Timeout{ .duration = .{
            .clock = .awake,
            .raw = std.Io.Duration.fromMilliseconds(100),
        } };
        const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
        const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
        const local_addr = endpoint.Udp4Address.init(socket.address.ip4.bytes, socket.address.ip4.port);
        const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };

        var initial_out: [4]quicz.endpoint_types.EndpointPolledDatagramResult = undefined;
        var handshake_out: [4]quicz.endpoint_types.EndpointPolledDatagramResult = undefined;
        var installed_out: [16]ServerEndpoint.DatagramPathResult = undefined;
        var pending_out: [16]ServerEndpoint.DatagramPathResult = undefined;
        var scratch: [8192]u8 = undefined;

        const action = server_ep.feedDatagram(&scratch, path, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1}) catch continue;

        var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = from_addr.octets, .port = from_addr.port } };
        switch (action) {
            .accept_initial => |initial_accept| {
                const handle = next_handle;
                next_handle += 1;
                var server_scid: [8]u8 = undefined;
                io.randomSecure(&server_scid) catch {};

                const record = allocator.create(ServerRecord) catch continue;
                record.* = .{
                    .handle = handle,
                    .transport = Tls13ServerTransport.init(allocator, .{
                        .initial_max_data = 65536,
                        .initial_max_stream_data = 16384,
                        .initial_max_streams_bidi = 128,
                        .initial_max_streams_uni = 128,
                        .max_datagram_size = max_datagram_size,
                        .max_idle_timeout_ms = 30000,
                        .max_datagram_frame_size = 65535,
                    }, .{
                        .alpn = &alpn,
                        .cert_chain_der = &.{&test_certs.cert_der},
                        .private_key_bytes = &test_certs.private_key,
                        .private_key_algorithm = .ecdsa_p256_sha256,
                    }) catch {
                        allocator.destroy(record);
                        continue;
                    },
                };
                record.transport.connection.validatePeerAddress() catch {};
                record.transport.setLocalInitialSourceConnectionId(&server_scid) catch {};
                const initial_info = quicz.protection.peekProtectedLongPacketInfo(received.data) catch {
                    record.transport.deinit();
                    allocator.destroy(record);
                    continue;
                };
                record.transport.setOriginalDestinationConnectionId(initial_info.dcid) catch {};

                const accepted = server_ep.acceptInitialRecord(
                    handle,
                    record,
                    0,
                    initial_accept,
                    &server_scid,
                    received.data,
                    .{},
                    &scratch,
                    &initial_out,
                    &handshake_out,
                ) catch {
                    record.transport.deinit();
                    allocator.destroy(record);
                    continue;
                };

                for (initial_out[0..accepted.initial.drain.datagrams_written]) |o| {
                    socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
                if (accepted.handshake) |hs| {
                    for (handshake_out[0..hs.drain.datagrams_written]) |o| {
                        socket.send(io, &dest, o.datagram) catch {};
                        allocator.free(o.datagram);
                    }
                }
                std.debug.print("connection {d} accepted (datagram-enabled)\n", .{handle});
            },
            .routed => {
                const step = server_ep.receiveDatagramStepWithRoutePath(
                    allocator,
                    path,
                    0,
                    received.data,
                    &[_]u8{},
                    &[_]quic_packet.Version{.v1},
                    .{ .space = .application, .out = &scratch, .unpredictable_prefix = &[_]u8{}, .supported_versions = &[_]quic_packet.Version{.v1} },
                    &scratch,
                    &[_]u8{},
                    &initial_out,
                    &handshake_out,
                    &installed_out,
                    .application,
                    &pending_out,
                ) catch continue;

                // Echo DATAGRAM frames back
                switch (step.process) {
                    .routed => |routed| switch (routed) {
                        .installed_key => |ik| {
                            if (ik.feed) |feed| {
                                if (feed.feed == .routed) {
                                    const conn_id = feed.feed.routed.connection_id;
                                    if (server_ep.records.get(conn_id)) |rec| {
                                        const conn = rec.transport.connectionRef();
                                        var dgram_buf: [1200]u8 = undefined;
                                        while (conn.recvDatagram(&dgram_buf) catch null) |n| {
                                            if (n > 0) {
                                                std.debug.print("datagram echo: {d} bytes: '{s}'\n", .{ n, dgram_buf[0..n] });
                                                conn.sendDatagram(dgram_buf[0..n]) catch {};
                                            }
                                        }
                                    }
                                }
                            }
                            for (installed_out[0..ik.drain.datagrams_written]) |o| {
                                socket.send(io, &dest, o.datagram) catch {};
                                allocator.free(o.datagram);
                            }
                        },
                        else => {},
                    },
                    else => {},
                }
                var drain_out: [16]ServerEndpoint.DatagramPathResult = undefined;
                const drain = server_ep.drainDatagramsAcrossRecordsWithRoutePathWithScratch(0, .application, &drain_out);
                for (drain_out[0..drain.datagrams_written]) |o| {
                    socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
                for (pending_out[0..step.pending_drain.datagrams_written]) |o| {
                    socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
            },
            else => {},
        }
    }
}

fn runClient(allocator: std.mem.Allocator, io: std.Io) !void {
    const server_port: u16 = 4433;

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
            .max_datagram_frame_size = 65535,
        },
        .{ .alpn = &alpn, .server_name = "localhost", .skip_cert_verify = true },
        original_dcid,
        client_scid,
    );
    defer client.deinit();

    var scratch: [8192]u8 = undefined;
    const begin_result = try client.beginWithRoutePath(0, &scratch);
    try socket.send(io, &server_address, begin_result.datagram);
    allocator.free(begin_result.datagram);
    std.debug.print("datagram echo client: Initial sent, waiting for handshake...\n", .{});

    var recv_buf: [max_datagram_size]u8 = undefined;
    var handshake_done = false;
    var attempts: usize = 0;
    while (!handshake_done and attempts < 20) : (attempts += 1) {
        const timeout = std.Io.Timeout{ .duration = .{
            .clock = .awake,
            .raw = std.Io.Duration.fromMilliseconds(5000),
        } };
        const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
        const result = client.receiveWithRoutePath(0, &scratch, received.data) catch continue;
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

    // Send DATAGRAM
    const msg = "hello datagram";
    try client.transport.connectionRef().sendDatagram(msg);
    var send_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
    const drain = try client.drainApplicationDatagramsWithRoutePath(0, &send_out);
    for (send_out[0..drain.datagrams_written]) |o| {
        try socket.send(io, &server_address, o.datagram);
        allocator.free(o.datagram);
    }
    std.debug.print("sent DATAGRAM: '{s}'\n", .{msg});

    // Wait for echo
    var got_echo = false;
    var echo_attempts: usize = 0;
    while (!got_echo and echo_attempts < 20) : (echo_attempts += 1) {
        const timeout = std.Io.Timeout{ .duration = .{
            .clock = .awake,
            .raw = std.Io.Duration.fromMilliseconds(5000),
        } };
        const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
        _ = client.receiveWithRoutePath(0, &scratch, received.data) catch continue;
        var dgram_buf: [1200]u8 = undefined;
        if (client.transport.connectionRef().recvDatagram(&dgram_buf) catch null) |n| {
            if (n > 0) {
                std.debug.print("datagram echo received: '{s}'\n", .{dgram_buf[0..n]});
                got_echo = true;
            }
        }
    }

    if (got_echo) {
        std.debug.print("datagram_echo: SUCCESS\n", .{});
    } else {
        std.debug.print("datagram_echo: no echo received\n", .{});
    }
}

/// Single-process loopback: run the server event loop as an async task while
/// the client drives the handshake + DATAGRAM echo on the main thread.
fn runLoopback(allocator: std.mem.Allocator, io: std.Io) !void {
    var stop = std.atomic.Value(bool).init(false);
    var group: std.Io.Group = .init;
    const server_task_args = .{ allocator, io, &stop };
    try group.concurrent(io, runServerTask, server_task_args);
    try runClient(allocator, io);
    stop.store(true, .release);
    group.cancel(io);
    group.await(io) catch {};
}

fn runServerTask(allocator: std.mem.Allocator, io: std.Io, stop: *std.atomic.Value(bool)) std.Io.Cancelable!void {
    runServer(allocator, io, stop) catch |err| {
        if (err != error.Canceled) std.debug.print("datagram echo server task: {}\n", .{err});
    };
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    // Parse --server / --client; default is a single-process loopback demo.
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next(); // skip program name
    const mode = args.next() orelse "loopback";

    if (std.mem.eql(u8, mode, "--server")) {
        var stop = std.atomic.Value(bool).init(false);
        try runServer(allocator, io, &stop);
    } else if (std.mem.eql(u8, mode, "--client")) {
        try runClient(allocator, io);
    } else {
        try runLoopback(allocator, io);
    }
}
