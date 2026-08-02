//! quicz I/O runtime — async streaming server (multi-connection).
//!
//! std.http model: accept loop spawns per-connection handler tasks.
//! Drive task receives UDP → routes to connections → pushes to queues.
//! Handlers poll queues with std.Thread.Mutex + std.time.sleep.

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

/// Per-connection server state.
const ConnState = struct {
    conn: *Connection,
    peer: std.Io.net.IpAddress,
    mutex: std.atomic.Mutex = .unlocked,
    stream_queue: std.ArrayList(u8) = .empty,
    pending_streams: std.ArrayList(u64) = .empty,
    send_queue: std.ArrayList(u8) = .empty,
    send_fin: bool = false,

    fn deinit(self: *ConnState, alloc: std.mem.Allocator) void {
        self.stream_queue.deinit(alloc);
        self.pending_streams.deinit(alloc);
        self.send_queue.deinit(alloc);
    }
};

/// Async streaming QUIC server (multi-connection, std.http model).
pub const Server = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    socket: std.Io.net.Socket,
    server_ep: ServerEndpoint,
    next_handle: u64 = 1,
    alpn: []const []const u8,
    cert_der: []const u8,
    private_key: []const u8,

    mutex: std.atomic.Mutex = .unlocked,
    conns: std.AutoHashMap(u64, *ConnState),
    pending_accept: std.ArrayList(u64) = .empty,
    drive_group: std.Io.Group = .init,
    started: bool = false,
    stopping: bool = false,

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

    pub fn start(self: *Server) !void {
        if (self.started) return;
        try self.drive_group.concurrent(self.io, Server.drive, .{self});
        self.started = true;
    }

    pub fn deinit(self: *Server) void {
        if (self.started) {
            @atomicStore(bool, &self.stopping, true, .release);
            self.drive_group.cancel(self.io);
            self.drive_group.await(self.io) catch {};
            self.started = false;
        }
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

    /// Drain queued stream sends and emit outgoing datagrams.
    fn drainOutgoing(self: *Server, io: std.Io, allocator: std.mem.Allocator) void {
        while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
        var cit = self.conns.valueIterator();
        while (cit.next()) |csp| {
            const st = csp.*;
            while (!st.mutex.tryLock()) std.atomic.spinLoopHint();
            if (st.send_queue.items.len > 0) {
                st.conn.sendOnStream(0, st.send_queue.items, st.send_fin) catch {};
                st.send_queue.clearRetainingCapacity();
                st.send_fin = false;
            }
            st.mutex.unlock();
        }
        self.mutex.unlock();
        var out: [16]ServerEndpoint.DatagramPathResult = undefined;
        const drained = self.server_ep.drainDatagramsAcrossRecordsWithRoutePathWithScratch(0, .application, &out);
        for (out[0..drained.datagrams_written]) |o| {
            var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = o.path.remote.octets, .port = o.path.remote.port } };
            self.socket.send(io, &dest, o.datagram) catch {};
            allocator.free(o.datagram);
        }
    }

    /// The connection driving task body.
    pub fn drive(self: *Server) std.Io.Cancelable!void {
        const allocator = self.allocator;
        const io = self.io;
        var recv_buf: [max_datagram_size]u8 = undefined;
        while (!@atomicLoad(bool, &self.stopping, .acquire)) {
            self.drainOutgoing(io, allocator);
            const timeout = std.Io.Timeout{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(10) } };
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch |e| { std.debug.print("[drive] step err {}\n", .{e}); continue; };
            std.debug.print("[drive] recv {d} bytes\n", .{received.data.len});            const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
            const local_addr = endpoint.Udp4Address.init(self.socket.address.ip4.bytes, self.socket.address.ip4.port);
            const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };

            var initial_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var handshake_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var installed_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var pending_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var scratch: [8192]u8 = undefined;

            const action = self.server_ep.feedDatagram(&scratch, path, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1}) catch |e| { std.debug.print("[drive] step err {}\n", .{e}); continue; };
            var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = from_addr.octets, .port = from_addr.port } };

            std.debug.print("[drive] action={s}\n", .{@tagName(action)});            switch (action) {
                .accept_initial => |initial_accept| {
                    const handle = self.next_handle;
                    self.next_handle += 1;
                    var server_scid: [8]u8 = undefined;
                    io.randomSecure(&server_scid) catch {};
                    const record = allocator.create(ServerRecord) catch |e| { std.debug.print("[drive] step err {}\n", .{e}); continue; };
                    const cert_chain = [_][]const u8{self.cert_der};
                    record.* = .{
                        .handle = handle,
                        .transport = Tls13ServerTransport.init(allocator, .{
                            .initial_max_data = 10_485_760,
                            .initial_max_stream_data = 10_485_760,
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
                    const cs = allocator.create(ConnState) catch |e| { std.debug.print("[drive] step err {}\n", .{e}); continue; };
                    cs.* = .{ .conn = record.transport.connectionRef(), .peer = dest };
                    while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
                    self.conns.put(handle, cs) catch {};
                    self.pending_accept.append(allocator, handle) catch {};
                    self.mutex.unlock();
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
                    ) catch |e| { std.debug.print("[drive] step err {}\n", .{e}); continue; };
                    std.debug.print("[drive] step.process tag={s}\n", .{@tagName(step.process)});                    switch (step.process) {
                        .routed => |routed| switch (routed) {
                            .installed_key => |ik| {
                                for (installed_out[0..ik.drain.datagrams_written]) |o| {
                                    self.socket.send(io, &dest, o.datagram) catch {};
                                    allocator.free(o.datagram);
                                }
                                // Push received stream data to per-conn queues.
                                while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
                                var cit = self.conns.valueIterator();
                                while (cit.next()) |csp| {
                                    const st = csp.*;
                                    var stream_buf: [4096]u8 = undefined;
                                    var sid: u64 = 0;
                                    while (sid < 512) : (sid += 4) {
                                        while (true) {
                                            const n = st.conn.recvOnStream(sid, &stream_buf) catch break;
                                            const len = n orelse break;
                                            if (len == 0) break;
                                            while (!st.mutex.tryLock()) std.atomic.spinLoopHint();
                                            const first = st.stream_queue.items.len == 0;
                                            st.stream_queue.appendSlice(allocator, stream_buf[0..len]) catch {};
                                            if (first) {
                                                st.pending_streams.append(allocator, sid) catch {};
                                            }
                                            st.mutex.unlock();
                                        }
                                    }
                                }
                                self.mutex.unlock();
                                self.drainOutgoing(io, allocator);
                            },
                            else => |other| { std.debug.print("[drive] routed inner={s}\n", .{@tagName(other)}); },
                        },
                        else => {},
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

    /// Accept the next new connection (polls with std.time.sleep).
    pub fn accept(self: *Server) !ServerConnection {
        while (true) {
            if (@atomicLoad(bool, &self.stopping, .acquire)) return error.Canceled;
            while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
            if (self.pending_accept.items.len > 0) {
                const id = self.pending_accept.orderedRemove(0);
                self.mutex.unlock();
                return .{ .server = self, .id = id };
            }
            self.mutex.unlock();
            std.atomic.spinLoopHint();
        }
    }

    /// Accept the next stream with pending data on a connection.
    pub fn acceptStreamId(self: *Server, conn_id: u64) !u64 {
        while (true) {
            if (@atomicLoad(bool, &self.stopping, .acquire)) return error.Canceled;
            while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
            const cs = self.conns.get(conn_id) orelse {
                self.mutex.unlock();
                return error.NoConnection;
            };
            while (!cs.mutex.tryLock()) std.atomic.spinLoopHint();
            if (cs.pending_streams.items.len > 0) {
                const sid = cs.pending_streams.orderedRemove(0);
                cs.mutex.unlock();
                self.mutex.unlock();
                return sid;
            }
            cs.mutex.unlock();
            self.mutex.unlock();
            std.atomic.spinLoopHint();
        }
    }

    /// Receive stream data on a connection (polls queue).
    pub fn receiveStreamData(self: *Server, conn_id: u64, buf: []u8) !usize {
        while (true) {
            if (@atomicLoad(bool, &self.stopping, .acquire)) return error.Canceled;
            while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
            const cs = self.conns.get(conn_id) orelse {
                self.mutex.unlock();
                return error.NoConnection;
            };
            while (!cs.mutex.tryLock()) std.atomic.spinLoopHint();
            if (cs.stream_queue.items.len > 0) {
                const n = @min(buf.len, cs.stream_queue.items.len);
                @memcpy(buf[0..n], cs.stream_queue.items[0..n]);
                cs.stream_queue.replaceRange(self.allocator, 0, n, &.{}) catch {};
                cs.mutex.unlock();
                self.mutex.unlock();
                return n;
            }
            cs.mutex.unlock();
            self.mutex.unlock();
            std.atomic.spinLoopHint();
        }
    }

    /// Queue stream data to send (drive task drains and sends).
    pub fn sendStreamData(self: *Server, conn_id: u64, stream_id: u64, data: []const u8, fin: bool) !void {
        _ = stream_id;
        while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
        const cs = self.conns.get(conn_id) orelse {
            self.mutex.unlock();
            return error.NoConnection;
        };
        while (!cs.mutex.tryLock()) std.atomic.spinLoopHint();
        cs.send_queue.appendSlice(self.allocator, data) catch {};
        if (fin) cs.send_fin = true;
        cs.mutex.unlock();
        self.mutex.unlock();
    }
};

/// A server-side connection handle.
pub const ServerConnection = struct {
    server: *Server,
    id: u64,

    pub fn acceptStream(self: *ServerConnection) !Stream {
        const sid = try self.server.acceptStreamId(self.id);
        return .{ .server = self.server, .conn_id = self.id, .id = sid };
    }
};

/// A bidirectional stream handle on a server connection.
pub const Stream = struct {
    server: *Server,
    conn_id: u64,
    id: u64,

    pub fn receive(self: *Stream, buf: []u8) !usize {
        return self.server.receiveStreamData(self.conn_id, buf);
    }
    pub fn send(self: *Stream, data: []const u8, fin: bool) !void {
        return self.server.sendStreamData(self.conn_id, self.id, data, fin);
    }
};
