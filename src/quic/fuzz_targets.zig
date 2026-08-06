//! Fuzz targets for QUIC packet/frame/QPACK parsing.
//!
//! These functions are designed to be called by a fuzzer with arbitrary
//! byte inputs. They must not crash on any input.

const std = @import("std");
const packet = @import("packet.zig");
const frame = @import("frame.zig");
const protection = @import("protection.zig");
const h3_frame = @import("../h3/frame.zig");
const qpack = @import("../h3/qpack.zig");
const h3_limits = @import("../h3/limits.zig");
const h3_request = @import("../h3/request.zig");
const buffer = @import("buffer.zig");
const Connection = @import("connection.zig").Connection;

/// Fuzz target: parse a QUIC long header from arbitrary bytes.
pub fn fuzzParseLongHeader(data: []const u8) void {
    var reader = buffer.fixedReader(data);
    _ = packet.parseLongHeader(reader.reader(), std.heap.page_allocator) catch return;
}

/// Fuzz target: parse a QUIC short header from arbitrary bytes.
pub fn fuzzParseShortHeader(data: []const u8) void {
    for ([_]usize{ 4, 8, 16, 20 }) |dcid_len| {
        var reader = buffer.fixedReader(data);
        _ = packet.parseShortHeader(reader.reader(), std.heap.page_allocator, dcid_len) catch continue;
    }
}

/// Fuzz target: decode a QUIC frame from arbitrary bytes.
pub fn fuzzDecodeFrame(data: []const u8) void {
    _ = frame.decodeFrameSlice(data, std.heap.page_allocator) catch return;
}

/// Fuzz target: peek at a protected long packet from arbitrary bytes.
pub fn fuzzPeekProtectedLong(data: []const u8) void {
    _ = protection.peekProtectedLongPacketInfo(data) catch return;
}

/// Fuzz target: decode an HTTP/3 frame from arbitrary bytes.
pub fn fuzzDecodeH3Frame(data: []const u8) void {
    _ = h3_frame.decodeFrame(data) catch return;
}

/// Fuzz target: decode a QPACK header block from arbitrary bytes.
pub fn fuzzDecodeQpack(data: []const u8) void {
    var fields: [64]qpack.HeaderField = undefined;
    _ = qpack.decodeHeaderBlock(data, &fields) catch return;
}

/// Fuzz target: decode an HTTP/3 request from arbitrary bytes.
pub fn fuzzDecodeH3Request(data: []const u8) void {
    _ = h3_request.decodeRequest(data) catch return;
}

/// Fuzz target: decode an HTTP/3 response from arbitrary bytes.
pub fn fuzzDecodeH3Response(data: []const u8) void {
    _ = h3_request.decodeResponse(data) catch return;
}

// ── State-machine driver (interactive surface) ──
//
// The parsing targets above only exercise the decode layer. The real attack
// surface is the connection state machine: a peer feeds *sequences* of
// datagrams that advance handshake/stream/flow-control/ack/key-update state.
// This driver wires two 1-RTT connections (real AEAD keys installed) and
// pushes the fuzz bytes through as adversarially-shaped QUIC frames inside
// properly-protected short packets. Frames that pass AEAD then hit the frame
// decode → stream/flow-control/ack state machine. The driver must never crash
// on any input; every feed error is swallowed and the loop continues.

const FuzzConnectionDriver = struct {
    client: Connection,
    server: Connection,
    client_secrets: protection.Aes128PacketProtectionKeys,
    server_secrets: protection.Aes128PacketProtectionKeys,
    client_dcid: [8]u8 = undefined,
    server_dcid: [8]u8 = undefined,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) !FuzzConnectionDriver {
        const dcid = [_]u8{ 0x21, 0x43, 0x65, 0x87, 0x09, 0xba, 0xdc, 0xfe };
        const secrets = try protection.deriveInitialSecrets(.v1, &dcid);
        var driver = FuzzConnectionDriver{
            .client = try Connection.init(allocator, .client, .{}),
            .server = try Connection.init(allocator, .server, .{}),
            .client_secrets = secrets.client,
            .server_secrets = secrets.server,
            .allocator = allocator,
        };
        errdefer driver.deinit();
        try driver.client.installOneRttTrafficSecrets(.{
            .local = secrets.client.secret,
            .peer = secrets.server.secret,
        });
        try driver.server.installOneRttTrafficSecrets(.{
            .local = secrets.server.secret,
            .peer = secrets.client.secret,
        });
        try driver.client.confirmHandshake();
        try driver.server.confirmHandshake();
        try driver.server.validatePeerAddress();
        @memcpy(&driver.client_dcid, &[_]u8{ 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70, 0x80 });
        @memcpy(&driver.server_dcid, &[_]u8{ 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x11, 0x22 });
        return driver;
    }

    fn deinit(self: *FuzzConnectionDriver) void {
        self.client.deinit();
        self.server.deinit();
    }

    /// Feed `payload` as a protected short packet from server to client.
    fn feedServerToClient(self: *FuzzConnectionDriver, payload: []const u8) void {
        const datagram = protection.protectShortPacketAes128(
            self.allocator,
            .{
                .dcid = &self.client_dcid,
                .key_phase = false,
                .packet_number = 0,
            },
            .{ .len = 1, .truncated_packet_number = 0 },
            self.server_secrets,
            payload,
        ) catch return;
        defer self.allocator.free(datagram);
        _ = self.client.processProtectedShortDatagram(0, self.server_secrets, self.client_dcid.len, datagram) catch {};
    }

    /// Feed `payload` as a protected short packet from client to server.
    fn feedClientToServer(self: *FuzzConnectionDriver, payload: []const u8) void {
        const datagram = protection.protectShortPacketAes128(
            self.allocator,
            .{
                .dcid = &self.server_dcid,
                .key_phase = false,
                .packet_number = 0,
            },
            .{ .len = 1, .truncated_packet_number = 0 },
            self.client_secrets,
            payload,
        ) catch return;
        defer self.allocator.free(datagram);
        _ = self.server.processProtectedShortDatagram(0, self.client_secrets, self.server_dcid.len, datagram) catch {};
    }
};

