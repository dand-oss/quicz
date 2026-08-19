//! quicz CLI - daily QUIC / HTTP/3 development tool.
//!
//! Subcommands:
//!   quicz h3 <url> [-k] [-v] [-i] [-I] [-L] [-s] [-f] [-o FILE] [-D FILE] [--max-redirects N] [-X METHOD] [-A UA] [-H NAME:VALUE]... [-d BODY] [--data @FILE] [--resolve HOST:PORT:ADDR] [--ca PEM] [--connect-timeout SECS] [--max-time SECS]
//!   quicz serve [--dir DIR] [--index FILE] [--port N] [--bind IP] [--cert PEM] [--key PEM]
//!   quicz echo --server [--port N] [--bind IP] [--cert PEM] [--key PEM]
//!   quicz echo --client HOST PORT [--data BODY] [--ca PEM]
//!   quicz bench HOST PORT [--size BYTES]
//!
//! The H3 / echo / bench clients accept IPv4 literals, `localhost`, or
//! resolvable host names. `--ca` requires an absolute PEM path.

const std = @import("std");
const test_certs = @import("test_certs");
const quicz = @import("quicz");

pub const std_options: std.Options = .{
    .log_level = .debug,
    .logFn = cliLog,
};

/// The CLI reports its own status and metrics via `std.debug.print`; swallow
/// the library's internal runtime logs so a successful request stays clean
/// even when the peer retransmits a packet the client cannot yet decrypt.
/// `-v` re-enables those runtime logs for connection debugging.
var g_verbose = false;

fn cliLog(
    comptime message_level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    if (g_verbose) std.log.defaultLog(message_level, scope, format, args);
}

const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;
const Client = quicz.runtime.client.Client;
const RuntimeH3Client = quicz.runtime.h3_client.H3Client;

const alpn_h3 = [_][]const u8{"h3"};
const alpn_hq = [_][]const u8{"hq-interop"};
const max_file_size: usize = 32 * 1024 * 1024;

/// Shared serve state. The H3 request handler is a plain function pointer, so
/// the CLI keeps the process Io, allocator, root directory, and server in
/// globals. Each connection driver owns its H3 state; the handler only borrows
/// these for file I/O.
var g_server: ?*Server = null;
var g_io: std.Io = undefined;
var g_allocator: std.mem.Allocator = undefined;
var g_root_dir: std.Io.Dir = undefined;
var g_index_name: []const u8 = "index.html";
var g_metrics_buf: [512]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const sub = args.next() orelse {
        printUsage();
        return;
    };

    if (std.mem.eql(u8, sub, "h3")) return cmdH3(allocator, io, &args);
    if (std.mem.eql(u8, sub, "serve")) return cmdServe(allocator, io, &args);
    if (std.mem.eql(u8, sub, "echo")) return cmdEcho(allocator, io, &args);
    if (std.mem.eql(u8, sub, "bench")) return cmdBench(allocator, io, &args);
    if (std.mem.eql(u8, sub, "help") or std.mem.eql(u8, sub, "--help") or std.mem.eql(u8, sub, "-h")) {
        printUsage();
        return;
    }
    std.debug.print("unknown subcommand: {s}\n\n", .{sub});
    printUsage();
}

fn printUsage() void {
    std.debug.print(
        \\quicz - QUIC / HTTP/3 development tool
        \\
        \\Usage:
        \\  quicz h3 <url> [-k] [-v] [-i] [-I] [-L] [-s] [-f] [-o FILE] [-D FILE] [--max-redirects N] [-X METHOD] [-A UA] [-H NAME:VALUE]... [-d BODY] [--data @FILE] [--resolve HOST:PORT:ADDR] [--ca PEM] [--connect-timeout SECS] [--max-time SECS]
        \\  quicz serve [--dir DIR] [--index FILE] [--port N] [--bind IP] [--cert PEM] [--key PEM]
        \\  quicz echo --server [--port N] [--bind IP] [--cert PEM] [--key PEM]
        \\  quicz echo --client HOST PORT [--data BODY] [--ca PEM] [--timeout-ms MS]
        \\  quicz bench HOST PORT [--size BYTES] [--timeout-ms MS]
        \\
    , .{});
}

fn nextArg(args: *std.process.Args.Iterator) ![]const u8 {
    return args.next() orelse return error.MissingArgument;
}

fn parseIpv4(s: []const u8) ![4]u8 {
    const addr = try std.Io.net.IpAddress.parseIp4(s, 0);
    return addr.ip4.bytes;
}

const ResolveOverride = struct {
    host: []const u8,
    port: u16,
    addr: [4]u8,
};

/// Parse a `--resolve HOST:PORT:ADDR` argument (curl-style DNS override).
fn parseResolveSpec(spec: []const u8) !ResolveOverride {
    const first_colon = std.mem.indexOfScalar(u8, spec, ':') orelse return error.BadResolveSpec;
    const last_colon = std.mem.lastIndexOfScalar(u8, spec, ':') orelse return error.BadResolveSpec;
    if (first_colon == last_colon) return error.BadResolveSpec;
    const host = spec[0..first_colon];
    if (host.len == 0) return error.BadResolveSpec;
    const port = try std.fmt.parseInt(u16, spec[first_colon + 1 .. last_colon], 10);
    const addr = try parseIpv4(spec[last_colon + 1 ..]);
    return .{ .host = host, .port = port, .addr = addr };
}

fn readFile(io: std.Io, path: []const u8, buf: []u8) ![]u8 {
    const file = try std.Io.Dir.openFile(.cwd(), io, path, .{});
    defer file.close(io);
    const n = try file.readPositionalAll(io, buf, 0);
    return buf[0..n];
}

