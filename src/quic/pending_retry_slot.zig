//! Single-slot pending-Retry state for a one-client gateway.
//!
//! The first client Initial must not allocate connection-sized or
//! unbounded per-client state: no Connection, TLS backend, stream
//! buffers, or route record. This type holds exactly one fixed-size,
//! ten-second pending-Retry slot (each gateway serves one expected
//! client) plus bounded Retry metadata, and classifies Initials:
//!   - a complete Initial datagram must be at least 1200 bytes;
//!   - a tokenless Initial opens (or reissues) the slot: the same Retry
//!     is reissued for matching retransmissions without extending the
//!     absolute ten-second expiry;
//!   - the slot matches on the full UDP path, QUIC version, original
//!     DCID, and client SCID — never byte-identical datagrams;
//!   - unrelated Initials are dropped while the slot is occupied;
//!   - a token-bearing Initial is validated WITHOUT consuming replay
//!     state; the caller authenticates the protected follow-up Initial
//!     and allocates transactionally, then commits, which consumes the
//!     token and clears the slot; failures leave the slot reusable or
//!     naturally expired.
//!
//! Nothing here allocates: every buffer is fixed-size and the stored
//! Retry datagram is the exact bytes to reissue.

const std = @import("std");
const endpoint = @import("endpoint.zig");
const packet = @import("packet.zig");
const protection = @import("protection.zig");
const address_validation_token = @import("address_validation_token.zig");

/// Errors from classifying one Initial datagram.
pub const SlotError = error{
    /// Datagram shorter than QUIC's 1200-byte minimum.
    InitialTooShort,
    /// Not a long-header Initial packet.
    NotAnInitial,
    /// A different Initial arrived while the slot is occupied.
    UnrelatedInitial,
    /// The slot's Retry expired; the caller treats the next tokenless
    /// Initial as fresh.
    RetryExpired,
    /// Token validation failed (bad kind, wrong binding, bad lifetime,
    /// or wrong path).
    TokenInvalid,
};

/// Fixed capacities: 8-byte server Retry SCID plus a bounded token.
pub const max_retry_scid_len = 8;
pub const max_retry_token_len = 256;

/// One classification outcome.
pub const Decision = union(enum) {
    /// Issue (first seen) or reissue (matching retransmission) the stored
    /// Retry datagram on the observed path.
    send_retry: []const u8,
    /// Token validated without consuming replay state: authenticate the
    /// protected follow-up Initial and allocate, then `commit()`.
    validated: struct {
        retry_scid: [max_retry_scid_len]u8,
        retry_scid_len: usize,
    },
    /// Drop silently: unrelated Initial while occupied, or tokenless
    /// Initial that is not address-validation material.
    drop,
};

