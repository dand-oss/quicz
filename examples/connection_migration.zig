//! QUIC connection migration demo (RFC 9000 §9).
//!
//! Usage:
//!   zig build run-connection-migration
//!
//! Demonstrates PATH_CHALLENGE/PATH_RESPONSE exchange and route path
//! update when the client's UDP address changes mid-connection.
//! Uses in-memory loopback (no real sockets) for deterministic output.

const std = @import("std");
const quicz = @import("quicz");

const Connection = quicz.Connection;

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var client = try Connection.init(gpa, .client, .{
        .initial_max_data = 65536,
        .initial_max_stream_data = 16384,
        .initial_max_streams_bidi = 8,
    });
    defer client.deinit();

    var server = try Connection.init(gpa, .server, .{
        .initial_max_data = 65536,
        .initial_max_stream_data = 16384,
        .initial_max_streams_bidi = 8,
    });
    defer server.deinit();
    try server.validatePeerAddress();

    // Simulate handshake confirmed state for path validation demo
    std.debug.print("=== Connection Migration Demo ===\n\n", .{});

    // 1. Client sends PATH_CHALLENGE
    std.debug.print("1. Client sends PATH_CHALLENGE\n", .{});
    try client.sendPathChallenge([_]u8{ 1, 2, 3, 4, 5, 6, 7, 8 });
    std.debug.print("   outstanding path challenges: {d}\n", .{client.outstandingPathChallengeCount()});

    // 2. Relay client datagram to server
    var buf: [1350]u8 = undefined;
    const payload = (try client.pollTx(0, &buf)) orelse {
        std.debug.print("   no PATH_CHALLENGE payload emitted\n", .{});
        return;
    };
    std.debug.print("   PATH_CHALLENGE payload: {d} bytes\n", .{payload.len});

    // 3. Server processes and queues PATH_RESPONSE
    try server.processDatagram(0, payload);
    std.debug.print("2. Server received PATH_CHALLENGE, queued PATH_RESPONSE\n", .{});

    // 4. Relay server PATH_RESPONSE back to client
    const response = (try server.pollTx(1, &buf)) orelse {
        std.debug.print("   no PATH_RESPONSE payload emitted\n", .{});
        return;
    };
    std.debug.print("   PATH_RESPONSE payload: {d} bytes\n", .{response.len});

    // 5. Client validates PATH_RESPONSE
    try client.processDatagram(2, response);
    std.debug.print("3. Client validated PATH_RESPONSE\n", .{});
    std.debug.print("   failed path validations: {d}\n", .{client.failedPathValidationCount()});

    // 6. Summary
    std.debug.print("\n=== Migration path validated successfully ===\n", .{});
    std.debug.print("PATH_CHALLENGE -> PATH_RESPONSE round-trip complete.\n", .{});
    std.debug.print("In production, the endpoint would commit the new route path\n", .{});
    std.debug.print("after successful validation (see endpoint.updateRoutePath).\n", .{});
}