/// Read a whole file into an allocator-owned buffer.
fn readFileAll(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![]u8 {
    const file = try std.Io.Dir.openFile(.cwd(), io, path, .{});
    defer file.close(io);
    const len = try file.length(io);
    const buf = try allocator.alloc(u8, len);
    errdefer allocator.free(buf);
    const n = try file.readPositionalAll(io, buf, 0);
    return buf[0..n];
}

/// Write an HTTP/3 status line and non-pseudo headers to a file.
fn writeHeadersToFile(io: std.Io, path: []const u8, status: u16, headers: []const quicz.qpack.HeaderField) !void {
    const file = try std.Io.Dir.createFile(.cwd(), io, path, .{});
    defer file.close(io);
    var buf: [32]u8 = undefined;
    const status_line = std.fmt.bufPrint(&buf, "HTTP/3 {d}\n", .{status}) catch "HTTP/3 ?\n";
    try file.writeStreamingAll(io, status_line);
    for (headers) |h| {
        if (h.name.len > 0 and h.name[0] == ':') continue;
        try file.writeStreamingAll(io, h.name);
        try file.writeStreamingAll(io, ": ");
        try file.writeStreamingAll(io, h.value);
        try file.writeStreamingAll(io, "\n");
    }
}

/// Candidate system CA bundle paths, checked in order; the first file that
/// yields at least one certificate wins.
const system_ca_bundle_paths = [_][]const u8{
    "/etc/ssl/cert.pem", // macOS, Debian/Ubuntu
    "/etc/ssl/certs/ca-certificates.crt", // Debian/Ubuntu
    "/etc/pki/tls/certs/ca-bundle.crt", // RHEL/Fedora
    "/etc/ssl/ca-bundle.pem", // SUSE / others
};

fn loadSystemCaBundle(allocator: std.mem.Allocator, io: std.Io) !std.crypto.Certificate.Bundle {
    const now = std.Io.Clock.real.now(io);
    for (system_ca_bundle_paths) |path| {
        var bundle: std.crypto.Certificate.Bundle = .empty;
        bundle.addCertsFromFilePathAbsolute(allocator, io, now, path) catch continue;
        if (bundle.bytes.items.len > 0) return bundle;
        bundle.deinit(allocator);
    }
    return error.SystemCaBundleNotFound;
}

/// Lowercase a header name so `-H 'Content-Type: ...'` behaves like curl
/// (HTTP field names must be lowercase; RFC 9110 §5.1).
fn lowercaseName(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const out = try allocator.dupe(u8, name);
    for (out) |*c| c.* = std.ascii.toLower(c.*);
    return out;
}

/// Run a network session under a hard timeout. The session runs as one
/// std.Io task; a watchdog task cancels the session if it has not completed
/// in `timeout_ms`. Without this, a missing or stalled server makes the CLI
/// block forever with no output.
const TimedWork = struct {
    done: std.atomic.Value(bool) = .init(false),
    result: ?anyerror = null,
};

fn timedSession(io: std.Io, timed: *TimedWork, work: *const fn (io: std.Io, ctx: *anyopaque) anyerror!void, ctx: *anyopaque) void {
    work(io, ctx) catch |e| {
        timed.result = e;
        timed.done.store(true, .release);
        return;
    };
    timed.result = null;
    timed.done.store(true, .release);
}

fn timedWatchdog(io: std.Io, session: *std.Io.Future(void), timed: *TimedWork, timeout_ms: u64) void {
    const tick_ms: u64 = 100;
    var waited: u64 = 0;
    while (waited < timeout_ms) {
        if (timed.done.load(.acquire)) return;
        std.Io.sleep(io, std.Io.Duration.fromMilliseconds(tick_ms), .awake) catch return;
        waited += tick_ms;
    }
    if (!timed.done.load(.acquire)) {
        session.cancel(io);
    }
}

fn mapTimedResult(r: anyerror) anyerror {
    return if (r == error.Canceled) error.Timeout else r;
}

fn runWithTimeout(io: std.Io, timeout_ms: u64, work: *const fn (io: std.Io, ctx: *anyopaque) anyerror!void, ctx: *anyopaque) !void {
    var timed: TimedWork = .{};
    var session = io.async(timedSession, .{ io, &timed, work, ctx });
    var watchdog = io.async(timedWatchdog, .{ io, &session, &timed, timeout_ms });
    _ = watchdog.await(io);
    _ = session.await(io);
    if (timed.result) |r| return mapTimedResult(r);
    return;
}

const ConnectCtx = struct { client: *Client };

fn connectWork(_: std.Io, ctx: *anyopaque) anyerror!void {
    const c: *ConnectCtx = @ptrCast(@alignCast(ctx));
    try c.client.connect();
}

/// Bound only the QUIC handshake with `--connect-timeout-ms`; the enclosing
/// `--timeout-ms` still caps the whole request.
fn connectWithTimeout(io: std.Io, timeout_ms: u64, client: *Client) !void {
    var ctx = ConnectCtx{ .client = client };
    try runWithTimeout(io, timeout_ms, connectWork, &ctx);
}

/// Resolve a host name to an IPv4 address. IPv4 literals and `localhost` are
/// handled directly; anything else goes through the std.Io DNS lookup.
fn resolveHost(io: std.Io, host: []const u8, port: u16) ![4]u8 {
    if (std.mem.eql(u8, host, "localhost")) return .{ 127, 0, 0, 1 };
    if (std.Io.net.IpAddress.parseIp4(host, port)) |addr| {
        return addr.ip4.bytes;
    } else |_| {}

    const name = std.Io.net.HostName.init(host) catch return error.BadHostName;
    var buf: [16]std.Io.net.HostName.LookupResult = undefined;
    var queue: std.Io.Queue(std.Io.net.HostName.LookupResult) = .init(&buf);
    try std.Io.net.HostName.lookup(name, io, &queue, .{ .port = port });
    while (queue.getOneUncancelable(io)) |item| {
        switch (item) {
            .address => |addr| switch (addr) {
                .ip4 => |ip4| return ip4.bytes,
                else => {},
            },
            .canonical_name => {},
        }
    } else |_| {}
    return error.NoIpv4Address;
}

fn resolveHostWithOverrides(io: std.Io, host: []const u8, port: u16, overrides: []const ResolveOverride) ![4]u8 {
    for (overrides) |o| {
        if (o.port == port and std.ascii.eqlIgnoreCase(o.host, host)) return o.addr;
    }
    return resolveHost(io, host, port);
}

fn loadCertKey(io: std.Io, cert_pem: ?[]const u8, key_pem: ?[]const u8) !struct { cert_der: []const u8, private_key: [32]u8 } {
    var cert_pem_buf: [64 * 1024]u8 = undefined;
    var cert_der_buf: [8192]u8 = undefined;
    var key_pem_buf: [64 * 1024]u8 = undefined;
    var key_der_buf: [512]u8 = undefined;

    if (cert_pem != null or key_pem != null) {
        if (cert_pem == null or key_pem == null) return error.CertAndKeyRequired;
        const cert_pem_data = try readFile(io, cert_pem.?, &cert_pem_buf);
        const cert_der = try quicz.tls_pem.decodeBlock(cert_pem_data, "CERTIFICATE", &cert_der_buf);
        const key_pem_data = try readFile(io, key_pem.?, &key_pem_buf);
        const private_key = try quicz.tls_pem.parsePrivateKeyP256(key_pem_data, &key_der_buf);
        return .{ .cert_der = cert_der, .private_key = private_key };
    }
    return .{ .cert_der = &test_certs.cert_der, .private_key = test_certs.private_key };
}

// ---------------------------------------------------------------- h3 client

const H3Target = struct {
    host: []const u8,
    port: u16,
    path: []const u8,
};

fn parseH3Url(url: []const u8) !H3Target {
    const prefix = "https://";
    if (!std.mem.startsWith(u8, url, prefix)) return error.HttpsOnly;
    const rest = url[prefix.len..];
    const slash = std.mem.indexOfScalar(u8, rest, '/') orelse rest.len;
    const authority = rest[0..slash];
    const path = if (slash < rest.len) rest[slash..] else "/";
    if (std.mem.indexOfScalar(u8, authority, '[') != null) return error.Ipv6NotSupported;

    const colon = std.mem.lastIndexOfScalar(u8, authority, ':');
    const host = if (colon) |c| authority[0..c] else authority;
    if (host.len == 0) return error.BadUrl;
    const port: u16 = if (colon) |c| try std.fmt.parseInt(u16, authority[c + 1 ..], 10) else 443;
    return .{ .host = host, .port = port, .path = path };
}

const max_cli_response_body_size: usize = 256 * 1024 * 1024;

const H3Job = struct {
    allocator: std.mem.Allocator,
    url: []const u8,
    method: []const u8,
    body: ?[]const u8,
    headers: []const quicz.qpack.HeaderField,
    insecure: bool,
    ca_bundle: ?*const std.crypto.Certificate.Bundle,
    output_path: ?[]const u8,
    include_headers: bool,
    follow_redirects: bool,
    max_redirects: usize,
    silent: bool,
    fail_on_http_error: bool,
    dump_headers_path: ?[]const u8,
    resolve: []const ResolveOverride,
    connect_timeout_ms: ?u64,
};

fn isRedirectStatus(status: u16) bool {
    return switch (status) {
        301, 302, 303, 307, 308 => true,
        else => false,
    };
}

fn findHeader(headers: []const quicz.qpack.HeaderField, name: []const u8) ?[]const u8 {
    for (headers) |h| {
        if (std.mem.eql(u8, h.name, name)) return h.value;
    }
    return null;
}

/// Apply curl-like defaults for the h3 subcommand: `-d` implies POST plus the
/// form content type, and every request carries a user-agent (overridable with
/// `-A`, replacing any `-H user-agent:` header).
fn applyH3Defaults(
    allocator: std.mem.Allocator,
    method: *[]const u8,
    method_explicit: bool,
    data_given: bool,
    headers: *std.ArrayList(quicz.qpack.HeaderField),
    user_agent: ?[]const u8,
) !void {
    if (data_given and !method_explicit and std.mem.eql(u8, method.*, "GET")) method.* = "POST";
    if (data_given and findHeader(headers.items, "content-type") == null) {
        const name = try lowercaseName(allocator, "content-type");
        headers.append(allocator, .{ .name = name, .value = "application/x-www-form-urlencoded" }) catch |e| {
            allocator.free(name);
            return e;
        };
    }
    const effective_user_agent = user_agent orelse "quicz/0.1.0";
    var i: usize = 0;
    while (i < headers.items.len) {
        if (std.mem.eql(u8, headers.items[i].name, "user-agent")) {
            allocator.free(headers.items[i].name);
            _ = headers.orderedRemove(i);
        } else {
            i += 1;
        }
    }
    const ua_name = try lowercaseName(allocator, "user-agent");
    headers.append(allocator, .{ .name = ua_name, .value = effective_user_agent }) catch |e| {
        allocator.free(ua_name);
        return e;
    };
}

/// Resolve a `Location` header against the current URL. Returns an
/// allocator-owned string; supports absolute https URLs, root-relative paths,
/// and path-relative targets.
fn resolveLocation(allocator: std.mem.Allocator, current_url: []const u8, location: []const u8) ![]const u8 {
    const loc = std.mem.trim(u8, location, " \t");
    if (loc.len == 0) return error.BadRedirectLocation;
    if (std.mem.startsWith(u8, loc, "https://")) return allocator.dupe(u8, loc);
    if (std.mem.indexOf(u8, loc, "://") != null) return error.NonHttpsRedirect;
    const base = try parseH3Url(current_url);
    if (std.mem.startsWith(u8, loc, "/")) {
        return resolvedTarget(allocator, base, "", loc);
    }
    var dir: []const u8 = "/";
    if (std.mem.lastIndexOfScalar(u8, base.path, '/')) |slash| {
        if (slash > 0) dir = base.path[0 .. slash + 1];
    }
    return resolvedTarget(allocator, base, dir, loc);
}

/// Rebuild an https URL from a target, omitting the default port 443.
fn resolvedTarget(allocator: std.mem.Allocator, target: H3Target, dir: []const u8, loc: []const u8) ![]const u8 {
    if (target.port == 443) {
        return std.fmt.allocPrint(allocator, "https://{s}{s}{s}", .{ target.host, dir, loc });
    }
    return std.fmt.allocPrint(allocator, "https://{s}:{d}{s}{s}", .{ target.host, target.port, dir, loc });
}

fn sameOrigin(host_a: []const u8, port_a: u16, host_b: []const u8, port_b: u16) bool {
    return port_a == port_b and std.mem.eql(u8, host_a, host_b);
}

fn h3Job(io: std.Io, ctx: *anyopaque) anyerror!void {
    const job: *const H3Job = @ptrCast(@alignCast(ctx));

    var current_url = job.url;
    var current_url_owned = false;
    defer if (current_url_owned) job.allocator.free(current_url);
    var redirects_left: usize = job.max_redirects;

    // Connection reused across same-origin redirects to avoid re-handshaking.
    var client: ?Client = null;
    var h3cli: ?RuntimeH3Client = null;
    var connected_host: ?[]const u8 = null;
    var connected_host_owned = false;
    var connected_port: u16 = 0;
    var connect_ms: i64 = 0;
    defer {
        if (h3cli) |*h| h.deinit();
        if (client) |*c| c.deinit();
        if (connected_host_owned) {
            if (connected_host) |host| job.allocator.free(host);
        }
    }

    while (true) {
        const parsed = try parseH3Url(current_url);

        const origin_changed = connected_host == null or
            !sameOrigin(connected_host.?, connected_port, parsed.host, parsed.port);
        if (origin_changed) {
            if (h3cli) |*h| h.deinit();
            if (client) |*c| c.deinit();
            if (connected_host_owned) {
                if (connected_host) |host| job.allocator.free(host);
            }
            h3cli = null;
            client = null;
            connected_host = null;
            connected_host_owned = false;

            const new_host = try job.allocator.dupe(u8, parsed.host);
            errdefer job.allocator.free(new_host);

            const ip = try resolveHostWithOverrides(io, parsed.host, parsed.port, job.resolve);
            if (g_verbose) {
                std.debug.print("* resolve {s} -> {d}.{d}.{d}.{d}\n", .{ parsed.host, ip[0], ip[1], ip[2], ip[3] });
            }
            // Initialise directly into the optional payload so the drive task
            // started by `connect()` keeps pointing at a stable address.
            client = try Client.init(job.allocator, io, .{
                .server_host = ip,
                .server_port = parsed.port,
                .server_name = parsed.host,
                .alpn = &alpn_h3,
                .insecure_skip_verify = job.insecure or job.ca_bundle == null,
                .ca_bundle = job.ca_bundle,
            });
            errdefer {
                if (client) |*c| {
                    c.deinit();
                    client = null;
                }
            }
            const c0 = std.Io.Timestamp.now(io, .awake);
            if (job.connect_timeout_ms) |ms| {
                try connectWithTimeout(io, ms, &client.?);
            } else {
                try client.?.connect();
            }
            const c1 = std.Io.Timestamp.now(io, .awake);
            connect_ms = std.Io.Duration.toMilliseconds(c0.durationTo(c1));
            if (g_verbose) {
                std.debug.print("* Connected to {s} ({d}.{d}.{d}.{d}) port {d}\n", .{ parsed.host, ip[0], ip[1], ip[2], ip[3], parsed.port });
            }

            // Initialise directly into the optional payload: `run()` points
            // the adapter's ctx at the H3 client itself, so it must not move.
            h3cli = RuntimeH3Client.init(job.allocator, &client.?, 4096, 8);
            errdefer {
                if (h3cli) |*h| {
                    h.deinit();
                    h3cli = null;
                }
            }
            try h3cli.?.run();
            // A diagnostic client should fetch bodies larger than the library's
            // 1 MiB default response cap.
            h3cli.?.h3.max_response_body_size = max_cli_response_body_size;

            connected_host = new_host;
            connected_host_owned = true;
            connected_port = parsed.port;
        }

        const request = quicz.h3_request.Request{
            .method = job.method,
            .path = parsed.path,
            .scheme = "https",
            .authority = parsed.host,
            .extra_headers = job.headers,
            .body = job.body,
        };
        const sid = try h3cli.?.sendRequest(request);
        if (g_verbose) std.debug.print("> {s} {s} HTTP/3\n", .{ job.method, parsed.path });
        const response = try h3cli.?.receiveResponse(sid);

        if (job.follow_redirects and isRedirectStatus(response.status)) {
            if (findHeader(response.headers, "location")) |location| {
                if (redirects_left == 0) return error.TooManyRedirects;
                const next_url = try resolveLocation(job.allocator, current_url, location);
                if (g_verbose) std.debug.print("* redirect: {s}\n", .{next_url});
                if (current_url_owned) job.allocator.free(current_url);
                current_url = next_url;
                current_url_owned = true;
                redirects_left -= 1;
                continue;
            }
        }

        if (job.fail_on_http_error and response.status >= 400) {
            std.debug.print("HTTP/3 {d}\n", .{response.status});
            return error.HttpError;
        }

        if (job.dump_headers_path) |dump_path| {
            try writeHeadersToFile(io, dump_path, response.status, response.headers);
        }

        if (job.include_headers) {
            std.debug.print("HTTP/3 {d}\n", .{response.status});
            for (response.headers) |h| {
                // Skip QPACK pseudo-headers; the status line already shows them.
                if (h.name.len > 0 and h.name[0] == ':') continue;
                std.debug.print("{s}: {s}\n", .{ h.name, h.value });
            }
        } else {
            std.debug.print("HTTP/3 {d}\n", .{response.status});
        }

        if (job.output_path) |path| {
            if (std.mem.eql(u8, path, "-")) {
                if (response.body) |payload| try std.Io.File.stdout().writeStreamingAll(io, payload);
            } else {
                const file = try std.Io.Dir.createFile(.cwd(), io, path, .{});
                defer file.close(io);
                if (response.body) |payload| try file.writeStreamingAll(io, payload);
            }
        } else if (response.body) |payload| {
            try std.Io.File.stdout().writeStreamingAll(io, payload);
        }

        if (job.follow_redirects and !std.mem.eql(u8, current_url, job.url)) {
            std.debug.print("final URL: {s}\n", .{current_url});
        }

        if (!job.silent) {
            const stats = h3cli.?.client.client.transport.connection.connectionStats();
            std.debug.print("connect={d} ms srtt={d} us loss={d} retrans={d} sent={d} received={d}\n", .{
                connect_ms,
                stats.smoothed_rtt_us,
                stats.packets_lost,
                stats.packets_retransmitted,
                stats.stream_bytes_sent,
                stats.stream_bytes_received,
            });
        }
        return;
    }
}

fn cmdH3(allocator: std.mem.Allocator, io: std.Io, args: *std.process.Args.Iterator) !void {
    const url = try nextArg(args);
    var insecure = false;
    var method: []const u8 = "GET";
    var body: ?[]const u8 = null;
    var timeout_ms: u64 = 10000;
    var method_explicit = false;
    var headers = std.ArrayList(quicz.qpack.HeaderField).empty;
    defer headers.deinit(allocator);
    defer {
        for (headers.items) |h| allocator.free(h.name);
    }
    var ca_pem: ?[]const u8 = null;
    var output_path: ?[]const u8 = null;
    var dump_headers_path: ?[]const u8 = null;
    var include_headers = false;
    var follow_redirects = false;
    var max_redirects: usize = 10;
    var silent = false;
    var fail_on_http_error = false;
    var owned_body: ?[]u8 = null;
    defer if (owned_body) |b| allocator.free(b);
    var data_given = false;
    var user_agent: ?[]const u8 = null;
    var connect_timeout_ms: ?u64 = null;
    var resolves = std.ArrayList(ResolveOverride).empty;
    defer resolves.deinit(allocator);

    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "-k")) {
            insecure = true;
        } else if (std.mem.eql(u8, a, "-v") or std.mem.eql(u8, a, "--verbose")) {
            g_verbose = true;
        } else if (std.mem.eql(u8, a, "-f") or std.mem.eql(u8, a, "--fail")) {
            fail_on_http_error = true;
        } else if (std.mem.eql(u8, a, "-s") or std.mem.eql(u8, a, "--silent")) {
            silent = true;
        } else if (std.mem.eql(u8, a, "-I") or std.mem.eql(u8, a, "--head")) {
            method = "HEAD";
            method_explicit = true;
            include_headers = true;
        } else if (std.mem.eql(u8, a, "-i") or std.mem.eql(u8, a, "--include")) {
            include_headers = true;
        } else if (std.mem.eql(u8, a, "-L") or std.mem.eql(u8, a, "--location")) {
            follow_redirects = true;
        } else if (std.mem.eql(u8, a, "-D") or std.mem.eql(u8, a, "--dump-header")) {
            dump_headers_path = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--max-redirects")) {
            max_redirects = try std.fmt.parseInt(usize, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "-o") or std.mem.eql(u8, a, "--output")) {
            output_path = try nextArg(args);
        } else if (std.mem.eql(u8, a, "-X")) {
            method = try nextArg(args);
            method_explicit = true;
        } else if (std.mem.eql(u8, a, "-d") or std.mem.eql(u8, a, "--data")) {
            const raw = try nextArg(args);
            data_given = true;
            if (raw.len > 0 and raw[0] == '@') {
                const buf = try readFileAll(allocator, io, raw[1..]);
                owned_body = buf;
                body = buf;
            } else {
                body = raw;
            }
        } else if (std.mem.eql(u8, a, "-A") or std.mem.eql(u8, a, "--user-agent")) {
            user_agent = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--resolve")) {
            const override = try parseResolveSpec(try nextArg(args));
            try resolves.append(allocator, override);
        } else if (std.mem.eql(u8, a, "--connect-timeout-ms")) {
            connect_timeout_ms = try std.fmt.parseInt(u64, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "--connect-timeout")) {
            const secs = try std.fmt.parseInt(u64, try nextArg(args), 10);
            connect_timeout_ms = try std.math.mul(u64, secs, 1000);
        } else if (std.mem.eql(u8, a, "--timeout-ms")) {
            timeout_ms = try std.fmt.parseInt(u64, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "--max-time")) {
            const secs = try std.fmt.parseInt(u64, try nextArg(args), 10);
            timeout_ms = try std.math.mul(u64, secs, 1000);
        } else if (std.mem.eql(u8, a, "-H")) {
            const hv = try nextArg(args);
            const colon = std.mem.indexOfScalar(u8, hv, ':') orelse return error.InvalidHeader;
            const name = std.mem.trim(u8, hv[0..colon], " \t");
            const value = std.mem.trim(u8, hv[colon + 1 ..], " \t");
            if (name.len == 0) return error.InvalidHeader;
            const lower_name = try lowercaseName(allocator, name);
            try headers.append(allocator, .{ .name = lower_name, .value = value });
        } else if (std.mem.eql(u8, a, "--ca")) {
            ca_pem = try nextArg(args);
        } else {
            std.debug.print("h3: unknown option: {s}\n", .{a});
            return error.UnknownOption;
        }
    }

    try applyH3Defaults(allocator, &method, method_explicit, data_given, &headers, user_agent);

    var maybe_bundle: ?std.crypto.Certificate.Bundle = null;
    if (ca_pem) |pem| {
        if (!std.Io.Dir.path.isAbsolute(pem)) return error.CaPathMustBeAbsolute;
        var bundle: std.crypto.Certificate.Bundle = .empty;
        const now = std.Io.Clock.real.now(io);
        try bundle.addCertsFromFilePathAbsolute(allocator, io, now, pem);
        maybe_bundle = bundle;
    } else if (!insecure) {
        // Verify against the system CA bundle by default; `-k` opts out.
        maybe_bundle = loadSystemCaBundle(allocator, io) catch |err| blk: {
            std.debug.print("h3: system CA bundle unavailable ({s}); certificate verification disabled\n", .{@errorName(err)});
            break :blk null;
        };
    }
    defer {
        if (maybe_bundle) |*b| b.deinit(allocator);
    }

    var job: H3Job = .{
        .allocator = allocator,
        .url = url,
        .method = method,
        .body = body,
        .headers = headers.items,
        .insecure = insecure,
        .ca_bundle = if (maybe_bundle) |*b| b else null,
        .output_path = output_path,
        .include_headers = include_headers,
        .follow_redirects = follow_redirects,
        .max_redirects = max_redirects,
        .silent = silent,
        .fail_on_http_error = fail_on_http_error,
        .dump_headers_path = dump_headers_path,
        .resolve = resolves.items,
        .connect_timeout_ms = connect_timeout_ms,
    };
    try runWithTimeout(io, timeout_ms, h3Job, &job);
}

