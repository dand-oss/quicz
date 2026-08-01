//! quicz I/O runtime — async streaming client (Phase 1, std.Io async model).
//!
//! Streaming client over Tls13ClientEndpoint, using std.Io. The
//! handshake + transfer run as a std.Io async task (Group.concurrent); the
//! streaming methods (connect/send/receive) drive the client endpoint with
//! std.Io recv/send.

const std = @import("std");
const quicz = @import("../lib.zig");

const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;
const endpoint = quicz.endpoint;

const max_datagram_size: usize = 8192;

pub const Client = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    socket: std.Io.net.Socket,
    client: Tls13ClientEndpoint,
    server_address: std.Io.net.IpAddress,
    scratch: [8192]u8 = undefined,

    pub const Config = struct {
        server_host: [4]u8 = .{ 127, 0, 0, 1 },
        server_port: u16,
        server_name: []const u8 = "localhost",
        alpn: []const []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: Config) !Client {
        var client_address = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
        const socket = try client_address.bind(io, .{ .mode = .dgram, .protocol = .udp });
        const server_address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = config.server_host, .port = config.server_port } };
        const client_path = endpoint.Udp4Tuple{
            .local = endpoint.Udp4Address.init(socket.address.ip4.bytes, socket.address.ip4.port),
            .remote = endpoint.Udp4Address.init(config.server_host, config.server_port),
        };
        const original_dcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
        const client_scid = [_]u8{ 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28 };
        const client = try Tls13ClientEndpoint.init(
            allocator, 1, client_path, .{ .active_migration_disabled = true },
            .{
                .initial_max_data = 1_048_576,
                .initial_max_stream_data = 1_048_576,
                .initial_max_streams_bidi = 128,
                .initial_max_streams_uni = 128,
                .max_datagram_size = max_datagram_size,
            },
            .{ .alpn = config.alpn, .server_name = config.server_name, .skip_cert_verify = true },
            original_dcid, client_scid,
        );
        return .{ .allocator = allocator, .io = io, .socket = socket, .client = client, .server_address = server_address };
    }

    pub fn deinit(self: *Client) void {
        self.client.deinit();
        self.socket.close(self.io);
    }

    /// Drive the TLS 1.3 handshake to completion (std.Io recv/send).
    pub fn connect(self: *Client) !void {
        const io = self.io;
        const begin_result = try self.client.beginWithRoutePath(0, &self.scratch);
        try self.socket.send(io, &self.server_address, begin_result.datagram);
        self.allocator.free(begin_result.datagram);
        var recv_buf: [max_datagram_size]u8 = undefined;
        var attempts: usize = 0;
        while (attempts < 100) : (attempts += 1) {
            if (self.client.handshakeConfirmed()) return;
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(2000) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            const result = self.client.receiveWithRoutePath(0, &self.scratch, received.data) catch continue;
            if (result.outbound_initial) |o| {
                self.socket.send(io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
            if (result.outbound_handshake) |o| {
                self.socket.send(io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
        }
        return error.HandshakeFailed;
    }

    /// Send `data` on a new bidirectional stream; returns the stream id.
    pub fn send(self: *Client, data: []const u8, fin: bool) !u64 {
        const stream_id = try self.client.openStream();
        var send_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
        const send_result = try self.client.sendStreamWithRoutePathAndDrainDatagrams(stream_id, data, fin, 0, &send_out);
        for (send_out[0..send_result.drain.datagrams_written]) |o| {
            try self.socket.send(self.io, &self.server_address, o.datagram);
            self.allocator.free(o.datagram);
        }
        return stream_id;
    }

    /// Receive echoed data on `stream_id` into `buf`; returns bytes read.
    pub fn receive(self: *Client, stream_id: u64, buf: []u8) !?usize {
        const io = self.io;
        var recv_buf: [max_datagram_size]u8 = undefined;
        var attempts: usize = 0;
        while (attempts < 100) : (attempts += 1) {
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(2000) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            _ = self.client.receiveWithRoutePath(0, &self.scratch, received.data) catch continue;
            if (try self.client.recvStream(stream_id, buf)) |len| if (len > 0) return len;
        }
        return null;
    }

    /// Full echo session (connect + send + receive); returns true on a matching
    /// echo. Suitable for running as a std.Io async task via Group.concurrent.
    pub fn runEchoSession(self: *Client, payload: []const u8) !bool {
        try self.connect();
        const stream_id = try self.send(payload, true);
        var echo_buf: [4096]u8 = undefined;
        const n = try self.receive(stream_id, &echo_buf);
        if (n) |len| return std.mem.eql(u8, echo_buf[0..len], payload);
        return false;
    }
};
