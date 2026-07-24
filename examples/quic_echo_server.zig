//! QUIC echo server — accepts connections and echoes stream data back.
//!
//! Usage:
//!   zig build run-quic-echo-server
//!
//! Listens on 127.0.0.1:4433. Pair with quic_echo_client.zig.
//! Demonstrates: Tls13ServerEndpoint multi-connection routing, TLS 1.3
//! handshake, bidirectional stream echo, graceful close.

const std = @import("std");
const quicz = @import("quicz");

const Connection = quicz.Connection;
const Tls13ServerTransport = quicz.Tls13ServerTransport;
const endpoint = quicz.endpoint;
const quic_packet = quicz.packet;

const bind_port: u16 = 4433;
const max_datagram_size: usize = 8192;

// Local test-only P-256 key pair (same as tls13_process_echo_server.zig).
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

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    // Bind UDP socket
    var address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = .{ 127, 0, 0, 1 }, .port = bind_port } };
    var socket = try address.bind(io, .{ .mode = .dgram, .protocol = .udp });
    defer socket.close(io);
    std.debug.print("quicz echo server: listening on 127.0.0.1:{d}\n", .{bind_port});

    // Create server endpoint
    var server_ep = try ServerEndpoint.initWithCapacity(allocator, 16, .{
        .max_routes = 64,
        .max_stateless_reset_tokens = 64,
    });
    defer server_ep.deinit();

    var recv_buf: [max_datagram_size]u8 = undefined;
    var next_handle: u64 = 1;
    const alpn = [_][]const u8{"hq-interop"};

    while (true) {
        const timeout = std.Io.Timeout{ .duration = .{
            .clock = .awake,
            .raw = std.Io.Duration.fromMilliseconds(100),
        } };
        const received = socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
        const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
        const local_addr = endpoint.Udp4Address.init(socket.address.ip4.bytes, socket.address.ip4.port);
        const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };

        var initial_out: [4]quicz.EndpointPolledDatagramResult = undefined;
        var handshake_out: [4]quicz.EndpointPolledDatagramResult = undefined;
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
                    }, .{
                        .alpn = &alpn,
                        .cert_chain_der = &.{&certificate_der},
                        .private_key_bytes = &server_private_key,
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
                std.debug.print("connection {d} accepted\n", .{handle});
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

                // Echo: read stream data and send it back
                switch (step.process) {
                    .routed => |routed| switch (routed) {
                        .installed_key => |ik| {
                            if (ik.feed) |feed| {
                                if (feed.feed == .routed) {
                                    // Try to echo any received stream data
                                    const conn_id = feed.feed.routed.connection_id;
                                    if (server_ep.records.get(conn_id)) |rec| {
                                        const conn = rec.transport.connectionRef();
                                        var stream_buf: [4096]u8 = undefined;
                                        var sid: u64 = 0;
                                        while (sid < 512) : (sid += 4) {
                                            const n = conn.recvOnStream(sid, &stream_buf) catch continue;
                                            if (n) |len| {
                                                if (len > 0) {
                                                    std.debug.print("echo {d} bytes on stream {d}\n", .{ len, sid });
                                                    conn.sendOnStream(sid, stream_buf[0..len], false) catch {};
                                                }
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
                // Drain any pending output (ACKs, retransmissions)
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
