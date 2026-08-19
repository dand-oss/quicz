//! Single-slot pending-Retry state for a one-client gateway
//! (bounded-candidate contract).
//!
//! The first client Initial allocates no connection-sized or unbounded
//! per-client state: no Connection, TLS backend, stream buffers, or route
//! record. This type holds exactly one fixed-size, ten-second pending-Retry
//! slot (each gateway serves one expected client) plus bounded Retry
//! metadata, and classifies Initials:
//!
//!   - a complete Initial datagram must be at least 1200 bytes;
//!   - the slot is only ever filled by `open()` for one tokenless Initial;
//!   - a tokenless Initial reissues the stored Retry only when the slot is
//!     occupied and unexpired and the full tuple matches — UDP path, QUIC
//!     version, original DCID, and client SCID (never byte-identical
//!     datagrams) — without extending the absolute ten-second expiry;
//!   - anything else while occupied (different tuple, or a token-bearing
//!     Initial) is either unrelated-dropped or token-rejected as below;
//!   - a token-bearing follow-up is accepted only when the slot is occupied
//!     and unexpired, its path and version match, its destination CID is
//!     the issued Retry SCID, its source CID is the stored client SCID,
//!     and its token bytes equal the exact stored token. The token is then
//!     validated WITHOUT consuming replay state; the caller authenticates
//!     the protected follow-up Initial against one bounded unpublished
//!     candidate and allocates transactionally, then `commit()` publishes,
//!     consumes replay state for exactly the stored token, and clears the
//!     slot. Failures leave the slot reusable or naturally expired.
//!
//! QUIC Initial protection derives from the public destination CID, so the
//! meaningful boundary this type enforces is the token-gated exchange —
//! not client authentication.
//!
//! Allocation profile: the slot itself is one fixed-size struct. `open()`
//! encodes the Retry directly into the fixed datagram buffer and computes
//! the RFC 9001 integrity tag, which internally makes one bounded
//! temporary allocation (header + token + 1 bytes) inside
//! `protection.retryIntegrityTag`. `classify()` and `commit()` never
//! allocate.

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
    /// A different Initial arrived while the slot is occupied (tokenless
    /// tuple mismatch), or a token-bearing Initial arrived with no live
    /// stored exchange.
    UnrelatedInitial,
    /// The stored Retry expired (or the slot is empty for a tokenless
    /// Initial); the caller treats the next tokenless Initial as fresh.
    RetryExpired,
    /// The token-bearing follow-up failed the exact stored-exchange match
    /// (Retry SCID, client SCID, token bytes) or address-validation
    /// policy rejected the token for this path.
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
    /// The exact stored exchange matched and the token validated without
    /// consuming replay state: authenticate the protected follow-up
    /// Initial against one bounded unpublished candidate, then
    /// `commit()` to publish and consume.
    validated: struct {
        retry_scid: [max_retry_scid_len]u8,
        retry_scid_len: usize,
    },
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

    /// The stored Retry token, readable only while the slot holds a
    /// live (unexpired, uncommitted) exchange. Null when unoccupied or
    /// expired — expiry does not clear `occupied`, so callers must use
    /// this accessor rather than reading `occupied` alone. The slice
    /// aliases the slot's fixed buffer and is valid until the next
    /// slot mutation.
    pub fn storedToken(self: *const PendingRetrySlot, now_nanos: i64) ?[]const u8 {
        if (!self.occupied) return null;
        if (now_nanos >= self.expires_nanos) return null;
        return self.retry_token[0..self.retry_token_len];
    }

    /// Build the slot's Retry datagram for one tokenless Initial.
    ///
    /// `token` is the address-validation token the caller issued for the
    /// observed path (the slot stores the encoded bytes; it never sees
    /// secrets). `retry_scid` is the server's chosen new SCID. The Retry
    /// is encoded directly into this slot's fixed buffer; the integrity
    /// tag makes one bounded internal temporary allocation (see the file
    /// comment).
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
            token.len > max_retry_token_len or
            token.len == 0) return error.UnrelatedInitial;

        var w: std.Io.Writer = .fixed(self.retry_datagram[0..]);
        packet.encodeRetryPacket(&w, .{
            .version = version,
            .dcid = client_scid,
            .scid = retry_scid,
            .token = token,
            .integrity_tag = .{0} ** 16,
        }) catch return error.NotAnInitial;
        try w.flush();
        const body_len = w.buffered().len - 16;
        const tag = protection.retryIntegrityTag(
            alloc,
            original_dcid,
            w.buffered()[0..body_len],
        ) catch return error.NotAnInitial;
        @memcpy(self.retry_datagram[body_len..][0..16], &tag);

        self.* = .{
            .expires_nanos = now_nanos + lifetime_nanos,
            .occupied = true,
            .version = version,
            .path = path,
            .original_dcid_len = original_dcid.len,
            .client_scid_len = client_scid.len,
            .retry_scid_len = retry_scid.len,
            .retry_token_len = token.len,
            .retry_datagram_len = w.buffered().len,
        };
        @memcpy(self.original_dcid[0..original_dcid.len], original_dcid);
        @memcpy(self.client_scid[0..client_scid.len], client_scid);
        @memcpy(self.retry_scid[0..retry_scid.len], retry_scid);
        @memcpy(self.retry_token[0..token.len], token);
        return self.retry_datagram[0..self.retry_datagram_len];
    }

    fn tupleMatches(
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
    /// Tokenless Initials reissue the stored Retry only for the exact
    /// stored tuple. Token-bearing follow-ups (`followup_dcid` is the
    /// datagram's destination CID, which must be the issued Retry SCID)
    /// are accepted only when the whole stored exchange matches — path,
    /// version, Retry SCID, client SCID, and the exact stored token
    /// bytes — and the token then validates against `policy` WITHOUT
    /// consuming replay state (the caller consumes it in `commit()` only
    /// after the bounded candidate is authenticated). The returned slice
    /// aliases this slot and stays valid until the next classification.
    pub fn classify(
        self: *PendingRetrySlot,
        policy: *const endpoint.AddressValidationPolicy,
        now_nanos: i64,
        path: endpoint.UdpTuple,
        version: packet.Version,
        original_dcid: []const u8,
        client_scid: []const u8,
        followup_dcid: []const u8,
        token: []const u8,
        datagram_len: usize,
        is_initial: bool,
    ) SlotError!Decision {
        if (datagram_len < 1200) return error.InitialTooShort;
        if (!is_initial) return error.NotAnInitial;

        if (token.len == 0) {
            if (self.expired(now_nanos)) return error.RetryExpired;
            if (self.tupleMatches(path, version, original_dcid, client_scid)) {
                return .{ .send_retry = self.retry_datagram[0..self.retry_datagram_len] };
            }
            return error.UnrelatedInitial;
        }

        // Token-bearing follow-up: the stored exchange must be live and
        // match exactly — Retry SCID (as the follow-up's destination
        // CID), client SCID, and the exact stored token bytes.
        if (self.expired(now_nanos)) return error.UnrelatedInitial;
        if (self.version != version or !self.path.eql(path)) return error.TokenInvalid;
        if (self.retry_scid_len != followup_dcid.len or
            !std.mem.eql(u8, self.retry_scid[0..self.retry_scid_len], followup_dcid)) return error.TokenInvalid;
        if (self.client_scid_len != client_scid.len or
            !std.mem.eql(u8, self.client_scid[0..self.client_scid_len], client_scid)) return error.TokenInvalid;
        if (self.retry_token_len != token.len or
            !std.mem.eql(u8, self.retry_token[0..self.retry_token_len], token)) return error.TokenInvalid;

        _ = policy.validateTokenForPathWithoutReplayForVersion(
            .retry,
            version,
            now_nanos,
            path,
            token,
        ) catch return error.TokenInvalid;
        return .{ .validated = .{
            .retry_scid = self.retry_scid,
            .retry_scid_len = self.retry_scid_len,
        } };
    }

    /// Publish the candidate: consume replay state for exactly the stored
    /// token and clear the slot. `token` must equal the stored token
    /// bytes; any other token (even one that would validate) is refused
    /// and the slot stays intact.
    pub fn commit(
        self: *PendingRetrySlot,
        policy: *endpoint.AddressValidationPolicy,
        now_nanos: i64,
        token: []const u8,
    ) address_validation_token.Error!void {
        if (!self.occupied) return error.InvalidToken;
        if (self.retry_token_len != token.len or
            !std.mem.eql(u8, self.retry_token[0..self.retry_token_len], token)) return error.InvalidToken;
        _ = try policy.validateTokenForPathForVersion(
            .retry,
            self.version,
            now_nanos,
            self.path,
            self.retry_token[0..self.retry_token_len],
        );
        self.occupied = false;
    }
};

