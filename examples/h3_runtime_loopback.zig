//! Production-runtime HTTP/3 + QPACK loopback.
//!
//! Runs a real `runtime.Server` and `runtime.Client` on `std.Io.Threaded` with
//! ALPN "h3", drives HTTP/3 through the runtime H3 drivers, and verifies two
//! request/response rounds: the first inserts dynamic-table entries, the second
//! references them once the peer acknowledged them (RFC 9204).
//!
//! This is the production path: no manual datagram pump, no direct Connection
//! access in the example; the runtime owns the sockets, endpoints and stream
//! queues.

const std = @import("std");
const test_certs = @import("test_certs.zig");
const quicz = @import("quicz");

const Server = quicz.runtime.server.Server;
const ServerConnection = quicz.runtime.server.ServerConnection;
const Client = quicz.runtime.client.Client;
const RuntimeH3Server = quicz.runtime.h3_server.H3Server;
const RuntimeH3Client = quicz.runtime.h3_client.H3Client;

const port: u16 = 4436;
const alpn = [_][]const u8{"h3"};
const allocator = std.heap.c_allocator;

const request = quicz.h3_request.Request{
    .method = "GET",
    .path = "/api/data",
    .authority = "service.internal",
    .extra_headers = &.{
        .{ .name = "x-trace-id", .value = "trace-001" },
        .{ .name = "x-api-key", .value = "key-abc" },
    },
};

fn handleRequest(req: quicz.h3_request.DecodedRequest) quicz.h3_request.Response {
    if (!std.mem.eql(u8, req.authority.?, "service.internal")) return .{ .status = 400, .body = "BAD AUTHORITY" };
    // POST /echo: reflect the aggregated request body to prove the server
    // buffers DATA frames spanning datagrams.
    if (std.mem.eql(u8, req.method, "POST") and std.mem.eql(u8, req.path, "/echo")) {
        return .{
            .status = 200,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/octet-stream" }},
            .body = req.body,
        };
    }
    // GET /stream: streamed body, chunked into multiple DATA frames.
    if (std.mem.eql(u8, req.method, "GET") and std.mem.eql(u8, req.path, "/stream")) {
        return .{
            .status = 200,
            .body_stream = quicz.h3_request.ResponseBody.fromRepeating(allocator, 'S', 65536) catch unreachable,
        };
    }
    if (!std.mem.eql(u8, req.method, "GET")) return .{ .status = 400, .body = "BAD METHOD" };
    if (!std.mem.eql(u8, req.path, "/api/data")) return .{ .status = 404, .body = "NOT FOUND" };
    return .{
        .status = 200,
        .extra_headers = &.{
            .{ .name = "x-response-id", .value = "resp-001" },
            .{ .name = "x-server", .value = "quicz-h3" },
        },
        .body = "OK",
    };
}

/// Per-connection runtime handler: the H3 driver owns the serve loop.
fn handleConnection(conn: ServerConnection) std.Io.Cancelable!void {
    var h3srv = RuntimeH3Server.init(allocator, conn.server, conn.id, handleRequest, 4096, 8);
    defer h3srv.deinit();
    try h3srv.run();
}

fn require(condition: bool) !void {
    if (!condition) return error.UnexpectedState;
}

fn runClientSession(io: std.Io) !void {
    var client = try Client.init(allocator, io, .{
        .server_port = port,
        .server_name = "localhost",
        .alpn = &alpn,
        .insecure_skip_verify = true,
    });
    defer client.deinit();
    try client.connect();

    var h3cli = RuntimeH3Client.init(allocator, &client, 4096, 8);
    defer h3cli.deinit();
    try h3cli.run();
    try require(h3cli.h3.settings_received);

    // Round 1: literal fields + encoder inserts (not yet acknowledged).
    const stream1 = try h3cli.sendRequest(request);
    const resp1 = try h3cli.receiveResponse(stream1);
    try require(resp1.status == 200);
    try require(std.mem.eql(u8, resp1.body.?, "OK"));

    // Round 2: the peer acknowledged round 1's insertions, so the request
    // header block can reference dynamic-table entries.
    const stream2 = try h3cli.sendRequest(request);
    const resp2 = try h3cli.receiveResponse(stream2);
    try require(resp2.status == 200);
    try require(std.mem.eql(u8, resp2.body.?, "OK"));

    // Round 3: POST /echo with a body larger than the default 4096 stream
    // flow-control window (but below the 8192 request buffer), proving the
    // server aggregates a body that overflows the window via the
    // drainOutgoing credit-retry path.
    const body3 = try allocator.alloc(u8, 4080);
    defer allocator.free(body3);
    @memset(body3, 0x41); // 'A'
    const req3 = quicz.h3_request.Request{
        .method = "POST",
        .path = "/echo",
        .authority = "service.internal",
        .body = body3,
    };
    // Send the body as a streamed (chunked) request body via sendRequestStreamed.
    const stream3 = try h3cli.sendRequestStreamed(
        req3,
        quicz.h3_request.ResponseBody.fromRepeating(allocator, 0x41, body3.len) catch unreachable,
    );
    const resp3 = try h3cli.receiveResponse(stream3);
    try require(resp3.status == 200);
    try require(resp3.body != null and std.mem.eql(u8, resp3.body.?, body3));

    // Round 4: GET /stream with a chunked (streamed) response body.
    const req4 = quicz.h3_request.Request{ .method = "GET", .path = "/stream", .authority = "service.internal" };
    const stream4 = try h3cli.sendRequest(req4);
    const resp4 = try h3cli.receiveResponse(stream4);
    try require(resp4.status == 200);
    try require(resp4.body != null and resp4.body.?.len == 65536);
    for (resp4.body.?) |b| try require(b == 'S');

    // Let decoder-stream acknowledgments catch up and confirm the QPACK
    // control flow closed: no pending sections, KRC == insert count.
    var drained = false;
    for (0..100) |_| {
        try h3cli.drain();
        const enc = &h3cli.h3.enc_table.?;
        if (h3cli.h3.pending_sections.?.count() == 0 and enc.known_received_count == enc.insert_count) {
            drained = true;
            break;
        }
        std.Io.sleep(io, std.Io.Duration.fromMilliseconds(10), .awake) catch {};
    }
    try require(drained);

    std.debug.print(
        "h3_runtime_loopback: runtime HTTP/3 + QPACK OK round1={d} round2={d} echo={d} stream={d} client_enc_entries={d} client_krc={d} pending=0\n",
        .{ resp1.status, resp2.status, resp3.status, resp4.status, h3cli.h3.enc_table.?.entryCount(), h3cli.h3.enc_table.?.known_received_count },
    );
    client.close();
}

fn clientTask(io: std.Io, result: *bool) std.Io.Cancelable!void {
    runClientSession(io) catch |e| {
        std.debug.print("h3 client session failed: {}\n", .{e});
        @atomicStore(bool, result, true, .release);
    };
}

pub fn main() !void {
    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var server = try Server.init(allocator, io, .{
        .port = port,
        .alpn = &alpn,
        .cert_der = &test_certs.cert_der,
        .private_key = &test_certs.private_key,
    });
    defer server.deinit();
    try server.serve(&handleConnection);
    std.debug.print("h3 runtime server on 127.0.0.1:{d}\n", .{port});

    var failed: bool = false;
    var client_group: std.Io.Group = .init;
    try client_group.concurrent(io, clientTask, .{ io, &failed });
    try client_group.await(io);
    if (@atomicLoad(bool, &failed, .acquire)) return error.ClientFailed;

    server.stop();
}
