//! quicz interop client for QUIC-Interop-Runner.
//!
//! Downloads files from URLs in REQUESTS environment variable.
//! Saves downloaded files to /downloads.
//! Test case controlled by TESTCASE environment variable.
//!
//! Uses POSIX sockets for UDP I/O (reliable in Docker containers).

const std = @import("std");
const posix = std.posix;
const quicz = @import("quicz");

const endpoint = quicz.endpoint;
const Tls13ClientEndpoint = quicz.Tls13ClientEndpoint;

const downloads_dir = "/downloads";
const max_datagram_size: usize = 8192;
const recv_timeout_ms: i32 = 5000;

/// Parse a URL into host, port, and path.
fn parseUrl(url: []const u8) !struct { host: []const u8, port: u16, path: []const u8 } {
    var rest = url;
    if (std.mem.indexOf(u8, rest, "://")) |scheme_end| {
        rest = rest[scheme_end + 3 ..];
    }
    const path_start = std.mem.indexOf(u8, rest, "/") orelse rest.len;
    const host_port = rest[0..path_start];
    const path = if (path_start < rest.len) rest[path_start..] else "/";
    var host = host_port;
    var port: u16 = 443;
    if (std.mem.lastIndexOf(u8, host_port, ":")) |colon| {
        host = host_port[0..colon];
        port = std.fmt.parseInt(u16, host_port[colon + 1 ..], 10) catch 443;
    }
    return .{ .host = host, .port = port, .path = path };
}

/// Resolve hostname to IPv4 address using getaddrinfo.
/// Resolve hostname to IPv4 address (IP literal or DNS) via std.Io.net.
fn resolveHost(hostname: []const u8) !u32 {
    var threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    const address = std.Io.net.IpAddress.resolve(io, hostname, 0) catch return error.DnsResolutionFailed;
    return switch (address) {
        .ip4 => |ip4| std.mem.readInt(u32, &ip4.bytes, .big),
        .ip6 => error.DnsResolutionFailed,
    };
}

/// Send a UDP datagram to the server.
fn sendTo(io: std.Io, sock: *std.Io.net.Socket, server_addr: *const std.Io.net.IpAddress, data: []const u8) !void {
    try sock.send(io, server_addr, data);
}

/// Receive a UDP datagram with timeout. Returns the received slice, or null on timeout.
fn recvFromTimeout(io: std.Io, sock: *std.Io.net.Socket, buf: []u8, timeout_ms: i32) ?std.Io.net.IncomingMessage {
    const timeout: std.Io.Timeout = .{ .duration = .{ .clock = .awake, .raw = std.Io.Duration.fromMilliseconds(@intCast(timeout_ms)) } };
    return sock.receiveTimeout(io, buf, timeout) catch return null;
}

