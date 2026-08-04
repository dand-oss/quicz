//! quicz I/O runtime — async streaming client (std.Io event-driven model).
//!
//! Mirrors the server runtime: a recv task blocks on the UDP socket and
//! queues datagrams; the drive task owns the client endpoint exclusively,
//! routes datagrams, delivers stream data to per-stream queues, services
//! lifecycle deadlines, and parks on a futex word bumped by every wakeup
//! source (std.Build.WebServer update_id pattern). Callers block on
//! semaphores instead of polling.

const std = @import("std");
const quicz = @import("../lib.zig");

const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;
const endpoint = quicz.endpoint;

const log = std.log.scoped(.quicz_runtime);

const max_datagram_size: usize = 8192;

/// Datagram received by the recv task, waiting for the drive task.
const QueuedDatagram = struct {
    /// Owned copy; the drive task frees it after processing.
    data: []u8,
};

/// Per-stream receive buffer (single connection, client-opened streams).
const StreamRecvState = struct {
    id: u64,
    queue: std.ArrayList(u8) = .empty,
    /// First unread byte; avoids shifting the queue on every read.
    read_offset: usize = 0,
    /// Peer FIN received and all stream bytes delivered to the queue.
    eof: bool = false,
};

/// One caller send, parked in the request slot until the drive task runs it.
/// The caller blocks until done, so `data` may stay a borrowed slice.
const SendRequest = struct {
    data: []const u8,
    fin: bool,
    /// Stream id assigned by the drive task; null on failure.
    result: ?u64 = null,
};