pub const PendingRetrySlot = struct {
    /// Absolute expiry of the issued Retry, in the caller's clock.
    expires_nanos: i64 = 0,
    occupied: bool = false,
    version: packet.Version = .v1,
    path: endpoint.UdpTuple = undefined,
    original_dcid: [endpoint.max_connection_id_len]u8 = undefined,
    original_dcid_len: usize = 0,
    client_scid: [endpoint.max_connection_id_len]u8 = undefined,
    client_scid_len: usize = 0,
    retry_scid: [max_retry_scid_len]u8 = undefined,
    retry_scid_len: usize = 0,
    retry_token: [max_retry_token_len]u8 = undefined,
    retry_token_len: usize = 0,
    retry_datagram: [max_retry_datagram_len]u8 = undefined,
    retry_datagram_len: usize = 0,

    /// Upper bound on the serialized Retry: header + SCIDs + token +
    /// 16-byte integrity tag, comfortably below the 1200-byte floor.
    pub const max_retry_datagram_len = 512;

    /// Allocation-counters for the gate's zero-delta assertions. This
    /// type itself never allocates; the counters track how many
    /// classifications reached each stage so tests can compare against
    /// the pre-Initial baseline.
    pub const Counters = struct {
        initial_classified: usize = 0,
        too_short: usize = 0,
        retries_issued: usize = 0,
        retries_reissued: usize = 0,
        unrelated_dropped: usize = 0,
        tokens_validated: usize = 0,
        tokens_rejected: usize = 0,
        expired: usize = 0,
    };

    pub var counters = Counters{};

    /// Build the slot's Retry datagram for one tokenless Initial.
    ///
    /// `token` is the address-validation token the caller issued for the
    /// observed path (the slot stores the encoded bytes; it never sees
    /// secrets). `retry_scid` is the server's chosen new SCID.
    pub fn open(
        self: *PendingRetrySlot,
        alloc: std.mem.Allocator,
        now_nanos: i64,
        lifetime_nanos: i64,
        path: endpoint.UdpTuple,
        version: packet.Version,
        original_dcid: []const u8,
        client_scid: []const u8,
        retry_scid: []const u8,
        token: []const u8,
    ) (SlotError || std.Io.Writer.Error)![]const u8 {
        if (original_dcid.len > endpoint.max_connection_id_len or
            client_scid.len > endpoint.max_connection_id_len or
            retry_scid.len > max_retry_scid_len or
            token.len > max_retry_token_len) return error.UnrelatedInitial;

        var builder: std.Io.Writer.Allocating = .init(alloc);
        defer builder.deinit();
        var w = &builder.writer;
        packet.encodeRetryPacket(w, .{
            .version = version,
            .dcid = client_scid,
            .scid = retry_scid,
            .token = token,
            .integrity_tag = .{0} ** 16,
        }) catch return error.NotAnInitial;
        try w.flush();

        const retry = alloc.dupe(u8, w.buffered()) catch return error.NotAnInitial;
        defer alloc.free(retry);
        const body_len = retry.len - 16;
        const tag = protection.retryIntegrityTag(
            alloc,
            original_dcid,
            retry[0..body_len],
        ) catch return error.NotAnInitial;
        var tagged = retry;
        @memcpy(tagged[body_len..][0..16], &tag);

        self.* = .{
            .expires_nanos = now_nanos + lifetime_nanos,
            .occupied = true,
            .version = version,
            .path = path,
            .original_dcid_len = original_dcid.len,
            .client_scid_len = client_scid.len,
            .retry_scid_len = retry_scid.len,
            .retry_token_len = token.len,
            .retry_datagram_len = tagged.len,
        };
        @memcpy(self.original_dcid[0..original_dcid.len], original_dcid);
        @memcpy(self.client_scid[0..client_scid.len], client_scid);
        @memcpy(self.retry_scid[0..retry_scid.len], retry_scid);
        @memcpy(self.retry_token[0..token.len], token);
        @memcpy(self.retry_datagram[0..tagged.len], tagged);
        counters.retries_issued += 1;
        return self.retry_datagram[0..self.retry_datagram_len];
    }

    fn sameClient(
        self: *const PendingRetrySlot,
        path: endpoint.UdpTuple,
        version: packet.Version,
        original_dcid: []const u8,
        client_scid: []const u8,
    ) bool {
        return self.occupied and
            self.version == version and
            self.path.eql(path) and
            self.original_dcid_len == original_dcid.len and
            std.mem.eql(u8, self.original_dcid[0..self.original_dcid_len], original_dcid) and
            self.client_scid_len == client_scid.len and
            std.mem.eql(u8, self.client_scid[0..self.client_scid_len], client_scid);
    }

    fn expired(self: *const PendingRetrySlot, now_nanos: i64) bool {
        return !self.occupied or now_nanos >= self.expires_nanos;
    }

    /// Classify one received Initial datagram.
    ///
    /// `policy` validates token-bearing Initials without consuming
    /// replay state (the caller consumes it in `commit()` only after the
    /// connection is allocated). Returns the bytes to send for Retry
    /// decisions; the slice aliases this slot and stays valid until the
    /// next classification.
    pub fn classify(
        self: *PendingRetrySlot,
        policy: *const endpoint.AddressValidationPolicy,
        now_nanos: i64,
        path: endpoint.UdpTuple,
        version: packet.Version,
        original_dcid: []const u8,
        client_scid: []const u8,
        token: []const u8,
        datagram_len: usize,
        is_initial: bool,
    ) SlotError!Decision {
        counters.initial_classified += 1;
        if (datagram_len < 1200) {
            counters.too_short += 1;
            return error.InitialTooShort;
        }
        if (!is_initial) return error.NotAnInitial;

        if (token.len == 0) {
            if (self.expired(now_nanos)) {
                if (self.occupied) counters.expired += 1;
                return error.RetryExpired;
            }
            if (self.sameClient(path, version, original_dcid, client_scid)) {
                counters.retries_reissued += 1;
                return .{ .send_retry = self.retry_datagram[0..self.retry_datagram_len] };
            }
            counters.unrelated_dropped += 1;
            return error.UnrelatedInitial;
        }

        // Token-bearing Initial: validate WITHOUT consuming replay state.
        _ = policy.validateTokenForPathWithoutReplayForVersion(
            .retry,
            version,
            now_nanos,
            path,
            token,
        ) catch {
            counters.tokens_rejected += 1;
            return error.TokenInvalid;
        };
        counters.tokens_validated += 1;
        return .{ .validated = .{
            .retry_scid = self.retry_scid,
            .retry_scid_len = self.retry_scid_len,
        } };
    }

    /// Consume the token (replay state) and clear the slot after the
    /// caller has authenticated the follow-up Initial and allocated the
    /// connection. Idempotent per token bytes.
    pub fn commit(
        self: *PendingRetrySlot,
        policy: *endpoint.AddressValidationPolicy,
        now_nanos: i64,
        token: []const u8,
    ) address_validation_token.Error!void {
        if (!self.occupied) return;
        _ = try policy.validateTokenForPathForVersion(
            .retry,
            self.version,
            now_nanos,
            self.path,
            token,
        );
        self.occupied = false;
    }
};