/// Fuzz target: drive the 1-RTT connection state machine with adversarial
/// frame payloads. The first byte selects the interactive path; the remainder
/// is fed as frame bytes (or stream data) through real AEAD protection.
pub fn fuzzDriveConnectionStateMachine(data: []const u8) void {
    if (data.len == 0) return;
    const allocator = std.heap.page_allocator;
    var driver = FuzzConnectionDriver.init(allocator) catch return;
    defer driver.deinit();

    const opcode = data[0];
    const payload = data[1..];
    const opo = opcode & 0x0f;

    // Path 0-3: feed payload as frames in either direction.
    switch (opo) {
        0, 1, 2, 3 => driver.feedServerToClient(payload),
        4, 5, 6, 7 => driver.feedClientToServer(payload),
        else => {},
    }

    // Paths touching the stream / flow-control / ack surface.
    var read_buf: [256]u8 = undefined;
    if ((opcode & 0x10) != 0) {
        const stream_id = driver.client.openStream() catch 0;
        _ = driver.client.sendOnStream(stream_id, payload, true) catch {};
        _ = driver.client.recvOnStream(stream_id, &read_buf) catch {};
    }
    if ((opcode & 0x20) != 0) {
        _ = driver.server.recvOnStream(0x00, &read_buf) catch {};
    }
    if ((opcode & 0x40) != 0) {
        _ = driver.client.pendingAckLargest(.application);
        _ = driver.client.bytesInFlight(.application);
    }
    if ((opcode & 0x80) != 0) {
        _ = driver.client.localOneRttKeyUpdateCount();
        _ = driver.client.peerOneRttKeyUpdateCount();
        _ = driver.client.pendingOneRttKeyUpdateAckThreshold();
        _ = driver.server.oneRttKeyDiscardDeadline();
    }
}

/// Fuzz target: drive the QPACK dynamic table state machine (RFC 9204 §4.3).
///
/// The static-table targets above (`fuzzDecodeQpack`) never touch the dynamic
/// table, so insert/duplicate/evict/lookup and cross-referencing header blocks
/// go unexercised. This driver builds a `DynamicTable`, feeds one half of the
/// input as an encoder instruction stream (Insert / Set Capacity / Duplicate)
/// applied as it decodes, then feeds the other half as a header block that
/// references dynamic-table indices. The fuzzer controls the table lifecycle
/// end to end; no input may crash.
pub fn fuzzDriveQpackDynamicTable(data: []const u8) void {
    if (data.len < 2) return;
    const allocator = std.heap.page_allocator;
    var table = qpack.DynamicTable.init(allocator);
    defer table.deinit();
    table.setCapacity(h3_limits.max_dynamic_table_capacity);

    // Front half: encoder instruction stream, applied greedily.
    const instr_end = @min(data.len / 2, data.len - 1);
    var fields: [h3_limits.max_header_fields]qpack.HeaderField = undefined;

    var pos: usize = 1;
    while (pos < instr_end) {
        const decoded = qpack.decodeEncoderInstruction(data[pos..]) catch break;
        switch (decoded.instruction) {
            .insert_name_ref => |ins| {
                // Static name table only; dynamic refs are exercised by feed.
                if (ins.is_static and ins.name_index < qpack.static_table.len) {
                    table.insert(qpack.static_table[@intCast(ins.name_index)].name, ins.value) catch {};
                }
            },
            .insert_literal => |ins| table.insert(ins.name, ins.value) catch {},
            .set_capacity => |cap| table.setCapacity(@intCast(@min(cap, h3_limits.max_dynamic_table_capacity))),
            .duplicate => |idx| table.duplicate(idx) catch {},
        }
        if (decoded.consumed == 0) break;
        pos += decoded.consumed;
    }

    // Back half: header block referencing the (possibly populated) table.
    if (pos < data.len) {
        _ = qpack.decodeHeaderBlockWithDynamic(data[pos..], &fields, &table) catch return;
    }
}