// ---------------------------------------------------------------- h3 server

fn sanitizeRelPath(path: []const u8) ![]const u8 {
    if (path.len == 0 or path[0] != '/') return error.BadPath;
    var it = std.mem.splitScalar(u8, path[1..], '/');
    while (it.next()) |seg| {
        if (std.mem.eql(u8, seg, "..")) return error.BadPath;
    }
    return path[1..];
}

fn contentTypeFor(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    if (std.mem.eql(u8, ext, ".html") or std.mem.eql(u8, ext, ".htm")) return "text/html; charset=utf-8";
    if (std.mem.eql(u8, ext, ".css")) return "text/css; charset=utf-8";
    if (std.mem.eql(u8, ext, ".js")) return "application/javascript";
    if (std.mem.eql(u8, ext, ".json")) return "application/json";
    if (std.mem.eql(u8, ext, ".txt")) return "text/plain; charset=utf-8";
    if (std.mem.eql(u8, ext, ".md")) return "text/markdown";
    if (std.mem.eql(u8, ext, ".wasm")) return "application/wasm";
    if (std.mem.eql(u8, ext, ".png")) return "image/png";
    if (std.mem.eql(u8, ext, ".jpg") or std.mem.eql(u8, ext, ".jpeg")) return "image/jpeg";
    if (std.mem.eql(u8, ext, ".gif")) return "image/gif";
    if (std.mem.eql(u8, ext, ".svg")) return "image/svg+xml";
    if (std.mem.eql(u8, ext, ".ico")) return "image/x-icon";
    if (std.mem.eql(u8, ext, ".pdf")) return "application/pdf";
    if (std.mem.eql(u8, ext, ".mp4")) return "video/mp4";
    if (std.mem.eql(u8, ext, ".webm")) return "video/webm";
    if (std.mem.eql(u8, ext, ".mp3")) return "audio/mpeg";
    if (std.mem.eql(u8, ext, ".zip")) return "application/zip";
    return "application/octet-stream";
}

