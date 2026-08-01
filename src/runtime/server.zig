//! quicz I/O runtime — server side (Phase 0).
//!
//! A quic-go/quinn-style server Transport shell over Tls13ServerEndpoint, using
//! std.Io (cross-platform) as the I/O layer. Design reference and the async
//! concurrency model are documented in docs/zh-CN/io_runtime_design.md.
//!
//! Dependency direction: io -> quic (the protocol library never depends on the
//! runtime), so the runtime can later be split into its own package.

const std = @import("std");
const quicz = @import("../lib.zig");

const Connection = quicz.Connection;
const Tls13ServerTransport = quicz.Tls13ServerTransport;
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

/// A QUIC echo server: owns the UDP socket + Tls13ServerEndpoint and drives
/// connections with a std.Io receive loop (recv -> route/accept -> echo -> send).
pub const EchoServer = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    socket: std.Io.net.Socket,
    server_ep: ServerEndpoint,
    next_handle: u64 = 1,
    alpn: []const []const u8,
    cert_der: []const u8,
    private_key: []const u8,

    pub const Config = struct {
        port: u16,
        alpn: []const []const u8,
        cert_der: []const u8,
        private_key: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: Config) !EchoServer {
        var address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = .{ 127, 0, 0, 1 }, .port = config.port } };
        const socket = try address.bind(io, .{ .mode = .dgram, .protocol = .udp });
        const server_ep = try ServerEndpoint.initWithCapacity(allocator, 16, .{
            .max_routes = 64,
            .max_stateless_reset_tokens = 64,
        });
        return .{
            .allocator = allocator,
            .io = io,
            .socket = socket,
            .server_ep = server_ep,
            .alpn = config.alpn,
            .cert_der = config.cert_der,
            .private_key = config.private_key,
        };
    }

    pub fn deinit(self: *EchoServer) void {
        self.server_ep.deinit();
        self.socket.close(self.io);
    }

    /// Run the std.Io receive loop forever.
    pub fn run(self: *EchoServer) !void {
        while (true) self.tick();
    }

    /// One receive-loop step: receive a datagram via std.Io and process it.
    pub fn tick(self: *EchoServer) void {
        const allocator = self.allocator;
        const io = self.io;
        var recv_buf: [max_datagram_size]u8 = undefined;
        const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(100) } };
        const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch return;
        const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
        const local_addr = endpoint.Udp4Address.init(self.socket.address.ip4.bytes, self.socket.address.ip4.port);
        const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };

        var initial_out: [4]quicz.EndpointPolledDatagramResult = undefined;
        var handshake_out: [4]quicz.EndpointPolledDatagramResult = undefined;
        var installed_out: [16]ServerEndpoint.DatagramPathResult = undefined;
        var pending_out: [16]ServerEndpoint.DatagramPathResult = undefined;
        var scratch: [8192]u8 = undefined;

        const action = self.server_ep.feedDatagram(&scratch, path, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1}) catch return;
        var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = from_addr.octets, .port = from_addr.port } };

        switch (action) {
            .accept_initial => |initial_accept| {
                const handle = self.next_handle;
                self.next_handle += 1;
                var server_scid: [8]u8 = undefined;
                io.randomSecure(&server_scid) catch {};
                const record = allocator.create(ServerRecord) catch return;
                const cert_chain = [_][]const u8{self.cert_der};
                record.* = .{
                    .handle = handle,
                    .transport = Tls13ServerTransport.init(allocator, .{
                        .initial_max_data = 1_048_576,
                        .initial_max_stream_data = 1_048_576,
                        .initial_max_streams_bidi = 128,
                        .initial_max_streams_uni = 128,
                        .max_datagram_size = max_datagram_size,
                        .max_idle_timeout_ms = 30000,
                    }, .{
                        .alpn = self.alpn,
                        .cert_chain_der = &cert_chain,
                        .private_key_bytes = self.private_key,
                        .private_key_algorithm = .ecdsa_p256_sha256,
                    }) catch {
                        allocator.destroy(record);
                        return;
                    },
                };
                record.transport.connection.validatePeerAddress() catch {};
                record.transport.setLocalInitialSourceConnectionId(&server_scid) catch {};
                const initial_info = quicz.protection.peekProtectedLongPacketInfo(received.data) catch {
                    record.transport.deinit();
                    allocator.destroy(record);
                    return;
                };
                record.transport.setOriginalDestinationConnectionId(initial_info.dcid) catch {};
                const accepted = self.server_ep.acceptInitialRecord(handle, record, 0, initial_accept, &server_scid, received.data, .{}, &scratch, &initial_out, &handshake_out) catch {
                    record.transport.deinit();
                    allocator.destroy(record);
                    return;
                };
                for (initial_out[0..accepted.initial.drain.datagrams_written]) |o| {
                    self.socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
                if (accepted.handshake) |hs| {
                    for (handshake_out[0..hs.drain.datagrams_written]) |o| {
                        self.socket.send(io, &dest, o.datagram) catch {};
                        allocator.free(o.datagram);
                    }
                }
            },
            .routed => {
                const step = self.server_ep.receiveDatagramStepWithRoutePath(
                    allocator, path, 0, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1},
                    .{ .space = .application, .out = &scratch, .unpredictable_prefix = &[_]u8{}, .supported_versions = &[_]quic_packet.Version{.v1} },
                    &scratch, &[_]u8{}, &initial_out, &handshake_out, &installed_out, .application, &pending_out,
                ) catch return;
                switch (step.process) {
                    .routed => |routed| switch (routed) {
                        .installed_key => |ik| {
                            if (ik.feed) |feed| {
                                if (feed.feed == .routed) {
                                    const conn_id = feed.feed.routed.connection_id;
                                    if (self.server_ep.records.get(conn_id)) |rec| {
                                        const conn = rec.transport.connectionRef();
                                        var stream_buf: [4096]u8 = undefined;
                                        var sid: u64 = 0;
                                        while (sid < 512) : (sid += 4) {
                                            const n = conn.recvOnStream(sid, &stream_buf) catch continue;
                                            if (n) |len| if (len > 0) conn.sendOnStream(sid, stream_buf[0..len], false) catch {};
                                        }
                                    }
                                }
                            }
                            for (installed_out[0..ik.drain.datagrams_written]) |o| {
                                self.socket.send(io, &dest, o.datagram) catch {};
                                allocator.free(o.datagram);
                            }
                        },
                        else => {},
                    },
                    else => {},
                }
                var drain_out: [16]ServerEndpoint.DatagramPathResult = undefined;
                const drain = self.server_ep.drainDatagramsAcrossRecordsWithRoutePathWithScratch(0, .application, &drain_out);
                for (drain_out[0..drain.datagrams_written]) |o| {
                    self.socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
                for (pending_out[0..step.pending_drain.datagrams_written]) |o| {
                    self.socket.send(io, &dest, o.datagram) catch {};
                    allocator.free(o.datagram);
                }
            },
            else => {},
        }
    }
};
