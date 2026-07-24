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
fn resolveHost(hostname: []const u8) !u32 {
    // Try parsing as IP address first
    if (std.net.Ip4Address.parse(hostname, 0)) |addr| {
        return std.mem.readInt(u32, &addr.sa.addr, .big);
    } else |_| {}

    // DNS resolution
    var hints: posix.addrinfo = .{
        .family = posix.AF.INET,
        .socktype = posix.SOCK.DGRAM,
    };
    var result: ?*posix.addrinfo = null;
    const rc = posix.getaddrinfo(hostname, null, &hints, &result);
    if (rc != 0) return error.DnsResolutionFailed;
    defer posix.freeaddrinfo(result);

    if (result) |info| {
        if (info.addr.len >= 8) {
            // sockaddr_in: family(2) + port(2) + addr(4)
            return std.mem.readInt(u32, info.addr[4..8], .big);
        }
    }
    return error.DnsResolutionFailed;
}

/// Create a UDP socket and bind to 0.0.0.0:0.
fn createUdpSocket() !posix.socket_t {
    const fd = try posix.socket(posix.AF.INET, posix.SOCK.DGRAM, 0);
    var addr: posix.sockaddr_in = .{
        .port = 0,
        .addr = 0, // 0.0.0.0
    };
    posix.bind(fd, @ptrCast(&addr), @sizeOf(posix.sockaddr_in)) catch |err| {
        posix.close(fd);
        return err;
    };
    return fd;
}

/// Send a UDP datagram to the server.
fn sendTo(fd: posix.socket_t, server_ip: u32, server_port: u16, data: []const u8) !void {
    var addr: posix.sockaddr_in = .{
        .port = std.mem.nativeToBig(u16, server_port),
        .addr = std.mem.nativeToBig(u32, server_ip),
    };
    _ = try posix.sendto(fd, data, 0, @ptrCast(&addr), @sizeOf(posix.sockaddr_in));
}

/// Receive a UDP datagram with timeout. Returns number of bytes received, or null on timeout.
fn recvFromTimeout(fd: posix.socket_t, buf: []u8, timeout_ms: i32) !?usize {
    var fds = [1]posix.pollfd{.{
        .fd = fd,
        .events = posix.POLL.IN,
        .revents = 0,
    }};
    const ready = posix.poll(&fds, timeout_ms) catch return null;
    if (ready == 0) return null; // timeout
    if (fds[0].revents & posix.POLL.IN == 0) return null;

    var addr: posix.sockaddr_in = undefined;
    var addr_len: posix.socklen_t = @sizeOf(posix.sockaddr_in);
    const n = posix.recvfrom(fd, buf, 0, @ptrCast(&addr), &addr_len) catch return null;
    return n;
}

/// Save downloaded data to a file in the downloads directory.
fn saveFile(path: []const u8, data: []const u8) !void {
    const filename = if (std.mem.lastIndexOf(u8, path, "/")) |slash|
        path[slash + 1 ..]
    else
        path;

    var buf: [512]u8 = undefined;
    const full_path = std.fmt.bufPrint(&buf, "{s}/{s}", .{ downloads_dir, filename }) catch return;

    const file = std.fs.createFileAbsolute(full_path, .{}) catch return;
    defer file.close();
    file.writeAll(data) catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read environment variables
    const testcase = std.posix.getenv("TESTCASE") orelse "handshake";
    const requests_env = std.posix.getenv("REQUESTS") orelse "";
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

    // Create UDP socket
    const fd = createUdpSocket() catch {
        std.debug.print("failed to create UDP socket\n", .{});
        return error.SocketFailed;
    };
    defer posix.close(fd);

    // Get local address
    var local_addr: posix.sockaddr_in = undefined;
    var local_len: posix.socklen_t = @sizeOf(posix.sockaddr_in);
    _ = posix.getsockname(fd, @ptrCast(&local_addr), &local_len) catch {};
    const local_ip = std.mem.bigToNative(u32, local_addr.addr);
    const local_port = std.mem.bigToNative(u16, local_addr.port);

    // Create client endpoint
    const client_handle: u64 = 1;
    var local_bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &local_bytes, local_ip, .big);
    var remote_bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &remote_bytes, server_ip, .big);

    const client_path = endpoint.Udp4Tuple{
        .local = endpoint.Udp4Address.init(local_bytes, local_port),
        .remote = endpoint.Udp4Address.init(remote_bytes, server_port),
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
    sendTo(fd, server_ip, server_port, begin_result.datagram) catch {
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
        const n = recvFromTimeout(fd, &recv_buf, recv_timeout_ms) orelse {
            std.debug.print("receive timeout during handshake\n", .{});
            continue;
        };

        const result = client.receiveWithRoutePath(0, &scratch, recv_buf[0..n]) catch {
            std.debug.print("failed to process server datagram\n", .{});
            continue;
        };

        if (result.outbound_initial) |o| {
            sendTo(fd, server_ip, server_port, o.datagram) catch {};
            allocator.free(o.datagram);
        }
        if (result.outbound_handshake) |o| {
            sendTo(fd, server_ip, server_port, o.datagram) catch {};
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
            sendTo(fd, server_ip, server_port, o.datagram) catch {};
            allocator.free(o.datagram);
        }

        // Receive response
        var response_buf: [1024 * 1024]u8 = undefined;
        var response_len: usize = 0;
        var recv_attempts: usize = 0;

        while (recv_attempts < 50) : (recv_attempts += 1) {
            const n = recvFromTimeout(fd, &recv_buf, recv_timeout_ms) orelse break;

            var recv_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
            var due_out: [16]Tls13ClientEndpoint.ApplicationDatagramPathResult = undefined;
            _ = client.receiveDatagramStepWithRoutePath(
                0,
                &scratch,
                recv_buf[0..n],
                &recv_out,
                &due_out,
            ) catch continue;

            for (recv_out[0..0]) |o| {
                sendTo(fd, server_ip, server_port, o.datagram) catch {};
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
            saveFile(parsed.path, response_buf[0..response_len]) catch {
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
            sendTo(fd, server_ip, server_port, o.datagram) catch {};
            allocator.free(o.datagram);
        }
    }

    std.debug.print("quicz interop client: complete\n", .{});
}