/// Response body that owns a heap buffer and releases it after the H3 server
/// finishes pumping (or cancels) the stream.
const OwnedBody = struct {
    allocator: std.mem.Allocator,
    data: []u8,
    /// Extra response headers. The H3 response borrows this slice, so it must
    /// outlive the handler return; owned here and freed with the body.
    headers: []quicz.qpack.HeaderField,
    offset: usize = 0,

    fn allData(self: *OwnedBody) []const u8 {
        return self.data[self.offset..];
    }
};

fn ownedBodyNext(ctx: *anyopaque, buf: []u8) anyerror!?usize {
    const state: *OwnedBody = @ptrCast(@alignCast(ctx));
    if (state.offset >= state.data.len) return null;
    const n = @min(state.data.len - state.offset, buf.len);
    @memcpy(buf[0..n], state.data[state.offset .. state.offset + n]);
    state.offset += n;
    return n;
}

fn ownedBodyDeinit(ctx: *anyopaque) void {
    const state: *OwnedBody = @ptrCast(@alignCast(ctx));
    const allocator = state.allocator;
    allocator.free(state.headers);
    allocator.free(state.data);
    allocator.destroy(state);
}

fn ownedResponse(status: u16, content_type: []const u8, data: []u8) quicz.h3_request.Response {
    const allocator = g_allocator;
    const state = allocator.create(OwnedBody) catch return .{ .status = 500, .body = "out of memory" };
    const headers = allocator.alloc(quicz.qpack.HeaderField, 1) catch return .{ .status = 500, .body = "out of memory" };
    headers[0] = .{ .name = "content-type", .value = content_type };
    state.* = .{ .allocator = allocator, .data = data, .headers = headers };
    return .{
        .status = status,
        .extra_headers = headers,
        .body_stream = .{ .ctx = state, .next_fn = ownedBodyNext, .deinit_fn = ownedBodyDeinit },
    };
}

