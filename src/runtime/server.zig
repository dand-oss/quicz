//! quicz I/O runtime — async streaming server (Phase 2: multi-connection).
//!
//! Streaming API driven by std.Io async tasks. A connection
//! driving task runs on Group.concurrent: it receives packets via std.Io,
//! processes them through the endpoint (sync, CPU-bound), and pushes accepted
//! connections / received stream data to per-connection queues (keyed by
//! connection id), signaling Conditions. The application calls
//! accept()/receiveStreamData()/sendStreamData() which wait on those Conditions
//! concurrently with the driving task (std.Io thread pool).

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

/// Per-connection server state: the connection, its peer address, and a queue
/// of received stream data the application drains via receiveStreamData.
const ConnState = struct {
    conn: *Connection,
    peer: std.Io.net.IpAddress,
    stream_queue: std.ArrayList(u8) = .empty,
    data_cond: std.Io.Condition = std.Io.Condition.init,

    fn deinit(self: *ConnState, alloc: std.mem.Allocator) void {
        self.stream_queue.deinit(alloc);
    }
};

/// Async streaming QUIC server (multi-connection).
pub const Server = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    socket: std.Io.net.Socket,
    server_ep: ServerEndpoint,
    next_handle: u64 = 1,
    alpn: []const []const u8,
    cert_der: []const u8,
    private_key: []const u8,

    // Multi-connection state (guarded by mutex).
    mutex: std.Io.Mutex = std.Io.Mutex.init,
    conn_cond: std.Io.Condition = std.Io.Condition.init,
    conns: std.AutoHashMap(u64, *ConnState),
    pending_accept: std.ArrayList(u64) = .empty,

    pub const Config = struct {
        port: u16,
        alpn: []const []const u8,
        cert_der: []const u8,
        private_key: []const u8,
    };

    pub fn init(allocator: std.mem.Allocator, io: std.Io, config: Config) !Server {
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
            .conns = std.AutoHashMap(u64, *ConnState).init(allocator),
        };
    }

    pub fn deinit(self: *Server) void {
        var it = self.conns.valueIterator();
        while (it.next()) |cs| {
            cs.*.deinit(self.allocator);
            self.allocator.destroy(cs.*);
        }
        self.conns.deinit();
        self.pending_accept.deinit(self.allocator);
        self.server_ep.deinit();
        self.socket.close(self.io);
    }

    /// The connection driving task body (runs on Group.concurrent).
    pub fn drive(self: *Server) std.Io.Cancelable!void {
        const allocator = self.allocator;
        const io = self.io;
        var recv_buf: [max_datagram_size]u8 = undefined;
        while (true) {
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(50) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
            const local_addr = endpoint.Udp4Address.init(self.socket.address.ip4.bytes, self.socket.address.ip4.port);
            const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };

            var initial_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var handshake_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var installed_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var pending_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var scratch: [8192]u8 = undefined;

            const action = self.server_ep.feedDatagram(&scratch, path, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1}) catch continue;
            var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = from_addr.octets, .port = from_addr.port } };

            switch (action) {
                .accept_initial => |initial_accept| {
                    const handle = self.next_handle;
                    self.next_handle += 1;
                    var server_scid: [8]u8 = undefined;
                    io.randomSecure(&server_scid) catch {};
                    const record = allocator.create(ServerRecord) catch continue;
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
                    const accepted = self.server_ep.acceptInitialRecord(handle, record, 0, initial_accept, &server_scid, received.data, .{}, &scratch, &initial_out, &handshake_out) catch {
                        record.transport.deinit();
                        allocator.destroy(record);
                        continue;
                    };
                    // Register per-connection state and queue it for accept().
                    const cs = allocator.create(ConnState) catch continue;
                    cs.* = .{ .conn = record.transport.connectionRef(), .peer = dest };
                    self.mutex.lock(io) catch return;
                    self.conns.put(handle, cs) catch {};
                    self.pending_accept.append(allocator, handle) catch {};
                    self.mutex.unlock(io);
                    self.conn_cond.signal(io);
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
                    ) catch continue;
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
                                                if (n) |len| if (len > 0) {
                                                    // Push to this connection's queue (look up by handle).
                                                    self.mutex.lock(io) catch return;
                                                    const cs = self.findConnStateLocked(rec);
                                                    if (cs) |state| {
                                                        state.stream_queue.appendSlice(allocator, stream_buf[0..len]) catch {};
                                                        state.data_cond.signal(io);
                                                    }
                                                    self.mutex.unlock(io);
                                                };
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
    }

    /// Find the ConnState for a ServerRecord (mutex must be held). Matches by
    /// connection pointer.
    fn findConnStateLocked(self: *Server, rec: *ServerRecord) ?*ConnState {
        const conn_ptr = rec.transport.connectionRef();
        var it = self.conns.valueIterator();
        while (it.next()) |cs| {
            if (cs.*.conn == conn_ptr) return cs.*;
        }
        return null;
    }

    /// Accept the next new connection; returns its connection id.
    pub fn accept(self: *Server) !u64 {
        self.mutex.lock(self.io) catch return error.Canceled;
        defer self.mutex.unlock(self.io);
        while (self.pending_accept.items.len == 0) {
            self.conn_cond.wait(self.io, &self.mutex) catch return error.Canceled;
        }
        return self.pending_accept.orderedRemove(0);
    }

    /// Receive stream data on a connection: waits until its queue has data,
    /// then copies up to buf.len bytes out.
    pub fn receiveStreamData(self: *Server, conn_id: u64, buf: []u8) !usize {
        self.mutex.lock(self.io) catch return error.Canceled;
        defer self.mutex.unlock(self.io);
        const cs = self.conns.get(conn_id) orelse return error.NoConnection;
        while (cs.stream_queue.items.len == 0) {
            cs.data_cond.wait(self.io, &self.mutex) catch return error.Canceled;
        }
        const n = @min(buf.len, cs.stream_queue.items.len);
        @memcpy(buf[0..n], cs.stream_queue.items[0..n]);
        cs.stream_queue.replaceRange(self.allocator, 0, n, &.{}) catch {};
        return n;
    }

    /// Send stream data on a connection (stream id), then flush QUIC packets.
    pub fn sendStreamData(self: *Server, conn_id: u64, stream_id: u64, data: []const u8) !void {
        self.mutex.lock(self.io) catch return error.Canceled;
        const cs = self.conns.get(conn_id) orelse {
            self.mutex.unlock(self.io);
            return error.NoConnection;
        };
        const conn = cs.conn;
        const peer = cs.peer;
        self.mutex.unlock(self.io);
        try conn.sendOnStream(stream_id, data, false);
        var out: [16]ServerEndpoint.DatagramPathResult = undefined;
        const drain = self.server_ep.drainDatagramsAcrossRecordsWithRoutePathWithScratch(0, .application, &out);
        for (out[0..drain.datagrams_written]) |o| {
            self.socket.send(self.io, &peer, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
    }
};