test "PendingRetrySlot: reissue, expiry, unrelated drop, exact follow-up" {
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

    const token = try policy.issueTokenForPath(
        alloc,
        .retry,
        1_000,
        10_000_000_000,
        path,
        nonce,
    );
    defer alloc.free(token);

    // An empty slot refuses tokenless Initials (fresh, not reissue) and
    // refuses token-bearing Initials (no stored exchange).
    var slot = PendingRetrySlot{};
    try std.testing.expectError(
        error.RetryExpired,
        slot.classify(&policy, 1_000, path, .v1, &odcid, &scid, &rscid, &.{}, 1200, true),
    );
    try std.testing.expectError(
        error.UnrelatedInitial,
        slot.classify(&policy, 1_000, path, .v1, &odcid, &scid, &rscid, token, 1200, true),
    );

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
    try std.testing.expect(retry.len > 0);
    try std.testing.expect(retry.len <= PendingRetrySlot.max_retry_datagram_len);

    // Matching retransmission reissues the SAME bytes without extending
    // the absolute expiry.
    const first_expiry = slot.expires_nanos;
    const reissued = try slot.classify(&policy, 5_000, path, .v1, &odcid, &scid, &rscid, &.{}, 1200, true);
    switch (reissued) {
        .send_retry => |bytes| try std.testing.expectEqualSlices(u8, retry, bytes),
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(first_expiry, slot.expires_nanos);

    // Unrelated tokenless Initial while occupied is dropped.
    const other_scid = [_]u8{ 0xaa, 0xbb, 0xcc, 0xdd };
    try std.testing.expectError(
        error.UnrelatedInitial,
        slot.classify(&policy, 5_000, path, .v1, &odcid, &other_scid, &rscid, &.{}, 1200, true),
    );

    // Short datagrams are rejected outright.
    try std.testing.expectError(
        error.InitialTooShort,
        slot.classify(&policy, 5_000, path, .v1, &odcid, &scid, &rscid, &.{}, 1199, true),
    );

    // Token-bearing follow-ups must match the exact stored exchange:
    // wrong Retry SCID, wrong client SCID, and different-but-valid token
    // bytes are all refused before policy validation.
    const other_rscid = [_]u8{ 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58 };
    try std.testing.expectError(
        error.TokenInvalid,
        slot.classify(&policy, 6_000, path, .v1, &odcid, &scid, &other_rscid, token, 1200, true),
    );
    try std.testing.expectError(
        error.TokenInvalid,
        slot.classify(&policy, 6_000, path, .v1, &odcid, &other_scid, &rscid, token, 1200, true),
    );
    var mutated = alloc.dupe(u8, token) catch return error.TestUnexpectedResult;
    defer alloc.free(mutated);
    mutated[0] ^= 0xff;
    try std.testing.expectError(
        error.TokenInvalid,
        slot.classify(&policy, 6_000, path, .v1, &odcid, &scid, &rscid, mutated, 1200, true),
    );

    // The exact follow-up validates without consuming replay state.
    for (0..2) |_| {
        const decision = try slot.classify(&policy, 6_000, path, .v1, &odcid, &scid, &rscid, token, 1200, true);
        switch (decision) {
            .validated => |v| try std.testing.expectEqual(rscid.len, v.retry_scid_len),
            else => return error.TestUnexpectedResult,
        }
    }
    try std.testing.expectEqual(@as(usize, 0), policy.replayFilterEntryCount());

    // commit() refuses a different valid token and leaves the slot.
    const other_token = try policy.issueTokenForPath(
        alloc,
        .retry,
        6_000,
        10_000_000_000,
        path,
        nonce,
    );
    defer alloc.free(other_token);
    try std.testing.expectError(
        address_validation_token.Error.InvalidToken,
        slot.commit(&policy, 6_000, other_token),
    );
    try std.testing.expect(slot.occupied);
    try std.testing.expectEqual(@as(usize, 0), policy.replayFilterEntryCount());

    // commit() consumes exactly the stored token and clears the slot.
    try slot.commit(&policy, 6_000, token);
    try std.testing.expectEqual(@as(usize, 1), policy.replayFilterEntryCount());
    try std.testing.expect(!slot.occupied);

    // After expiry the slot treats the next tokenless Initial as fresh.
    _ = try slot.open(alloc, 20_000_000_000_000, 10_000_000_000, path, .v1, &odcid, &scid, &rscid, token);
    try std.testing.expectError(
        error.RetryExpired,
        slot.classify(&policy, 20_000_000_000_000 + 11_000_000_000, path, .v1, &odcid, &scid, &rscid, &.{}, 1200, true),
    );
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
    // Wrong path on the token-bearing follow-up (even with every other
    // field exact): refused.
    try std.testing.expectError(
        error.TokenInvalid,
        slot.classify(&policy, 2_000, other_path, .v1, &odcid, &scid, &rscid, token, 1200, true),
    );
    // The slot remains usable for the original client.
    const reissued = try slot.classify(&policy, 2_000, path, .v1, &odcid, &scid, &rscid, &.{}, 1200, true);
    switch (reissued) {
        .send_retry => {},
        else => return error.TestUnexpectedResult,
    }
}

test "PendingRetrySlot: storedToken across occupied, expired, and post-commit states" {
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

    const now: i64 = 1000;
    const token = try policy.issueTokenForPath(
        alloc,
        .retry,
        now,
        10 * std.time.ns_per_s,
        path,
        nonce,
    );
    defer alloc.free(token);

    var slot = PendingRetrySlot{};
    _ = try slot.open(alloc, now, 10 * std.time.ns_per_s, path, .v1, &odcid, &scid, &rscid, token);

    // Occupied and live: the exact stored bytes are readable.
    const stored = slot.storedToken(now + 1) orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualSlices(u8, token, stored);

    // Expired: null even though `occupied` is still set.
    try std.testing.expect(slot.occupied);
    try std.testing.expect(slot.storedToken(now + 10 * std.time.ns_per_s) == null);

    // Post-commit: null once the exchange is published.
    try slot.commit(&policy, now + 2, token);
    try std.testing.expect(!slot.occupied);
    try std.testing.expect(slot.storedToken(now + 3) == null);
}