fn headResponse(status: u16, content_type: []const u8) quicz.h3_request.Response {
    const allocator = g_allocator;
    const state = allocator.create(OwnedBody) catch return .{ .status = 500, .body = "out of memory" };
    const headers = allocator.alloc(quicz.qpack.HeaderField, 1) catch {
        allocator.destroy(state);
        return .{ .status = 500, .body = "out of memory" };
    };
    const data = allocator.alloc(u8, 0) catch {
        allocator.free(headers);
        allocator.destroy(state);
        return .{ .status = 500, .body = "out of memory" };
    };
    headers[0] = .{ .name = "content-type", .value = content_type };
    state.* = .{ .allocator = allocator, .data = data, .headers = headers };
    return .{
        .status = status,
        .extra_headers = headers,
        .body_stream = .{ .ctx = state, .next_fn = ownedBodyNext, .deinit_fn = ownedBodyDeinit },
    };
}

fn readFileBody(rel: []const u8) ![]u8 {
    const file = try g_root_dir.openFile(g_io, rel, .{});
    defer file.close(g_io);
    const len = try file.length(g_io);
    if (len > max_file_size) return error.FileTooLarge;
    const buf = try g_allocator.alloc(u8, @intCast(len));
    errdefer g_allocator.free(buf);
    const n = try file.readPositionalAll(g_io, buf, 0);
    return buf[0..n];
}

fn directoryListingResponse(rel: []const u8) quicz.h3_request.Response {
    var prefix_buf: [4096]u8 = undefined;
    const prefix: []const u8 = if (rel.len == 0) "/" else blk: {
        const trimmed = if (rel[rel.len - 1] == '/') rel[0 .. rel.len - 1] else rel;
        const written = std.fmt.bufPrint(&prefix_buf, "/{s}/", .{trimmed}) catch return .{ .status = 500, .body = "server error" };
        break :blk written;
    };
    var dir_owned = false;
    const dir = if (rel.len == 0) g_root_dir else blk: {
        const d = g_root_dir.openDir(g_io, rel, .{ .iterate = true }) catch return .{ .status = 500, .body = "server error" };
        dir_owned = true;
        break :blk d;
    };
    defer if (dir_owned) dir.close(g_io);
    var out = std.ArrayList(u8).empty;
    defer out.deinit(g_allocator);
    out.appendSlice(g_allocator, "<!doctype html><html><head><meta charset=\"utf-8\"><title>quicz serve</title></head><body><h1>quicz serve</h1><ul>") catch return .{ .status = 500, .body = "server error" };
    var it = std.Io.Dir.iterate(dir);
    while (true) {
        const maybe_entry = it.next(g_io) catch return .{ .status = 500, .body = "server error" };
        const entry = maybe_entry orelse break;
        out.appendSlice(g_allocator, "<li><a href=\"") catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, prefix) catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, entry.name) catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, "\">") catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, entry.name) catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, if (entry.kind == .directory) "/</a></li>" else "</a></li>") catch return .{ .status = 500, .body = "server error" };
    }
    out.appendSlice(g_allocator, "</ul></body></html>") catch return .{ .status = 500, .body = "server error" };
    const data = out.toOwnedSlice(g_allocator) catch return .{ .status = 500, .body = "server error" };
    return ownedResponse(200, "text/html; charset=utf-8", data);
}

/// Serve a directory: its `--index` file when present, otherwise a listing.
fn serveDirectory(rel: []const u8, is_head: bool) ?quicz.h3_request.Response {
    const dir = g_root_dir.openDir(g_io, rel, .{ .iterate = true }) catch return null;
    defer dir.close(g_io);

    const file = dir.openFile(g_io, g_index_name, .{}) catch null;
    if (file) |f| {
        defer f.close(g_io);
        const len = f.length(g_io) catch return .{ .status = 500, .body = "server error" };
        if (len > max_file_size) return .{ .status = 413, .body = "file too large" };
        const data = g_allocator.alloc(u8, @intCast(len)) catch return .{ .status = 500, .body = "server error" };
        errdefer g_allocator.free(data);
        const n = f.readPositionalAll(g_io, data, 0) catch return .{ .status = 500, .body = "server error" };
        const body = data[0..n];
        if (is_head) {
            g_allocator.free(data);
            return headResponse(200, contentTypeFor(g_index_name));
        }
        return ownedResponse(200, contentTypeFor(g_index_name), body);
    }

    if (is_head) return headResponse(200, "text/html; charset=utf-8");
    return directoryListingResponse(rel);
}

