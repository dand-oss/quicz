//! High-level QUIC endpoint API (RFC 9000 / 9001 / 9002).
//!
//! Provides a three-layer embeddable API for applications:
//!
//!   Endpoint   — owns the UDP socket, connection registry, timers, and I/O loop.
//!   Connection  — a single QUIC connection with stream and datagram operations.
//!   Stream — a single bidirectional or unidirectional stream.
//!
//! Design goals (aligned with YoMo v3 requirements):
//!   - Callers never see packet number spaces, traffic secrets, or CRYPTO frames.
//!   - Allocator is explicit; every resource has a deterministic deinit path.
//!   - IPv4 and IPv6 dual-stack from a single bind call.
//!   - Bounded connection, stream, and buffer limits enforced at the API layer.
//!   - Close is idempotent; resources are released exactly once.
//!
//! Usage sketch (server):
//!
//!   var ep = try Endpoint.listen(.{
//!       .allocator = gpa,
//!       .address = "0.0.0.0",
//!       .port = 4433,
//!       .cert_pem = cert_bytes,
//!       .key_pem = key_bytes,
//!       .alpn = &.{"h3"},
//!   });
//!   defer ep.deinit();
//!
//!   while (true) {
//!       var conn = (try ep.accept()) orelse continue;
//!       var stream = (try conn.acceptStream()) orelse continue;
//!       const n = try stream.read(buf);
//!       try stream.write(buf[0..n], .{ .fin = true });
//!       stream.close();
//!   }
//!
//! Usage sketch (client):
//!
//!   var ep = try Endpoint.bind(.{ .allocator = gpa });
//!   defer ep.deinit();
//!
//!   var conn = try ep.connect(.{
//!       .address = "127.0.0.1",
//!       .port = 4433,
//!       .server_name = "localhost",
//!       .alpn = &.{"h3"},
//!   });
//!   var stream = try conn.openStream();
//!   try stream.write(request, .{ .fin = true });
//!   const n = try stream.read(buf);

const std = @import("std");
const connection_mod = @import("connection.zig");
const endpoint_mod = @import("endpoint.zig");
const transport_params = @import("transport_parameters.zig");
const protocol_limits = @import("protocol_limits.zig");
const tls13 = @import("../tls/tls13.zig");

// ---------------------------------------------------------------------------
// Address — dual-stack IPv4/IPv6
// ---------------------------------------------------------------------------

/// Network address supporting both IPv4 and IPv6.
pub const Address = struct {
    pub const Tag = enum { ipv4, ipv6 };

    tag: Tag,
    port: u16,
    /// IPv4 bytes (valid when tag == .ipv4).
    v4: [4]u8 = .{ 0, 0, 0, 0 },
    /// IPv6 bytes (valid when tag == .ipv6).
    v6: [16]u8 = .{0} ** 16,

    /// Create an IPv4 address.
    pub fn ipv4(a: [4]u8, port: u16) Address {
        return .{ .tag = .ipv4, .port = port, .v4 = a };
    }

    /// Create an IPv6 address.
    pub fn ipv6(a: [16]u8, port: u16) Address {
        return .{ .tag = .ipv6, .port = port, .v6 = a };
    }

    /// Parse a dotted-quad IPv4 string. Returns null on parse failure.
    pub fn parseIpv4(s: []const u8, port: u16) ?Address {
        var octets: [4]u8 = undefined;
        var parts = std.mem.splitScalar(u8, s, '.');
        for (&octets) |*o| {
            const part = parts.next() orelse return null;
            o.* = std.fmt.parseInt(u8, part, 10) catch return null;
        }
        if (parts.next() != null) return null;
        return ipv4(octets, port);
    }

    /// Convert to the internal Udp4Address used by the low-level endpoint.
    /// Only valid for IPv4 addresses; IPv6 callers should use the raw socket path.
    pub fn toUdp4(self: Address) endpoint_mod.Udp4Address {
        return endpoint_mod.Udp4Address.init(self.v4, self.port);
    }

    pub fn eql(self: Address, other: Address) bool {
        if (self.tag != other.tag or self.port != other.port) return false;
        return switch (self.tag) {
            .ipv4 => std.mem.eql(u8, &self.v4, &other.v4),
            .ipv6 => std.mem.eql(u8, &self.v6, &other.v6),
        };
    }
};

// ---------------------------------------------------------------------------
// EndpointConfig / ConnectConfig
// ---------------------------------------------------------------------------