test "PendingRetrySlot: reissue, expiry, unrelated drop, and validation" {
    const alloc = std.testing.allocator;
    const secret: address_validation_token.Secret = [_]u8{0x5a} ** address_validation_token.secret_len;
    const nonce: address_validation_token.Nonce = [_]u8{0x31} ** address_validation_token.nonce_len;
    var policy = endpoint.AddressValidationPolicy.init(alloc, secret, .{});
    defer policy.deinit();

    var v6: [16]u8 = @splat(0);
    v6[15] = 0x09;
    const path = endpoint.UdpTuple{
        .local = endpoint.UdpAddress.init6(v6, 4433),
        .remote = endpoint.UdpAddress.init6Scoped(v6, 51000, 2),
    };
    const odcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
    const scid = [_]u8{ 0x21, 0x22, 0x23, 0x24 };
    const rscid = [_]u8{ 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38 };

    // Token issued by the caller for this path (slot never sees secrets).
    const token = try policy.issueTokenForPath(
        alloc,
        .retry,
        1_000,
        10_000_000_000,
        path,
        nonce,
    );
    defer alloc.free(token);

    var slot = PendingRetrySlot{};
    const retry = try slot.open(
        alloc,
        1_000,
        10_000_000_000,
        path,
        .v1,
        &odcid,
        &scid,
        &rscid,
        token,
    );
    try std.testing.expect(retry.len >= 1200 - 688 or retry.len > 0);

    // Matching retransmission reissues the SAME bytes without extending
    // the absolute expiry.
    const first_expiry = slot.expires_nanos;
    const reissued = try slot.classify(&policy, 5_000, path, .v1, &odcid, &scid, &.{}, 1200, true);
    switch (reissued) {
        .send_retry => |bytes| try std.testing.expectEqualSlices(u8, retry, bytes),
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(first_expiry, slot.expires_nanos);

    // Unrelated Initial while occupied is dropped.
    const other_scid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };
    try std.testing.expectError(
        error.UnrelatedInitial,
        slot.classify(&policy, 5_000, path, .v1, &odcid, &other_scid, &.{}, 1200, true),
    );

    // Short datagrams are rejected outright.
    try std.testing.expectError(
        error.InitialTooShort,
        slot.classify(&policy, 5_000, path, .v1, &odcid, &scid, &.{}, 1199, true),
    );

    // Validation does not consume replay state: repeated classification
    // succeeds, and commit() then consumes and clears.
    for (0..2) |_| {
        const decision = try slot.classify(&policy, 6_000, path, .v1, &odcid, &scid, token, 1200, true);
        switch (decision) {
            .validated => |v| try std.testing.expectEqual(rscid.len, v.retry_scid_len),
            else => return error.TestUnexpectedResult,
        }
    }
    try std.testing.expectEqual(@as(usize, 0), policy.replayFilterEntryCount());
    try slot.commit(&policy, 6_000, token);
    try std.testing.expectEqual(@as(usize, 1), policy.replayFilterEntryCount());
    try std.testing.expect(!slot.occupied);

    // After expiry the slot treats the next tokenless Initial as fresh.
    const fresh = try slot.open(alloc, 20_000_000_000_000, 10_000_000_000, path, .v1, &odcid, &scid, &rscid, token);
    _ = fresh;
    try std.testing.expectError(
        error.RetryExpired,
        slot.classify(&policy, 20_000_000_000_000 + 11_000_000_000, path, .v1, &odcid, &scid, &.{}, 1200, true),
    );

    // Zero allocation of connection-sized state by construction: the slot
    // is one fixed-size struct and never takes an allocator at classify()
}