/// Save downloaded data to a file in the downloads directory.
fn saveFile(io: std.Io, path: []const u8, data: []const u8) !void {
    const filename = if (std.mem.lastIndexOf(u8, path, "/")) |slash|
        path[slash + 1 ..]
    else
        path;

    var buf: [512]u8 = undefined;
    const full_path = std.fmt.bufPrint(&buf, "{s}/{s}", .{ downloads_dir, filename }) catch return;

    const file = std.Io.Dir.createFileAbsolute(io, full_path, .{}) catch return;
    defer file.close(io);
    file.writeStreamingAll(io, data) catch return;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // Read environment variables
    const testcase = init.environ_map.get("TESTCASE") orelse "handshake";
    const requests_env = init.environ_map.get("REQUESTS") orelse "";
    std.debug.print("quicz interop client: testcase={s}\n", .{testcase});

    if (requests_env.len == 0) {
        std.debug.print("quicz interop client: no REQUESTS, attempting handshake only\n", .{});
    }

    // Parse REQUESTS (space-separated URLs)
    var urls: [32][]const u8 = undefined;
    var url_count: usize = 0;
    var iter = std.mem.splitScalar(u8, requests_env, ' ');
    while (iter.next()) |url| {
        if (url.len == 0) continue;
        if (url_count >= urls.len) break;
        urls[url_count] = url;
        url_count += 1;
    }

    // Default server for handshake-only mode
    const default_host = "server4";
    const default_port: u16 = 443;

    const server_host: []const u8 = if (url_count > 0) (try parseUrl(urls[0])).host else default_host;
    const server_port: u16 = if (url_count > 0) (try parseUrl(urls[0])).port else default_port;
    std.debug.print("quicz interop client: connecting to {s}:{d}\n", .{ server_host, server_port });

    // Resolve server address
    const server_ip = resolveHost(server_host) catch blk: {
        std.debug.print("failed to resolve {s}, using Docker default\n", .{server_host});
        break :blk @as(u32, 193) << 24 | @as(u32, 167) << 16 | @as(u32, 100) << 8 | @as(u32, 100);
    };

    // Create UDP socket (std.Io.net, 0.16)
    var threaded = std.Io.Threaded.init(std.heap.page_allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();
    var client_bind_addr = std.Io.net.IpAddress{ .ip4 = .loopback(0) };
    var client_socket = client_bind_addr.bind(io, .{ .mode = .dgram, .protocol = .udp }) catch {
        std.debug.print("failed to create UDP socket\n", .{});
        return error.SocketFailed;
    };
    defer client_socket.close(io);
    var server_address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = std.mem.toBytes(server_ip), .port = server_port } };

    // Local address (from the bound client socket)
    const local_ip_bytes = client_socket.address.ip4.bytes;
    const local_port = client_socket.address.ip4.port;

    // Create client endpoint
    const client_handle: u64 = 1;
    const client_path = endpoint.Udp4Tuple{
        .local = endpoint.Udp4Address.init(local_ip_bytes, local_port),
        .remote = endpoint.Udp4Address.init(std.mem.toBytes(server_ip), server_port),
    };
    const original_dcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
    const client_scid = [_]u8{ 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28 };
    const alpn = [_][]const u8{"hq-interop"};

    var client = Tls13ClientEndpoint.init(
        allocator,
        client_handle,
        client_path,
        .{ .active_migration_disabled = true },
        .{
            .initial_max_data = 1_048_576,
            .initial_max_stream_data = 1_048_576,
            .initial_max_streams_bidi = 128,
            .initial_max_streams_uni = 128,
            .max_datagram_size = max_datagram_size,
        },
        .{
            .alpn = &alpn,
            .server_name = server_host,
            .skip_cert_verify = true,
        },
        original_dcid,
        client_scid,
    ) catch {
        std.debug.print("failed to init client endpoint\n", .{});
        return error.ClientInitFailed;
    };
    defer client.deinit();

    // Begin handshake
    var scratch: [8192]u8 = undefined;
    const begin_result = client.beginWithRoutePath(0, &scratch) catch {
        std.debug.print("failed to begin handshake\n", .{});
        return error.HandshakeFailed;
    };

    // Send Initial to server
    sendTo(io, &client_socket, &server_address, begin_result.datagram) catch {
        std.debug.print("failed to send Initial\n", .{});
        return error.SendFailed;
    };
    allocator.free(begin_result.datagram);
    std.debug.print("quicz interop client: Initial sent\n", .{});

    // Handshake loop
    var recv_buf: [max_datagram_size]u8 = undefined;
    var handshake_done = false;
    var attempts: usize = 0;

    while (!handshake_done and attempts < 20) : (attempts += 1) {
        const received = recvFromTimeout(io, &client_socket, &recv_buf, recv_timeout_ms) orelse {
            std.debug.print("receive timeout during handshake\n", .{});
            continue;
        };

        const result = client.receiveWithRoutePath(0, &scratch, received.data) catch {
            std.debug.print("failed to process server datagram\n", .{});
            continue;
        };

        if (result.outbound_initial) |o| {
            sendTo(io, &client_socket, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }
        if (result.outbound_handshake) |o| {
            sendTo(io, &client_socket, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }

        if (client.handshakeConfirmed()) {
            handshake_done = true;
            std.debug.print("quicz interop client: handshake confirmed\n", .{});
        }
    }

    if (!handshake_done) {
        std.debug.print("quicz interop client: handshake failed\n", .{});
        return error.HandshakeFailed;
    }

    // Download files
    for (urls[0..url_count]) |url| {
        const parsed = parseUrl(url) catch continue;
        std.debug.print("quicz interop client: downloading {s}\n", .{parsed.path});

        const stream_id = client.openStream() catch continue;

        var send_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
        const send_result = client.sendStreamWithRoutePathAndDrainDatagrams(
            stream_id,
            parsed.path,
            true,
            0,
            &send_out,
        ) catch continue;

        for (send_out[0..send_result.drain.datagrams_written]) |o| {
            sendTo(io, &client_socket, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }

        // Receive response
        var response_buf: [1024 * 1024]u8 = undefined;
        var response_len: usize = 0;
        var recv_attempts: usize = 0;

        while (recv_attempts < 50) : (recv_attempts += 1) {
            const received = recvFromTimeout(io, &client_socket, &recv_buf, recv_timeout_ms) orelse break;

            var recv_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
            var due_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
            _ = client.receiveDatagramStepWithRoutePath(
                0,
                &scratch,
                received.data,
                &recv_out,
                &due_out,
            ) catch continue;

            for (recv_out[0..0]) |o| {
                sendTo(io, &client_socket, &server_address, o.datagram) catch {};
                allocator.free(o.datagram);
            }

            var read_buf: [65536]u8 = undefined;
            if (client.recvStream(stream_id, &read_buf) catch null) |bytes_read| {
                if (bytes_read > 0 and response_len + bytes_read <= response_buf.len) {
                    @memcpy(response_buf[response_len .. response_len + bytes_read], read_buf[0..bytes_read]);
                    response_len += bytes_read;
                }
            }

            if (client.streamFinished(stream_id) catch false) break;
        }

        if (response_len > 0) {
            saveFile(io, parsed.path, response_buf[0..response_len]) catch {
                std.debug.print("failed to save {s}\n", .{parsed.path});
            };
            std.debug.print("quicz interop client: saved {s} ({d} bytes)\n", .{ parsed.path, response_len });
        }
    }

    // Close connection
    var close_out: [4]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
    const close_result = client.closeApplicationWithRoutePathAndDrainDatagrams(0, "done", 0, &close_out) catch null;
    if (close_result) |result| {
        for (close_out[0..result.drain.datagrams_written]) |o| {
            sendTo(io, &client_socket, &server_address, o.datagram) catch {};
            allocator.free(o.datagram);
        }
    }

    std.debug.print("quicz interop client: complete\n", .{});
}