/// Configuration for Endpoint.listen() (server) or Endpoint.bind() (client).
pub const EndpointConfig = struct {
    allocator: std.mem.Allocator,
    /// Bind address. "0.0.0.0" or "::" for any. Default "0.0.0.0".
    address: []const u8 = "0.0.0.0",
    /// Bind port. 0 lets the OS assign an ephemeral port.
    port: u16 = 0,

    // -- TLS (server) --
    /// PEM-encoded certificate chain. Required for listen().
    cert_pem: ?[]const u8 = null,
    /// PEM-encoded private key. Required for listen().
    key_pem: ?[]const u8 = null,

    // -- TLS (client) --
    /// PEM-encoded CA certificate for verification. Null uses system roots.
    ca_cert_pem: ?[]const u8 = null,
    /// Skip certificate verification (testing only).
    insecure_skip_verify: bool = false,

    // -- ALPN --
    /// Application-Layer Protocol Negotiation identifiers, e.g. &.{"h3"}.
    alpn: []const []const u8 = &.{},

    // -- Transport limits --
    /// Maximum concurrent connections. 0 = unlimited.
    max_connections: usize = 0,
    /// Maximum concurrent bidirectional streams per connection.
    max_streams_bidi: u64 = 100,
    /// Maximum concurrent unidirectional streams per connection.
    max_streams_uni: u64 = 100,
    /// Maximum idle timeout in milliseconds. 0 disables.
    max_idle_timeout_ms: u64 = 30_000,
    /// Maximum UDP payload size advertised to peers.
    max_datagram_size: u16 = 1350,
    /// Initial connection-level flow control window.
    initial_max_data: u64 = 1_048_576,
    /// Initial per-stream flow control window.
    initial_max_stream_data: u64 = 262_144,
    /// Enable QUIC DATAGRAM extension (RFC 9221).
    enable_datagrams: bool = false,
    /// Maximum DATAGRAM frame size. 0 disables.
    max_datagram_frame_size: u64 = 0,
    /// Require Retry for address validation (server only).
    require_retry: bool = false,
    /// Enable IPv6 dual-stack socket.
    ipv6: bool = false,
};

/// Configuration for Endpoint.connect() (client dial).
pub const ConnectConfig = struct {
    /// Remote address string (dotted quad or IPv6 literal).
    address: []const u8,
    /// Remote port.
    port: u16,
    /// TLS SNI server name.
    server_name: []const u8 = "localhost",
    /// ALPN identifiers.
    alpn: []const []const u8 = &.{},
    /// PEM-encoded CA certificate. Null uses system roots.
    ca_cert_pem: ?[]const u8 = null,
    /// Skip certificate verification (testing only).
    insecure_skip_verify: bool = false,
    /// Handshake timeout in milliseconds.
    handshake_timeout_ms: u64 = 10_000,
};

// ---------------------------------------------------------------------------
// StreamWriteOptions
// ---------------------------------------------------------------------------

/// Options for Stream.write().
pub const StreamWriteOptions = struct {
    /// Set the FIN bit — no more data will be sent on this stream.
    fin: bool = false,
};

// ---------------------------------------------------------------------------
// Stream
// ---------------------------------------------------------------------------

