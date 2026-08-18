//! HTTP/3 server on the production runtime.
//!
//! Usage:
//!   zig build run-h3-server
//!
//! Listens on 127.0.0.1:4433 with ALPN "h3", serving H3 through
//! `runtime.Server.serveH3` (std.Io.Threaded): the transport (socket,
//! endpoint, connection lifecycle) is owned by the runtime server, and each
//! connection is driven by the runtime H3 driver.
//!
//! Test with:
//!   curl --http3-prior https://127.0.0.1:4433/ -k -v
//! (requires a curl build with HTTP/3 support)

const std = @import("std");
const test_certs = @import("test_certs.zig");
const quicz = @import("quicz");

const Server = quicz.runtime.server.Server;

const bind_port: u16 = 4433;
const alpn = [_][]const u8{"h3"};
const allocator = std.heap.c_allocator;

const response_body = "Hello from quicz HTTP/3!";

/// Set in main so the handler can serve live server metrics.
var g_server: ?*Server = null;
var g_metrics_buf: [512]u8 = undefined;

fn handleRequest(req: quicz.h3_request.DecodedRequest) quicz.h3_request.Response {
    // GET /metrics: live aggregate connection stats (see Server.Metrics).
    if (std.mem.eql(u8, req.method, "GET") and std.mem.eql(u8, req.path, "/metrics")) {
        if (g_server) |srv| {
            const m = srv.metricsSnapshot();
            const body = std.fmt.bufPrint(&g_metrics_buf, "connections={d}\nsent={d}\nreceived={d}\nin_flight={d}\nsrtt_us={d}\nloss={d}\nretransmitted={d}\n", .{ m.active_connections, m.stream_bytes_sent, m.stream_bytes_received, m.total_bytes_in_flight, m.smoothed_rtt_us, m.packets_lost, m.packets_retransmitted }) catch "metrics error";
            return .{ .status = 200, .extra_headers = &.{.{ .name = "content-type", .value = "text/plain" }}, .body = body };
        }
        return .{ .status = 503, .body = "server not ready" };
    }
    // POST /echo: reflect the aggregated request body.
    if (std.mem.eql(u8, req.method, "POST") and std.mem.eql(u8, req.path, "/echo")) {
        return .{
            .status = 200,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/octet-stream" }},
            .body = req.body,
        };
    }
    // GET /stream: streamed (chunked) response body.
    if (std.mem.eql(u8, req.method, "GET") and std.mem.eql(u8, req.path, "/stream")) {
        return .{
            .status = 200,
            .extra_headers = &.{.{ .name = "content-type", .value = "text/plain" }},
            .body_stream = quicz.h3_request.ResponseBody.fromRepeating(allocator, 'S', 65536) catch unreachable,
        };
    }
    if (!std.mem.eql(u8, req.method, "GET")) return .{ .status = 405, .body = "method not allowed" };
    if (!std.mem.eql(u8, req.path, "/")) return .{ .status = 404, .body = "not found" };
    return .{
        .status = 200,
        .extra_headers = &.{
            .{ .name = "content-type", .value = "text/plain" },
            .{ .name = "server", .value = "quicz" },
        },
        .body = response_body,
    };
}

pub fn main() !void {
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var server = try Server.init(allocator, io, .{
        .port = bind_port,
        .alpn = &alpn,
        .cert_der = &test_certs.cert_der,
        .private_key = &test_certs.private_key,
    });
    defer server.deinit();
    g_server = &server;
    try server.serveH3(.{}, handleRequest);
    std.debug.print("quicz H3 server (runtime): https://127.0.0.1:{d} (ALPN h3)\n", .{bind_port});

    // Block until killed (serveLoop runs as a concurrent task).
    server.drive_group.await(io) catch {};
}