pub const Client = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    socket: std.Io.net.Socket,
    client: Tls13ClientEndpoint,
    server_address: std.Io.net.IpAddress,
    scratch: [8192]u8 = undefined,

    drive_group: std.Io.Group = .init,
    started: bool = false,
    stopping: bool = false,

    /// Futex word bumped by every drive wakeup source (recv task, senders,
    /// connect/close requests, stop); the drive task parks on it with an
    /// absolute deadline (std.Build.WebServer update_id pattern).
    wake_id: std.atomic.Value(u32) = .init(0),
    queue_mutex: std.atomic.Mutex = .unlocked,
    /// Datagrams received by the recv task, consumed FIFO by the drive task.
    datagram_queue: std.ArrayList(QueuedDatagram) = .empty,
    datagram_read_offset: usize = 0,

    /// Handshake coordination: the drive task runs the handshake; callers
    /// wait on handshake_sem for the terminal state.
    handshake_state: std.atomic.Value(u8) = .init(0),
    handshake_sem: std.Io.Semaphore = .{ .permits = 0 },
    connect_requested: bool = false,
    close_requested: bool = false,
    /// Drive-task only.
    handshake_started: bool = false,

    /// Send request slot (one in flight; the caller blocks until done).
    send_mutex: std.atomic.Mutex = .unlocked,
    send_request: ?*SendRequest = null,
    send_done_sem: std.Io.Semaphore = .{ .permits = 0 },

    /// Per-stream receive state, protected by state_mutex.
    state_mutex: std.atomic.Mutex = .unlocked,
    recv_streams: std.ArrayList(StreamRecvState) = .empty,
    /// Streams this client opened; the drive task delivers their data.
    open_streams: std.ArrayList(u64) = .empty,
    data_sem: std.Io.Semaphore = .{ .permits = 0 },
    /// Drive-observed connection close; a blocked receive() cannot learn
    /// about the close from stream data or EOF, so it checks this flag.
    conn_closing_or_closed: bool = false,

    const handshake_pending: u8 = 0;
    const handshake_confirmed: u8 = 1;
    const handshake_failed: u8 = 2;

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
        if (self.started) {
            @atomicStore(bool, &self.stopping, true, .release);
            self.notifyDrive(self.io);
            self.drive_group.cancel(self.io);
            self.drive_group.await(self.io) catch {};
            self.started = false;
        }
        for (self.datagram_queue.items[self.datagram_read_offset..]) |qd| {
            self.allocator.free(qd.data);
        }
        self.datagram_queue.deinit(self.allocator);
        for (self.recv_streams.items) |*s| s.queue.deinit(self.allocator);
        self.recv_streams.deinit(self.allocator);
        self.open_streams.deinit(self.allocator);
        self.client.deinit();
        self.socket.close(self.io);
    }

    /// Raise SO_RCVBUF so server echo bursts do not overflow the kernel
    /// receive buffer between client drains.
    fn enlargeSocketReceiveBuffer(handle: std.Io.net.Socket.Handle) void {
        const size: u32 = 4 * 1024 * 1024;
        std.posix.setsockopt(handle, std.posix.SOL.SOCKET, std.posix.SO.RCVBUF, std.mem.asBytes(&size)) catch {};
    }

    /// Gracefully close the connection with an APPLICATION_CLOSE; the drive
    /// task emits the close frame and any PTO retransmit while it runs.
    pub fn close(self: *Client) void {
        @atomicStore(bool, &self.close_requested, true, .release);
        self.notifyDrive(self.io);
    }

    fn nowNanos(self: *const Client) i64 {
        return @intCast(std.Io.Timestamp.now(self.io, .awake).nanoseconds);
    }

    /// Wake the drive task: bump the futex word, then wake the waiter.
    /// std.Build.WebServer uses the same pattern (notifyUpdate/update_id).
    fn notifyDrive(self: *Client, io: std.Io) void {
        _ = self.wake_id.rmw(.Add, 1, .release);
        io.futexWake(u32, &self.wake_id.raw, 1);
    }

    /// Spawn the recv and drive tasks (idempotent).
    fn startTasks(self: *Client) !void {
        if (self.started) return;
        try self.drive_group.concurrent(self.io, Client.recvTask, .{self});
        self.drive_group.concurrent(self.io, Client.drive, .{self}) catch |err| {
            @atomicStore(bool, &self.stopping, true, .release);
            self.drive_group.cancel(self.io);
            self.drive_group.await(self.io) catch {};
            return err;
        };
        self.started = true;
    }

    /// Drive the TLS 1.3 handshake to completion. Blocks until the drive
    /// task confirms the handshake or the connection closes first.
    pub fn connect(self: *Client) !void {
        try self.startTasks();
        if (self.handshake_state.load(.acquire) == handshake_confirmed) return;
        @atomicStore(bool, &self.connect_requested, true, .release);
        self.notifyDrive(self.io);
        self.handshake_sem.wait(self.io) catch return error.HandshakeFailed;
        if (self.handshake_state.load(.acquire) != handshake_confirmed) return error.HandshakeFailed;
    }

    /// Send `data` on a new bidirectional stream; returns the stream id.
    /// The drive task runs the request (the endpoint is drive-task only).
    pub fn send(self: *Client, data: []const u8, fin: bool) !u64 {
        try self.startTasks();
        var req: SendRequest = .{ .data = data, .fin = fin };
        while (true) {
            while (!self.send_mutex.tryLock()) std.atomic.spinLoopHint();
            if (self.send_request == null) break;
            self.send_mutex.unlock();
            std.atomic.spinLoopHint();
        }
        self.send_request = &req;
        self.send_mutex.unlock();
        self.notifyDrive(self.io);
        self.send_done_sem.waitUncancelable(self.io);
        return req.result orelse error.StreamSendFailed;
    }

    /// Receive data on `stream_id` into `buf`. Blocks until data arrives;
    /// returns bytes read, 0 at EOF (peer FIN fully consumed).
    pub fn receive(self: *Client, stream_id: u64, buf: []u8) !usize {
        const io = self.io;
        while (true) {
            if (@atomicLoad(bool, &self.stopping, .acquire)) return error.Canceled;
            while (!self.state_mutex.tryLock()) std.atomic.spinLoopHint();
            var found: ?*StreamRecvState = null;
            for (self.recv_streams.items) |*s| {
                if (s.id == stream_id) {
                    found = s;
                    break;
                }
            }
            if (found) |s| {
                const available = s.queue.items[s.read_offset..];
                if (available.len > 0) {
                    const n = @min(buf.len, available.len);
                    @memcpy(buf[0..n], available[0..n]);
                    s.read_offset += n;
                    if (s.read_offset == s.queue.items.len) {
                        s.queue.clearRetainingCapacity();
                        s.read_offset = 0;
                    }
                    self.state_mutex.unlock();
                    return n;
                }
                if (s.eof) {
                    self.state_mutex.unlock();
                    return 0;
                }
            }
            // No data and no EOF: a closing/closed connection will never
            // deliver more on this stream.
            if (@atomicLoad(bool, &self.conn_closing_or_closed, .acquire)) {
                return error.ConnectionClosed;
            }
            self.state_mutex.unlock();
            self.data_sem.wait(io) catch return error.Canceled;
        }
    }

    /// Full echo session (connect + send + receive-to-EOF); returns true when
    /// the echoed bytes match the payload. Suitable for running as a std.Io
    /// async task via Group.concurrent.
    pub fn runEchoSession(self: *Client, payload: []const u8) !bool {
        try self.connect();
        const stream_id = try self.send(payload, true);
        var echo_buf: [4096]u8 = undefined;
        var total: usize = 0;
        while (total < payload.len) {
            const n = try self.receive(stream_id, &echo_buf);
            if (n == 0) break;
            if (total + n > payload.len) return false;
            if (!std.mem.eql(u8, echo_buf[0..n], payload[total .. total + n])) return false;
            total += n;
        }
        return total == payload.len;
    }

    /// Receive datagrams into the queue and wake the drive task. Mirrors the
    /// official WebServer accept task: block on the socket, hand work off.
    fn recvTask(self: *Client) std.Io.Cancelable!void {
        const io = self.io;
        const allocator = self.allocator;
        var recv_buf: [max_datagram_size]u8 = undefined;
        while (!@atomicLoad(bool, &self.stopping, .acquire)) {
            const received = self.socket.receiveTimeout(io, &recv_buf, .none) catch |err| switch (err) {
                error.Canceled => return,
                else => {
                    if (@atomicLoad(bool, &self.stopping, .acquire)) return;
                    log.debug("client recv task: receive: {}", .{err});
                    continue;
                },
            };
            const copy = allocator.dupe(u8, received.data) catch continue;
            while (!self.queue_mutex.tryLock()) std.atomic.spinLoopHint();
            self.datagram_queue.append(allocator, .{ .data = copy }) catch {
                self.queue_mutex.unlock();
                allocator.free(copy);
                continue;
            };
            self.queue_mutex.unlock();
            self.notifyDrive(io);
        }
    }

    /// The client driving task body: run requested handshake/close/send work,
    /// drain outgoing, process queued datagrams, service due deadlines, then
    /// park on the wakeup futex until the next event or lifecycle deadline.
    fn drive(self: *Client) std.Io.Cancelable!void {
        const allocator = self.allocator;
        const io = self.io;
        defer self.failPendingSendRequest();
        while (!@atomicLoad(bool, &self.stopping, .acquire)) {
            self.beginHandshakeOnce();
            self.processCloseRequest();
            self.processSendRequest();
            self.drainOutgoing();
            self.drainQueuedDatagrams();
            self.checkHandshakeProgress();
            self.checkConnectionClose();
            self.serviceDueDeadlines();
            // Park until a datagram arrives, a request is queued, stop() runs,
            // or the next lifecycle deadline comes due. The snapshot is taken
            // after draining, pairing with notifyDrive's bump: a notifier that
            // already ran changed wake_id, so the wait returns immediately.
            const snapshot = self.wake_id.load(.acquire);
            const timeout: std.Io.Timeout = blk: {
                if (self.client.nextDeadline()) |d| {
                    break :blk .{ .deadline = .{ .raw = .{ .nanoseconds = d.deadline() }, .clock = .awake } };
                }
                // The endpoint reports no pending deadline. During the handshake
                // this is unsafe: a lost Initial/Handshake response must be
                // retransmitted by PTO, and if the endpoint under-reports its
                // deadline the drive would park forever and connect() would
                // hang. Bound the wait so the loop re-evaluates the handshake
                // (and the endpoint can produce a retransmit on the next pass).
                if (self.handshake_state.load(.acquire) == handshake_pending) {
                    log.warn("client drive: handshake pending but endpoint has no deadline; bounding park to 250ms", .{});
                    break :blk .{ .deadline = .{ .raw = .{ .nanoseconds = self.nowNanos() + 250_000_000 }, .clock = .awake } };
                }
                break :blk .none;
            };
            // Re-check stopping after the snapshot: a deinit/stop that ran
            // before the snapshot already bumped wake_id (and its futexWake
            // may have had no waiter yet), and one that runs after the
            // snapshot changes wake_id so the compare cannot match. Without
            // this check the drive could park forever past a stop request.
            if (@atomicLoad(bool, &self.stopping, .acquire)) break;
            io.futexWaitTimeout(u32, &self.wake_id.raw, snapshot, timeout) catch return;
        }
        _ = allocator;
    }

    /// Begin the handshake once connect() has been requested.
    fn beginHandshakeOnce(self: *Client) void {
        if (self.handshake_started) return;
        if (!@atomicLoad(bool, &self.connect_requested, .acquire)) return;
        self.handshake_started = true;
        const begin = self.client.beginWithRoutePath(self.nowNanos(), &self.scratch) catch |err| {
            log.err("client: begin handshake: {}", .{err});
            self.handshake_state.store(handshake_failed, .release);
            self.handshake_sem.post(self.io);
            return;
        };
        self.socket.send(self.io, &self.server_address, begin.datagram) catch {};
        self.allocator.free(begin.datagram);
    }

    /// Emit the APPLICATION_CLOSE frame once close() has been requested.
    fn processCloseRequest(self: *Client) void {
        if (!@atomicLoad(bool, &self.close_requested, .acquire)) return;
        @atomicStore(bool, &self.close_requested, false, .release);
        const closed = self.client.closeApplicationWithRoutePath(0, "session complete", self.nowNanos()) catch return;
        if (closed) |o| {
            self.socket.send(self.io, &self.server_address, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
    }

    /// Run the parked send request: open a stream and queue the data.
    fn processSendRequest(self: *Client) void {
        while (!self.send_mutex.tryLock()) std.atomic.spinLoopHint();
        const req = self.send_request orelse {
            self.send_mutex.unlock();
            return;
        };
        self.send_request = null;
        self.send_mutex.unlock();

        process: {
            const stream_id = self.client.openStream() catch break :process;
            const outbound = self.client.sendStreamWithRoutePath(stream_id, req.data, req.fin, self.nowNanos()) catch break :process;
            if (outbound) |o| {
                self.socket.send(self.io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
            while (!self.state_mutex.tryLock()) std.atomic.spinLoopHint();
            self.open_streams.append(self.allocator, stream_id) catch {};
            self.state_mutex.unlock();
            req.result = stream_id;
        }
        self.send_done_sem.post(self.io);
    }

    /// Complete a parked send request as failed (drive task shutdown path).
    fn failPendingSendRequest(self: *Client) void {
        while (!self.send_mutex.tryLock()) std.atomic.spinLoopHint();
        const req = self.send_request;
        self.send_request = null;
        self.send_mutex.unlock();
        if (req) |r| {
            r.result = null;
            self.send_done_sem.post(self.io);
        }
    }

    /// Drain pending outgoing datagrams to the server. Bounded: the server
    /// endpoint can keep producing closing-frame retransmits, and an unbounded
    /// loop here wedges the drive task so it never reaches the main loop's
    /// `stopping` check (and group.cancel cannot interrupt a non-blocking
    /// busy-spin). The remainder is picked up on the next drive iteration,
    /// mirroring the server runtime's single-pass drain.
    fn drainOutgoing(self: *Client) void {
        var out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
        var iterations: usize = 0;
        while (iterations < 16) : (iterations += 1) {
            const drained = self.client.drainApplicationDatagramsWithRoutePath(self.nowNanos(), &out) catch return;
            if (drained.datagrams_written == 0) return;
            for (out[0..drained.datagrams_written]) |o| {
                self.socket.send(self.io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
        }
    }

    /// Process every queued datagram in FIFO order and free its buffer.
    fn drainQueuedDatagrams(self: *Client) void {
        while (true) {
            while (!self.queue_mutex.tryLock()) std.atomic.spinLoopHint();
            if (self.datagram_read_offset >= self.datagram_queue.items.len) {
                self.datagram_queue.clearRetainingCapacity();
                self.datagram_read_offset = 0;
                self.queue_mutex.unlock();
                return;
            }
            const qd = self.datagram_queue.items[self.datagram_read_offset];
            self.datagram_read_offset += 1;
            self.queue_mutex.unlock();
            self.processDatagram(qd.data);
            self.allocator.free(qd.data);
        }
    }

    /// Route one datagram through the client endpoint, send the TLS outbound
    /// it returns, deliver stream data, and drain the responses (ACKs).
    fn processDatagram(self: *Client, data: []const u8) void {
        const result = self.client.receiveWithRoutePath(self.nowNanos(), &self.scratch, data) catch |err| {
            log.debug("client: receive: {}", .{err});
            return;
        };
        if (result.outbound_initial) |o| {
            self.socket.send(self.io, &self.server_address, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
        if (result.outbound_handshake) |o| {
            self.socket.send(self.io, &self.server_address, o.datagram) catch {};
            self.allocator.free(o.datagram);
        }
        self.deliverStreamData();
        self.drainOutgoing();
    }

    /// Push received bytes of every open stream into its queue and surface
    /// EOF once the peer FIN is fully consumed.
    fn deliverStreamData(self: *Client) void {
        while (!self.state_mutex.tryLock()) std.atomic.spinLoopHint();
        var pushed = false;
        for (self.open_streams.items) |sid| {
            var buf: [4096]u8 = undefined;
            while (true) {
                const n = self.client.recvStream(sid, &buf) catch break;
                const len = n orelse break;
                if (len == 0) break;
                var idx: ?usize = null;
                for (self.recv_streams.items, 0..) |s, i| {
                    if (s.id == sid) {
                        idx = i;
                        break;
                    }
                }
                if (idx == null) {
                    self.recv_streams.append(self.allocator, .{ .id = sid }) catch break;
                    idx = self.recv_streams.items.len - 1;
                }
                self.recv_streams.items[idx.?].queue.appendSlice(self.allocator, buf[0..len]) catch break;
                pushed = true;
            }
            if (self.client.streamFinished(sid) catch false) {
                var idx: ?usize = null;
                for (self.recv_streams.items, 0..) |s, i| {
                    if (s.id == sid) {
                        idx = i;
                        break;
                    }
                }
                if (idx == null) {
                    self.recv_streams.append(self.allocator, .{ .id = sid }) catch continue;
                    idx = self.recv_streams.items.len - 1;
                }
                if (!self.recv_streams.items[idx.?].eof) {
                    self.recv_streams.items[idx.?].eof = true;
                    pushed = true;
                }
            }
        }
        self.state_mutex.unlock();
        if (pushed) self.data_sem.post(self.io);
    }

    /// Service lifecycle deadlines that came due and send the datagrams they
    /// produce (PTO retransmits, closing packets). Bounded per pass.
    fn serviceDueDeadlines(self: *Client) void {
        var passes: usize = 0;
        while (passes < 8) : (passes += 1) {
            var out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
            const due = self.client.serviceDueDeadlineAndDrainDatagramsWithRoutePath(self.nowNanos(), &out) catch |err| {
                log.debug("client: due deadline processing: {}", .{err});
                return;
            };
            const result = due orelse return;
            for (out[0..result.drain.datagrams_written]) |o| {
                self.socket.send(self.io, &self.server_address, o.datagram) catch {};
                self.allocator.free(o.datagram);
            }
        }
    }

    /// Surface the terminal handshake state to waiting callers.
    fn checkHandshakeProgress(self: *Client) void {
        if (self.handshake_state.load(.acquire) != handshake_pending) return;
        if (!self.handshake_started) return;
        if (self.client.handshakeConfirmed()) {
            self.handshake_state.store(handshake_confirmed, .release);
            self.handshake_sem.post(self.io);
            return;
        }
        // A connection closing before confirmation can never complete the
        // handshake (server rejection, close frame, expired timers).
        if (self.client.transport.connection.isClosingOrClosed()) {
            self.handshake_state.store(handshake_failed, .release);
            self.handshake_sem.post(self.io);
        }
    }

    /// Surface a closing/closed connection to a blocked receive(): wake the
    /// stream waiters once, so they observe error.ConnectionClosed.
    fn checkConnectionClose(self: *Client) void {
        if (@atomicLoad(bool, &self.conn_closing_or_closed, .acquire)) return;
        if (!self.client.transport.connection.isClosingOrClosed()) return;
        @atomicStore(bool, &self.conn_closing_or_closed, true, .release);
        self.data_sem.post(self.io);
    }
};
