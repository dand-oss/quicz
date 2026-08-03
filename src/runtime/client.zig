//! quicz I/O runtime — async streaming client (std.Io async model).
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
        enlargeSocketReceiveBuffer(socket.handle);
        const server_address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = config.server_host, .port = config.server_port } };
        const client_path = endpoint.Udp4Tuple{
            .local = endpoint.Udp4Address.init(socket.address.ip4.bytes, socket.address.ip4.port),
            .remote = endpoint.Udp4Address.init(config.server_host, config.server_port),
        };
        var original_dcid: [8]u8 = undefined;
        var client_scid: [8]u8 = undefined;
        io.randomSecure(&original_dcid) catch io.random(&original_dcid);
        io.randomSecure(&client_scid) catch io.random(&client_scid);
        const client = try Tls13ClientEndpoint.init(
            allocator,
            1,
            client_path,
            .{ .active_migration_disabled = true },
            .{
                .initial_max_data = 10_485_760,
                .initial_max_stream_data = 10_485_760,
                .initial_max_streams_bidi = 128,
                .initial_max_streams_uni = 128,
                .max_datagram_size = max_datagram_size,
            },
            .{ .alpn = config.alpn, .server_name = config.server_name, .skip_cert_verify = true },
            original_dcid,
            client_scid,
        );
        return .{ .allocator = allocator, .io = io, .socket = socket, .client = client, .server_address = server_address };
    }

    pub fn localPort(self: *const Client) u16 {
        return self.socket.address.ip4.port;
    }

    pub fn deinit(self: *Client) void {
        self.client.deinit();
        self.socket.close(self.io);
    }

    /// Raise SO_RCVBUF so server echo bursts do not overflow the kernel
    /// receive buffer between client drains.
    fn enlargeSocketReceiveBuffer(handle: std.Io.net.Socket.Handle) void {
        const size: u32 = 4 * 1024 * 1024;
        std.posix.setsockopt(handle, std.posix.SOL.SOCKET, std.posix.SO.RCVBUF, std.mem.asBytes(&size)) catch {};
    }

    /// Gracefully close the connection with an APPLICATION_CLOSE.
    pub fn close(self: *Client) void {
        const closed = self.client.closeApplicationWithRoutePath(0, "session complete", self.nowNanos()) catch return;
        if (closed) |o| {
            self.socket.send(self.io, &self.server_address, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
    }

    fn nowNanos(self: *const Client) i64 {
        return @intCast(std.Io.Timestamp.now(self.io, .awake).nanoseconds);
    }

    /// Drive the TLS 1.3 handshake to completion.
    pub fn connect(self: *Client) !void {
        const io = self.io;
        const begin_result = try self.client.beginWithRoutePath(self.nowNanos(), &self.scratch);
        try self.socket.send(io, &self.server_address, begin_result.datagram);
        self.allocator.free(begin_result.datagram);
        var recv_buf: [max_datagram_size]u8 = undefined;
        var attempts: usize = 0;
        while (attempts < 100) : (attempts += 1) {
            if (self.client.handshakeConfirmed()) return;
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(2000) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            const result = self.client.receiveWithRoutePath(self.nowNanos(), &self.scratch, received.data) catch continue;
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
    /// Drains ALL outgoing datagrams in a loop (1MB needs ~128 packets).
    pub fn send(self: *Client, data: []const u8, fin: bool) !u64 {
        const stream_id = try self.client.openStream();
        if (try self.client.sendStreamWithRoutePath(stream_id, data, fin, self.nowNanos())) |o| {
            self.socket.send(self.io, &self.server_address, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
        try self.drainAllOutgoing();
        return stream_id;
    }

    /// Drain all pending outgoing datagrams from the client endpoint and send
    /// them to the server. Loops until the endpoint queue is empty.
    fn drainAllOutgoing(self: *Client) !void {
        var out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
        while (true) {
            const drained = self.client.drainApplicationDatagramsWithRoutePath(self.nowNanos(), &out) catch break;
            if (drained.datagrams_written == 0) break;
            for (out[0..drained.datagrams_written]) |o| {
                self.socket.send(self.io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
        }
    }

    /// Receive data on `stream_id` into `buf`. Returns bytes read, 0 at
    /// EOF (peer FIN fully consumed), or null when nothing arrived.
    /// Bidirectional drive: drains outgoing (ACKs + pending stream data) after
    /// each received packet (quic_bench_hs pattern).
    pub fn receive(self: *Client, stream_id: u64, buf: []u8) !?usize {
        const io = self.io;
        var recv_buf: [max_datagram_size]u8 = undefined;
        var attempts: usize = 0;
        while (attempts < 500) : (attempts += 1) {
            // Drain pending outgoing (remaining stream data, ACKs).
            self.drainAllOutgoing() catch {};
            // Short timeout: 100ms (loopback RTT ~1μs, no need to wait long).
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(100) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch {
                // Timeout: check if stream already has buffered data.
                const r = self.client.recvStream(stream_id, buf) catch null;
                if (r) |len| if (len > 0) return len;
                if (self.client.streamFinished(stream_id) catch false) return 0;
                continue;
            };
            _ = self.client.receiveWithRoutePath(self.nowNanos(), &self.scratch, received.data) catch continue;
            // Drain ACKs generated by processing the incoming packet.
            self.drainAllOutgoing() catch {};
            const r = self.client.recvStream(stream_id, buf) catch continue;
            if (r) |len| if (len > 0) return len;
            if (self.client.streamFinished(stream_id) catch false) return 0;
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