// ── Unit tests for fuzz targets ──

test "fuzz targets handle empty input" {
    fuzzParseLongHeader(&.{});
    fuzzParseShortHeader(&.{});
    fuzzPeekProtectedLong(&.{});
    fuzzDecodeH3Frame(&.{});
    fuzzDecodeQpack(&.{});
    fuzzDecodeH3Request(&.{});
    fuzzDecodeH3Response(&.{});
}

test "fuzz targets handle garbage input" {
    const garbage = [_]u8{ 0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8, 0xf7, 0xf6, 0xf5, 0xf4, 0xf3, 0xf2, 0xf1, 0xf0 };
    fuzzParseLongHeader(&garbage);
    fuzzParseShortHeader(&garbage);
    fuzzPeekProtectedLong(&garbage);
    fuzzDecodeH3Frame(&garbage);
    fuzzDecodeQpack(&garbage);
    fuzzDecodeH3Request(&garbage);
    fuzzDecodeH3Response(&garbage);
}

test "fuzz targets handle truncated valid-looking input" {
    const truncated_long = [_]u8{ 0xC0, 0x00, 0x00, 0x00, 0x01 };
    fuzzParseLongHeader(&truncated_long);
    fuzzPeekProtectedLong(&truncated_long);

    const truncated_h3 = [_]u8{ 0x00, 0x64 };
    fuzzDecodeH3Frame(&truncated_h3);

    const truncated_qpack = [_]u8{ 0x00, 0x00, 0xC8 };
    fuzzDecodeQpack(&truncated_qpack);
}

test "fuzz targets handle maximum varint values" {
    const max_varint = [_]u8{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF };
    fuzzParseLongHeader(&max_varint);
    fuzzDecodeH3Frame(&max_varint);
    fuzzDecodeQpack(&max_varint);
}

test "fuzz state-machine driver handles empty input" {
    fuzzDriveConnectionStateMachine(&.{});
}

test "fuzz state-machine driver never crashes on garbage" {
    const garbage = [_]u8{
        0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8,
        0xf7, 0xf6, 0xf5, 0xf4, 0xf3, 0xf2, 0xf1, 0xf0,
    };
    fuzzDriveConnectionStateMachine(&garbage);
}

test "fuzz state-machine driver exercises frame + stream paths" {
    // DATAGRAM frame (type 0x30) with garbage payload through real AEAD.
    const op_dir = [_]u8{ 0x00, 0x30, 0x05, 0xde, 0xad, 0xbe, 0xef, 0xc0 };
    fuzzDriveConnectionStateMachine(&op_dir);
    // STREAM frame (type 0x08) with unterminated length.
    const op_stream = [_]u8{ 0x04, 0x08, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff };
    fuzzDriveConnectionStateMachine(&op_stream);
    // PING + ACK through the client→server path.
    const op_ack = [_]u8{ 0x05, 0x01, 0x02, 0x00, 0x01, 0x00, 0x00, 0x00 };
    fuzzDriveConnectionStateMachine(&op_ack);
    // Trigger stream + key-update-read paths.
    fuzzDriveConnectionStateMachine(&[_]u8{ 0x10, 0x68, 0x69 });
    fuzzDriveConnectionStateMachine(&[_]u8{ 0x90, 0x01 });
    fuzzDriveConnectionStateMachine(&[_]u8{ 0x3f, 0x00, 0x01, 0x02, 0x03 });
}

test "QPACK dynamic-table driver handles empty and tiny input" {
    fuzzDriveQpackDynamicTable(&.{});
    fuzzDriveQpackDynamicTable(&.{0x00});
}

test "QPACK dynamic-table driver never crashes on garbage" {
    const garbage = [_]u8{
        0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8,
        0xf7, 0xf6, 0xf5, 0xf4, 0xf3, 0xf2, 0xf1, 0xf0,
        0xef, 0xee, 0xed, 0xec, 0xeb, 0xea, 0xe9, 0xe8,
    };
    fuzzDriveQpackDynamicTable(&garbage);
}

test "QPACK dynamic-table driver exercises insert + set-capacity + block" {
    // Insert-with-literal-name (0x41), then a Set Capacity (0x3f ...), then a
    // header block referencing the dynamic table.
    fuzzDriveQpackDynamicTable(&[_]u8{
        0x41, 0x02, 'f', 'o', 0x03, 'b', 'a', 'r', // insert literal "foo"="bar"
        0x00, 0x00, // header block: req insert count 0, delta base 0
        0x80, // indexed field line, dynamic (T=0)
    });
    fuzzDriveQpackDynamicTable(&[_]u8{
        0x3f, 0x01, 0x00, // set capacity varint
        0x00, 0x00, 0x00, // empty-ish block
    });
    fuzzDriveQpackDynamicTable(&[_]u8{ 0x5f, 0x01, 0x01, 'x', 0x00, 0x00, 0x40 });
}