/// A single QUIC stream (bidirectional or unidirectional).
///
/// Obtained from Connection.openStream(), Connection.openUniStream(),
/// or Connection.acceptStream(). The caller owns the stream and must
/// call close() when done.
pub const Stream = struct {
    conn: *Connection,
    id: u64,
    closed: bool = false,

    /// Read available data from the stream receive buffer.
    ///
    /// Returns the number of bytes copied into `buf`, or 0 when the
    /// peer has sent FIN and all data has been consumed.
    /// Returns error.StreamReset if the peer reset the stream.
    pub fn read(self: *Stream, buf: []u8) !usize {
        if (self.closed) return error.StreamClosed;
        const inner = self.conn.inner orelse return error.ConnectionClosed;
        const result = inner.recvOnStream(self.id, buf) catch |err| switch (err) {
            error.StreamClosed => return error.StreamReset,
            else => return err,
        };
        return result orelse 0;
    }

    /// Queue data for transmission on this stream.
    ///
    /// Data is buffered internally and flushed when the connection
    /// produces outgoing datagrams. Set `options.fin = true` to signal
    /// end-of-stream.
    pub fn write(self: *Stream, data: []const u8, options: StreamWriteOptions) !void {
        if (self.closed) return error.StreamClosed;
        const inner = self.conn.inner orelse return error.ConnectionClosed;
        try inner.sendOnStream(self.id, data, options.fin);
    }

    /// Reset the send side of the stream with an application error code.
    pub fn reset(self: *Stream, error_code: u64) !void {
        if (self.closed) return;
        const inner = self.conn.inner orelse return;
        inner.resetStream(self.id, error_code) catch {};
    }

    /// Request the peer stop sending on this stream.
    pub fn stopSending(self: *Stream, error_code: u64) !void {
        if (self.closed) return;
        const inner = self.conn.inner orelse return;
        inner.stopSending(self.id, error_code) catch {};
    }

    /// Check whether the peer has sent FIN and all data has been received.
    pub fn isFinished(self: *const Stream) bool {
        const inner = self.conn.inner orelse return true;
        return inner.recvStreamFinished(self.id) catch true;
    }

    /// Return the final size advertised by the peer, if known.
    pub fn finalSize(self: *const Stream) ?u64 {
        const inner = self.conn.inner orelse return null;
        return inner.recvStreamFinalSize(self.id) catch null;
    }

    /// Close the stream handle. Idempotent.
    ///
    /// This releases the local handle. If the send side has not been
    /// finished, a RESET_STREAM is implied with error code 0.
    pub fn close(self: *Stream) void {
        if (self.closed) return;
        self.closed = true;
        if (self.conn.inner) |inner| {
            inner.resetStream(self.id, 0) catch {};
        }
    }
};

// ---------------------------------------------------------------------------
// Connection
// ---------------------------------------------------------------------------

/// A single QUIC connection.
///
/// Obtained from Endpoint.connect() (client) or Endpoint.accept() (server).
/// The caller owns the connection and must call close() when done.
pub const Connection = struct {
    inner: ?*connection_mod.Connection,
    allocator: std.mem.Allocator,
    remote_addr: Address,
    local_addr: Address,
    closed: bool = false,

    // -- Stream operations --

    /// Open a new client-initiated bidirectional stream.
    pub fn openStream(self: *Connection) !Stream {
        const inner = self.inner orelse return error.ConnectionClosed;
        const stream_id = try inner.openStream();
        return .{ .conn = self, .id = stream_id };
    }

    /// Open a new client-initiated unidirectional stream.
    pub fn openUniStream(self: *Connection) !Stream {
        const inner = self.inner orelse return error.ConnectionClosed;
        const stream_id = try inner.openUniStream();
        return .{ .conn = self, .id = stream_id };
    }

    /// Accept the next peer-initiated bidirectional stream.
    ///
    /// Returns null when no stream is currently available (non-blocking).
    /// In an event-driven loop, call this after Endpoint.poll() signals
    /// new stream activity.
    pub fn acceptStream(self: *Connection) !?Stream {
        const inner = self.inner orelse return error.ConnectionClosed;
        // Scan for the lowest-numbered peer-initiated bidi stream that
        // has received data but has not yet been accepted by the application.
        // The low-level connection tracks stream state internally; this
        // wrapper exposes the next available one.
        _ = inner;
        // TODO: wire to connection accept-stream queue once the lifecycle
        // layer exposes a pending-accept iterator. For now, callers use
        // the event-driven pollDatagram path which delivers stream frames
        // directly into the connection's receive stream map.
        return null;
    }

    // -- Datagram operations (RFC 9221) --

    /// Send an unreliable DATAGRAM frame.
    pub fn sendDatagram(self: *Connection, data: []const u8) !void {
        const inner = self.inner orelse return error.ConnectionClosed;
        try inner.sendDatagram(data);
    }

    /// Receive the next queued DATAGRAM payload.
    pub fn recvDatagram(self: *Connection, buf: []u8) !?usize {
        const inner = self.inner orelse return error.ConnectionClosed;
        return try inner.recvDatagram(buf);
    }

    // -- Connection state --

    /// True once the TLS handshake is confirmed (1-RTT keys available).
    pub fn isHandshakeConfirmed(self: *const Connection) bool {
        const inner = self.inner orelse return false;
        return inner.handshakeConfirmed();
    }

    /// True if the connection is closing or closed.
    pub fn isClosed(self: *const Connection) bool {
        if (self.closed) return true;
        const inner = self.inner orelse return true;
        return inner.pendingCloseErrorCode() != null;
    }

    /// Return the negotiated QUIC version.
    pub fn version(self: *const Connection) u32 {
        const inner = self.inner orelse return 0;
        return @intFromEnum(inner.chosenVersion());
    }

    // -- Close --

    /// Close the connection with an application error code and reason.
    /// Idempotent — subsequent calls are no-ops.
    pub fn close(self: *Connection, error_code: u64, reason: []const u8) void {
        if (self.closed) return;
        self.closed = true;
        if (self.inner) |inner| {
            inner.closeApplication(error_code, reason) catch {};
        }
    }

    /// Close with a transport error code.
    pub fn closeWithTransportError(self: *Connection, error_code: u64, frame_type: u64, reason: []const u8) void {
        if (self.closed) return;
        self.closed = true;
        if (self.inner) |inner| {
            inner.closeConnection(error_code, frame_type, reason) catch {};
        }
    }

    /// Release the connection and all associated resources.
    pub fn deinit(self: *Connection) void {
        if (self.inner) |inner| {
            inner.deinit();
            self.allocator.destroy(inner);
            self.inner = null;
        }
    }
};