/// HTTP/3 request echo: returns the method, path, authority, and body the
/// client sent, so any H3 client can inspect its request on the wire.
fn echoResponse(req: quicz.h3_request.DecodedRequest, is_head: bool) quicz.h3_request.Response {
    if (is_head) return headResponse(200, "text/plain; charset=utf-8");
    var out = std.ArrayList(u8).empty;
    defer out.deinit(g_allocator);
    out.appendSlice(g_allocator, "method: ") catch return .{ .status = 500, .body = "server error" };
    out.appendSlice(g_allocator, req.method) catch return .{ .status = 500, .body = "server error" };
    out.appendSlice(g_allocator, "\npath: ") catch return .{ .status = 500, .body = "server error" };
    out.appendSlice(g_allocator, req.path) catch return .{ .status = 500, .body = "server error" };
    if (req.authority) |authority| {
        out.appendSlice(g_allocator, "\nauthority: ") catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, authority) catch return .{ .status = 500, .body = "server error" };
    }
    if (req.body) |body| {
        out.appendSlice(g_allocator, "\nbody: ") catch return .{ .status = 500, .body = "server error" };
        out.appendSlice(g_allocator, body) catch return .{ .status = 500, .body = "server error" };
    }
    const data = out.toOwnedSlice(g_allocator) catch return .{ .status = 500, .body = "server error" };
    return ownedResponse(200, "text/plain; charset=utf-8", data);
}

fn serveHandler(req: quicz.h3_request.DecodedRequest) quicz.h3_request.Response {
    const is_head = std.mem.eql(u8, req.method, "HEAD");
    if (std.mem.eql(u8, req.path, "/echo")) return echoResponse(req, is_head);
    if (!std.mem.eql(u8, req.method, "GET") and !is_head) {
        return .{ .status = 405, .extra_headers = &.{.{ .name = "allow", .value = "GET, HEAD" }}, .body = "method not allowed" };
    }

    if (std.mem.eql(u8, req.path, "/metrics")) {
        if (g_server) |srv| {
            const m = srv.metricsSnapshot();
            const body = std.fmt.bufPrint(&g_metrics_buf, "connections={d}\nsent={d}\nreceived={d}\nin_flight={d}\nsrtt_us={d}\nloss={d}\nretransmitted={d}\n", .{
                m.active_connections,
                m.stream_bytes_sent,
                m.stream_bytes_received,
                m.total_bytes_in_flight,
                m.smoothed_rtt_us,
                m.packets_lost,
                m.packets_retransmitted,
            }) catch "metrics error";
            if (is_head) return headResponse(200, "text/plain");
            return .{ .status = 200, .extra_headers = &.{.{ .name = "content-type", .value = "text/plain" }}, .body = body };
        }
        return .{ .status = 503, .body = "server not ready" };
    }

    const rel = sanitizeRelPath(req.path) catch return .{ .status = 400, .body = "bad request" };
    const primary = if (rel.len == 0) g_index_name else rel;
    if (readFileBody(primary)) |data| {
        if (is_head) {
            g_allocator.free(data);
            return headResponse(200, contentTypeFor(primary));
        }
        return ownedResponse(200, contentTypeFor(primary), data);
    } else |e| switch (e) {
        error.FileTooLarge => return .{ .status = 413, .body = "file too large" },
        else => {
            if (rel.len == 0) {
                if (is_head) return headResponse(200, "text/html; charset=utf-8");
                return directoryListingResponse("");
            }
            return serveDirectory(rel, is_head) orelse .{ .status = 404, .body = "not found" };
        },
    }
}

/// HTTP/1.1 fallback server so browsers can open the same static content over
/// TCP while the QUIC listener keeps serving HTTP/3. Mirrors how real H3 sites
/// expose both listeners and let browsers upgrade via Alt-Svc.
fn serveHttp11(tcp_server: *std.Io.net.Server, port: u16) std.Io.Cancelable!void {
    const io = g_io;
    var group: std.Io.Group = .init;
    defer group.cancel(io);
    while (true) {
        var stream = tcp_server.accept(io) catch |err| switch (err) {
            error.Canceled => |e| return e,
            else => {
                std.debug.print("serve: HTTP/1.1 accept failed: {s}\n", .{@errorName(err)});
                return;
            },
        };
        group.concurrent(io, handleHttp11Connection, .{ stream, port }) catch |err| {
            std.debug.print("serve: HTTP/1.1 handler spawn failed: {s}\n", .{@errorName(err)});
            stream.close(io);
            continue;
        };
    }
}

fn handleHttp11Connection(stream: std.Io.net.Stream, port: u16) void {
    const io = g_io;
    defer {
        var copy = stream;
        copy.close(io);
    }
    var send_buffer: [65536]u8 = undefined;
    var recv_buffer: [65536]u8 = undefined;
    var connection_reader = stream.reader(io, &recv_buffer);
    var connection_writer = stream.writer(io, &send_buffer);
    var http_server: std.http.Server = .init(&connection_reader.interface, &connection_writer.interface);

    while (true) {
        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => {
                std.debug.print("serve: HTTP/1.1 receive failed: {s}\n", .{@errorName(err)});
                return;
            },
        };
        handleHttp11Request(&request, port) catch |err| switch (err) {
            else => {
                std.debug.print("serve: HTTP/1.1 request failed: {s}\n", .{@errorName(err)});
                return;
            },
        };
    }
}

fn handleHttp11Request(request: *std.http.Server.Request, port: u16) !void {
    const target = request.head.target;
    const path = if (std.mem.indexOfScalar(u8, target, '?')) |q| target[0..q] else target;
    const decoded = quicz.h3_request.DecodedRequest{
        .method = @tagName(request.head.method),
        .path = path,
        .scheme = "http",
        .authority = null,
        .body = null,
    };
    const h3resp = serveHandler(decoded);
    defer if (h3resp.body_stream) |bs| bs.deinit();

    var body: []const u8 = "";
    if (h3resp.body) |b| {
        body = b;
    } else if (h3resp.body_stream) |bs| {
        const state: *OwnedBody = @ptrCast(@alignCast(bs.ctx));
        body = state.allData();
    }

    var header_buf: [8]std.http.Header = undefined;
    var header_count: usize = 0;
    for (h3resp.extra_headers) |h| {
        if (header_count >= header_buf.len) break;
        header_buf[header_count] = .{ .name = h.name, .value = h.value };
        header_count += 1;
    }
    var alt_svc_buf: [64]u8 = undefined;
    const alt_svc = std.fmt.bufPrint(&alt_svc_buf, "h3=\":{d}\"; ma=86400", .{port}) catch null;
    if (alt_svc) |as| {
        if (header_count < header_buf.len) {
            header_buf[header_count] = .{ .name = "alt-svc", .value = as };
            header_count += 1;
        }
    }

    const status: std.http.Status = @enumFromInt(@as(u10, @intCast(h3resp.status)));
    try request.respond(body, .{
        .status = status,
        .extra_headers = header_buf[0..header_count],
        .keep_alive = false,
    });
}

