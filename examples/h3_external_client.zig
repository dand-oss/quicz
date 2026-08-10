//! HTTP/3 client against a real third-party H3 server (quic-go http3.Server).
//!
//! Reverse-interop direction of `examples/interop/http3_client`: a quicz
//! `runtime.Client` + `runtime.h3_client.H3Client` connects to an external
//! HTTP/3 server (go quic-go `http3.Server`, see
//! `examples/interop/http3_server/main.go`) and completes real requests:
//! GET /, POST /echo (body), GET /headers (extra response headers).
//!
//! Usage:
//!   go run ../interop/http3_server/main.go &          # go server on :4439
//!   zig build run-h3-external-client                  # quicz client
//!
//! The server certificate is self-signed, so the client skips verification
//! (equivalent to curl -k).
const std = @import("std");
const quicz = @import("quicz");

const Client = quicz.runtime.client.Client;
const RuntimeH3Client = quicz.runtime.h3_client.H3Client;

const server_host = [_]u8{ 127, 0, 0, 1 };
const server_port: u16 = 4439;
const alpn = [_][]const u8{"h3"};
const allocator = std.heap.c_allocator;

fn require(condition: bool) !void {
    if (!condition) return error.UnexpectedState;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var client = try Client.init(allocator, io, .{
        .server_host = server_host,
        .server_port = server_port,
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
    std.debug.print("h3 external client: handshake + SETTINGS OK\n", .{});

    // GET / : root response body.
    const req1 = quicz.h3_request.Request{ .method = "GET", .path = "/", .authority = "localhost" };
    const stream1 = try h3cli.sendRequest(req1);
    const resp1 = try h3cli.receiveResponse(stream1);
    try require(resp1.status == 200);
    try require(std.mem.eql(u8, resp1.body.?, "Hello from go http3 server"));
    std.debug.print("GET / status={d} body=\"{s}\"\n", .{ resp1.status, resp1.body.? });

    // GET /headers : go's QPACK encoder emits extra response headers here
    // (x-quicz-probe, server); quicz decodes and skips them.
    const req2 = quicz.h3_request.Request{ .method = "GET", .path = "/headers", .authority = "localhost" };
    const stream2 = try h3cli.sendRequest(req2);
    const resp2 = try h3cli.receiveResponse(stream2);
    try require(resp2.status == 200);
    std.debug.print("GET /headers status={d}\n", .{resp2.status});

    // POST /echo : request body round-trip through go's QPACK dynamic table.
    const body = "hello from quicz h3 client";
    const req3 = quicz.h3_request.Request{
        .method = "POST",
        .path = "/echo",
        .authority = "localhost",
        .body = body,
    };
    const stream3 = try h3cli.sendRequest(req3);
    const resp3 = try h3cli.receiveResponse(stream3);
    try require(resp3.status == 200);
    try require(resp3.body != null and std.mem.eql(u8, resp3.body.?, body));
    std.debug.print("POST /echo status={d} echoed \"{s}\"\n", .{ resp3.status, resp3.body.? });

    // Second GET / : dynamic-table references (round 1 inserts acknowledged).
    const stream4 = try h3cli.sendRequest(req1);
    const resp4 = try h3cli.receiveResponse(stream4);
    try require(resp4.status == 200);
    try require(std.mem.eql(u8, resp4.body.?, "Hello from go http3 server"));

    std.debug.print("h3 external client: reverse interop OK (go quic-go http3.Server)\n", .{});
}