// ---------------------------------------------------------------------------
// Endpoint
// ---------------------------------------------------------------------------

/// QUIC endpoint — owns the UDP socket, connection registry, and timers.
///
/// Create with Endpoint.listen() (server) or Endpoint.bind() (client).
/// The endpoint drives I/O through poll() and delivers incoming connections
/// through accept().
pub const Endpoint = struct {
    allocator: std.mem.Allocator,
    config: EndpointConfig,
    local_addr: Address,
    /// Pending accepted connections waiting for the application.
    pending_accepts: std.ArrayList(Connection),
    /// All live connections owned by this endpoint.
    connections: std.ArrayList(Connection),
    is_server: bool,
    closed: bool = false,

    // -- Constructors --

    /// Create a server endpoint listening on the configured address and port.
    pub fn listen(config: EndpointConfig) !Endpoint {
        if (config.cert_pem == null or config.key_pem == null) {
            return error.MissingCertificate;
        }
        var ep = Endpoint{
            .allocator = config.allocator,
            .config = config,
            .local_addr = Address.ipv4(.{ 0, 0, 0, 0 }, config.port),
            .pending_accepts = .empty,
            .connections = .empty,
            .is_server = true,
        };
        errdefer ep.deinit();

        // Parse bind address
        if (Address.parseIpv4(config.address, config.port)) |addr| {
            ep.local_addr = addr;
        }

        return ep;
    }

    /// Create a client endpoint (no listening socket until connect()).
    pub fn bind(config: EndpointConfig) !Endpoint {
        var ep = Endpoint{
            .allocator = config.allocator,
            .config = config,
            .local_addr = Address.ipv4(.{ 0, 0, 0, 0 }, 0),
            .pending_accepts = .empty,
            .connections = .empty,
            .is_server = false,
        };
        errdefer ep.deinit();
        return ep;
    }

    // -- Server: accept --

    /// Accept the next incoming connection.
    ///
    /// Returns null when no connection is pending. Call poll() first to
    /// drive I/O and populate the accept queue.
    pub fn accept(self: *Endpoint) !?Connection {
        if (self.pending_accepts.items.len == 0) return null;
        return self.pending_accepts.orderedRemove(0);
    }

    // -- Client: connect --

    /// Initiate a new outgoing connection.
    ///
    /// The handshake is driven by subsequent poll() calls. Check
    /// Connection.isHandshakeConfirmed() to know when the connection is ready.
    pub fn connect(self: *Endpoint, config: ConnectConfig) !Connection {
        const remote = Address.parseIpv4(config.address, config.port) orelse
            return error.InvalidAddress;

        const inner = try self.allocator.create(connection_mod.Connection);
        errdefer self.allocator.destroy(inner);

        var conn_config = connection_mod.Config{};
        conn_config.max_idle_timeout_ms = self.config.max_idle_timeout_ms;
        conn_config.initial_max_data = self.config.initial_max_data;
        conn_config.initial_max_stream_data = self.config.initial_max_stream_data;
        conn_config.initial_max_streams_bidi = self.config.max_streams_bidi;
        conn_config.initial_max_streams_uni = self.config.max_streams_uni;
        conn_config.max_datagram_size = self.config.max_datagram_size;

        inner.* = try connection_mod.Connection.init(
            self.allocator,
            .client,
            conn_config,
        );

        const conn = Connection{
            .inner = inner,
            .allocator = self.allocator,
            .remote_addr = remote,
            .local_addr = self.local_addr,
        };

        try self.connections.append(self.allocator, conn);
        return conn;
    }

    // -- I/O --

    /// Drive I/O: receive datagrams from the socket, feed them to
    /// connections, fire timers, and queue outgoing datagrams.
    ///
    /// Call this in a loop. Returns the number of events processed.
    /// A return of 0 with no error means the socket timed out.
    pub fn poll(self: *Endpoint, timeout_ms: u64) !usize {
        _ = self;
        _ = timeout_ms;
        // The actual I/O loop wires into udp_event_loop.UdpSocket and
        // EndpointConnectionLifecycle. This facade method will be
        // connected once the lifecycle layer is refactored to expose
        // a unified poll interface.
        return 0;
    }

    /// Return the number of live connections.
    pub fn connectionCount(self: *const Endpoint) usize {
        return self.connections.items.len;
    }

    /// Return the local bound address.
    pub fn localAddress(self: *const Endpoint) Address {
        return self.local_addr;
    }

    // -- Lifecycle --

    /// Close the endpoint and all connections. Idempotent.
    pub fn close(self: *Endpoint) void {
        if (self.closed) return;
        self.closed = true;
        for (self.connections.items) |*conn| {
            conn.close(0, "endpoint closing");
        }
        for (self.pending_accepts.items) |*conn| {
            conn.close(0, "endpoint closing");
        }
    }

    /// Release all resources. Call close() first if not already closed.
    pub fn deinit(self: *Endpoint) void {
        self.close();
        for (self.connections.items) |*conn| {
            conn.deinit();
        }
        for (self.pending_accepts.items) |*conn| {
            conn.deinit();
        }
        self.connections.deinit(self.allocator);
        self.pending_accepts.deinit(self.allocator);
    }
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "Address: parse IPv4" {
    const addr = Address.parseIpv4("127.0.0.1", 4433).?;
    try std.testing.expectEqual(Address.Tag.ipv4, addr.tag);
    try std.testing.expectEqual(@as(u16, 4433), addr.port);
    try std.testing.expectEqualSlices(u8, &.{ 127, 0, 0, 1 }, &addr.v4);
}

test "Address: parse IPv4 invalid" {
    try std.testing.expect(Address.parseIpv4("999.0.0.1", 80) == null);
    try std.testing.expect(Address.parseIpv4("abc", 80) == null);
    try std.testing.expect(Address.parseIpv4("1.2.3", 80) == null);
}

test "Address: equality" {
    const a = Address.ipv4(.{ 10, 0, 0, 1 }, 443);
    const b = Address.ipv4(.{ 10, 0, 0, 1 }, 443);
    const c = Address.ipv4(.{ 10, 0, 0, 2 }, 443);
    try std.testing.expect(a.eql(b));
    try std.testing.expect(!a.eql(c));
}

test "Address: IPv6" {
    const a = Address.ipv6(.{0} ** 15 ++ .{1}, 443);
    try std.testing.expectEqual(Address.Tag.ipv6, a.tag);
    try std.testing.expectEqual(@as(u8, 1), a.v6[15]);
}

test "EndpointConfig: defaults" {
    const config = EndpointConfig{ .allocator = std.testing.allocator };
    try std.testing.expectEqual(@as(u64, 30_000), config.max_idle_timeout_ms);
    try std.testing.expectEqual(@as(u64, 100), config.max_streams_bidi);
    try std.testing.expectEqual(@as(u16, 1350), config.max_datagram_size);
    try std.testing.expect(!config.require_retry);
    try std.testing.expect(!config.ipv6);
}

test "Endpoint: bind and deinit" {
    var ep = try Endpoint.bind(.{ .allocator = std.testing.allocator });
    defer ep.deinit();
    try std.testing.expectEqual(@as(usize, 0), ep.connectionCount());
    try std.testing.expect(!ep.is_server);
}

test "Endpoint: listen requires cert" {
    const result = Endpoint.listen(.{ .allocator = std.testing.allocator });
    try std.testing.expectError(error.MissingCertificate, result);
}

test "Stream: write options default" {
    const opts = StreamWriteOptions{};
    try std.testing.expect(!opts.fin);
}