fn cmdServe(allocator: std.mem.Allocator, io: std.Io, args: *std.process.Args.Iterator) !void {
    var dir_path: []const u8 = ".";
    var port: u16 = 4433;
    var bind: ?[4]u8 = null;
    var cert_pem: ?[]const u8 = null;
    var key_pem: ?[]const u8 = null;

    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "--dir")) {
            dir_path = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--index")) {
            g_index_name = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--port")) {
            port = try std.fmt.parseInt(u16, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "--bind")) {
            bind = try parseIpv4(try nextArg(args));
        } else if (std.mem.eql(u8, a, "--cert")) {
            cert_pem = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--key")) {
            key_pem = try nextArg(args);
        } else {
            std.debug.print("serve: unknown option: {s}\n", .{a});
            return error.UnknownOption;
        }
    }

    g_allocator = allocator;
    g_io = io;
    g_root_dir = try std.Io.Dir.openDir(.cwd(), io, dir_path, .{ .iterate = true });

    const identity = try loadCertKey(io, cert_pem, key_pem);

    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn_h3,
        .cert_der = identity.cert_der,
        .private_key = &identity.private_key,
        .bind_addr = bind,
    });
    defer server.deinit();
    g_server = &server;

    const ip = bind orelse [_]u8{ 127, 0, 0, 1 };
    var tcp_address = std.Io.net.IpAddress{ .ip4 = .{ .bytes = ip, .port = port } };
    var tcp_server = tcp_address.listen(io, .{ .reuse_address = true }) catch |err| {
        std.debug.print("serve: failed to listen on TCP {d}: {s}\n", .{ port, @errorName(err) });
        return err;
    };
    defer tcp_server.deinit(io);
    var tcp_serve_task = io.concurrent(serveHttp11, .{ &tcp_server, port }) catch |err| {
        std.debug.print("serve: failed to start HTTP/1.1 serve loop: {s}\n", .{@errorName(err)});
        return err;
    };
    defer tcp_serve_task.cancel(io) catch {};

    try server.serveH3(.{}, serveHandler);
    std.debug.print("quicz serve: http://127.0.0.1:{d}/ (HTTP/1.1) https://127.0.0.1:{d}/ (HTTP/3) dir={s}\n", .{ port, port, dir_path });
    server.drive_group.await(io) catch {};
    tcp_serve_task.await(io) catch {};
}

// ---------------------------------------------------------------- echo

fn echoHandler(conn: ServerConnection) std.Io.Cancelable!void {
    var c = conn;
    var buf: [65536]u8 = undefined;
    while (true) {
        var stream = c.acceptStream() catch return;
        if (stream.isUni()) {
            while (true) {
                const n = stream.receive(&buf) catch break;
                if (n == 0) break;
            }
            continue;
        }
        while (true) {
            const n = stream.receive(&buf) catch break;
            if (n == 0) break;
            stream.send(buf[0..n], false) catch break;
        }
        stream.send(&.{}, true) catch {};
    }
}

fn cmdEcho(allocator: std.mem.Allocator, io: std.Io, args: *std.process.Args.Iterator) !void {
    var server_mode = false;
    var client_mode = false;
    var port: u16 = 4433;
    var bind: ?[4]u8 = null;
    var payload: []const u8 = "hello quicz cli";
    var cert_pem: ?[]const u8 = null;
    var key_pem: ?[]const u8 = null;
    var ca_pem: ?[]const u8 = null;
    var host: ?[]const u8 = null;
    var client_port: ?u16 = null;
    var timeout_ms: u64 = 10000;

    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "--server")) {
            server_mode = true;
        } else if (std.mem.eql(u8, a, "--client")) {
            client_mode = true;
        } else if (std.mem.eql(u8, a, "--port")) {
            port = try std.fmt.parseInt(u16, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "--bind")) {
            bind = try parseIpv4(try nextArg(args));
        } else if (std.mem.eql(u8, a, "--data")) {
            payload = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--cert")) {
            cert_pem = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--key")) {
            key_pem = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--ca")) {
            ca_pem = try nextArg(args);
        } else if (std.mem.eql(u8, a, "--timeout-ms")) {
            timeout_ms = try std.fmt.parseInt(u64, try nextArg(args), 10);
        } else if (host == null) {
            host = a;
        } else if (client_port == null) {
            client_port = try std.fmt.parseInt(u16, a, 10);
        } else {
            return error.TooManyArgs;
        }
    }

    if (server_mode == client_mode) return error.AmbiguousMode;
    if (server_mode) {
        return runEchoServer(allocator, io, port, bind, cert_pem, key_pem);
    }
    const hp = host orelse return error.MissingHost;
    const cp = client_port orelse return error.MissingPort;
    return runEchoClient(allocator, io, hp, cp, payload, ca_pem, timeout_ms);
}

fn runEchoServer(allocator: std.mem.Allocator, io: std.Io, port: u16, bind: ?[4]u8, cert_pem: ?[]const u8, key_pem: ?[]const u8) !void {
    const identity = try loadCertKey(io, cert_pem, key_pem);
    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn_hq,
        .cert_der = identity.cert_der,
        .private_key = &identity.private_key,
        .bind_addr = bind,
    });
    defer server.deinit();
    try server.serve(&echoHandler);
    std.debug.print("quicz echo server on UDP port {d}\n", .{port});
    server.drive_group.await(io) catch {};
}

const EchoClientJob = struct {
    allocator: std.mem.Allocator,
    ip: [4]u8,
    host: []const u8,
    port: u16,
    payload: []const u8,
    ca_bundle: ?*const std.crypto.Certificate.Bundle,
};

fn echoClientJob(io: std.Io, ctx: *anyopaque) anyerror!void {
    const job: *const EchoClientJob = @ptrCast(@alignCast(ctx));
    var client = try Client.init(job.allocator, io, .{
        .server_host = job.ip,
        .server_port = job.port,
        .server_name = job.host,
        .alpn = &alpn_hq,
        .insecure_skip_verify = job.ca_bundle == null,
        .ca_bundle = job.ca_bundle,
    });
    defer client.deinit();

    const t0 = std.Io.Timestamp.now(io, .awake);
    try client.connect();
    const t1 = std.Io.Timestamp.now(io, .awake);
    const ok = try client.runEchoSession(job.payload);
    const connect_ms = std.Io.Duration.toMilliseconds(t0.durationTo(t1));
    if (ok) {
        std.debug.print("echo OK connect={d} ms bytes={d}\n", .{ connect_ms, job.payload.len });
    } else {
        std.debug.print("echo MISMATCH connect={d} ms\n", .{connect_ms});
        return error.EchoMismatch;
    }
}

fn runEchoClient(allocator: std.mem.Allocator, io: std.Io, host: []const u8, port: u16, payload: []const u8, ca_pem: ?[]const u8, timeout_ms: u64) !void {
    const ip = try resolveHost(io, host, port);

    var maybe_bundle: ?std.crypto.Certificate.Bundle = null;
    if (ca_pem) |pem| {
        if (!std.Io.Dir.path.isAbsolute(pem)) return error.CaPathMustBeAbsolute;
        var bundle: std.crypto.Certificate.Bundle = .empty;
        const now = std.Io.Clock.real.now(io);
        try bundle.addCertsFromFilePathAbsolute(allocator, io, now, pem);
        maybe_bundle = bundle;
    }
    defer {
        if (maybe_bundle) |*b| b.deinit(allocator);
    }

    var job: EchoClientJob = .{
        .allocator = allocator,
        .ip = ip,
        .host = host,
        .port = port,
        .payload = payload,
        .ca_bundle = if (maybe_bundle) |*b| b else null,
    };
    try runWithTimeout(io, timeout_ms, echoClientJob, &job);
}

// ---------------------------------------------------------------- bench

const BenchJob = struct {
    allocator: std.mem.Allocator,
    ip: [4]u8,
    host: []const u8,
    port: u16,
    size: usize,
};