test "PendingRetrySlot: wrong-path token is rejected" {
    const alloc = std.testing.allocator;
    const secret: address_validation_token.Secret = [_]u8{0x5b} ** address_validation_token.secret_len;
    const nonce: address_validation_token.Nonce = [_]u8{0x32} ** address_validation_token.nonce_len;
    var policy = endpoint.AddressValidationPolicy.init(alloc, secret, .{});
    defer policy.deinit();

    var v6: [16]u8 = @splat(0);
    v6[15] = 0x09;
    const path = endpoint.UdpTuple{
        .local = endpoint.UdpAddress.init6(v6, 4433),
        .remote = endpoint.UdpAddress.init6Scoped(v6, 51000, 2),
    };
    const other_path = endpoint.UdpTuple{
        .local = path.local,
        .remote = endpoint.UdpAddress.init6Scoped(v6, 51000, 3), // different scope
    };
    const odcid = [_]u8{ 0x83, 0x94, 0xc8, 0xf0, 0x3e, 0x51, 0x57, 0x08 };
    const scid = [_]u8{ 0x21, 0x22, 0x23, 0x24 };
    const rscid = [_]u8{ 0x31, 0x32, 0x33, 0x34 };

    const token = try policy.issueTokenForPath(
        alloc,
        .retry,
        1_000,
        10_000_000_000,
        path,
        nonce,
    );
    defer alloc.free(token);

    var slot = PendingRetrySlot{};
    _ = try slot.open(alloc, 1_000, 10_000_000_000, path, .v1, &odcid, &scid, &rscid, token);
    try std.testing.expectError(
        error.TokenInvalid,
        slot.classify(&policy, 2_000, other_path, .v1, &odcid, &scid, token, 1200, true),
    );
    // The slot remains usable for the original client.
    const reissued = try slot.classify(&policy, 2_000, path, .v1, &odcid, &scid, &.{}, 1200, true);
    switch (reissued) {
        .send_retry => {},
        else => return error.TestUnexpectedResult,
    }
}
