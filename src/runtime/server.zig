//! quicz I/O runtime — async streaming server (multi-connection).
//!
//! std.http model: accept loop spawns per-connection handler tasks.
//! Drive task receives UDP → routes to connections → pushes to queues.
//! Handlers poll queues with std.Thread.Mutex + std.time.sleep.

const std = @import("std");
const quicz = @import("../lib.zig");

const log = std.log.scoped(.quicz_runtime);

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

/// Per-stream receive buffer within a connection.
const StreamRecvState = struct {
    id: u64,
    queue: std.ArrayList(u8) = .empty,
    /// First unread byte; avoids shifting the queue on every read.
    read_offset: usize = 0,
    /// Peer FIN received and all stream bytes delivered to the queue.
    eof: bool = false,
};

/// Per-stream send buffer within a connection.
const StreamSendState = struct {
    id: u64,
    queue: std.ArrayList(u8) = .empty,
    fin: bool = false,
};

/// Per-connection server state.
const ConnState = struct {
    conn: *Connection,
    handle: u64,
    peer: std.Io.net.IpAddress,
    mutex: std.atomic.Mutex = .unlocked,
    recv_streams: std.ArrayList(StreamRecvState) = .empty,
    pending_streams: std.ArrayList(u64) = .empty,
    send_streams: std.ArrayList(StreamSendState) = .empty,
    /// Posted by the drive task when stream data or EOF arrives.
    data_sem: std.Io.Semaphore = .{ .permits = 0 },
    /// Set by releaseConnection; the drive task reclaims the state once
    /// the connection is closed and the handler is done with it
    /// (single-owner reclamation; s2n-quic uses a handle refcount here,
    /// which only pays off when one connection has several handlers).
    handler_done: bool = false,

    fn deinit(self: *ConnState, alloc: std.mem.Allocator) void {
        for (self.recv_streams.items) |*s| s.queue.deinit(alloc);
        self.recv_streams.deinit(alloc);
        self.pending_streams.deinit(alloc);
        for (self.send_streams.items) |*s| s.queue.deinit(alloc);
        self.send_streams.deinit(alloc);
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
    /// Posted by the drive task when a new connection is accepted.
    accept_sem: std.Io.Semaphore = .{ .permits = 0 },
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
        enlargeSocketReceiveBuffer(socket.handle);
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

    /// Signal the drive task and all accept/receive loops to stop.
    pub fn stop(self: *Server) void {
        @atomicStore(bool, &self.stopping, true, .release);
        // Wake a blocked accept loop so it observes `stopping`.
        self.accept_sem.post(self.io);
    }

    pub fn deinit(self: *Server) void {
        if (self.started) {
            self.stop();
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

    /// Mark the handler done with a connection. Call once per connection
    /// when the handler finishes; the drive task frees the state once the
    /// connection is also closed (single-owner reclamation).
    pub fn releaseConnection(self: *Server, conn_id: u64) void {
        while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
        if (self.conns.get(conn_id)) |cs| {
            cs.handler_done = true;
        }
        self.mutex.unlock();
    }

    /// Raise SO_RCVBUF so client bursts do not overflow the kernel receive
    /// buffer before the drive task drains it; loss recovery still covers
    /// any residual drops.
    fn enlargeSocketReceiveBuffer(handle: std.Io.net.Socket.Handle) void {
        const size: u32 = 4 * 1024 * 1024;
        std.posix.setsockopt(handle, std.posix.SOL.SOCKET, std.posix.SO.RCVBUF, std.mem.asBytes(&size)) catch {};
    }

    fn nowNanos(self: *const Server) i64 {
        return @intCast(std.Io.Timestamp.now(self.io, .awake).nanoseconds);
    }

    /// Drain queued stream sends and emit outgoing datagrams.
    fn drainOutgoing(self: *Server, io: std.Io, allocator: std.mem.Allocator) void {
        while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
        var closed_handles: [64]u64 = undefined;
        var closed_count: usize = 0;
        var cit = self.conns.valueIterator();
        while (cit.next()) |csp| {
            const st = csp.*;
            if (st.conn.isClosingOrClosed() and st.handler_done) {
                if (closed_count < closed_handles.len) {
                    closed_handles[closed_count] = st.handle;
                    closed_count += 1;
                }
                continue;
            }
            while (!st.mutex.tryLock()) std.atomic.spinLoopHint();
            for (st.send_streams.items) |*sq| {
                if (sq.queue.items.len > 0 or sq.fin) {
                    st.conn.sendOnStream(sq.id, sq.queue.items, sq.fin) catch {};
                    sq.queue.clearRetainingCapacity();
                    sq.fin = false;
                }
            }
            st.mutex.unlock();
        }
        for (closed_handles[0..closed_count]) |h| {
            if (self.conns.fetchRemove(h)) |kv| {
                kv.value.deinit(allocator);
                allocator.destroy(kv.value);
                log.info("connection {d} closed: state reclaimed", .{h});
            }
        }
        self.mutex.unlock();
        var out: [16]ServerEndpoint.DatagramPathResult = undefined;
        const drained = self.server_ep.drainDatagramsAcrossRecordsWithRoutePathWithScratch(self.nowNanos(), .application, &out);
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
            const received = self.socket.receiveTimeout(io, &recv_buf, timeout) catch continue;
            const from_addr = endpoint.Udp4Address.init(received.from.ip4.bytes, received.from.ip4.port);
            const local_addr = endpoint.Udp4Address.init(self.socket.address.ip4.bytes, self.socket.address.ip4.port);
            const path = endpoint.Udp4Tuple{ .local = local_addr, .remote = from_addr };
            const now = self.nowNanos();

            var initial_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var handshake_out: [4]quicz.EndpointPolledDatagramResult = undefined;
            var installed_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var pending_out: [16]ServerEndpoint.DatagramPathResult = undefined;
            var scratch: [8192]u8 = undefined;

            const action = self.server_ep.feedDatagram(&scratch, path, received.data, &[_]u8{}, &[_]quic_packet.Version{.v1}) catch |e| {
                log.debug("drive: feedDatagram: {}", .{e});
                continue;
            };
            var dest = std.Io.net.IpAddress{ .ip4 = .{ .bytes = from_addr.octets, .port = from_addr.port } };

            switch (action) {
                .accept_initial => |initial_accept| {
                    const handle = self.next_handle;
                    self.next_handle += 1;
                    var server_scid: [8]u8 = undefined;
                    io.randomSecure(&server_scid) catch {};
                    const record = allocator.create(ServerRecord) catch |e| {
                        std.debug.print("[drive] step err {}\n", .{e});
                        continue;
                    };
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
                    const accepted = self.server_ep.acceptInitialRecord(handle, record, now, initial_accept, &server_scid, received.data, .{}, &scratch, &initial_out, &handshake_out) catch {
                        record.transport.deinit();
                        allocator.destroy(record);
                        continue;
                    };
                    const cs = allocator.create(ConnState) catch |e| {
                        log.err("drive: allocate ConnState: {}", .{e});
                        continue;
                    };
                    cs.* = .{ .conn = record.transport.connectionRef(), .handle = handle, .peer = dest };
                    while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
                    self.conns.put(handle, cs) catch {};
                    self.pending_accept.append(allocator, handle) catch {};
                    self.mutex.unlock();
                    self.accept_sem.post(io);
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
                        allocator,
                        path,
                        now,
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
                    ) catch |e| {
                        log.debug("drive: receiveDatagramStep: {}", .{e});
                        continue;
                    };
                    switch (step.process) {
                        .routed => |routed| switch (routed) {
                            .installed_key => |ik| {
                                for (installed_out[0..ik.drain.datagrams_written]) |o| {
                                    self.socket.send(io, &dest, o.datagram) catch {};
                                    allocator.free(o.datagram);
                                }
                                // Deliver received stream data to per-connection
                                // queues via the endpoint's own records: the
                                // routed connection is the record's connection.
                                while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
                                var rit = self.server_ep.records.records.valueIterator();
                                while (rit.next()) |recp| {
                                    const rec = recp.*;
                                    const conn = rec.transport.connectionRef();
                                    const handle = rec.handle;
                                    const st = self.conns.get(handle) orelse continue;
                                    var stream_buf: [4096]u8 = undefined;
                                    var sid: u64 = 0;
                                    var pushed = false;
                                    while (sid < 512) : (sid += 4) {
                                        while (true) {
                                            const n = conn.recvOnStream(sid, &stream_buf) catch break;
                                            const len = n orelse break;
                                            if (len == 0) break;
                                            while (!st.mutex.tryLock()) std.atomic.spinLoopHint();
                                            var idx: ?usize = null;
                                            for (st.recv_streams.items, 0..) |s, i| {
                                                if (s.id == sid) {
                                                    idx = i;
                                                    break;
                                                }
                                            }
                                            if (idx == null) {
                                                st.recv_streams.append(allocator, .{ .id = sid }) catch {};
                                                idx = st.recv_streams.items.len - 1;
                                                st.pending_streams.append(allocator, sid) catch {};
                                            }
                                            st.recv_streams.items[idx.?].queue.appendSlice(allocator, stream_buf[0..len]) catch {};
                                            pushed = true;
                                            st.mutex.unlock();
                                        }
                                        // FIN received and all bytes drained from the
                                        // connection: surface EOF on the stream queue.
                                        if (conn.recvStreamFinished(sid) catch false) {
                                            while (!st.mutex.tryLock()) std.atomic.spinLoopHint();
                                            var eof_idx: ?usize = null;
                                            for (st.recv_streams.items, 0..) |s, i| {
                                                if (s.id == sid) {
                                                    eof_idx = i;
                                                    break;
                                                }
                                            }
                                            if (eof_idx == null) {
                                                st.recv_streams.append(allocator, .{ .id = sid }) catch {};
                                                eof_idx = st.recv_streams.items.len - 1;
                                                st.pending_streams.append(allocator, sid) catch {};
                                            }
                                            st.recv_streams.items[eof_idx.?].eof = true;
                                            pushed = true;
                                            st.mutex.unlock();
                                        }
                                    }
                                    if (pushed) st.data_sem.post(io);
                                }
                                self.mutex.unlock();
                                self.drainOutgoing(io, allocator);
                            },
                            else => {},
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
            self.accept_sem.wait(self.io) catch return error.Canceled;
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
            cs.data_sem.wait(self.io) catch return error.Canceled;
        }
    }

    /// Receive stream data for one stream (polls its per-stream queue).
    pub fn receiveStreamData(self: *Server, conn_id: u64, sid: u64, buf: []u8) !usize {
        while (true) {
            if (@atomicLoad(bool, &self.stopping, .acquire)) return error.Canceled;
            while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
            const cs = self.conns.get(conn_id) orelse {
                self.mutex.unlock();
                return error.NoConnection;
            };
            while (!cs.mutex.tryLock()) std.atomic.spinLoopHint();
            for (cs.recv_streams.items) |*s| {
                if (s.id != sid) continue;
                const available = s.queue.items[s.read_offset..];
                if (available.len > 0) {
                    const n = @min(buf.len, available.len);
                    @memcpy(buf[0..n], available[0..n]);
                    s.read_offset += n;
                    if (s.read_offset == s.queue.items.len) {
                        s.queue.clearRetainingCapacity();
                        s.read_offset = 0;
                    }
                    cs.mutex.unlock();
                    self.mutex.unlock();
                    return n;
                }
                if (s.eof) {
                    cs.mutex.unlock();
                    self.mutex.unlock();
                    return 0;
                }
                break;
            }
            cs.mutex.unlock();
            self.mutex.unlock();
            cs.data_sem.wait(self.io) catch return error.Canceled;
        }
    }

    /// Queue stream data to send (drive task drains and sends).
    pub fn sendStreamData(self: *Server, conn_id: u64, stream_id: u64, data: []const u8, fin: bool) !void {
        while (!self.mutex.tryLock()) std.atomic.spinLoopHint();
        const cs = self.conns.get(conn_id) orelse {
            self.mutex.unlock();
            return error.NoConnection;
        };
        while (!cs.mutex.tryLock()) std.atomic.spinLoopHint();
        var idx: ?usize = null;
        for (cs.send_streams.items, 0..) |s, i| {
            if (s.id == stream_id) {
                idx = i;
                break;
            }
        }
        if (idx == null) {
            cs.send_streams.append(self.allocator, .{ .id = stream_id }) catch {};
            idx = cs.send_streams.items.len - 1;
        }
        cs.send_streams.items[idx.?].queue.appendSlice(self.allocator, data) catch {};
        if (fin) cs.send_streams.items[idx.?].fin = true;
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

    /// Read queued stream bytes. Returns 0 at EOF: the peer FIN arrived
    /// and every stream byte was already consumed.
    pub fn receive(self: *Stream, buf: []u8) !usize {
        return self.server.receiveStreamData(self.conn_id, self.id, buf);
    }
    pub fn send(self: *Stream, data: []const u8, fin: bool) !void {
        return self.server.sendStreamData(self.conn_id, self.id, data, fin);
    }
};