fn benchJob(io: std.Io, ctx: *anyopaque) anyerror!void {
    const job: *const BenchJob = @ptrCast(@alignCast(ctx));
    var client = try Client.init(job.allocator, io, .{
        .server_host = job.ip,
        .server_port = job.port,
        .server_name = job.host,
        .alpn = &alpn_hq,
        .insecure_skip_verify = true,
    });
    defer client.deinit();

    const t0 = std.Io.Timestamp.now(io, .awake);
    try client.connect();
    const t1 = std.Io.Timestamp.now(io, .awake);

    const payload = try job.allocator.alloc(u8, job.size);
    defer job.allocator.free(payload);
    @memset(payload, 'x');
    const sid = try client.send(payload, true);

    var rbuf: [65536]u8 = undefined;
    var received: usize = 0;
    while (received < job.size) {
        const n = try client.receive(sid, &rbuf);
        if (n == 0) break;
        received += n;
    }
    const t2 = std.Io.Timestamp.now(io, .awake);

    const connect_ms = std.Io.Duration.toMilliseconds(t0.durationTo(t1));
    const seconds = @as(f64, @floatFromInt(std.Io.Duration.toNanoseconds(t1.durationTo(t2)))) / 1e9;
    const mbps = @as(f64, @floatFromInt(received)) * 8.0 / 1e6 / seconds;
    std.debug.print("connect={d} ms size={d} B received={d} B time={d:.3} s rate={d:.1} Mbit/s\n", .{
        connect_ms,
        job.size,
        received,
        seconds,
        mbps,
    });
    if (received != job.size) return error.BenchFailed;
}

fn cmdBench(allocator: std.mem.Allocator, io: std.Io, args: *std.process.Args.Iterator) !void {
    var host: ?[]const u8 = null;
    var port: ?u16 = null;
    var size: usize = 64 * 1024;
    var timeout_ms: u64 = 10000;

    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "--size")) {
            size = try std.fmt.parseInt(usize, try nextArg(args), 10);
        } else if (std.mem.eql(u8, a, "--timeout-ms")) {
            timeout_ms = try std.fmt.parseInt(u64, try nextArg(args), 10);
        } else if (host == null) {
            host = a;
        } else if (port == null) {
            port = try std.fmt.parseInt(u16, a, 10);
        } else {
            return error.TooManyArgs;
        }
    }
    const hp = host orelse return error.MissingHost;
    const cp = port orelse return error.MissingPort;
    if (size == 0 or size > 256 * 1024 * 1024) return error.BadSize;

    const ip = try resolveHost(io, hp, cp);
    var job: BenchJob = .{
        .allocator = allocator,
        .ip = ip,
        .host = hp,
        .port = cp,
        .size = size,
    };
    try runWithTimeout(io, timeout_ms, benchJob, &job);
}

test "parse h3 url" {
    const t = try parseH3Url("https://example.com:8443/path?q=1");
    try std.testing.expectEqualStrings("example.com", t.host);
    try std.testing.expectEqual(@as(u16, 8443), t.port);
    try std.testing.expectEqualStrings("/path?q=1", t.path);

    const t2 = try parseH3Url("https://127.0.0.1/");
    try std.testing.expectEqual(@as(u16, 443), t2.port);
    try std.testing.expectEqualStrings("/", t2.path);

    try std.testing.expectError(error.HttpsOnly, parseH3Url("http://x/"));
}

test "sanitize rel path rejects traversal" {
    try std.testing.expectEqualStrings("a/b", try sanitizeRelPath("/a/b"));
    try std.testing.expectError(error.BadPath, sanitizeRelPath("/a/../b"));
    try std.testing.expectError(error.BadPath, sanitizeRelPath("a/b"));
}

test "parse ipv4" {
    try std.testing.expectEqual([4]u8{ 127, 0, 0, 1 }, try parseIpv4("127.0.0.1"));
    try std.testing.expectError(error.InvalidCharacter, parseIpv4("not-an-ip"));
}

test "parse resolve spec" {
    const o = try parseResolveSpec("example.com:443:127.0.0.1");
    try std.testing.expectEqualStrings("example.com", o.host);
    try std.testing.expectEqual(@as(u16, 443), o.port);
    try std.testing.expectEqual([4]u8{ 127, 0, 0, 1 }, o.addr);
    try std.testing.expectError(error.BadResolveSpec, parseResolveSpec("example.com:443"));
    try std.testing.expectError(error.BadResolveSpec, parseResolveSpec(":443:127.0.0.1"));
}

test "apply h3 defaults" {
    const allocator = std.testing.allocator;
    var headers = std.ArrayList(quicz.qpack.HeaderField).empty;
    defer {
        for (headers.items) |h| allocator.free(h.name);
        headers.deinit(allocator);
    }

    var method: []const u8 = "GET";
    try applyH3Defaults(allocator, &method, false, true, &headers, null);
    try std.testing.expectEqualStrings("POST", method);
    try std.testing.expectEqualStrings("application/x-www-form-urlencoded", findHeader(headers.items, "content-type").?);
    try std.testing.expectEqualStrings("quicz/0.1.0", findHeader(headers.items, "user-agent").?);

    // A user-supplied content-type survives; -A replaces any -H user-agent.
    for (headers.items) |h| allocator.free(h.name);
    headers.clearRetainingCapacity();
    const content_type_name = try lowercaseName(allocator, "Content-Type");
    try headers.append(allocator, .{ .name = content_type_name, .value = "application/json" });
    const legacy_ua_name = try lowercaseName(allocator, "User-Agent");
    try headers.append(allocator, .{ .name = legacy_ua_name, .value = "legacy" });
    var m2: []const u8 = "GET";
    try applyH3Defaults(allocator, &m2, false, true, &headers, "my-agent/1.0");
    try std.testing.expectEqualStrings("application/json", findHeader(headers.items, "content-type").?);
    try std.testing.expectEqualStrings("my-agent/1.0", findHeader(headers.items, "user-agent").?);
    var ua_count: usize = 0;
    for (headers.items) |h| {
        if (std.mem.eql(u8, h.name, "user-agent")) ua_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), ua_count);

    // An explicit -X GET is not overridden by -d.
    for (headers.items) |h| allocator.free(h.name);
    headers.clearRetainingCapacity();
    var m3: []const u8 = "GET";
    try applyH3Defaults(allocator, &m3, true, true, &headers, null);
    try std.testing.expectEqualStrings("GET", m3);
}

test "lowercase header name" {
    const out = try lowercaseName(std.testing.allocator, "Content-Type");
    defer std.testing.allocator.free(out);
    try std.testing.expectEqualStrings("content-type", out);
}

test "redirect helpers" {
    try std.testing.expect(isRedirectStatus(301));
    try std.testing.expect(isRedirectStatus(308));
    try std.testing.expect(!isRedirectStatus(200));

    try std.testing.expect(sameOrigin("a.com", 443, "a.com", 443));
    try std.testing.expect(!sameOrigin("a.com", 8443, "a.com", 443));
    try std.testing.expect(!sameOrigin("a.com", 443, "b.com", 443));

    const headers = [_]quicz.qpack.HeaderField{
        .{ .name = "content-type", .value = "text/plain" },
        .{ .name = "location", .value = "/new" },
    };
    try std.testing.expectEqualStrings("/new", findHeader(&headers, "location").?);
    try std.testing.expect(findHeader(&headers, "server") == null);
}

test "resolve redirect location" {
    const allocator = std.testing.allocator;
    const abs = try resolveLocation(allocator, "https://a.com/x", "https://b.com/y");
    defer allocator.free(abs);
    try std.testing.expectEqualStrings("https://b.com/y", abs);

    const root = try resolveLocation(allocator, "https://a.com:8443/x", "/new");
    defer allocator.free(root);
    try std.testing.expectEqualStrings("https://a.com:8443/new", root);

    const rel = try resolveLocation(allocator, "https://a.com/a/b", "../c");
    defer allocator.free(rel);
    try std.testing.expectEqualStrings("https://a.com/a/../c", rel);

    try std.testing.expectError(error.NonHttpsRedirect, resolveLocation(allocator, "https://a.com/", "http://b.com/x"));
}
