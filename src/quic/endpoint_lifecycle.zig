const std = @import("std");

pub const packet = @import("packet.zig");
pub const frame = @import("frame.zig");
pub const recovery = @import("recovery.zig");
pub const protection = @import("protection.zig");
pub const address_validation_token = @import("address_validation_token.zig");
pub const endpoint = @import("endpoint.zig");
const lifecycle_opts = @import("lifecycle_options.zig");
pub const transport_error = @import("transport_error.zig");
pub const transport_parameters = @import("transport_parameters.zig");
const transport_types = @import("transport_types.zig");
const crypto_types = @import("crypto_types.zig");
const tls_backend_module = @import("tls_backend.zig");
pub const tls13 = @import("../tls/tls13.zig");
pub const tls13_backend = @import("tls13_backend.zig");
comptime {
    // Keep tls13 reachable so its tests run under `zig build test`.
    _ = tls13;
    _ = tls13_backend;
}
const endpoint_types = @import("endpoint_types.zig");
const endpoint_timers = @import("endpoint_timers.zig");
const connection_config = @import("connection_config.zig");
const connection_rules = @import("connection_rules.zig");
const connection_version = @import("connection_version.zig");
const connection_state = @import("connection_state.zig");
const packet_number_space = @import("packet_number_space.zig");
const stream_id_rules = @import("stream_id.zig");
const packet_context = @import("packet_context.zig");
const protocol_limits = @import("protocol_limits.zig");
const buffer = @import("buffer.zig");
const wire_len = @import("wire_len.zig");
const frame_rules = @import("frame_rules.zig");
const frame_payload_module = @import("frame_payload.zig");

pub const Error = transport_types.Error;
pub const ConnectionSide = transport_types.ConnectionSide;
pub const VersionCompatibility = transport_types.VersionCompatibility;
pub const canConvertFirstFlightVersion = transport_types.canConvertFirstFlightVersion;
pub const selectCompatibleVersion = transport_types.selectCompatibleVersion;
pub const ConnectionState = transport_types.ConnectionState;
pub const PeerClose = transport_types.PeerClose;
pub const HandshakeState = transport_types.HandshakeState;
pub const StreamSendState = transport_types.StreamSendState;
pub const StreamReceiveState = transport_types.StreamReceiveState;
pub const StreamState = transport_types.StreamState;
pub const PacketNumberSpace = transport_types.PacketNumberSpace;
pub const LossDetectionTimerKind = transport_types.LossDetectionTimerKind;
pub const LossDetectionTimerDeadline = transport_types.LossDetectionTimerDeadline;
pub const HandshakeTrafficSecrets = crypto_types.HandshakeTrafficSecrets;
pub const ZeroRttTrafficSecrets = crypto_types.ZeroRttTrafficSecrets;
pub const OneRttTrafficSecrets = crypto_types.OneRttTrafficSecrets;
pub const CryptoBackend = crypto_types.CryptoBackend;
pub const CryptoBackendProgress = crypto_types.CryptoBackendProgress;
const PeerTransportParameterDrivePolicy = crypto_types.PeerTransportParameterDrivePolicy;
pub const TlsBackendStatus = tls_backend_module.TlsBackendStatus;
pub const TlsBackendPacketSpace = tls_backend_module.TlsBackendPacketSpace;
pub const TlsBackendReceiveFn = tls_backend_module.TlsBackendReceiveFn;
pub const TlsBackendPullFn = tls_backend_module.TlsBackendPullFn;
pub const TlsBackendSetBytesFn = tls_backend_module.TlsBackendSetBytesFn;
pub const TlsBackendPullBytesFn = tls_backend_module.TlsBackendPullBytesFn;
pub const TlsBackendPullHandshakeSecretsFn = tls_backend_module.TlsBackendPullHandshakeSecretsFn;
pub const TlsBackendPullZeroRttSecretsFn = tls_backend_module.TlsBackendPullZeroRttSecretsFn;
pub const TlsBackendPullOneRttSecretsFn = tls_backend_module.TlsBackendPullOneRttSecretsFn;
pub const TlsBackendHandshakeConfirmedFn = tls_backend_module.TlsBackendHandshakeConfirmedFn;
pub const TlsBackend = tls_backend_module.TlsBackend;
pub const PreferredAddress = connection_config.PreferredAddress;
pub const Config = connection_config.Config;
pub const EndpointLossDetectionTimerDeadline = endpoint_types.EndpointLossDetectionTimerDeadline;
pub const EndpointLossDetectionTimers = endpoint_timers.EndpointLossDetectionTimers;
pub const EndpointConnectionRetireResult = endpoint_types.EndpointConnectionRetireResult;
pub const EndpointVersionNegotiationResult = endpoint_types.EndpointVersionNegotiationResult;
pub const EndpointVersionNegotiationFollowupResult = endpoint_types.EndpointVersionNegotiationFollowupResult;
pub const EndpointVersionNegotiationError = endpoint_types.EndpointVersionNegotiationError;
pub const EndpointProtectedInitialError = endpoint_types.EndpointProtectedInitialError;
pub const EndpointRetryProtectedInitialError = endpoint_types.EndpointRetryProtectedInitialError;
pub const EndpointProtectedDatagramError = endpoint_types.EndpointProtectedDatagramError;
pub const EndpointAddressValidationError = endpoint_types.EndpointAddressValidationError;
pub const EndpointConnectionIdError = endpoint_types.EndpointConnectionIdError;
pub const EndpointIssuedConnectionIdOptions = endpoint_types.EndpointIssuedConnectionIdOptions;
pub const EndpointIssuedConnectionIdResult = endpoint_types.EndpointIssuedConnectionIdResult;
pub const EndpointAcceptedProtectedInitialResult = endpoint_types.EndpointAcceptedProtectedInitialResult;
pub const EndpointProtectedLongDatagramResult = endpoint_types.EndpointProtectedLongDatagramResult;
pub const EndpointRoutedCryptoBackendDriveProtectedLongDatagramResult = endpoint_types.EndpointRoutedCryptoBackendDriveProtectedLongDatagramResult;
pub const EndpointRoutedCryptoBackendDriveProtectedLongDatagramDrainResult = endpoint_types.EndpointRoutedCryptoBackendDriveProtectedLongDatagramDrainResult;
pub const EndpointRoutedCryptoBackendDriveDatagramResult = endpoint_types.EndpointRoutedCryptoBackendDriveDatagramResult;
pub const EndpointRoutedCryptoBackendDriveDatagramDrainResult = endpoint_types.EndpointRoutedCryptoBackendDriveDatagramDrainResult;
pub const EndpointRoutedCryptoBackendDriveNextDeadlineResult = endpoint_types.EndpointRoutedCryptoBackendDriveNextDeadlineResult;
pub const EndpointRoutedDatagramResult = endpoint_types.EndpointRoutedDatagramResult;
pub const EndpointRoutedDatagramDrainResult = endpoint_types.EndpointRoutedDatagramDrainResult;
pub const EndpointRoutedNextDeadlineResult = endpoint_types.EndpointRoutedNextDeadlineResult;
pub const EndpointPathValidatedShortDatagramResult = endpoint_types.EndpointPathValidatedShortDatagramResult;
pub const EndpointProtectedShortRecoveryPollResult = endpoint_types.EndpointProtectedShortRecoveryPollResult;
pub const EndpointProtectedLongRecoveryPollResult = endpoint_types.EndpointProtectedLongRecoveryPollResult;
pub const EndpointConnectionDeadlineKind = endpoint_types.EndpointConnectionDeadlineKind;
pub const EndpointConnectionDeadline = endpoint_types.EndpointConnectionDeadline;
pub const EndpointInstalledKeyDatagramSpace = endpoint_types.EndpointInstalledKeyDatagramSpace;
pub const EndpointPollInstalledKeyDatagramOptions = endpoint_types.EndpointPollInstalledKeyDatagramOptions;
pub const EndpointFeedInstalledKeyDatagramOptions = endpoint_types.EndpointFeedInstalledKeyDatagramOptions;
pub const EndpointPendingWorkResult = endpoint_types.EndpointPendingWorkResult;
pub const EndpointPendingWorkDatagramResult = endpoint_types.EndpointPendingWorkDatagramResult;
pub const EndpointPendingWorkDatagramDrainResult = endpoint_types.EndpointPendingWorkDatagramDrainResult;
pub const EndpointPendingWorkSweepResult = endpoint_types.EndpointPendingWorkSweepResult;
pub const EndpointPendingWorkNextDeadlineResult = endpoint_types.EndpointPendingWorkNextDeadlineResult;
pub const EndpointPendingWorkSweepDatagramResult = endpoint_types.EndpointPendingWorkSweepDatagramResult;
pub const EndpointPendingWorkSweepDatagramDrainResult = endpoint_types.EndpointPendingWorkSweepDatagramDrainResult;
pub const EndpointPendingWorkCryptoBackendDatagramResult = endpoint_types.EndpointPendingWorkCryptoBackendDatagramResult;
pub const EndpointPendingWorkCryptoBackendDatagramDrainResult = endpoint_types.EndpointPendingWorkCryptoBackendDatagramDrainResult;
pub const EndpointPendingWorkCryptoBackendNextDeadlineResult = endpoint_types.EndpointPendingWorkCryptoBackendNextDeadlineResult;
pub const EndpointCryptoBackendDriveSweepResult = endpoint_types.EndpointCryptoBackendDriveSweepResult;
pub const EndpointCryptoBackendDriveNextDeadlineResult = endpoint_types.EndpointCryptoBackendDriveNextDeadlineResult;
pub const EndpointCryptoBackendDriveDatagramResult = endpoint_types.EndpointCryptoBackendDriveDatagramResult;
pub const EndpointCryptoBackendDriveDatagramDrainResult = endpoint_types.EndpointCryptoBackendDriveDatagramDrainResult;
pub const EndpointCryptoBackendDriveProtectedLongDatagramResult = endpoint_types.EndpointCryptoBackendDriveProtectedLongDatagramResult;
pub const EndpointCryptoBackendDriveProtectedLongDatagramDrainResult = endpoint_types.EndpointCryptoBackendDriveProtectedLongDatagramDrainResult;
pub const EndpointPolledDatagramResult = endpoint_types.EndpointPolledDatagramResult;
pub const EndpointDatagramDrainResult = endpoint_types.EndpointDatagramDrainResult;
pub const EndpointDueWorkDatagramResult = endpoint_types.EndpointDueWorkDatagramResult;
pub const EndpointDueWorkDatagramDrainResult = endpoint_types.EndpointDueWorkDatagramDrainResult;
pub const EndpointDueWorkNextDeadlineResult = endpoint_types.EndpointDueWorkNextDeadlineResult;
pub const EndpointDueWorkCryptoBackendNextDeadlineResult = endpoint_types.EndpointDueWorkCryptoBackendNextDeadlineResult;
pub const EndpointDueWorkCryptoBackendDatagramResult = endpoint_types.EndpointDueWorkCryptoBackendDatagramResult;
pub const EndpointDueWorkCryptoBackendDatagramDrainResult = endpoint_types.EndpointDueWorkCryptoBackendDatagramDrainResult;
pub const EndpointFeedInstalledKeyDatagramResult = endpoint_types.EndpointFeedInstalledKeyDatagramResult;
pub const EndpointFeedInstalledKeyPathUpdateResult = endpoint_types.EndpointFeedInstalledKeyPathUpdateResult;
pub const EndpointFeedPathUpdateDatagramPollResult = endpoint_types.EndpointFeedPathUpdateDatagramPollResult;
pub const EndpointFeedInstalledKeyDatagramNextDeadlineResult = endpoint_types.EndpointFeedInstalledKeyDatagramNextDeadlineResult;
pub const EndpointFeedPendingWorkNextDeadlineResult = endpoint_types.EndpointFeedPendingWorkNextDeadlineResult;
pub const EndpointFeedPendingWorkDatagramPollResult = endpoint_types.EndpointFeedPendingWorkDatagramPollResult;
pub const EndpointFeedPendingWorkDatagramDrainResult = endpoint_types.EndpointFeedPendingWorkDatagramDrainResult;
pub const EndpointFeedPendingWorkCryptoBackendNextDeadlineResult = endpoint_types.EndpointFeedPendingWorkCryptoBackendNextDeadlineResult;
pub const EndpointFeedPendingWorkCryptoBackendDatagramResult = endpoint_types.EndpointFeedPendingWorkCryptoBackendDatagramResult;
pub const EndpointFeedPendingWorkCryptoBackendDatagramDrainResult = endpoint_types.EndpointFeedPendingWorkCryptoBackendDatagramDrainResult;
pub const EndpointFeedInstalledKeyDatagramPollResult = endpoint_types.EndpointFeedInstalledKeyDatagramPollResult;
pub const EndpointFeedInstalledKeyDatagramDrainResult = endpoint_types.EndpointFeedInstalledKeyDatagramDrainResult;
pub const EndpointFeedCryptoBackendDriveNextDeadlineResult = endpoint_types.EndpointFeedCryptoBackendDriveNextDeadlineResult;
pub const EndpointFeedCryptoBackendDriveDatagramResult = endpoint_types.EndpointFeedCryptoBackendDriveDatagramResult;
pub const EndpointFeedCryptoBackendDriveDatagramDrainResult = endpoint_types.EndpointFeedCryptoBackendDriveDatagramDrainResult;
pub const EndpointAcceptedProtectedInitialResponseResult = endpoint_types.EndpointAcceptedProtectedInitialResponseResult;
pub const EndpointAcceptedInitialCryptoBackendNextDeadlineResult = endpoint_types.EndpointAcceptedInitialCryptoBackendNextDeadlineResult;
pub const EndpointAcceptedInitialCryptoBackendDatagramResult = endpoint_types.EndpointAcceptedInitialCryptoBackendDatagramResult;
pub const EndpointAcceptedInitialCryptoBackendDatagramDrainResult = endpoint_types.EndpointAcceptedInitialCryptoBackendDatagramDrainResult;
pub const EndpointRetryProtectedInitialResult = endpoint_types.EndpointRetryProtectedInitialResult;
pub const EndpointAddressValidationResult = endpoint_types.EndpointAddressValidationResult;
pub const FramePacketType = packet_context.FramePacketType;
pub const ProtectedLongDatagramKeys = packet_context.ProtectedLongDatagramKeys;
pub const EcnCodepoint = packet_context.EcnCodepoint;
pub const EcnValidationState = packet_context.EcnValidationState;

pub const AckElicitingSendAdmission = connection_rules.AckElicitingSendAdmission;

test {
    _ = protection;
    _ = address_validation_token;
    _ = endpoint;
    _ = transport_error;
    _ = transport_parameters;
    _ = transport_types;
    _ = crypto_types;
    _ = tls_backend_module;
    _ = endpoint_types;
    _ = endpoint_timers;
    _ = connection_config;
    _ = connection_rules;
    _ = connection_version;
    _ = connection_state;
    _ = packet_number_space;
    _ = stream_id_rules;
    _ = wire_len;
    _ = frame_rules;
    _ = frame_payload_module;
}

test "frame payload helper exposes raw frame type value" {
    try std.testing.expectEqual(@as(u64, 0x1c), frame_payload_module.rawFrameTypeValue(&.{0x1c}));
}

test "frame payload helper classifies packet type close error" {
    const invalid_zero_rtt_ack = [_]u8{ 0x02, 0, 0, 0, 0 };
    const close = (try frame_payload_module.classifyCloseError(
        .zero_rtt,
        &invalid_zero_rtt_ack,
        std.testing.allocator,
    )).?;
    try std.testing.expectEqual(transport_error.TransportErrorCode.protocol_violation, close.code);
    try std.testing.expectEqual(@as(u64, 0x02), close.frame_type);
    try std.testing.expectEqualStrings("packet type", close.reason_phrase);
}

const max_quic_varint = protocol_limits.max_quic_varint;
const max_stream_count = protocol_limits.max_stream_count;
const max_connection_id_len = protocol_limits.max_connection_id_len;
const min_initial_destination_connection_id_len = protocol_limits.min_initial_destination_connection_id_len;
const min_initial_udp_datagram_len = protocol_limits.min_initial_udp_datagram_len;
const min_active_connection_id_limit = protocol_limits.min_active_connection_id_limit;
const close_state_pto_multiplier = protocol_limits.close_state_pto_multiplier;
const max_path_challenge_transmissions = protocol_limits.max_path_challenge_transmissions;
const packet_threshold_loss_gap = protocol_limits.packet_threshold_loss_gap;
const anti_amplification_multiplier = protocol_limits.anti_amplification_multiplier;

const EcnAckValidationResult = connection_state.EcnAckValidationResult;
const PendingStreamFrame = connection_state.PendingStreamFrame;
const PendingCryptoFrame = connection_state.PendingCryptoFrame;
const PendingRecvStreamFrame = connection_state.PendingRecvStreamFrame;
const PendingBlockedFrame = connection_state.PendingBlockedFrame;
const PendingMaxFrame = connection_state.PendingMaxFrame;
const PendingCloseFrame = connection_state.PendingCloseFrame;
const PeerCloseSnapshot = connection_state.PeerCloseSnapshot;
const PendingPathChallenge = connection_state.PendingPathChallenge;
const OutstandingPathChallenge = connection_state.OutstandingPathChallenge;
const SentPacket = connection_state.SentPacket;
const RttEstimateSnapshot = connection_state.RttEstimateSnapshot;
const PtoBackoffSnapshot = connection_state.PtoBackoffSnapshot;
const PacketNumberSpaceState = packet_number_space.State;
const PacketNumberSpaceView = packet_number_space.View;
const ActiveConnectionId = connection_state.ActiveConnectionId;
const ActiveConnectionIdSnapshot = connection_state.ActiveConnectionIdSnapshot;
const LocalConnectionId = connection_state.LocalConnectionId;
const LocalConnectionIdSnapshot = connection_state.LocalConnectionIdSnapshot;
const deinitPendingStreamFrameSlice = connection_state.deinitPendingStreamFrameSlice;
const deinitPendingCryptoFrameSlice = connection_state.deinitPendingCryptoFrameSlice;
const deinitSentPacketSlice = connection_state.deinitSentPacketSlice;
const clearSentPacketList = connection_state.clearSentPacketList;
const deinitSentPacketList = connection_state.deinitSentPacketList;
const deinitPendingCloseFrame = connection_state.deinitPendingCloseFrame;
const quicVarIntWireLen = wire_len.quicVarIntWireLen;
const protectedLongDatagramWireLen = wire_len.protectedLongDatagramWireLen;
const protectedLongPlaintextLenForMinDatagram = wire_len.protectedLongPlaintextLenForMinDatagram;
const protectedShortDatagramWireLen = wire_len.protectedShortDatagramWireLen;
const protectedShortPlaintextLenForMinDatagram = wire_len.protectedShortPlaintextLenForMinDatagram;
const addWireLen = wire_len.addWireLen;
const streamFrameWireLen = wire_len.streamFrameWireLen;
const cryptoFrameWireLen = wire_len.cryptoFrameWireLen;
const maxStreamFrameDataLen = wire_len.maxStreamFrameDataLen;
const maxCryptoFrameDataLen = wire_len.maxCryptoFrameDataLen;
const ackFrameWireLen = wire_len.ackFrameWireLen;
const pathResponseFrameWireLen = wire_len.pathResponseFrameWireLen;
const pathChallengeFrameWireLen = wire_len.pathChallengeFrameWireLen;
const pingFrameWireLen = wire_len.pingFrameWireLen;
const resetStreamFrameWireLen = wire_len.resetStreamFrameWireLen;
const stopSendingFrameWireLen = wire_len.stopSendingFrameWireLen;
const retireConnectionIdFrameWireLen = wire_len.retireConnectionIdFrameWireLen;
const newConnectionIdFrameWireLen = wire_len.newConnectionIdFrameWireLen;
const newTokenFrameWireLen = wire_len.newTokenFrameWireLen;
const handshakeDoneFrameWireLen = wire_len.handshakeDoneFrameWireLen;
const closeReasonLenWireLen = wire_len.closeReasonLenWireLen;
const connectionCloseFrameWireLen = wire_len.connectionCloseFrameWireLen;
const applicationCloseFrameWireLen = wire_len.applicationCloseFrameWireLen;
const closeFrameWireLen = wire_len.closeFrameWireLen;
const blockedFrameWireLen = wire_len.blockedFrameWireLen;
const maxFrameWireLen = wire_len.maxFrameWireLen;
const ackFrameRangesAreValid = frame_rules.ackFrameRangesAreValid;
const ackFrameContains = frame_rules.ackFrameContains;
const frameIsAckEliciting = frame_rules.frameIsAckEliciting;
const frameAllowedInPacketNumberSpace = frame_rules.frameAllowedInPacketNumberSpace;
const defaultFramePacketTypeForSpace = frame_rules.defaultFramePacketTypeForSpace;
const packetNumberSpaceForFramePacketType = frame_rules.packetNumberSpaceForFramePacketType;
const frameAllowedInFramePacketType = frame_rules.frameAllowedInFramePacketType;
const zeroEcnCounts = packet_number_space.zeroEcnCounts;
const protectedLongDatagramKeysForSpace = packet_context.protectedLongDatagramKeysForSpace;
const streamEndOffset = stream_id_rules.endOffset;
const streamRangesOverlap = stream_id_rules.rangesOverlap;
const isBidirectionalStream = stream_id_rules.isBidirectional;
const isLocalStreamInitiator = stream_id_rules.isLocalInitiator;
const isLocalBidirectionalStream = stream_id_rules.isLocalBidirectional;
const isLocalUnidirectionalStream = stream_id_rules.isLocalUnidirectional;
const streamCountForId = stream_id_rules.countForId;

const PeerTransportParameterValidationError = connection_rules.PeerTransportParameterValidationError;
const peerTransportParameterValidationErrorAsPublic = connection_rules.peerTransportParameterValidationErrorAsPublic;
const statelessResetTokensEqual = connection_rules.statelessResetTokensEqual;

const Connection = @import("../lib.zig").Connection;
const EndpointConnectionView = @import("../lib.zig").EndpointConnectionView;
const EndpointConnectionPollView = @import("../lib.zig").EndpointConnectionPollView;
const EndpointConnectionInstalledKeyPollView = @import("../lib.zig").EndpointConnectionInstalledKeyPollView;
const EndpointConnectionReceiveView = @import("../lib.zig").EndpointConnectionReceiveView;
const EndpointCryptoBackendDriveView = @import("../lib.zig").EndpointCryptoBackendDriveView;
const EndpointVersionNegotiationHandoffResult = @import("../lib.zig").EndpointVersionNegotiationHandoffResult;
const EndpointVersionNegotiationProtectedInitialResult = @import("../lib.zig").EndpointVersionNegotiationProtectedInitialResult;

fn endpointEcnPathState(state: EcnValidationState) endpoint.EcnPathValidationState {
    return switch (state) {
        .unknown => .unknown,
        .capable => .capable,
        .failed => .failed,
    };
}

pub const EndpointConnectionLifecycle = struct {
    /// Destination-CID router owned by this endpoint lifecycle.
    router: endpoint.EndpointRouter,
    /// Aggregate loss/PTO timers keyed by caller-owned connection handle.
    recovery_timers: EndpointLossDetectionTimers,
    /// Per-UDP-path ECN validation state owned by this endpoint lifecycle.
    ecn_paths: endpoint.EcnPathPolicy,

    /// Create an endpoint lifecycle owner with empty routes and timers.
    pub fn init(allocator: std.mem.Allocator) EndpointConnectionLifecycle {
        return initWithRouterOptions(allocator, .{});
    }

    /// Create an endpoint lifecycle owner with explicit router resource limits.
    ///
    /// The caller still owns connection storage and decides admission policy;
    /// these limits bound the lifecycle-owned route and stateless-reset tables.
    pub fn initWithRouterOptions(
        allocator: std.mem.Allocator,
        router_options: endpoint.EndpointRouterOptions,
    ) EndpointConnectionLifecycle {
        return .{
            .router = endpoint.EndpointRouter.initWithOptions(allocator, router_options),
            .recovery_timers = EndpointLossDetectionTimers.init(allocator),
            .ecn_paths = endpoint.EcnPathPolicy.init(allocator),
        };
    }

    /// Release route and timer storage owned by this endpoint lifecycle.
    pub fn deinit(self: *EndpointConnectionLifecycle) void {
        self.ecn_paths.deinit();
        self.recovery_timers.deinit();
        self.router.deinit();
    }

    /// Return the number of active destination-CID routes.
    pub fn routeCount(self: *const EndpointConnectionLifecycle) usize {
        return self.router.routeCount();
    }

    /// Return the number of destination CIDs with retained stateless reset tokens.
    pub fn statelessResetTokenCount(self: *const EndpointConnectionLifecycle) usize {
        return self.router.statelessResetTokenCount();
    }

    /// Return the number of armed recovery timers.
    pub fn recoveryTimerCount(self: *const EndpointConnectionLifecycle) usize {
        return self.recovery_timers.count();
    }

    /// Return the stored ECN validation state for one connection path.
    pub fn ecnPathState(
        self: *const EndpointConnectionLifecycle,
        connection_id: u64,
        path: endpoint.Udp4Tuple,
    ) endpoint.EcnPathValidationState {
        return self.ecn_paths.stateForConnectionPath(connection_id, path);
    }

    /// Return whether endpoint packetization may set ECT on one connection path.
    pub fn mayUseEctOnPath(
        self: *const EndpointConnectionLifecycle,
        connection_id: u64,
        path: endpoint.Udp4Tuple,
    ) bool {
        return self.ecn_paths.mayUseEctOnConnectionPath(connection_id, path);
    }

    /// Mirror a connection packet-space ECN result onto one UDP path.
    ///
    /// `Connection` validates ACK_ECN counters in packet-number space
    /// state. The endpoint lifecycle stores that result under the concrete UDP
    /// tuple so migration starts from an independent ECN validation state.
    pub fn refreshEcnPathStateFromConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        path: endpoint.Udp4Tuple,
        connection: *const Connection,
        space: PacketNumberSpace,
    ) endpoint.RouteError!endpoint.EcnPathValidationState {
        const state = endpointEcnPathState(connection.ecnValidationState(space));
        try self.ecn_paths.setStateForConnectionPath(connection_id, path, state);
        return state;
    }

    /// Validate an endpoint-issued address token and unblock one server connection.
    ///
    /// The address token is authenticated and replay-recorded by endpoint
    /// policy. Only after that succeeds does this helper mark the caller-owned
    /// server connection's peer address as validated and refresh the endpoint's
    /// recovery timer snapshot for that connection handle.
    pub fn validateAddressTokenForPathAndArmConnection(
        self: *EndpointConnectionLifecycle,
        policy: *endpoint.AddressValidationPolicy,
        connection_id: u64,
        connection: *Connection,
        expected_kind: address_validation_token.Kind,
        expected_originating_version: packet.Version,
        now_nanos: i64,
        path: endpoint.Udp4Tuple,
        token: []const u8,
    ) EndpointAddressValidationError!EndpointAddressValidationResult {
        if (connection.side != .server) return error.InvalidPacket;
        if (connection.connectionState() != .active) {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return error.ConnectionClosed;
        }

        const validation = try policy.validateTokenForPathForVersion(
            expected_kind,
            expected_originating_version,
            now_nanos,
            path,
            token,
        );
        try connection.validatePeerAddress();
        try self.armRecoveryTimerFromConnection(connection_id, connection);

        return .{
            .validation = validation,
            .recovery_timer = connection.lossDetectionTimerDeadline(),
        };
    }

    /// Validate and consume an endpoint-issued Retry token for one server connection.
    ///
    /// The helper first proves that the connection is still waiting for this
    /// one-time Retry token, then authenticates and replay-records the
    /// endpoint path token. Only after both checks succeed does it consume the
    /// connection token, unblock anti-amplification, and refresh endpoint
    /// recovery scheduling.
    pub fn validateRetryTokenForPathAndArmConnection(
        self: *EndpointConnectionLifecycle,
        policy: *endpoint.AddressValidationPolicy,
        connection_id: u64,
        connection: *Connection,
        expected_originating_version: packet.Version,
        now_nanos: i64,
        path: endpoint.Udp4Tuple,
        token: []const u8,
    ) EndpointAddressValidationError!EndpointAddressValidationResult {
        if (connection.side != .server) return error.InvalidPacket;
        if (connection.connectionState() != .active) {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return error.ConnectionClosed;
        }
        if (!connection.hasPendingRetryToken(token)) return error.InvalidPacket;

        _ = try policy.validateTokenForPathWithoutReplayForVersion(
            .retry,
            expected_originating_version,
            now_nanos,
            path,
            token,
        );
        const validation = try policy.validateTokenForPathForVersion(
            .retry,
            expected_originating_version,
            now_nanos,
            path,
            token,
        );
        try connection.validateRetryToken(token);
        try self.armRecoveryTimerFromConnection(connection_id, connection);

        return .{
            .validation = validation,
            .recovery_timer = connection.lossDetectionTimerDeadline(),
        };
    }

    /// Register a destination connection ID for a caller-owned connection.
    pub fn registerConnectionId(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        destination_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        options: endpoint.RouteOptions,
    ) endpoint.RouteError!void {
        return self.router.registerConnectionId(connection_id, destination_connection_id, path, options);
    }

    /// Retire a destination CID route on a specific UDP tuple.
    ///
    /// This keeps zero-length CID route retirement on the lifecycle owner,
    /// where the tuple is required to disambiguate otherwise identical empty
    /// destination CIDs.
    pub fn retireConnectionIdOnPath(
        self: *EndpointConnectionLifecycle,
        destination_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
    ) endpoint.RouteError!bool {
        return self.router.retireConnectionIdOnPath(destination_connection_id, path);
    }

    /// Register the client Initial Source CID on the lifecycle-owned router.
    ///
    /// This keeps client-side Initial response routing on the same endpoint
    /// state owner used for later protected datagram delivery and recovery
    /// timer scheduling.
    pub fn registerClientInitialSourceConnectionId(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        client_source_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        options: endpoint.ClientInitialRouteOptions,
    ) endpoint.RouteError!endpoint.RouteResult {
        return self.router.registerClientInitialSourceConnectionId(connection_id, client_source_connection_id, path, options);
    }

    /// Register server routes after accepting a client Initial.
    ///
    /// The accepted Original DCID and server Source CID remain owned by the
    /// endpoint lifecycle so Initial retransmissions and follow-up short-header
    /// packets use one route owner.
    pub fn registerAcceptedInitialConnectionIds(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
    ) endpoint.RouteError!endpoint.AcceptedInitialRouteResult {
        return self.router.registerAcceptedInitialConnectionIds(connection_id, initial_accept, server_source_connection_id, options);
    }

    /// Process one accepted client Initial and install server endpoint routes.
    ///
    /// `initial_accept` must come from `handleDatagramWithVersionNegotiation()`
    /// for the same datagram. The connection validates and decrypts the
    /// protected Initial before endpoint routes are installed, so malformed
    /// Initial packets do not leave active routes behind. After successful
    /// packet processing, the lifecycle owner records the received UDP datagram
    /// length for the modeled server anti-amplification budget, services any
    /// recovery timer that expired while the server was blocked, registers the
    /// Original DCID and server Source CID routes, then mirrors the connection
    /// recovery timer. TLS transcript ownership and address-token policy remain
    /// caller-owned.
    pub fn processAcceptedProtectedInitialDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
    ) EndpointProtectedInitialError!EndpointAcceptedProtectedInitialResult {
        const initial_secrets = protection.deriveInitialSecrets(
            initial_accept.version,
            initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;

        const processed_packets = connection.processProtectedLongDatagram(
            now_nanos,
            .{ .initial = initial_secrets.client },
            datagram,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        _ = connection.recordPeerAddressDatagramReceived(now_nanos, datagram.len) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        const accepted_routes = try self.registerAcceptedInitialConnectionIds(
            connection_id,
            initial_accept,
            server_source_connection_id,
            options,
        );
        try self.armRecoveryTimerFromConnection(connection_id, connection);

        return .{
            .initial_accept = initial_accept,
            .accepted_routes = accepted_routes,
            .processed_packets = processed_packets,
        };
    }

    /// Process one accepted client Initial and emit a protected server Initial.
    ///
    /// This is the lifecycle-owned server-side Initial response bridge for
    /// socket loops that still use caller-derived Initial keys. The incoming
    /// protected Initial is authenticated and processed before routes are
    /// installed. Only then does the helper queue caller-provided server
    /// Initial CRYPTO bytes, emit one protected server Initial datagram, and
    /// mirror the connection recovery timer. TLS transcript ownership remains
    /// caller-owned; this helper only coordinates packet/routing lifecycle.
    pub fn processAcceptedProtectedInitialResponseDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        response_crypto: []const u8,
    ) EndpointProtectedInitialError!EndpointAcceptedProtectedInitialResponseResult {
        if (response_crypto.len == 0) return error.InvalidPacket;

        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );

        try connection.sendCryptoInSpace(.initial, response_crypto);
        const initial_secrets = protection.deriveInitialSecrets(
            accepted_initial.initial_accept.version,
            accepted_initial.initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const response_datagram = (try self.pollProtectedLongCryptoDatagramInSpace(
            connection_id,
            connection,
            .initial,
            now_nanos,
            accepted_initial.initial_accept.source_connection_id,
            server_source_connection_id,
            &[_]u8{},
            initial_secrets.server,
        )) orelse return error.Internal;

        return .{
            .accepted_initial = accepted_initial,
            .response_datagram = response_datagram,
        };
    }

    /// Process one accepted client Initial, drive Initial TLS, and emit response.
    ///
    /// This is the TLS-backend form of
    /// `processAcceptedProtectedInitialResponseDatagram()`. The lifecycle
    /// authenticates the client Initial, installs server endpoint routes,
    /// delivers received Initial CRYPTO into `backend`, queues backend-produced
    /// Initial CRYPTO, and emits at most one protected server Initial datagram.
    /// Connection/backend/socket storage remains caller-owned.
    pub fn processAcceptedProtectedInitialWithCryptoBackendAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendDatagramResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const backend_progress = try self.driveCryptoBackendInSpaceAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        );
        const initial_secrets = protection.deriveInitialSecrets(
            accepted_initial.initial_accept.version,
            accepted_initial.initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .response_datagram = try self.pollProtectedLongCryptoDatagramInSpace(
                connection_id,
                connection,
                .initial,
                now_nanos,
                accepted_initial.initial_accept.source_connection_id,
                server_source_connection_id,
                &[_]u8{},
                initial_secrets.server,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one accepted client Initial, drive Initial TLS, and select a deadline.
    ///
    /// This no-output form is for socket loops that want to authenticate and
    /// route the accepted Initial, deliver received CRYPTO into the backend,
    /// queue backend-produced Initial CRYPTO, and update their next wakeup
    /// without immediately polling protected output.
    pub fn processAcceptedProtectedInitialWithCryptoBackendAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendNextDeadlineResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const backend_progress = try self.driveCryptoBackendInSpaceAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        );
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one accepted client Initial, drive Initial TLS, and drain output.
    ///
    /// This bounded-output form lets socket loops cap the number of protected
    /// server Initial datagrams emitted after backend progress. It preserves
    /// caller ownership of connection/backend/socket storage and each returned
    /// datagram.
    pub fn processAcceptedProtectedInitialWithCryptoBackendAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendDatagramDrainResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const backend_progress = try self.driveCryptoBackendInSpaceAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        );
        const initial_secrets = protection.deriveInitialSecrets(
            accepted_initial.initial_accept.version,
            accepted_initial.initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .drain = self.drainProtectedLongCryptoDatagramsInSpace(
                connection_id,
                connection,
                .initial,
                now_nanos,
                accepted_initial.initial_accept.source_connection_id,
                server_source_connection_id,
                &[_]u8{},
                initial_secrets.server,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one accepted Initial through a close-propagating TLS backend.
    ///
    /// This preserves the success behavior of
    /// `processAcceptedProtectedInitialWithCryptoBackendAndPollDatagram()`, but
    /// peer transport-parameter errors returned by `backend` queue
    /// `CONNECTION_CLOSE` through
    /// `driveCryptoBackendInSpaceOrCloseAndArmConnection()` and poll that
    /// protected Initial close instead of polling ordinary backend CRYPTO
    /// output.
    pub fn processAcceptedProtectedInitialWithCryptoBackendOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendDatagramResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const initial_secrets = protection.deriveInitialSecrets(
            accepted_initial.initial_accept.version,
            accepted_initial.initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const closing_before = connection.connectionState() == .closing;
        const backend_progress = self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing or closing_before) return err;
            return .{
                .accepted_initial = accepted_initial,
                .backend = .{},
                .response_datagram = try self.pollProtectedLongDatagram(
                    connection_id,
                    connection,
                    now_nanos,
                    accepted_initial.initial_accept.source_connection_id,
                    server_source_connection_id,
                    &[_]u8{},
                    .{ .initial = initial_secrets.server },
                ),
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .response_datagram = try self.pollProtectedLongCryptoDatagramInSpace(
                connection_id,
                connection,
                .initial,
                now_nanos,
                accepted_initial.initial_accept.source_connection_id,
                server_source_connection_id,
                &[_]u8{},
                initial_secrets.server,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one accepted Initial through close propagation and select a deadline.
    ///
    /// This is the no-output form of
    /// `processAcceptedProtectedInitialWithCryptoBackendOrCloseAndPollDatagram()`.
    /// Peer transport-parameter errors queue CONNECTION_CLOSE through the
    /// close-propagating backend path and return the current deadline selection
    /// without polling backend output.
    pub fn processAcceptedProtectedInitialWithCryptoBackendOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendNextDeadlineResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const closing_before = connection.connectionState() == .closing;
        const backend_progress = self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing or closing_before) return err;
            return .{
                .accepted_initial = accepted_initial,
                .backend = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one accepted Initial through a close-propagating TLS backend and drain output.
    ///
    /// This bounded-output form preserves the success behavior of
    /// `processAcceptedProtectedInitialWithCryptoBackendAndDrainDatagrams()`,
    /// while using the close-propagating backend path. Peer
    /// transport-parameter errors queue CONNECTION_CLOSE and drain that
    /// protected Initial close instead of draining ordinary backend CRYPTO
    /// output.
    pub fn processAcceptedProtectedInitialWithCryptoBackendOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        initial_accept: endpoint.InitialAcceptResult,
        server_source_connection_id: []const u8,
        datagram: []const u8,
        options: endpoint.AcceptedInitialRouteOptions,
        backend: CryptoBackend,
        scratch: []u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedInitialError!EndpointAcceptedInitialCryptoBackendDatagramDrainResult {
        const accepted_initial = try self.processAcceptedProtectedInitialDatagram(
            connection_id,
            connection,
            now_nanos,
            initial_accept,
            server_source_connection_id,
            datagram,
            options,
        );
        const initial_secrets = protection.deriveInitialSecrets(
            accepted_initial.initial_accept.version,
            accepted_initial.initial_accept.original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const closing_before = connection.connectionState() == .closing;
        const backend_progress = self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
            connection_id,
            connection,
            .initial,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing or closing_before) return err;
            if (out.len == 0) return error.BufferTooSmall;
            return .{
                .accepted_initial = accepted_initial,
                .backend = .{},
                .drain = self.drainProtectedLongDatagrams(
                    connection_id,
                    connection,
                    now_nanos,
                    accepted_initial.initial_accept.source_connection_id,
                    server_source_connection_id,
                    &[_]u8{},
                    .{ .initial = initial_secrets.server },
                    out,
                ),
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        return .{
            .accepted_initial = accepted_initial,
            .backend = backend_progress,
            .drain = self.drainProtectedLongCryptoDatagramsInSpace(
                connection_id,
                connection,
                .initial,
                now_nanos,
                accepted_initial.initial_accept.source_connection_id,
                server_source_connection_id,
                &[_]u8{},
                initial_secrets.server,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Replace an Initial route's DCID with the Retry Source CID.
    ///
    /// This is the lifecycle-owned endpoint route switch after server Retry.
    /// The connection still owns Retry integrity and token validation; the
    /// endpoint lifecycle owns the route mutation used by the follow-up Initial.
    /// Unified accepted Initial processing with options-struct interface.
    /// Replaces 8 processAcceptedProtectedInitial variants.
    /// Unified across-connections feed with options-struct interface.
    /// Replaces 5+ feedDatagramWithInstalledKeysAcrossConnections variants.
    /// Unified Handshake poll with options-struct interface.
    /// Replaces 4+ pollProtectedHandshakeDatagramWithInstalledKeys variants.
    /// unified short poll with options-struct interface.
    /// Replaces 4+ pollProtectedShortDatagramWithInstalledKeys variants.
    pub fn switchInitialDestinationConnectionIdAfterRetry(
        self: *EndpointConnectionLifecycle,
        original_destination_connection_id: []const u8,
        retry_source_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
    ) endpoint.RouteError!endpoint.RouteResult {
        return self.router.switchInitialDestinationConnectionIdAfterRetry(
            original_destination_connection_id,
            retry_source_connection_id,
            path,
        );
    }

    /// Commit a caller-validated migration to a server preferred address.
    ///
    /// The connection still owns preferred-address transport-parameter
    /// validation and path validation. The lifecycle owner commits the route
    /// replacement and retained reset-token state used by the socket event
    /// loop after validation succeeds.
    /// Unified feed with crypto backend drive — replaces 20+ AndDriveCryptoBackend variants.
    /// Unified routed Handshake with crypto backend — replaces 10+ variants.
    /// Unified routed short with crypto backend — replaces 10+ variants.
    /// Unified due deadline with crypto backend — replaces 10+ variants.
    /// Unified pending work with crypto backend — replaces 10+ variants.
    pub fn commitPreferredAddressMigration(
        self: *EndpointConnectionLifecycle,
        current_destination_connection_id: []const u8,
        current_path: endpoint.Udp4Tuple,
        preferred_destination_connection_id: []const u8,
        preferred_path: endpoint.Udp4Tuple,
        preferred_stateless_reset_token: [packet.stateless_reset_token_len]u8,
    ) endpoint.RouteError!endpoint.RouteResult {
        return self.router.commitPreferredAddressMigration(
            current_destination_connection_id,
            current_path,
            preferred_destination_connection_id,
            preferred_path,
            preferred_stateless_reset_token,
        );
    }

    /// Register a replacement destination CID and retire older sequence routes.
    ///
    /// This is the lifecycle-owned endpoint route update for
    /// NEW_CONNECTION_ID-style replacement policy. The connection still owns
    /// issuing and validating CID sequence numbers; the lifecycle owner commits
    /// the resulting endpoint route and retained reset-token state.
    /// Unified drain across connections with options-struct interface.
    /// Replaces 5+ drainDatagramsAcrossConnectionsWithInstalledKeyOptions variants.
    /// Unified due deadline with installed key options.
    /// Replaces 5+ processDueDeadlineWithInstalledKeyOptions variants.
    /// Unified pending work with installed key options.
    /// Replaces 5+ processPendingWorkWithInstalledKeyOptions variants.
    /// Unified feed across connections with pending work and crypto backend.
    /// Replaces 10+ feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackend variants.
    pub fn registerReplacementConnectionId(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        destination_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        sequence_number: u64,
        retire_prior_to: u64,
        options: endpoint.ReplacementRouteOptions,
    ) endpoint.RouteError!endpoint.ReplacementResult {
        return self.router.registerReplacementConnectionId(
            connection_id,
            destination_connection_id,
            path,
            sequence_number,
            retire_prior_to,
            options,
        );
    }

    /// Issue a local CID and register its endpoint route in one lifecycle step.
    ///
    /// The connection owns RFC 9000 NEW_CONNECTION_ID sequencing and token
    /// uniqueness checks. The endpoint lifecycle owns the receive route and
    /// retained stateless reset token. If route registration fails, the helper
    /// rolls back the just-issued local CID so callers do not have to repair
    /// split connection/router state.
    /// Unified routed long datagram processing.
    /// Replaces 4+ processRoutedProtectedLongDatagramInSpace variants.
    /// Unified routed Handshake datagram processing.
    /// Replaces 4+ processRoutedProtectedHandshakeDatagram variants.
    /// Unified close with route path.
    /// Replaces 4+ closeWithRoutePath/closeAndDrainDatagrams variants.
    /// Unified process with next deadline selection.
    /// Replaces 5+ AndSelectNextDeadline variants.
    /// Unified feed with pending work and next deadline.
    /// Replaces 5+ AndProcessPendingWorkAndSelectNextDeadline variants.
    pub fn issueConnectionIdRoute(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        destination_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        stateless_reset_token: [packet.stateless_reset_token_len]u8,
        retire_prior_to: u64,
        options: EndpointIssuedConnectionIdOptions,
    ) EndpointConnectionIdError!EndpointIssuedConnectionIdResult {
        const original_local_connection_id_count = connection.local_connection_ids.items.len;
        const original_next_sequence = connection.next_local_connection_id_sequence;
        const sequence_number = connection.issueConnectionId(
            destination_connection_id,
            stateless_reset_token,
            retire_prior_to,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer connection.rollbackIssuedConnectionIds(
            original_local_connection_id_count,
            original_next_sequence,
        );

        const replacement = try self.registerReplacementConnectionId(
            connection_id,
            destination_connection_id,
            path,
            sequence_number,
            retire_prior_to,
            .{
                .active_migration_disabled = options.active_migration_disabled,
                .stateless_reset_token = stateless_reset_token,
            },
        );

        return .{
            .sequence_number = replacement.sequence_number,
            .retire_prior_to = replacement.retire_prior_to,
            .retired_count = replacement.retired_count,
        };
    }

    /// Move a route to a caller-validated UDP tuple.
    ///
    /// The connection still owns PATH_CHALLENGE/PATH_RESPONSE validation and
    /// packet-number ordering. The lifecycle owner only commits the resulting
    /// path update to the same routing state used for receive classification,
    /// protected datagram delivery, and timer/route retirement.
    /// Unified feed with compatible version handling.
    /// Replaces 10+ WithCompatibleVersion variants.
    /// Unified feed across connections with compatible version.
    /// Replaces 10+ AcrossConnectionsAndWithCompatibleVersion variants.
    /// Unified Handshake with crypto backend and compatible version.
    /// Replaces 10+ HandshakeAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified short with crypto backend and compatible version.
    /// Replaces 10+ ShortAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified due deadline with crypto backend and compatible version.
    /// Replaces 10+ DueDeadlineAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified pending work across connections with crypto backend.
    /// Replaces 10+ PendingWorkAcrossConnectionsAndDriveCryptoBackend variants.
    pub fn updateRoutePath(
        self: *EndpointConnectionLifecycle,
        destination_connection_id: []const u8,
        current_path: endpoint.Udp4Tuple,
        new_path: endpoint.Udp4Tuple,
    ) endpoint.RouteError!endpoint.RouteResult {
        return self.router.updateRoutePath(destination_connection_id, current_path, new_path);
    }

    /// Move a route to a caller-validated UDP tuple and reset spin-bit state.
    ///
    /// QUIC spin-bit state is scoped to the current network path. The
    /// connection still owns the actual spin value, but the lifecycle owner
    /// commits the endpoint path update and resets the connection's next spin
    /// bit only after that route update succeeds.
    /// Unified feed with pending work and crypto backend in space.
    /// Replaces 10+ AndProcessPendingWorkAndDriveCryptoBackendInSpace variants.
    /// Unified feed across connections with pending work and crypto backend in space.
    /// Replaces 10+ AcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendInSpace variants.
    /// Unified feed across connections with pending work and crypto backend across spaces.
    /// Replaces 10+ AcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpaces variants.
    /// Unified due deadline across connections with crypto backend.
    /// Replaces 5+ DueDeadlineAcrossConnectionsAndDriveCryptoBackend variants.
    /// Unified pending work across connections with crypto backend and compatible version.
    /// Replaces 10+ PendingWorkAcrossConnectionsAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified feed with pending work, crypto backend, and compatible version.
    /// Replaces 10+ AndProcessPendingWorkAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified feed across connections with pending work, crypto backend, and compatible version.
    /// Replaces 10+ AcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendWithCompatibleVersion variants.
    /// Unified feed across connections with pending work, crypto backend across spaces, and compatible version.
    /// Replaces 10+ AcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesWithCompatibleVersion variants.
    pub fn updateRoutePathAndResetSpinBit(
        self: *EndpointConnectionLifecycle,
        destination_connection_id: []const u8,
        current_path: endpoint.Udp4Tuple,
        new_path: endpoint.Udp4Tuple,
        connection: *Connection,
    ) endpoint.RouteError!endpoint.RouteResult {
        const updated = try self.updateRoutePath(destination_connection_id, current_path, new_path);
        connection.resetSpinBitForPath();
        return updated;
    }

    /// Move a route to the UDP tuple that carried validated path traffic.
    ///
    /// This endpoint-owned commit path is used only after a protected datagram
    /// has been authenticated and `Connection` has consumed a matching
    /// PATH_RESPONSE. It also resets connection spin-bit state because the
    /// accepted route is now a new network path.
    /// Unified feed with OrClose and drain.
    /// Replaces feedDatagramWithInstalledKeysOrCloseAndDrainDatagrams and similar.
    /// Unified feed with OrClose and poll.
    /// Replaces feedDatagramWithInstalledKeysOrCloseAndPollDatagram and similar.
    /// Unified Handshake with OrClose and drain.
    /// Replaces processProtectedHandshakeDatagramWithInstalledKeysOrCloseAndDrainDatagrams.
    /// Unified Handshake with OrClose and poll.
    /// Replaces processProtectedHandshakeDatagramWithInstalledKeysOrCloseAndPollDatagram.
    /// Unified short with OrClose and drain.
    /// Replaces processProtectedShortDatagramWithInstalledKeysOrCloseAndDrainDatagrams.
    /// Unified short with OrClose and poll.
    /// Replaces processProtectedShortDatagramWithInstalledKeysOrCloseAndPollDatagram.
    /// Unified routed short with OrClose and drain.
    /// Replaces processRoutedProtectedShortDatagramWithInstalledKeysOrCloseAndDrainDatagrams.
    /// Unified routed short with OrClose and poll.
    /// Replaces processRoutedProtectedShortDatagramWithInstalledKeysOrCloseAndPollDatagram.
    /// Unified Initial with OrClose and drain.
    /// Replaces processAcceptedProtectedInitialWithCryptoBackendOrCloseAndDrainDatagrams.
    /// Unified Initial with OrClose and poll.
    /// Replaces processAcceptedProtectedInitialWithCryptoBackendOrCloseAndPollDatagram.
    pub fn updateRoutePathFromValidatedDatagramAndResetSpinBit(
        self: *EndpointConnectionLifecycle,
        destination_connection_id: []const u8,
        new_path: endpoint.Udp4Tuple,
        connection: *Connection,
    ) endpoint.RouteError!endpoint.RouteResult {
        const updated = try self.router.updateRoutePathFromValidatedDatagram(destination_connection_id, new_path);
        connection.resetSpinBitForPath();
        return updated;
    }

    /// Return the committed UDP tuple for a registered destination connection ID.
    /// Unified Handshake with crypto backend, OrClose, and drain.
    /// Unified Handshake with crypto backend, OrClose, and poll.
    /// Unified short with crypto backend, OrClose, and drain.
    /// Unified short with crypto backend, OrClose, and poll.
    /// Unified due deadline with crypto backend, OrClose, and drain.
    /// Unified due deadline with crypto backend, OrClose, and poll.
    /// Unified pending work with crypto backend, OrClose, and drain.
    /// Unified pending work with crypto backend, OrClose, and poll.
    /// Unified feed with crypto backend in space, OrClose, and drain.
    /// Unified feed with crypto backend in space, OrClose, and poll.
    pub fn currentRoutePath(
        self: *const EndpointConnectionLifecycle,
        destination_connection_id: []const u8,
    ) endpoint.RouteError!endpoint.Udp4Tuple {
        return self.router.currentRoutePath(destination_connection_id);
    }

    /// Route one received datagram using the owned endpoint routing table.
    /// Unified feed across connections with OrClose and drain.
    /// Unified feed across connections with OrClose and poll.
    /// Unified feed across connections with crypto backend, OrClose, and drain.
    /// Unified feed across connections with crypto backend, OrClose, and poll.
    /// Unified feed across connections with compatible version, OrClose, and drain.
    /// Unified feed across connections with compatible version, OrClose, and poll.
    /// Unified feed across connections with crypto backend, compatible version, OrClose, and drain.
    /// Unified feed across connections with crypto backend, compatible version, OrClose, and poll.
    /// Unified feed with pending work, OrClose, and drain.
    /// Unified feed with pending work, OrClose, and poll.
    pub fn routeDatagram(
        self: *const EndpointConnectionLifecycle,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
    ) endpoint.RouteError!endpoint.RouteResult {
        return self.router.routeDatagram(path, datagram);
    }

    /// Route and process one protected Initial datagram on an existing route.
    ///
    /// This is the lifecycle-owned receive bridge for protected Initial
    /// responses after a route has already been installed. The helper first
    /// proves the datagram routes to `connection_id`, derives Initial keys from
    /// the packet version and the caller-provided Original DCID, then processes
    /// the packet in Initial space and mirrors recovery timers. Server-side
    /// first-Initial acceptance still uses
    /// `processAcceptedProtectedInitialDatagram()` because routes are installed
    /// only after authentication succeeds.
    /// Unified feed across connections with pending work, OrClose, and drain.
    /// Unified feed across connections with pending work, OrClose, and poll.
    /// Unified feed across connections with pending work, crypto backend, OrClose, and drain.
    /// Unified feed across connections with pending work, crypto backend, OrClose, and poll.
    /// Unified feed across connections with pending work, crypto backend across spaces, OrClose, and drain.
    /// Unified feed across connections with pending work, crypto backend across spaces, OrClose, and poll.
    /// Unified feed with pending work, crypto backend in space, compatible version, OrClose, and drain.
    /// Unified feed with pending work, crypto backend in space, compatible version, OrClose, and poll.
    /// Unified feed across connections with pending work, crypto backend in space, compatible version, OrClose, and drain.
    /// Unified feed across connections with pending work, crypto backend in space, compatible version, OrClose, and poll.
    pub fn processRoutedProtectedInitialDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        datagram: []const u8,
    ) EndpointProtectedInitialError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const info = protection.peekProtectedLongPacketInfo(datagram) catch return error.InvalidPacket;
        if (info.packet_type != .initial) return error.InvalidPacket;
        const initial_secrets = protection.deriveInitialSecrets(
            info.version,
            original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const keys = switch (connection.side) {
            .client => initial_secrets.server,
            .server => initial_secrets.client,
        };
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            .initial,
            now_nanos,
            keys,
            datagram,
        );
        return route;
    }

    /// Route and process one protected Initial datagram with close propagation.
    ///
    /// This preserves `processRoutedProtectedInitialDatagram()` routing and
    /// success behavior, but authenticated plaintext frame errors queue a
    /// transport CONNECTION_CLOSE before returning `InvalidPacket`.
    /// Unified feed across connections with pending work, crypto backend across spaces, compatible version, OrClose, and drain.
    /// Unified feed across connections with pending work, crypto backend across spaces, compatible version, OrClose, and poll.
    /// Unified feed with pending work, crypto backend across spaces, OrClose, and drain.
    /// Unified feed with pending work, crypto backend across spaces, OrClose, and poll.
    /// Unified feed with pending work, crypto backend across spaces, compatible version, OrClose, and drain.
    /// Unified feed with pending work, crypto backend across spaces, compatible version, OrClose, and poll.
    /// Unified due deadline across connections with crypto backend, OrClose, and drain.
    /// Unified due deadline across connections with crypto backend, OrClose, and poll.
    /// Unified pending work across connections with crypto backend, OrClose, and drain.
    /// Unified pending work across connections with crypto backend, OrClose, and poll.
    pub fn processRoutedProtectedInitialDatagramOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        datagram: []const u8,
    ) EndpointProtectedInitialError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const info = protection.peekProtectedLongPacketInfo(datagram) catch return error.InvalidPacket;
        if (info.packet_type != .initial) return error.InvalidPacket;
        const initial_secrets = protection.deriveInitialSecrets(
            info.version,
            original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const keys = switch (connection.side) {
            .client => initial_secrets.server,
            .server => initial_secrets.client,
        };
        try self.processProtectedLongDatagramInSpaceOrClose(
            connection_id,
            connection,
            .initial,
            now_nanos,
            keys,
            datagram,
        );
        return route;
    }

    /// Route and process a coalesced Initial/Handshake UDP datagram after
    /// Handshake keys are installed.
    ///
    /// The full UDP datagram is preserved for RFC 9000 Initial minimum-size
    /// validation while `Connection` authenticates each encoded long packet at
    /// its own boundary. The caller supplies the Original DCID so Initial keys
    /// remain tied to the client-selected first-flight destination CID.
    /// Unified pending work across connections with crypto backend, compatible version, OrClose, and drain.
    /// Unified pending work across connections with crypto backend, compatible version, OrClose, and poll.
    /// Unified due deadline across connections with crypto backend, compatible version, OrClose, and drain.
    /// Unified due deadline across connections with crypto backend, compatible version, OrClose, and poll.
    /// Unified Handshake with crypto backend, compatible version, OrClose, and drain.
    /// Unified Handshake with crypto backend, compatible version, OrClose, and poll.
    /// Unified short with crypto backend, compatible version, OrClose, and drain.
    /// Unified short with crypto backend, compatible version, OrClose, and poll.
    /// Unified Initial with crypto backend, compatible version, OrClose, and drain.
    /// Unified Initial with crypto backend, compatible version, OrClose, and poll.
    pub fn processRoutedProtectedLongDatagramWithInstalledHandshakeKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        datagram: []const u8,
    ) EndpointProtectedInitialError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const info = protection.peekProtectedLongPacketInfo(datagram) catch return error.InvalidPacket;
        if (info.packet_type != .initial) return error.InvalidPacket;
        const initial_secrets = protection.deriveInitialSecrets(
            info.version,
            original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const initial_keys = switch (connection.side) {
            .client => initial_secrets.server,
            .server => initial_secrets.client,
        };
        _ = connection.processProtectedLongDatagramWithInstalledHandshakeKeys(
            now_nanos,
            initial_keys,
            datagram,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return route;
    }

    /// Accept a Retry follow-up Initial on an already-switched endpoint route.
    ///
    /// This helper keeps the server Retry follow-up receive path on the
    /// lifecycle owner after `switchInitialDestinationConnectionIdAfterRetry()`
    /// has replaced the Original DCID route with the Retry Source CID. It
    /// proves the datagram routes to the caller's connection handle, extracts
    /// Initial accept metadata, prevalidates the path-bound Retry token, then
    /// authenticates the protected Initial packet. Only an authenticated
    /// packet consumes the one-time token and unblocks anti-amplification.
    /// Unified routed Handshake with crypto backend, compatible version, OrClose, and drain.
    /// Unified routed Handshake with crypto backend, compatible version, OrClose, and poll.
    /// Unified routed long with crypto backend, OrClose, and drain.
    /// Unified routed long with crypto backend, OrClose, and poll.
    /// Unified long with crypto backend, compatible version, OrClose, and drain.
    /// Unified long with crypto backend, compatible version, OrClose, and poll.
    /// Unified Initial with crypto backend in space, OrClose, and drain.
    /// Unified Initial with crypto backend in space, OrClose, and poll.
    /// Unified Initial with crypto backend in space, compatible version, OrClose, and drain.
    /// Unified Initial with crypto backend in space, compatible version, OrClose, and poll.
    pub fn processRetryValidatedProtectedInitialDatagram(
        self: *EndpointConnectionLifecycle,
        policy: *endpoint.AddressValidationPolicy,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        supported_versions: []const packet.Version,
    ) EndpointRetryProtectedInitialError!EndpointRetryProtectedInitialResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const initial_accept = (try endpoint.peekInitialAcceptDatagram(
            path,
            datagram,
            supported_versions,
        )) orelse return error.InvalidPacket;
        if (!std.mem.eql(u8, initial_accept.original_destination_connection_id, route.destination_connection_id.asSlice())) {
            return error.InvalidPacket;
        }
        if (initial_accept.token.len == 0) return error.InvalidPacket;

        // Keep malformed or unauthenticated Initials from consuming the
        // single-use token. This preliminary check rejects the wrong path,
        // version, expiry, or token before decryption, without replay state
        // or connection state side effects.
        if (connection.side != .server) return error.InvalidPacket;
        if (connection.connectionState() != .active) {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return error.ConnectionClosed;
        }
        if (!connection.hasPendingRetryToken(initial_accept.token)) return error.InvalidPacket;
        _ = try policy.validateTokenForPathWithoutReplayForVersion(
            .retry,
            initial_accept.version,
            now_nanos,
            path,
            initial_accept.token,
        );
        _ = try self.processRoutedProtectedInitialDatagram(
            connection_id,
            connection,
            path,
            now_nanos,
            initial_accept.original_destination_connection_id,
            datagram,
        );
        const token_validation = try self.validateRetryTokenForPathAndArmConnection(
            policy,
            connection_id,
            connection,
            initial_accept.version,
            now_nanos,
            path,
            initial_accept.token,
        );

        return .{
            .route = route,
            .initial_accept = initial_accept,
            .token_validation = token_validation,
        };
    }

    /// Return a retained stateless reset token for an inactive destination CID.
    ///
    /// Active routes suppress their reset token. This read-only lookup lets
    /// socket loops keep retired-CID reset handling on the same lifecycle owner
    /// that installed replacement routes and applied `retire_prior_to`.
    /// Unified routed long with crypto backend, compatible version, OrClose, and drain.
    /// Unified routed long with crypto backend, compatible version, OrClose, and poll.
    /// Unified feed with crypto backend across spaces, compatible version, OrClose, and drain.
    /// Unified feed with crypto backend across spaces, compatible version, OrClose, and poll.
    /// Unified feed across connections with crypto backend in space, OrClose, and drain.
    /// Unified feed across connections with crypto backend in space, OrClose, and poll.
    /// Unified feed across connections with crypto backend in space, compatible version, OrClose, and drain.
    /// Unified feed across connections with crypto backend in space, compatible version, OrClose, and poll.
    /// Unified feed across connections with crypto backend across spaces, OrClose, and drain.
    /// Unified feed across connections with crypto backend across spaces, OrClose, and poll.
    /// Unified feed across connections with crypto backend across spaces, compatible version, OrClose, and drain.
    /// Unified feed across connections with crypto backend across spaces, compatible version, OrClose, and poll.
    /// Unified feed with pending work, crypto backend in space, OrClose, and drain.
    /// Unified feed with pending work, crypto backend in space, OrClose, and poll.
    /// Unified feed with pending work, crypto backend across spaces, compatible version, OrClose, and drain.
    /// Unified feed with pending work, crypto backend across spaces, compatible version, OrClose, and poll.
    pub fn statelessResetTokenForDatagram(
        self: *const EndpointConnectionLifecycle,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
    ) endpoint.RouteError!?[packet.stateless_reset_token_len]u8 {
        return self.router.statelessResetTokenForDatagram(path, datagram);
    }

    /// Classify one received datagram using lifecycle-owned routing state.
    ///
    /// Active routes are returned for connection delivery. Retired CIDs with
    /// retained reset tokens can produce a stateless reset datagram, while
    /// unknown packets are dropped. This keeps socket receive classification on
    /// the same endpoint state owner that retires routes and recovery timers.
    pub fn handleDatagram(
        self: *const EndpointConnectionLifecycle,
        out: []u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        unpredictable_prefix: []const u8,
    ) endpoint.RouteError!endpoint.DatagramAction {
        return self.router.handleDatagram(out, path, datagram, unpredictable_prefix);
    }

    /// Classify one received datagram, including Version Negotiation responses.
    ///
    /// Unsupported-version long headers can produce a Version Negotiation
    /// datagram before normal route/reset/drop handling. Supported Initials
    /// without an existing route can be surfaced as accept candidates.
    pub fn handleDatagramWithVersionNegotiation(
        self: *const EndpointConnectionLifecycle,
        out: []u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        unpredictable_prefix: []const u8,
        supported_versions: []const packet.Version,
    ) endpoint.RouteError!endpoint.DatagramAction {
        return self.router.handleDatagramWithVersionNegotiation(out, path, datagram, unpredictable_prefix, supported_versions);
    }

    /// Socket-facing datagram intake entrypoint.
    ///
    /// This is the public endpoint-loop name for receive classification. It
    /// performs version-independent routing, unsupported-version Version
    /// Negotiation response generation, stateless reset lookup, and new Initial
    /// accept classification without owning socket I/O or `Connection` storage.
    pub fn feedDatagram(
        self: *const EndpointConnectionLifecycle,
        out: []u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        unpredictable_prefix: []const u8,
        supported_versions: []const packet.Version,
    ) endpoint.RouteError!endpoint.DatagramAction {
        return self.handleDatagramWithVersionNegotiation(
            out,
            path,
            datagram,
            unpredictable_prefix,
            supported_versions,
        );
    }

    fn processRoutedStatelessResetDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
    ) Error!bool {
        if (datagram.len == 0 or packet.parseHeaderForm(datagram[0]) != .short) return false;
        if (connection.processStatelessResetDatagram(now_nanos, datagram) == null) return false;
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return true;
    }

    /// Socket-facing installed-key datagram receive entrypoint.
    ///
    /// This combines `feedDatagram()` classification with routed protected
    /// packet processing after TLS has installed keys on `connection`. Routed
    /// datagrams must resolve to `connection_id`; authenticated plaintext frame
    /// errors use the close-propagating receive paths. Version Negotiation,
    /// stateless reset, new Initial accept, and drop actions are surfaced
    /// unchanged for the socket loop to handle.
    pub fn feedDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramResult {
        const action = try self.feedDatagram(
            options.out,
            path,
            datagram,
            options.unpredictable_prefix,
            options.supported_versions,
        );
        return switch (action) {
            .routed => |route| routed: {
                if (route.connection_id != connection_id) return error.InvalidPacket;
                if (try self.processRoutedStatelessResetDatagram(connection_id, connection, now_nanos, datagram)) {
                    break :routed .dropped;
                }
                switch (options.space) {
                    .handshake => try self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
                        connection_id,
                        connection,
                        now_nanos,
                        datagram,
                    ),
                    .zero_rtt => try self.processProtectedZeroRttDatagramWithInstalledKeysOrClose(
                        connection_id,
                        connection,
                        now_nanos,
                        datagram,
                    ),
                    .application => try self.processProtectedShortDatagramWithInstalledKeysOrClose(
                        connection_id,
                        connection,
                        now_nanos,
                        route.destination_connection_id.asSlice().len,
                        datagram,
                    ),
                }
                break :routed .{ .routed = route };
            },
            .accept_initial => |initial| .{ .accept_initial = initial },
            .version_negotiation => |response| .{ .version_negotiation = response },
            .stateless_reset => |reset| .{ .stateless_reset = reset },
            .dropped => .dropped,
        };
    }

    /// Unified installed-key feed with options-struct interface.
    ///
    /// Replaces the combinatorial variants:
    ///   feedDatagramWithInstalledKeys
    ///   feedDatagramWithInstalledKeysOrClose
    ///   feedDatagramWithInstalledKeysAndDrainDatagrams
    ///   feedDatagramWithInstalledKeysOrCloseAndDrainDatagrams
    ///
    /// Migration pattern: callers switch from variant functions to this
    /// unified function with the appropriate options.
    /// Socket-facing installed-key receive with validated migration commit.
    ///
    /// This matches `feedDatagramWithInstalledKeys()` for Version Negotiation,
    /// stateless reset, new Initial, Handshake, 0-RTT, and drop actions. For
    /// routed 1-RTT application packets, it additionally commits the endpoint
    /// route only when authenticated processing consumes an outstanding
    /// PATH_CHALLENGE response from the changed UDP tuple. When the caller
    /// supplies `path_challenge_data`, a successfully processed application
    /// packet from a changed path queues one PATH_CHALLENGE unless validation
    /// is already pending or has just completed. The result exposes the UDP
    /// tuple that immediate path-validation-related output should use.
    pub fn feedDatagramWithInstalledKeysAndUpdatePathOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyPathUpdateResult {
        const action = try self.feedDatagram(
            options.out,
            path,
            datagram,
            options.unpredictable_prefix,
            options.supported_versions,
        );
        return switch (action) {
            .routed => |route| routed: {
                if (route.connection_id != connection_id) return error.InvalidPacket;
                if (try self.processRoutedStatelessResetDatagram(connection_id, connection, now_nanos, datagram)) {
                    break :routed .{ .feed = .dropped };
                }
                switch (options.space) {
                    .handshake => try self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
                        connection_id,
                        connection,
                        now_nanos,
                        datagram,
                    ),
                    .zero_rtt => try self.processProtectedZeroRttDatagramWithInstalledKeysOrClose(
                        connection_id,
                        connection,
                        now_nanos,
                        datagram,
                    ),
                    .application => {
                        const outstanding_before = connection.outstandingPathChallengeCount();
                        try self.processProtectedShortDatagramWithInstalledKeysOrClose(
                            connection_id,
                            connection,
                            now_nanos,
                            route.destination_connection_id.asSlice().len,
                            datagram,
                        );
                        const outstanding_after = connection.outstandingPathChallengeCount();
                        const updated_route: ?endpoint.RouteResult = if (route.path_changed and outstanding_after < outstanding_before)
                            try self.updateRoutePathFromValidatedDatagramAndResetSpinBit(
                                route.destination_connection_id.asSlice(),
                                path,
                                connection,
                            )
                        else
                            null;
                        var path_challenge_queued = false;
                        if (updated_route == null and route.path_changed and
                            connection.pendingPathChallengeCount() == 0 and
                            connection.outstandingPathChallengeCount() == 0)
                        {
                            if (options.path_challenge_data) |challenge_data| {
                                try connection.sendPathChallenge(challenge_data);
                                path_challenge_queued = true;
                            }
                        }
                        break :routed .{
                            .feed = .{ .routed = route },
                            .updated_route = updated_route,
                            .path_challenge_queued = path_challenge_queued,
                            .selected_output_path = if (updated_route != null or path_challenge_queued) path else null,
                        };
                    },
                }
                break :routed .{ .feed = .{ .routed = route } };
            },
            .accept_initial => |initial| .{ .feed = .{ .accept_initial = initial } },
            .version_negotiation => |response| .{ .feed = .{ .version_negotiation = response } },
            .stateless_reset => |reset| .{ .feed = .{ .stateless_reset = reset } },
            .dropped => .{ .feed = .dropped },
        };
    }

    /// Feed with validated path-update handling, then poll installed-key output.
    ///
    /// This single-connection socket-loop step pairs any immediate
    /// path-validation-related output with the UDP tuple selected by the core
    /// feed result. Ordinary receive processing, route commit, and polling
    /// semantics are inherited from the underlying feed and poll helpers.
    pub fn feedDatagramWithInstalledKeysAndUpdatePathOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPathUpdateDatagramPollResult {
        const feed = self.feedDatagramWithInstalledKeysAndUpdatePathOrClose(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
            feed_options,
        ) catch |err| {
            if (err != error.InvalidPacket) return err;
            const close_datagram = if (connection.connectionState() == .closing)
                try self.pollDatagram(
                    connection_id,
                    connection,
                    now_nanos,
                    poll_options,
                )
            else
                null;
            const routed = if (close_datagram != null)
                self.routeDatagram(path, datagram) catch null
            else
                null;
            const output_path: ?endpoint.Udp4Tuple = if (routed) |route|
                if (route.connection_id == connection_id)
                    try self.currentRoutePath(route.destination_connection_id.asSlice())
                else
                    null
            else
                null;
            return .{
                .feed = .{ .feed = .dropped },
                .feed_error = err,
                .datagram = if (close_datagram) |protected_datagram| .{
                    .connection_id = connection_id,
                    .datagram = protected_datagram,
                } else null,
                .output_path = output_path,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        const routed = switch (feed.feed) {
            .routed => |value| value,
            else => return .{
                .feed = feed,
                .next_deadline = self.nextDeadline(connection_id, connection),
            },
        };
        const output_path = feed.selected_output_path orelse try self.currentRoutePath(routed.destination_connection_id.asSlice());
        const polled = try self.pollDatagram(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        );
        const polled_result: ?EndpointPolledDatagramResult = if (polled) |protected_datagram|
            .{
                .connection_id = connection_id,
                .datagram = protected_datagram,
            }
        else
            null;
        return .{
            .feed = feed,
            .datagram = polled_result,
            .output_path = if (polled_result != null) output_path else null,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Socket-facing installed-key receive dispatch across caller-owned connections.
    ///
    /// This helper keeps endpoint routing and protected packet receive under
    /// the lifecycle owner while leaving connection storage with the caller.
    /// Routed datagrams are matched by `connection_id` against `connections`;
    /// missing matches return `InvalidPacket`. Non-routed actions are surfaced
    /// unchanged so the socket loop can send Version Negotiation/stateless
    /// reset responses or accept new Initials.
    pub fn feedDatagramWithInstalledKeysAcrossConnections(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramResult {
        const action = try self.feedDatagram(
            options.out,
            path,
            datagram,
            options.unpredictable_prefix,
            options.supported_versions,
        );
        return switch (action) {
            .routed => |route| routed: {
                const view = for (connections) |candidate| {
                    if (candidate.connection_id == route.connection_id) break candidate;
                } else return error.InvalidPacket;
                if (try self.processRoutedStatelessResetDatagram(view.connection_id, view.connection, now_nanos, datagram)) {
                    break :routed .dropped;
                }
                switch (options.space) {
                    .handshake => try self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
                        view.connection_id,
                        view.connection,
                        now_nanos,
                        datagram,
                    ),
                    .zero_rtt => try self.processProtectedZeroRttDatagramWithInstalledKeysOrClose(
                        view.connection_id,
                        view.connection,
                        now_nanos,
                        datagram,
                    ),
                    .application => try self.processProtectedShortDatagramWithInstalledKeysOrClose(
                        view.connection_id,
                        view.connection,
                        now_nanos,
                        route.destination_connection_id.asSlice().len,
                        datagram,
                    ),
                }
                break :routed .{ .routed = route };
            },
            .accept_initial => |initial| .{ .accept_initial = initial },
            .version_negotiation => |response| .{ .version_negotiation = response },
            .stateless_reset => |reset| .{ .stateless_reset = reset },
            .dropped => .dropped,
        };
    }

    /// Feed an installed-key datagram, then select the next wakeup.
    ///
    /// This is the no-output receive step for embeddable socket loops. It
    /// keeps route lookup and protected receive under lifecycle ownership, then
    /// recomputes the next endpoint-visible deadline from the caller-owned
    /// scheduling view without polling output.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        return .{
            .feed = feed,
            .next_deadline = self.nextDeadlineAcrossConnections(deadline_connections),
        };
    }

    /// Feed one installed-key datagram, then select the next wakeup.
    ///
    /// This is the single-connection no-output receive step. It reuses the
    /// cross-connection lifecycle path with one caller-owned connection.
    pub fn feedDatagramWithInstalledKeysAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndSelectNextDeadline(
            &receive_connections,
            &deadline_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
    }

    /// Feed an installed-key datagram, process pending work, then select the next wakeup.
    ///
    /// This is the no-output socket-loop receive step that keeps datagram
    /// processing, idle/close/recovery pending work, and deadline selection
    /// under one endpoint lifecycle owner.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .next_deadline = self.nextDeadlineAcrossConnections(deadline_connections),
        };
    }

    /// Feed one installed-key datagram, process pending work, then select its next wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndSelectNextDeadline(
            &receive_connections,
            &deadline_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
    }

    /// Feed an installed-key datagram, process pending work, drive backends, then select a wakeup.
    ///
    /// This is the no-output receive/backend planning step for socket loops.
    /// Backend progress runs only when the datagram routed to a connection and
    /// pending idle/close cleanup did not retire any connection in this pass.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        return self.feedStepWithPendingWorkCryptoDeadline(receive_connections, deadline_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{}, &.{});
    
    }

    /// Feed one installed-key datagram, process pending work, drive one backend, then select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{}, &.{});
    
    }

    // -----------------------------------------------------------------------
    // Unified feedDatagram + pending work + crypto backend drive step
    // -----------------------------------------------------------------------

    /// Unified feed + pending-work + crypto backend drive + deadline selection.
    ///
    /// Replaces all feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWork
    /// AndDriveCryptoBackends*AndSelectNextDeadline variants.
    ///
    /// Crypto drive is conditional: only runs when the feed routed a datagram
    /// and pending work did not retire the connection.
    pub fn feedStepWithPendingWorkCryptoDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        var backend: ?EndpointCryptoBackendDriveSweepResult = null;
        if (pending_work.idle_retired_count == 0 and pending_work.close_retired_count == 0) {
            switch (feed) {
                .routed => {
                    var sweep = EndpointCryptoBackendDriveSweepResult{};
                    for (drive_views) |view| {
                        const progress = self.driveCryptoBackendStepInner(
                            view.connection_id, view.connection, spaces,
                            view.backend, view.scratch, crypto_opts, compatibilities,
                        ) catch |err| {
                            self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                            return err;
                        };
                        try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
                        accumulateCryptoBackendProgress(&sweep, progress);
                    }
                    backend = sweep;
                },
                else => {},
            }
        }
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .backend = backend,
            .next_deadline = self.nextDeadlineAcrossConnections(deadline_connections),
        };
    }

    /// Unified feed + pending-work + crypto backend drive + poll output.
    ///
    /// Replaces all feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWork
    /// AndDriveCryptoBackends*AndPollDatagram variants.
    pub fn feedStepWithPendingWorkCryptoPoll(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        var backend: ?EndpointCryptoBackendDriveDatagramResult = null;
        if (pending_work.idle_retired_count == 0 and pending_work.close_retired_count == 0) {
            switch (feed) {
                .routed => backend = try self.driveCryptoBackendStepWithPoll(
                    spaces, drive_views, crypto_opts, compatibilities,
                    poll_views, now_nanos, poll_space,
                ),
                else => {},
            }
        }
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .backend = backend,
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Unified feed + pending-work + crypto backend drive + drain output.
    ///
    /// Replaces all feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWork
    /// AndDriveCryptoBackends*AndDrainDatagrams variants.
    pub fn feedStepWithPendingWorkCryptoDrain(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        var backend: ?EndpointCryptoBackendDriveDatagramDrainResult = null;
        if (pending_work.idle_retired_count == 0 and pending_work.close_retired_count == 0) {
            switch (feed) {
                .routed => backend = try self.driveCryptoBackendStepWithDrain(
                    spaces, drive_views, crypto_opts, compatibilities,
                    poll_views, now_nanos, poll_space, out,
                ),
                else => {},
            }
        }
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .backend = backend,
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Unified feed + pending-work + crypto backend drive + installed-key poll.
    pub fn feedStepWithPendingWorkCryptoInstalledKeyPoll(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections, path, now_nanos, datagram, feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(receive_connections, now_nanos);
        var backend: ?EndpointCryptoBackendDriveDatagramResult = null;
        if (pending_work.idle_retired_count == 0 and pending_work.close_retired_count == 0) {
            switch (feed) {
                .routed => backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(
                    spaces, drive_views, crypto_opts, compatibilities, poll_views, now_nanos,
                ),
                else => {},
            }
        }
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .backend = backend,
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Unified feed + pending-work + crypto backend drive + installed-key drain.
    pub fn feedStepWithPendingWorkCryptoInstalledKeyDrain(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections, path, now_nanos, datagram, feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(receive_connections, now_nanos);
        var backend: ?EndpointCryptoBackendDriveDatagramDrainResult = null;
        if (pending_work.idle_retired_count == 0 and pending_work.close_retired_count == 0) {
            switch (feed) {
                .routed => backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(
                    spaces, drive_views, crypto_opts, compatibilities, poll_views, now_nanos, out,
                ),
                else => {},
            }
        }
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .backend = backend,
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }





    /// Feed one installed-key datagram, process pending work, drive one backend
    /// across ordered packet number spaces, then select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{}, &.{});
    
    }


    /// Feed one installed-key datagram, process pending work, drive one backend
    /// across ordered packet number spaces with close-on-error handling, then
    /// select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesOrCloseAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{ .close_on_error = true }, &.{});
    
    }


    /// Feed one installed-key datagram, process pending work, drive one close-propagating backend, then select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{});
    
    }

    /// Feed an installed-key datagram, process pending work, drive compatible-version backends, then select a wakeup.
    ///
    /// This is the RFC 9368-compatible receive/pending/backend planning step
    /// for socket loops. Backend progress runs only when the datagram routed
    /// and pending idle/close cleanup did not retire any connection.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        return self.feedStepWithPendingWorkCryptoDeadline(receive_connections, deadline_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one compatible-version close path, then select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities);
    
    }

    /// Feed an installed-key datagram, process pending work, drive compatible-version backends across ordered spaces, then select a wakeup.
    ///
    /// This is the RFC 9368-compatible receive/pending/backend planning step
    /// for socket loops that service ordered Initial/Handshake spaces in one
    /// pass. Backend progress runs only when the datagram routed and pending
    /// idle/close cleanup did not retire any connection.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        return self.feedStepWithPendingWorkCryptoDeadline(receive_connections, deadline_connections, path, now_nanos, datagram, feed_options, backend_spaces, drive_views, .{ .compatible_version = true }, compatibilities);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one compatible-version close path across ordered spaces, then select a wakeup.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesWithCompatibleVersionOrCloseAndSelectNextDeadline()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoDeadline(&receive_connections, &deadline_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities);
    
    }

    /// Feed an installed-key datagram, process pending work, drive compatible-version backends, then poll output.
    ///
    /// Backend progress runs only when the datagram routed and pending
    /// idle/close cleanup did not retire any connection.
    /// Feed one installed-key datagram, process pending work, drive one compatible-version backend, then poll output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram()`.
    /// Feed an installed-key datagram, process pending work, drive compatible-version backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one compatible-version backend, then poll explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one compatible-version close path, then poll explicit output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// output polling.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one compatible-version backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, out);
    
    }

    /// Feed an installed-key datagram, process pending work, drive compatible-version close path, then drain output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// output draining.
    /// Feed one installed-key datagram, process pending work, drive one compatible-version close path, then drain output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams()`.
    /// Feed an installed-key datagram, process pending work, drive compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, out);
    
    }

    /// Feed an installed-key datagram, process pending work, drive backends, then poll output.
    ///
    /// This is the receive/backend/output socket-loop step that also preserves
    /// endpoint-owned idle, close, and recovery ordering between packet receive
    /// and backend progress.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        return self.feedStepWithPendingWorkCryptoPoll(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{}, &.{}, poll_views, poll_space);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one backend
    /// across ordered packet number spaces, then poll output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoPoll(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{}, &.{}, &poll_views, poll_options.space);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one
    /// close-propagating backend across ordered packet number spaces, then poll
    /// explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionInstalledKeyPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .poll_options = poll_options,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one backend, then poll output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{}, &.{}, &poll_views, poll_options.space);
    
    }

    /// Feed an installed-key datagram, process pending work, drive backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{}, &.{}, poll_views);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one backend, then poll explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{}, &.{}, poll_views);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, out);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one close-propagating backend, then poll output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, poll_options.space);
    
    }

    /// Feed an installed-key datagram, process pending work, drive close-propagating backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one close-propagating backend, then poll explicit output.
    ///
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before output polling.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyPoll(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one backend
    /// across ordered packet number spaces, then drain output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesAndDrainDatagrams()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoDrain(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{}, &.{}, &poll_views, poll_options.space, out);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one backend
    /// across ordered packet number spaces, then drain explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesAndDrainDatagramsWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionInstalledKeyPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .poll_options = poll_options,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{}, &.{}, &poll_views, out);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one
    /// close-propagating backend across ordered packet number spaces, then drain
    /// explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesOrCloseAndDrainDatagramsWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionInstalledKeyPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .poll_options = poll_options,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, out);
    
    }


    /// Feed one installed-key datagram, process pending work, drive one
    /// close-propagating backend across ordered packet number spaces, then drain
    /// output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsAcrossSpacesOrCloseAndDrainDatagrams()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoDrain(&receive_connections, path, now_nanos, datagram, feed_options, backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, poll_options.space, out);
    
    }

    /// Feed an installed-key datagram, process pending work, drive backends, then drain output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        return self.feedStepWithPendingWorkCryptoDrain(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{}, &.{}, poll_views, poll_space, out);
    
    }

    /// Feed an installed-key datagram, process pending work, drive close-propagating backends, then drain output.
    ///
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before output draining.
    /// Feed one installed-key datagram, process pending work, drive one close-propagating backend, then drain output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagrams()`.
    /// Feed an installed-key datagram, process pending work, drive close-propagating backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, out);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one close-propagating backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, out);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one backend, then drain output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndDrainDatagrams()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedStepWithPendingWorkCryptoDrain(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{}, &.{}, &poll_views, poll_options.space, out);
    
    }

    /// Feed an installed-key datagram, process pending work, drive backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDriveCryptoBackendsInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, drive_views, .{}, &.{}, poll_views, out);
    
    }

    /// Feed one installed-key datagram, process pending work, drive one backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDriveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkCryptoBackendDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedStepWithPendingWorkCryptoInstalledKeyDrain(&receive_connections, path, now_nanos, datagram, feed_options, &.{backend_space}, &drive_views, .{}, &.{}, poll_views, out);
    
    }

    /// Feed an installed-key datagram, process pending work, then poll output.
    ///
    /// Unlike `feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagram()`,
    /// this socket-loop step runs pending work and output polling even when the
    /// received datagram is not routed to a live connection. That lets callers
    /// keep timeout cleanup and queued output progress tied to a single receive
    /// iteration.
    /// Feed an installed-key datagram, process pending work, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramPollResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .datagram = try self.pollDatagramAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, process pending work, then poll output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramPollResult {
        const feed = try self.feedDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWork(
            connection_id,
            connection,
            now_nanos,
        );
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .feed = feed,
                .pending_work = pending_sweep,
                .datagram = null,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .feed = feed,
            .pending_work = pending_sweep,
            .datagram = try self.pollDatagramAcrossConnections(
                &poll_views,
                now_nanos,
                poll_options.space,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Feed one installed-key datagram, process pending work, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramPollResult {
        const feed = try self.feedDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWork(
            connection_id,
            connection,
            now_nanos,
        );
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .feed = feed,
                .pending_work = pending_sweep,
                .datagram = null,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        return .{
            .feed = feed,
            .pending_work = pending_sweep,
            .datagram = try self.pollDatagramAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Feed an installed-key datagram, process pending work, then drain output.
    ///
    /// Unlike `feedDatagramWithInstalledKeysAcrossConnectionsAndDrainDatagrams()`,
    /// this socket-loop step runs pending work and bounded output draining even
    /// when the received datagram is not routed to a live connection. That lets
    /// callers keep timeout cleanup and queued output progress tied to a single
    /// receive iteration.
    /// Feed an installed-key datagram, process pending work, then drain explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDrainDatagrams()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWorkAcrossConnections(
            receive_connections,
            now_nanos,
        );
        return .{
            .feed = feed,
            .pending_work = pending_work,
            .drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
                out,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, process pending work, then drain output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndProcessPendingWorkAndDrainDatagrams()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWork(
            connection_id,
            connection,
            now_nanos,
        );
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .feed = feed,
                .pending_work = pending_sweep,
                .drain = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .feed = feed,
            .pending_work = pending_sweep,
            .drain = self.drainDatagramsAcrossConnections(
                &poll_views,
                now_nanos,
                poll_options.space,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Feed one installed-key datagram, process pending work, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndProcessPendingWorkAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndProcessPendingWorkAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedPendingWorkDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        const pending_work = try self.processPendingWork(
            connection_id,
            connection,
            now_nanos,
        );
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .feed = feed,
                .pending_work = pending_sweep,
                .drain = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        return .{
            .feed = feed,
            .pending_work = pending_sweep,
            .drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Feed an installed-key datagram, drive TLS backends, then select a wakeup.
    ///
    /// This is the no-output receive-to-backend step for socket loops. It
    /// routes and processes the incoming datagram first; only routed datagrams
    /// drive backends. Version Negotiation, stateless reset, new Initial
    /// acceptance, and dropped datagrams remain explicit socket policy results.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        deadline_connections: []const EndpointConnectionView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStep(&.{backend_space}, drive_views, .{ .output = .select_deadline }, &.{}, deadline_connections),
        };
    }
    /// Feed an installed-key datagram, drive close-propagating backends, then select a wakeup.
    ///
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before deadline selection. Non-routed feed results never drive
    /// backends.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        deadline_connections: []const EndpointConnectionView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStep(&.{backend_space}, drive_views, .{ .close_on_error = true, .output = .select_deadline }, &.{}, deadline_connections),
        };
    }

    /// Feed one installed-key datagram, drive a close-propagating backend, then select a wakeup.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndSelectNextDeadline(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            &deadline_connections,
        );
    }

    /// Feed an installed-key datagram, then poll installed-key output.
    ///
    /// This is the socket-facing receive-to-output step for paths that do not
    /// need TLS backend progress after packet receive. Non-routed feed results
    /// return without polling.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramPollResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .datagram = try self.pollDatagramAcrossConnections(
                poll_views,
                now_nanos,
                poll_space,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, then poll output with explicit options.
    ///
    /// This cross-connection form lets caller-owned socket loops preserve each
    /// candidate connection's installed-key output choice while still using
    /// lifecycle-owned route lookup and protected receive dispatch.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramPollResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .datagram = try self.pollDatagramAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, then poll installed-key output.
    ///
    /// This is the single-connection receive-to-output loop step. It reuses
    /// the cross-connection lifecycle path with one caller-owned connection so
    /// simple socket loops do not need to build receive/poll view slices.
    pub fn feedDatagramWithInstalledKeysAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramPollResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagram(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            &poll_views,
            poll_options.space,
        );
    }

    /// Feed one installed-key datagram, then poll explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramPollResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            poll_views,
        );
    }

    /// Feed an installed-key datagram, then drain installed-key output.
    ///
    /// This is the socket-facing receive-to-bounded-drain step for paths that
    /// do not need TLS backend progress after packet receive, such as 1-RTT
    /// application packets that only need ACK or queued STREAM output. Non-
    /// routed feed results return without draining.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .drain = self.drainDatagramsAcrossConnections(
                poll_views,
                now_nanos,
                poll_space,
                out,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, then drain output with explicit options.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
                out,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, then drain installed-key output.
    ///
    /// This is the single-connection receive-to-bounded-drain loop step. It
    /// reuses the cross-connection lifecycle path with one caller-owned
    /// connection so simple socket loops do not need to build receive/poll view
    /// slices.
    pub fn feedDatagramWithInstalledKeysAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDrainDatagrams(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            &poll_views,
            poll_options.space,
            out,
        );
    }

    /// Feed one installed-key datagram, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedInstalledKeyDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDrainDatagramsWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            poll_views,
            out,
        );
    }

    /// Feed an installed-key datagram, drive TLS backends, then poll output.
    ///
    /// This is a socket-loop receive-to-backend-to-output step for callers that
    /// own connection/backend storage. Non-routed feed results are returned
    /// without driving backends, so Version Negotiation, stateless reset, new
    /// Initial acceptance, and drop handling remain explicit at the socket
    /// policy layer.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, poll_space),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive TLS backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive one backend, then poll output.
    ///
    /// This is the single-connection receive-to-backend-to-output loop step. It
    /// reuses the cross-connection lifecycle path with one caller-owned
    /// connection/backend pair.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            &poll_views,
            poll_options.space,
        );
    }

    /// Feed one installed-key datagram, drive one backend, then poll explicit output.
    ///
    /// This is the single-connection form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            poll_views,
        );
    }

    /// Feed an installed-key datagram, drive TLS backends, then drain output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    /// The caller-owned output slice limits work after a routed receive and
    /// backend sweep. Non-routed feed results return without backend work.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, poll_space, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive TLS backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive one backend, then drain output.
    ///
    /// This is the single-connection bounded-output receive-to-backend loop
    /// step. It reuses the cross-connection lifecycle path with one
    /// caller-owned connection/backend pair so simple client/server socket
    /// loops do not need to manually build receive, drive, and poll view slices.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagrams(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            &poll_views,
            poll_options.space,
            out,
        );
    }

    /// Feed one installed-key datagram, drive one backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagramsWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            poll_views,
            out,
        );
    }

    /// Feed an installed-key datagram, drive close-propagating backends, then poll output.
    ///
    /// Backend peer transport-parameter errors stop before output polling,
    /// preserving the originating connection close path.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, poll_space),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive close-propagating backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive close-propagating backend, then poll output.
    ///
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before output polling.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            &poll_views,
            poll_options.space,
        );
    }

    /// Feed one installed-key datagram, drive one close-propagating backend, then poll explicit output.
    ///
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before output polling.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            poll_views,
        );
    }

    /// Feed an installed-key datagram, drive close-propagating backends, then drain output.
    ///
    /// Backend peer transport-parameter errors return before any output slot is
    /// initialized, preserving the close-propagating backend contract.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, poll_space, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive close-propagating backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive close-propagating backend, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagrams()`.
    /// Backend peer transport-parameter errors queue CONNECTION_CLOSE and
    /// return before any installed-key output slot is initialized.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagrams(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            &poll_views,
            poll_options.space,
            out,
        );
    }

    /// Feed one installed-key datagram, drive one close-propagating backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            poll_views,
            out,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version backends, then select a wakeup.
    ///
    /// This is the no-output RFC 9368-compatible receive-to-backend step for
    /// socket loops. It routes and processes the incoming datagram first; only
    /// routed datagrams drive backends. Version Negotiation, stateless reset,
    /// new Initial acceptance, and dropped datagrams remain explicit socket
    /// policy results.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStep(&.{backend_space}, drive_views, .{ .compatible_version = true, .output = .select_deadline }, compatibilities, deadline_connections),
        };
    }

    /// Feed one installed-key datagram, drive one compatible-version backend, then select a wakeup.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndSelectNextDeadline(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &deadline_connections,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version close path, then select a wakeup.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// deadline selection. Non-routed feed results never drive backends.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStep(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true, .output = .select_deadline }, compatibilities, deadline_connections),
        };
    }

    /// Feed one installed-key datagram, drive compatible-version close path, then select a wakeup.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveNextDeadlineResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &deadline_connections,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version backends, then poll output.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive compatible-version backends, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive one compatible-version backend, then poll output.
    ///
    /// This is the single-connection receive-to-backend-to-output loop step for
    /// RFC 9368-compatible handshakes.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &poll_views,
            poll_options.space,
        );
    }

    /// Feed one installed-key datagram, drive one compatible-version backend, then poll explicit output.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            poll_views,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version backends, then drain output.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive compatible-version backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive one compatible-version backend, then drain output.
    ///
    /// This is the single-connection bounded-output receive-to-backend loop
    /// step for RFC 9368-compatible handshakes. It reuses the cross-connection
    /// lifecycle path with one caller-owned connection/backend pair.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagrams(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &poll_views,
            poll_options.space,
            out,
        );
    }

    /// Feed one installed-key datagram, drive one compatible-version backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            poll_views,
            out,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version close path, then poll output.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive compatible-version close path, then poll explicit output.
    ///
    /// This is the per-connection-output-options form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagram()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive compatible-version close path, then poll output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// output polling.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &poll_views,
            poll_options.space,
        );
    }

    /// Feed one installed-key datagram, drive one compatible-version close path, then poll explicit output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// output polling.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            poll_views,
        );
    }

    /// Feed an installed-key datagram, drive compatible-version close path, then drain output.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed an installed-key datagram, drive compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        receive_connections: []const EndpointConnectionReceiveView,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const feed = try self.feedDatagramWithInstalledKeysAcrossConnections(
            receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
        );
        switch (feed) {
            .routed => {},
            else => return .{ .feed = feed },
        }
        return .{
            .feed = feed,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(receive_connections),
        };
    }

    /// Feed one installed-key datagram, drive compatible-version close path, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams()`.
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// any installed-key output slot is initialized.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            &poll_views,
            poll_options.space,
            out,
        );
    }

    /// Feed one installed-key datagram, drive one compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn feedDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        feed_options: EndpointFeedInstalledKeyDatagramOptions,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointFeedCryptoBackendDriveDatagramDrainResult {
        const receive_connections = [_]EndpointConnectionReceiveView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.feedDatagramWithInstalledKeysAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
            &receive_connections,
            path,
            now_nanos,
            datagram,
            feed_options,
            backend_space,
            &drive_views,
            compatibilities,
            poll_views,
            out,
        );
    }

    /// Process a client-side Version Negotiation response and retire old routes.
    ///
    /// A valid RFC 8999 Version Negotiation packet supersedes the current
    /// connection attempt. This helper keeps endpoint state in sync by deriving
    /// the follow-up connection config from the connection, then retiring all
    /// routes and recovery timers for the old connection handle. Ignored VN
    /// packets return null and leave endpoint state unchanged.
    pub fn processVersionNegotiationDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        local_initial_source_connection_id: []const u8,
        datagram: []const u8,
    ) Error!?EndpointVersionNegotiationResult {
        const selected = (connection.processVersionNegotiationDatagram(
            now_nanos,
            original_destination_connection_id,
            local_initial_source_connection_id,
            datagram,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        }) orelse return null;
        const followup_config = connection.versionNegotiationFollowupConfig() catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        return .{
            .selected_version = selected,
            .followup_config = followup_config,
            .retired = self.retireConnection(connection_id),
        };
    }

    /// Process Version Negotiation and install the follow-up Initial route.
    ///
    /// This is the lifecycle-owned endpoint orchestration point for an
    /// incompatible-version retry. The current connection still validates the
    /// RFC 8999 packet and derives the next client config. The endpoint
    /// lifecycle retires the superseded attempt and registers the next client
    /// Initial Source CID route only when that VN packet is accepted. Ignored
    /// VN packets return null and leave both the old and follow-up routes
    /// untouched.
    pub fn processVersionNegotiationFollowupDatagram(
        self: *EndpointConnectionLifecycle,
        old_connection_id: u64,
        followup_connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        old_local_initial_source_connection_id: []const u8,
        followup_local_initial_source_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        options: endpoint.ClientInitialRouteOptions,
    ) EndpointVersionNegotiationError!?EndpointVersionNegotiationFollowupResult {
        const selected = (connection.processVersionNegotiationDatagram(
            now_nanos,
            original_destination_connection_id,
            old_local_initial_source_connection_id,
            datagram,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(old_connection_id, connection);
            return err;
        }) orelse return null;
        const followup_config = connection.versionNegotiationFollowupConfig() catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(old_connection_id, connection);
            return err;
        };

        const reuses_client_source_cid = std.mem.eql(
            u8,
            old_local_initial_source_connection_id,
            followup_local_initial_source_connection_id,
        );
        var retired = EndpointConnectionRetireResult{
            .routes_retired = 0,
            .recovery_timer_disarmed = false,
        };
        if (reuses_client_source_cid) {
            retired = self.retireConnection(old_connection_id);
        }

        const followup_route = try self.registerClientInitialSourceConnectionId(
            followup_connection_id,
            followup_local_initial_source_connection_id,
            path,
            options,
        );
        if (!reuses_client_source_cid) {
            retired = self.retireConnection(old_connection_id);
        }

        return .{
            .version_negotiation = .{
                .selected_version = selected,
                .followup_config = followup_config,
                .retired = retired,
            },
            .followup_route = followup_route,
        };
    }

    /// Process Version Negotiation and return the initialized follow-up connection.
    ///
    /// This wraps `processVersionNegotiationFollowupDatagram()` for socket
    /// loops that want one endpoint-owned handoff step. The old connection
    /// attempt validates the VN packet; the lifecycle owner updates routes and
    /// timers; the returned client `Connection` is initialized from the
    /// negotiated follow-up config. Ignored VN packets return null and do not
    /// allocate or mutate endpoint routing.
    pub fn processVersionNegotiationHandoffDatagram(
        self: *EndpointConnectionLifecycle,
        old_connection_id: u64,
        followup_connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        old_local_initial_source_connection_id: []const u8,
        followup_local_initial_source_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        options: endpoint.ClientInitialRouteOptions,
    ) EndpointVersionNegotiationError!?EndpointVersionNegotiationHandoffResult {
        const followup = (try self.processVersionNegotiationFollowupDatagram(
            old_connection_id,
            followup_connection_id,
            connection,
            now_nanos,
            original_destination_connection_id,
            old_local_initial_source_connection_id,
            followup_local_initial_source_connection_id,
            path,
            datagram,
            options,
        )) orelse return null;
        errdefer _ = self.retireConnection(followup_connection_id);

        return .{
            .followup = followup,
            .followup_connection = try Connection.init(
                connection.allocator,
                .client,
                followup.version_negotiation.followup_config,
            ),
        };
    }

    /// Process Version Negotiation and emit the first protected follow-up Initial.
    ///
    /// This is the caller-keyed retry-loop bridge for incompatible Version
    /// Negotiation. It validates the VN packet, retires the superseded attempt,
    /// registers the follow-up Initial route, initializes the follow-up client
    /// connection, queues the supplied Initial CRYPTO bytes, emits one
    /// protected Initial datagram with Initial keys for the selected version,
    /// and mirrors the follow-up recovery timer onto the endpoint lifecycle.
    /// Real TLS traffic-secret ownership remains a higher-level integration
    /// step; Initial keys are derived from the selected version and original
    /// client Initial Destination CID.
    ///
    /// Ignored VN packets return null and do not mutate endpoint state. On
    /// success, the caller owns both the returned `followup_connection` and
    /// `initial_datagram`.
    pub fn processVersionNegotiationProtectedInitialDatagram(
        self: *EndpointConnectionLifecycle,
        old_connection_id: u64,
        followup_connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        original_destination_connection_id: []const u8,
        old_local_initial_source_connection_id: []const u8,
        followup_local_initial_source_connection_id: []const u8,
        path: endpoint.Udp4Tuple,
        datagram: []const u8,
        options: endpoint.ClientInitialRouteOptions,
        initial_token: []const u8,
        initial_crypto: []const u8,
    ) EndpointVersionNegotiationError!?EndpointVersionNegotiationProtectedInitialResult {
        if (initial_crypto.len == 0) return error.InvalidPacket;

        var handoff = (try self.processVersionNegotiationHandoffDatagram(
            old_connection_id,
            followup_connection_id,
            connection,
            now_nanos,
            original_destination_connection_id,
            old_local_initial_source_connection_id,
            followup_local_initial_source_connection_id,
            path,
            datagram,
            options,
        )) orelse return null;
        errdefer _ = self.retireConnection(followup_connection_id);
        errdefer handoff.followup_connection.deinit();

        try handoff.followup_connection.sendCryptoInSpace(.initial, initial_crypto);
        const initial_secrets = protection.deriveInitialSecrets(
            handoff.followup.version_negotiation.selected_version,
            original_destination_connection_id,
        ) catch return error.InvalidPacket;
        const initial_datagram = (try self.pollProtectedLongCryptoDatagramInSpace(
            followup_connection_id,
            &handoff.followup_connection,
            .initial,
            now_nanos,
            original_destination_connection_id,
            followup_local_initial_source_connection_id,
            initial_token,
            initial_secrets.client,
        )) orelse return error.Internal;

        return .{
            .handoff = handoff,
            .initial_datagram = initial_datagram,
        };
    }

    /// Mirror one connection's current aggregate loss/PTO timer.
    pub fn armRecoveryTimerFromConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *const Connection,
    ) Error!void {
        try self.recovery_timers.armFromConnection(connection_id, connection);
    }

    fn refreshRecoveryTimerAfterConnectionError(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *const Connection,
    ) void {
        // Preserve the connection error; timer mirroring is secondary once the
        // connection path is already failing.
        self.armRecoveryTimerFromConnection(connection_id, connection) catch {};
    }

    /// Return the earliest connection-level recovery timer known to the endpoint.
    pub fn earliestRecoveryDeadline(self: *const EndpointConnectionLifecycle) ?EndpointLossDetectionTimerDeadline {
        return self.recovery_timers.earliestDeadline();
    }

    /// Return the next endpoint-visible deadline for one connection handle.
    ///
    /// Socket loops can use this to wait on idle timeout, close/drain timeout,
    /// or QUIC loss/PTO recovery without comparing independent connection and
    /// endpoint timer sources themselves.
    pub fn nextDeadline(
        self: *const EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *const Connection,
    ) ?EndpointConnectionDeadline {
        const state = connection.connectionState();
        var next: ?EndpointConnectionDeadline = null;

        if (state == .active) {
            if (connection.idleTimeoutDeadline()) |deadline| {
                next = .{
                    .connection_id = connection_id,
                    .deadline_nanos = deadline,
                    .kind = .idle_timeout,
                };
            }
        }
        if (state == .closing or state == .draining) {
            if (connection.closeDeadline()) |deadline| {
                if (next == null or deadline < next.?.deadline_nanos) {
                    next = .{
                        .connection_id = connection_id,
                        .deadline_nanos = deadline,
                        .kind = .close_timeout,
                    };
                }
            }
        }
        if (state == .active) {
            if (self.recovery_timers.deadlineForConnection(connection_id)) |deadline| {
                if (next == null or deadline.timer.deadline_nanos < next.?.deadline_nanos) {
                    next = .{
                        .connection_id = connection_id,
                        .deadline_nanos = deadline.timer.deadline_nanos,
                        .kind = .recovery,
                        .recovery = deadline.timer,
                    };
                }
            }
            if (connection.oneRttKeyDiscardDeadline()) |deadline| {
                if (next == null or deadline < next.?.deadline_nanos) {
                    next = .{
                        .connection_id = connection_id,
                        .deadline_nanos = deadline,
                        .kind = .key_discard,
                    };
                }
            }
        }

        return next;
    }

    /// Return the earliest endpoint-visible deadline across caller-owned connections.
    ///
    /// The endpoint lifecycle still does not own connection storage. Callers
    /// provide the currently live connection views from their connection map,
    /// and the lifecycle combines connection-owned idle/close deadlines with
    /// endpoint-owned recovery timer snapshots.
    pub fn nextDeadlineAcrossConnections(
        self: *const EndpointConnectionLifecycle,
        connections: []const EndpointConnectionView,
    ) ?EndpointConnectionDeadline {
        var next: ?EndpointConnectionDeadline = null;
        for (connections) |view| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (next == null or candidate.deadline_nanos < next.?.deadline_nanos) {
                next = candidate;
            }
        }
        return next;
    }

    fn nextDeadlineAcrossReceiveConnections(
        self: *const EndpointConnectionLifecycle,
        connections: []const EndpointConnectionReceiveView,
    ) ?EndpointConnectionDeadline {
        var next: ?EndpointConnectionDeadline = null;
        for (connections) |view| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (next == null or candidate.deadline_nanos < next.?.deadline_nanos) {
                next = candidate;
            }
        }
        return next;
    }

    fn nextDeadlineAcrossPollConnections(
        self: *const EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
    ) ?EndpointConnectionDeadline {
        var next: ?EndpointConnectionDeadline = null;
        for (connections) |view| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (next == null or candidate.deadline_nanos < next.?.deadline_nanos) {
                next = candidate;
            }
        }
        return next;
    }

    fn nextDeadlineAcrossInstalledKeyPollConnections(
        self: *const EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
    ) ?EndpointConnectionDeadline {
        var next: ?EndpointConnectionDeadline = null;
        for (connections) |view| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (next == null or candidate.deadline_nanos < next.?.deadline_nanos) {
                next = candidate;
            }
        }
        return next;
    }

    /// Drive a connection TLS/crypto backend under endpoint lifecycle ownership.
    ///
    /// This wraps `Connection.driveCryptoBackendInSpace()` and then refreshes
    /// the endpoint's aggregate recovery timer snapshot for the caller-owned
    /// connection handle. Socket loops should use this helper when backend
    /// progress can queue protected CRYPTO, install keys, confirm the
    /// handshake, or discard packet-number-space state that affects recovery
    /// scheduling.
    pub fn driveCryptoBackendInSpaceAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendInSpace(space, backend, scratch) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }

    /// Drive one TLS backend across ordered packet number spaces, then refresh
    /// the endpoint's aggregate recovery timer snapshot.
    ///
    /// This is the cross-space form of `driveCryptoBackendInSpaceAndArmConnection()`.
    /// A live TLS handshake emits CRYPTO for more than one encryption level from
    /// a single inbound flight, so a socket loop can service Initial and
    /// Handshake output in one pass instead of one call per space. `spaces` must
    /// be ordered from the lowest to the highest encryption level. On backend
    /// failure the recovery timer snapshot is still refreshed before the error
    /// propagates.
    pub fn driveCryptoBackendAcrossSpacesAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendAcrossSpaces(spaces, backend, scratch) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }


    /// Drive one TLS backend, then poll one caller-keyed long-header output.
    ///
    /// This single-connection form is for socket loops that already hold
    /// Initial or Handshake packet-protection keys and want at most one
    /// protected long-header CRYPTO datagram after backend progress. The
    /// caller owns connection/backend/socket storage and any returned datagram.
    pub fn driveCryptoBackendInSpaceAndPollProtectedLongCryptoDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramResult {
        var backend_progress = try self.driveCryptoBackendInSpaceAndArmConnection(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        );
        const handshake_discarded_before_poll = connection.packetNumberSpaceDiscarded(.handshake);
        if (connection.packetNumberSpaceDiscarded(poll_space)) {
            return .{
                .backend = backend_progress,
                .datagram = null,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }
        const datagram = try self.pollProtectedLongCryptoDatagramInSpace(
            connection_id,
            connection,
            poll_space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            keys,
        );
        if (!handshake_discarded_before_poll and connection.packetNumberSpaceDiscarded(.handshake)) {
            backend_progress.handshake_space_discarded = true;
        }
        return .{
            .backend = backend_progress,
            .datagram = if (datagram) |bytes| .{
                .connection_id = connection_id,
                .datagram = bytes,
            } else null,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Drive one TLS backend with close propagation, then poll caller-keyed output.
    ///
    /// This is the close-propagating variant of
    /// `driveCryptoBackendInSpaceAndPollProtectedLongCryptoDatagram()`.
    /// Backend peer transport-parameter errors queue and poll protected close
    /// output instead of polling ordinary caller-keyed CRYPTO output.
    pub fn driveCryptoBackendInSpaceOrCloseAndPollProtectedLongCryptoDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramResult {
        var backend_progress = self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const datagram = try self.pollProtectedLongDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
                initial_token,
                try protectedLongDatagramKeysForSpace(poll_space, keys),
            );
            return .{
                .backend = .{},
                .datagram = if (datagram) |bytes| .{
                    .connection_id = connection_id,
                    .datagram = bytes,
                } else null,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        const handshake_discarded_before_poll = connection.packetNumberSpaceDiscarded(.handshake);
        if (connection.packetNumberSpaceDiscarded(poll_space)) {
            return .{
                .backend = backend_progress,
                .datagram = null,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }
        const datagram = try self.pollProtectedLongCryptoDatagramInSpace(
            connection_id,
            connection,
            poll_space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            keys,
        );
        if (!handshake_discarded_before_poll and connection.packetNumberSpaceDiscarded(.handshake)) {
            backend_progress.handshake_space_discarded = true;
        }
        return .{
            .backend = backend_progress,
            .datagram = if (datagram) |bytes| .{
                .connection_id = connection_id,
                .datagram = bytes,
            } else null,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Drive one TLS backend, then drain caller-keyed long-header CRYPTO output.
    ///
    /// This single-connection form is for socket loops that already hold
    /// Initial or Handshake packet-protection keys. It applies backend progress
    /// first, refreshes endpoint recovery state, and then drains at most
    /// `out.len` protected long-header CRYPTO datagrams from `drain_space`.
    /// Connection/backend/socket storage and each returned datagram remain
    /// caller-owned.
    pub fn driveCryptoBackendInSpaceAndDrainProtectedLongCryptoDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramDrainResult {
        var backend_progress = try self.driveCryptoBackendInSpaceAndArmConnection(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        );
        const handshake_discarded_before_drain = connection.packetNumberSpaceDiscarded(.handshake);
        if (connection.packetNumberSpaceDiscarded(drain_space)) {
            return .{
                .backend = backend_progress,
                .drain = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }
        const drain = self.drainProtectedLongCryptoDatagramsInSpace(
            connection_id,
            connection,
            drain_space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            keys,
            out,
        );
        if (!handshake_discarded_before_drain and connection.packetNumberSpaceDiscarded(.handshake)) {
            backend_progress.handshake_space_discarded = true;
        }
        return .{
            .backend = backend_progress,
            .drain = drain,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Drive one TLS backend with close propagation, then drain caller-keyed output.
    ///
    /// This is the close-propagating variant of
    /// `driveCryptoBackendInSpaceAndDrainProtectedLongCryptoDatagrams()`.
    /// Backend peer transport-parameter errors queue and drain protected close
    /// output instead of draining ordinary caller-keyed CRYPTO output.
    pub fn driveCryptoBackendInSpaceOrCloseAndDrainProtectedLongCryptoDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramDrainResult {
        var backend_progress = self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainProtectedLongDatagrams(
                    connection_id,
                    connection,
                    now_nanos,
                    dcid,
                    scid,
                    initial_token,
                    try protectedLongDatagramKeysForSpace(drain_space, keys),
                    out,
                ),
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        const handshake_discarded_before_drain = connection.packetNumberSpaceDiscarded(.handshake);
        if (connection.packetNumberSpaceDiscarded(drain_space)) {
            return .{
                .backend = backend_progress,
                .drain = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }
        const drain = self.drainProtectedLongCryptoDatagramsInSpace(
            connection_id,
            connection,
            drain_space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            keys,
            out,
        );
        if (!handshake_discarded_before_drain and connection.packetNumberSpaceDiscarded(.handshake)) {
            backend_progress.handshake_space_discarded = true;
        }
        return .{
            .backend = backend_progress,
            .drain = drain,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    fn accumulateCryptoBackendProgress(
        result: *EndpointCryptoBackendDriveSweepResult,
        progress: CryptoBackendProgress,
    ) void {
        result.connections_driven += 1;
        result.progress.local_transport_parameters_bytes += progress.local_transport_parameters_bytes;
        result.progress.peer_transport_parameters_bytes += progress.peer_transport_parameters_bytes;
        result.progress.peer_transport_parameters_applied = result.progress.peer_transport_parameters_applied or
            progress.peer_transport_parameters_applied;
        if (result.progress.peer_compatible_version_selected == null) {
            result.progress.peer_compatible_version_selected = progress.peer_compatible_version_selected;
        }
        result.progress.handshake_keys_installed = result.progress.handshake_keys_installed or
            progress.handshake_keys_installed;
        result.progress.handshake_space_discarded = result.progress.handshake_space_discarded or
            progress.handshake_space_discarded;
        result.progress.zero_rtt_keys_installed = result.progress.zero_rtt_keys_installed or
            progress.zero_rtt_keys_installed;
        result.progress.one_rtt_keys_installed = result.progress.one_rtt_keys_installed or
            progress.one_rtt_keys_installed;
        result.progress.inbound_chunks += progress.inbound_chunks;
        result.progress.inbound_bytes += progress.inbound_bytes;
        result.progress.outbound_chunks += progress.outbound_chunks;
        result.progress.outbound_bytes += progress.outbound_bytes;
        result.progress.handshake_confirmed = result.progress.handshake_confirmed or progress.handshake_confirmed;
        result.progress.application_protocol_negotiated = result.progress.application_protocol_negotiated or
            progress.application_protocol_negotiated;
    }

    fn countRetainedHandshakeSpaces(poll_views: []const EndpointConnectionPollView) usize {
        var count: usize = 0;
        for (poll_views) |view| {
            if (!view.connection.packetNumberSpaceDiscarded(.handshake)) {
                count += 1;
            }
        }
        return count;
    }

    fn closingDriveViewCount(views: []const EndpointCryptoBackendDriveView) usize {
        var count: usize = 0;
        for (views) |view| {
            if (view.connection.connectionState() == .closing) count += 1;
        }
        return count;
    }

    fn countRetainedHandshakeSpacesWithInstalledKeyOptions(
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) usize {
        var count: usize = 0;
        for (poll_views) |view| {
            if (!view.connection.packetNumberSpaceDiscarded(.handshake)) {
                count += 1;
            }
        }
        return count;
    }

    fn markHandshakeSpaceDiscardedIfCountDrops(
        progress: *CryptoBackendProgress,
        before: usize,
        after: usize,
    ) void {
        if (after < before) {
            progress.handshake_space_discarded = true;
        }
    }

    fn skipBackendDriveOutputForDiscardedSpace(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: EndpointInstalledKeyDatagramSpace,
    ) Error!bool {
        if (space != .handshake) return false;
        if (connection.packetNumberSpaceDiscarded(.handshake)) return true;
        if (!connection.handshakeConfirmed()) return false;

        try connection.discardPacketNumberSpace(.handshake);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return true;
    }

    fn pollDatagramAcrossConnectionsAfterBackendDrive(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            if (try self.skipBackendDriveOutputForDiscardedSpace(view.connection_id, view.connection, space)) continue;
            const datagram = try self.pollDatagram(
                view.connection_id,
                view.connection,
                now_nanos,
                .{
                    .space = space,
                    .destination_connection_id = view.destination_connection_id,
                    .source_connection_id = view.source_connection_id,
                },
            );
            if (datagram) |bytes| {
                return .{
                    .connection_id = view.connection_id,
                    .datagram = bytes,
                };
            }
        }
        return null;
    }

    fn pollDatagramAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            if (try self.skipBackendDriveOutputForDiscardedSpace(
                view.connection_id,
                view.connection,
                view.poll_options.space,
            )) continue;
            const datagram = try self.pollDatagram(
                view.connection_id,
                view.connection,
                now_nanos,
                view.poll_options,
            );
            if (datagram) |bytes| {
                return .{
                    .connection_id = view.connection_id,
                    .datagram = bytes,
                };
            }
        }
        return null;
    }

    fn drainDatagramsAcrossConnectionsAfterBackendDrive(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const polled = self.pollDatagramAcrossConnectionsAfterBackendDrive(
                connections,
                now_nanos,
                space,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = polled orelse return result;
            result.datagrams_written += 1;
        }
        return result;
    }

    fn drainDatagramsAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const polled = self.pollDatagramAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
                connections,
                now_nanos,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = polled orelse return result;
            result.datagrams_written += 1;
        }
        return result;
    }

    fn pollDatagramForBackendClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            if (view.connection_id != connection_id) continue;
            const matching_views = [_]EndpointConnectionPollView{view};
            return self.pollDatagramAcrossConnectionsAfterBackendDrive(
                &matching_views,
                now_nanos,
                space,
            );
        }
        return error.InvalidPacket;
    }

    fn pollDatagramWithInstalledKeyOptionsForBackendClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            if (view.connection_id != connection_id) continue;
            const matching_views = [_]EndpointConnectionInstalledKeyPollView{view};
            return self.pollDatagramAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
                &matching_views,
                now_nanos,
            );
        }
        return error.InvalidPacket;
    }

    fn drainDatagramsForBackendClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        for (connections) |view| {
            if (view.connection_id != connection_id) continue;
            if (out.len == 0) return error.BufferTooSmall;
            const matching_views = [_]EndpointConnectionPollView{view};
            const drain = self.drainDatagramsAcrossConnectionsAfterBackendDrive(
                &matching_views,
                now_nanos,
                space,
                out,
            );
            if (drain.datagrams_written == 0) {
                if (drain.first_error) |err| return err;
            }
            return drain;
        }
        return error.InvalidPacket;
    }

    fn drainDatagramsWithInstalledKeyOptionsForBackendClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        for (connections) |view| {
            if (view.connection_id != connection_id) continue;
            if (out.len == 0) return error.BufferTooSmall;
            const matching_views = [_]EndpointConnectionInstalledKeyPollView{view};
            const drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
                &matching_views,
                now_nanos,
                out,
            );
            if (drain.datagrams_written == 0) {
                if (drain.first_error) |err| return err;
            }
            return drain;
        }
        return error.InvalidPacket;
    }

    /// Drive crypto backends across caller-owned connections.
    ///
    /// This is the socket-loop sweep form of
    /// `driveCryptoBackendInSpaceAndArmConnection()`. The lifecycle still does
    /// not own connection or backend storage; it only centralizes backend
    /// driving and recovery-timer refresh for each caller-provided view.
    pub fn driveCryptoBackendsInSpaceAndArmConnections(
        self: *EndpointConnectionLifecycle,
        space: PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendInSpaceAndArmConnection(
                view.connection_id,
                view.connection,
                space,
                view.backend,
                view.scratch,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }

    /// Drive TLS backends across ordered packet number spaces for each view.
    ///
    /// This is the multi-connection form of
    /// `driveCryptoBackendAcrossSpacesAndArmConnection()`. Each caller-provided
    /// view is driven across the same ordered `spaces` in one pass, so a socket
    /// loop can advance Initial and Handshake output for several handshaking
    /// connections after a single receive. Progress is aggregated across every
    /// successfully driven view. `spaces` must be ordered from the lowest to the
    /// highest encryption level.
    pub fn driveCryptoBackendsAcrossSpacesAndArmConnections(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendAcrossSpacesAndArmConnection(
                view.connection_id,
                view.connection,
                spaces,
                view.backend,
                view.scratch,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }


    // -----------------------------------------------------------------------
    // Unified crypto backend drive step
    // -----------------------------------------------------------------------

    /// Unified crypto backend drive replacing combinatorial variant explosion.
    ///
    /// Replaces all driveCryptoBackend{InSpace,AcrossSpaces}{OrClose,}
    /// {WithCompatibleVersion,}And{ArmConnection,SelectNextDeadline} variants
    /// and their multi-connection driveCryptoBackends* counterparts.
    ///
    /// `spaces` controls single-space vs across-spaces: pass a one-element
    /// slice for InSpace, multiple for AcrossSpaces.
    ///
    /// Callers migrate from:
    ///   lifecycle.driveCryptoBackendsInSpaceOrCloseAndSelectNextDeadline(space, views, deadline_conns)
    /// to:
    ///   lifecycle.driveCryptoBackendStep(&.{space}, views, .{ .close_on_error = true, .output = .select_deadline }, &.{}, deadline_conns)
    pub fn driveCryptoBackendStep(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const closing_before = if (opts.close_on_error) closingDriveViewCount(drive_views) else 0;
        var sweep = EndpointCryptoBackendDriveSweepResult{};
        for (drive_views) |view| {
            const progress = self.driveCryptoBackendStepInner(
                view.connection_id,
                view.connection,
                spaces,
                view.backend,
                view.scratch,
                opts,
                compatibilities,
            ) catch |err| {
                self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                if (opts.close_on_error and err == error.InvalidPacket and
                    closingDriveViewCount(drive_views) > closing_before)
                {
                    return .{
                        .backend = sweep,
                        .next_deadline = if (opts.output == .select_deadline)
                            self.nextDeadlineAcrossConnections(deadline_connections)
                        else
                            null,
                    };
                }
                return err;
            };
            try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
            accumulateCryptoBackendProgress(&sweep, progress);
        }
        const next_deadline: ?EndpointConnectionDeadline = if (opts.output == .select_deadline)
            self.nextDeadlineAcrossConnections(deadline_connections)
        else
            null;
        return .{
            .backend = sweep,
            .next_deadline = next_deadline,
        };
    }

    /// Inner single-connection dispatch for driveCryptoBackendStep.
    /// Selects the Connection method based on options.
    fn driveCryptoBackendStepInner(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
    ) Error!CryptoBackendProgress {
        _ = self;
        _ = connection_id;
        const single = spaces.len == 1;
        if (opts.compatible_version) {
            if (opts.close_on_error) {
                if (single) {
                    return connection.driveCryptoBackendInSpaceWithCompatibleVersionOrClose(
                        spaces[0], backend, scratch, compatibilities,
                    );
                }
                return connection.driveCryptoBackendAcrossSpacesWithCompatibleVersionOrClose(
                    spaces, backend, scratch, compatibilities,
                );
            }
            if (single) {
                return connection.driveCryptoBackendInSpaceWithCompatibleVersion(
                    spaces[0], backend, scratch, compatibilities,
                );
            }
            return connection.driveCryptoBackendAcrossSpacesWithCompatibleVersion(
                spaces, backend, scratch, compatibilities,
            );
        }
        if (opts.close_on_error) {
            if (single) {
                return connection.driveCryptoBackendInSpaceOrClose(
                    spaces[0], backend, scratch,
                );
            }
            return connection.driveCryptoBackendAcrossSpacesOrClose(
                spaces, backend, scratch,
            );
        }
        if (single) {
            return connection.driveCryptoBackendInSpace(
                spaces[0], backend, scratch,
            );
        }
        return connection.driveCryptoBackendAcrossSpaces(
            spaces, backend, scratch,
        );
    }

    /// Unified crypto backend drive + poll output step.
    ///
    /// Replaces all driveCryptoBackend*AndPollDatagram{WithInstalledKeyOptions,}
    /// variants (normal and OrClose, InSpace and AcrossSpaces, WithCompatibleVersion).
    pub fn driveCryptoBackendStepWithPoll(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        now_nanos: i64,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        var sweep = EndpointCryptoBackendDriveSweepResult{};
        for (drive_views) |view| {
            const progress = self.driveCryptoBackendStepInner(
                view.connection_id, view.connection, spaces,
                view.backend, view.scratch, opts, compatibilities,
            ) catch |err| {
                self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                if (opts.close_on_error and spaces.len == 1 and
                    err == error.InvalidPacket and
                    view.connection.connectionState() == .closing)
                {
                    return .{
                        .backend = sweep,
                        .datagram = try self.pollDatagramForBackendClose(
                            view.connection_id, poll_views, now_nanos, poll_space,
                        ),
                        .next_deadline = self.nextDeadlineAcrossPollConnections(poll_views),
                    };
                }
                return err;
            };
            try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
            accumulateCryptoBackendProgress(&sweep, progress);
        }
        const retained_before = countRetainedHandshakeSpaces(poll_views);
        const datagram = try self.pollDatagramAcrossConnectionsAfterBackendDrive(
            poll_views, now_nanos, poll_space,
        );
        markHandshakeSpaceDiscardedIfCountDrops(
            &sweep.progress, retained_before, countRetainedHandshakeSpaces(poll_views),
        );
        return .{
            .backend = sweep,
            .datagram = datagram,
            .next_deadline = self.nextDeadlineAcrossPollConnections(poll_views),
        };
    }

    /// Unified crypto backend drive + drain output step.
    ///
    /// Replaces all driveCryptoBackend*AndDrainDatagrams{WithInstalledKeyOptions,}
    /// variants (normal and OrClose, InSpace and AcrossSpaces, WithCompatibleVersion).
    pub fn driveCryptoBackendStepWithDrain(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        now_nanos: i64,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        var sweep = EndpointCryptoBackendDriveSweepResult{};
        for (drive_views) |view| {
            const progress = self.driveCryptoBackendStepInner(
                view.connection_id, view.connection, spaces,
                view.backend, view.scratch, opts, compatibilities,
            ) catch |err| {
                self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                if (opts.close_on_error and spaces.len == 1 and
                    err == error.InvalidPacket and
                    view.connection.connectionState() == .closing)
                {
                    return .{
                        .backend = sweep,
                        .drain = try self.drainDatagramsForBackendClose(
                            view.connection_id, poll_views, now_nanos, poll_space, out,
                        ),
                        .next_deadline = self.nextDeadlineAcrossPollConnections(poll_views),
                    };
                }
                return err;
            };
            try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
            accumulateCryptoBackendProgress(&sweep, progress);
        }
        const retained_before = countRetainedHandshakeSpaces(poll_views);
        const drain = self.drainDatagramsAcrossConnectionsAfterBackendDrive(
            poll_views, now_nanos, poll_space, out,
        );
        markHandshakeSpaceDiscardedIfCountDrops(
            &sweep.progress, retained_before, countRetainedHandshakeSpaces(poll_views),
        );
        return .{
            .backend = sweep,
            .drain = drain,
            .next_deadline = self.nextDeadlineAcrossPollConnections(poll_views),
        };
    }

    /// Unified crypto backend drive + installed-key poll output step.
    ///
    /// Replaces all driveCryptoBackend*AndPollDatagramWithInstalledKeyOptions
    /// variants (normal and OrClose, InSpace and AcrossSpaces, WithCompatibleVersion).
    pub fn driveCryptoBackendStepWithInstalledKeyPoll(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        var sweep = EndpointCryptoBackendDriveSweepResult{};
        for (drive_views) |view| {
            const progress = self.driveCryptoBackendStepInner(
                view.connection_id, view.connection, spaces,
                view.backend, view.scratch, opts, compatibilities,
            ) catch |err| {
                self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                if (opts.close_on_error and spaces.len == 1 and
                    err == error.InvalidPacket and
                    view.connection.connectionState() == .closing)
                {
                    return .{
                        .backend = sweep,
                        .datagram = try self.pollDatagramWithInstalledKeyOptionsForBackendClose(
                            view.connection_id, poll_views, now_nanos,
                        ),
                        .next_deadline = self.nextDeadlineAcrossInstalledKeyPollConnections(poll_views),
                    };
                }
                return err;
            };
            try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
            accumulateCryptoBackendProgress(&sweep, progress);
        }
        const retained_before = countRetainedHandshakeSpacesWithInstalledKeyOptions(poll_views);
        const datagram = try self.pollDatagramAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
            poll_views, now_nanos,
        );
        markHandshakeSpaceDiscardedIfCountDrops(
            &sweep.progress, retained_before,
            countRetainedHandshakeSpacesWithInstalledKeyOptions(poll_views),
        );
        return .{
            .backend = sweep,
            .datagram = datagram,
            .next_deadline = self.nextDeadlineAcrossInstalledKeyPollConnections(poll_views),
        };
    }

    /// Unified crypto backend drive + installed-key drain output step.
    ///
    /// Replaces all driveCryptoBackend*AndDrainDatagramsWithInstalledKeyOptions
    /// variants (normal and OrClose, InSpace and AcrossSpaces, WithCompatibleVersion).
    pub fn driveCryptoBackendStepWithInstalledKeyDrain(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        var sweep = EndpointCryptoBackendDriveSweepResult{};
        for (drive_views) |view| {
            const progress = self.driveCryptoBackendStepInner(
                view.connection_id, view.connection, spaces,
                view.backend, view.scratch, opts, compatibilities,
            ) catch |err| {
                self.refreshRecoveryTimerAfterConnectionError(view.connection_id, view.connection);
                if (opts.close_on_error and spaces.len == 1 and
                    err == error.InvalidPacket and
                    view.connection.connectionState() == .closing)
                {
                    return .{
                        .backend = sweep,
                        .drain = try self.drainDatagramsWithInstalledKeyOptionsForBackendClose(
                            view.connection_id, poll_views, now_nanos, out,
                        ),
                        .next_deadline = self.nextDeadlineAcrossInstalledKeyPollConnections(poll_views),
                    };
                }
                return err;
            };
            try self.armRecoveryTimerFromConnection(view.connection_id, view.connection);
            accumulateCryptoBackendProgress(&sweep, progress);
        }
        const retained_before = countRetainedHandshakeSpacesWithInstalledKeyOptions(poll_views);
        const drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptionsAfterBackendDrive(
            poll_views, now_nanos, out,
        );
        markHandshakeSpaceDiscardedIfCountDrops(
            &sweep.progress, retained_before,
            countRetainedHandshakeSpacesWithInstalledKeyOptions(poll_views),
        );
        return .{
            .backend = sweep,
            .drain = drain,
            .next_deadline = self.nextDeadlineAcrossInstalledKeyPollConnections(poll_views),
        };
    }


    /// Drive one backend, then select the next endpoint-visible deadline.
    ///
    /// This is the single-connection no-output backend-drive step for simple
    /// socket loops.
    pub fn driveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendStep(&.{space}, &drive_views, .{ .output = .select_deadline }, &.{}, &deadline_connections);
    }










    /// Drive one backend, then poll one installed-key datagram.
    ///
    /// This is the single-connection backend-drive-to-datagram step for simple
    /// socket loops that do not need to manually build drive and poll view
    /// slices.
    pub fn driveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithPoll(&.{space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space);
    }

    /// Drive one backend, then poll explicit installed-key output.
    ///
    /// This is the single-backend form of
    /// `driveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    /// It keeps backend ownership simple while allowing output to be selected
    /// from caller-provided installed-key poll views.
    pub fn driveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyPoll(&.{space}, &drive_views, .{}, &.{}, poll_views, now_nanos);
    }



    /// Drive one backend, then drain installed-key output.
    ///
    /// This is the single-connection bounded-output backend-drive step for
    /// simple socket loops that do not need to manually build drive and poll
    /// view slices.
    pub fn driveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithDrain(&.{space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space, out);
    }

    /// Drive one backend, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `driveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(&.{space}, &drive_views, .{}, &.{}, poll_views, now_nanos, out);
    }

    /// Drive crypto backends across caller-owned connections with close propagation.
    ///
    /// This is the sweep form of
    /// `driveCryptoBackendInSpaceOrCloseAndArmConnection()`. It returns on the
    /// first backend/transport-parameter error so the socket loop can surface
    /// that connection error without hiding it behind later backend progress.
    pub fn driveCryptoBackendsInSpaceOrCloseAndArmConnections(
        self: *EndpointConnectionLifecycle,
        space: PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendInSpaceOrCloseAndArmConnection(
                view.connection_id,
                view.connection,
                space,
                view.backend,
                view.scratch,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }


    /// Drive one close-propagating backend, then select the next deadline.
    ///
    /// This is the single-connection no-output form for socket loops that want
    /// close propagation but do not need to poll output in the same step.
    pub fn driveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendStep(&.{space}, &drive_views, .{ .close_on_error = true, .output = .select_deadline }, &.{}, &deadline_connections);
    }



    /// Drive one close-propagating backend, then poll one installed-key datagram.
    ///
    /// Peer transport-parameter errors queue CONNECTION_CLOSE and return before
    /// output polling.
    pub fn driveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithPoll(&.{space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space);
    }

    /// Drive one close-propagating backend, then poll explicit installed-key output.
    ///
    /// This is the single-backend form of
    /// `driveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyPoll(&.{space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos);
    }


    /// Drive close-propagating backends, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `driveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
/// Drive close-propagating backends, then drain installed-key output.
    ///
    /// Peer transport-parameter errors return before output draining. Successful
    /// backend progress uses the same bounded drain contract as
    /// `drainDatagramsAcrossConnections()`.
    pub fn driveCryptoBackendsInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        now_nanos: i64,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        return self.driveCryptoBackendStepWithDrain(&.{space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, poll_space, out);
    
    }



    /// Drive one close-propagating backend, then drain installed-key output.
    ///
    /// Peer transport-parameter errors queue CONNECTION_CLOSE and return before
    /// any output slot is initialized.
    pub fn driveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithDrain(&.{space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space, out);
    }

    /// Drive one close-propagating backend, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `driveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(&.{space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out);
    }

    /// Drive a crypto backend and queue transport close on peer-parameter errors.
    ///
    /// This is the endpoint lifecycle wrapper for
    /// `Connection.driveCryptoBackendInSpaceOrClose()`. It refreshes endpoint
    /// recovery scheduling after both success and close-propagating errors so
    /// socket loops keep their connection-handle timer snapshot aligned with
    /// the connection state.
    pub fn driveCryptoBackendInSpaceOrCloseAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendInSpaceOrClose(space, backend, scratch) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }

    /// Drive a compatible-version crypto backend under endpoint lifecycle ownership.
    ///
    /// This is the endpoint wrapper for
    /// `Connection.driveCryptoBackendInSpaceWithCompatibleVersion()`. It is the
    /// RFC 9368 server-side TLS backend path when the peer's Version
    /// Information transport parameter can select an explicitly allowed
    /// compatible version.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendInSpaceWithCompatibleVersion(
            space,
            backend,
            scratch,
            compatibilities,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }


    /// Drive compatible-version crypto backends across caller-owned connections.
    ///
    /// This is the sweep form of
    /// `driveCryptoBackendInSpaceWithCompatibleVersionAndArmConnection()`. It is
    /// the endpoint-owned loop path for RFC 9368-compatible server handshakes
    /// when multiple caller-owned connections share one event-loop iteration.
    pub fn driveCryptoBackendsInSpaceWithCompatibleVersionAndArmConnections(
        self: *EndpointConnectionLifecycle,
        space: PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendInSpaceWithCompatibleVersionAndArmConnection(
                view.connection_id,
                view.connection,
                space,
                view.backend,
                view.scratch,
                compatibilities,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }



    /// Drive one compatible-version backend across ordered packet number
    /// spaces, then select the next deadline.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendStep(spaces, &drive_views, .{ .compatible_version = true, .output = .select_deadline }, compatibilities, &deadline_connections);
    }


    /// Drive one compatible-version backend across ordered packet number spaces,
    /// then poll installed-key output.
    /// Drive one compatible-version backend across ordered packet number spaces,
    /// then poll explicit installed-key output.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyPoll(spaces, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos);
    }


    /// Drive one compatible-version backend across ordered packet number spaces,
    /// then drain installed-key output.
    /// Drive one compatible-version backend across ordered packet number spaces,
    /// then drain explicit installed-key output.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(spaces, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, out);
    }


    /// Drive one compatible-version backend, then select the next deadline.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendStep(&.{space}, &drive_views, .{ .compatible_version = true, .output = .select_deadline }, compatibilities, &deadline_connections);
    }



    /// Drive one compatible-version backend, then poll one installed-key datagram.
    ///
    /// This is the single-connection form of
    /// `driveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithPoll(&.{space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space);
    }

    /// Drive one compatible-version backend, then poll explicit installed-key output.
    ///
    /// This is the single-backend form of
    /// `driveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyPoll(&.{space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos);
    }



    /// Drive one compatible-version backend, then drain installed-key output.
    ///
    /// This is the single-connection form of
    /// `driveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagrams()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithDrain(&.{space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out);
    }

    /// Drive one compatible-version backend, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `driveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(&.{space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, out);
    }

    /// Drive a compatible-version backend and queue transport close on errors.
    ///
    /// This wraps `Connection.driveCryptoBackendInSpaceWithCompatibleVersionOrClose()`
    /// and refreshes endpoint recovery scheduling after both success and
    /// close-propagating peer Version Information errors.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendInSpaceWithCompatibleVersionOrClose(
            space,
            backend,
            scratch,
            compatibilities,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }

    /// Drive a compatible-version backend across ordered packet number spaces
    /// and queue transport close on negotiation errors.
    ///
    /// This wraps `Connection.driveCryptoBackendAcrossSpacesWithCompatibleVersionOrClose()`
    /// and refreshes endpoint recovery scheduling after both success and
    /// close-propagating peer Version Information errors.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionOrCloseAndArmConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!CryptoBackendProgress {
        const progress = connection.driveCryptoBackendAcrossSpacesWithCompatibleVersionOrClose(
            spaces,
            backend,
            scratch,
            compatibilities,
        ) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return progress;
    }

    /// Drive compatible-version crypto backends with close propagation.
    ///
    /// This is the sweep form of
    /// `driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndArmConnection()`.
    /// It stops on the first peer Version Information error so the socket loop
    /// can surface the connection close without hiding it behind later backend
    /// work.
    pub fn driveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndArmConnections(
        self: *EndpointConnectionLifecycle,
        space: PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndArmConnection(
                view.connection_id,
                view.connection,
                space,
                view.backend,
                view.scratch,
                compatibilities,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }

    /// Drive compatible-version crypto backends across ordered packet number
    /// spaces with close propagation.
    ///
    /// This is the cross-space form of
    /// `driveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndArmConnections()`.
    pub fn driveCryptoBackendsAcrossSpacesWithCompatibleVersionOrCloseAndArmConnections(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveSweepResult {
        var result = EndpointCryptoBackendDriveSweepResult{};
        for (views) |view| {
            const progress = try self.driveCryptoBackendAcrossSpacesWithCompatibleVersionOrCloseAndArmConnection(
                view.connection_id,
                view.connection,
                spaces,
                view.backend,
                view.scratch,
                compatibilities,
            );
            accumulateCryptoBackendProgress(&result, progress);
        }
        return result;
    }

    /// Drive compatible-version close-propagating backends across ordered
    /// packet number spaces, then select the next deadline.
    pub fn driveCryptoBackendsAcrossSpacesWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        return self.driveCryptoBackendStep(spaces, drive_views, .{ .close_on_error = true, .compatible_version = true, .output = .select_deadline }, compatibilities, deadline_connections);
    }

    /// Drive one compatible-version close-propagating backend across ordered
    /// packet number spaces, then select the next deadline.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendsAcrossSpacesWithCompatibleVersionOrCloseAndSelectNextDeadline(
            spaces,
            &drive_views,
            compatibilities,
            &deadline_connections,
        );
    }

    /// Drive one compatible-version close-propagating backend across ordered
    /// packet number spaces, then drain installed-key output.
    /// Drive one compatible-version close-propagating backend across ordered
    /// packet number spaces, then drain explicit installed-key output.
    pub fn driveCryptoBackendAcrossSpacesWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(spaces, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, out);
    }


    /// Drive one compatible-version close path, then select the next deadline.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const deadline_connections = [_]EndpointConnectionView{.{
            .connection_id = connection_id,
            .connection = connection,
        }};
        return self.driveCryptoBackendStep(&.{space}, &drive_views, .{ .close_on_error = true, .compatible_version = true, .output = .select_deadline }, compatibilities, &deadline_connections);
    }



    /// Drive one compatible-version close path, then poll one installed-key datagram.
    ///
    /// Peer Version Information errors that move the connection into closing
    /// return the protected close datagram in the same step.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithPoll(&.{space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space);
    }

    /// Drive one compatible-version close path, then poll explicit installed-key output.
    ///
    /// This is the single-backend form of
    /// `driveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyPoll(&.{space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos);
    }



    /// Drive one compatible-version close path, then drain installed-key output.
    ///
    /// Peer Version Information errors that move the connection into closing
    /// drain the protected close datagram in the same step.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return self.driveCryptoBackendStepWithDrain(&.{space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out);
    }

    /// Drive one compatible-version close path, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return self.driveCryptoBackendStepWithInstalledKeyDrain(&.{space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, out);
    }

    /// Service one connection's due loss/PTO timer and refresh endpoint state.
    pub fn serviceRecoveryTimer(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!?EndpointLossDetectionTimerDeadline {
        return self.recovery_timers.serviceConnection(connection_id, connection, now_nanos);
    }

    /// Process one pending-work pass for a caller-owned connection.
    ///
    /// The endpoint lifecycle owns the ordering expected by socket loops:
    /// terminal idle timeout first, close/drain timeout second, and loss/PTO
    /// recovery service only while the connection remains live.
    pub fn processPendingWork(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!EndpointPendingWorkResult {
        var result = EndpointPendingWorkResult{};

        result.idle_retired = try self.checkIdleTimeoutsAndRetireConnection(
            connection_id,
            connection,
            now_nanos,
        );
        if (result.idle_retired != null) return result;

        result.close_retired = try self.checkCloseTimeoutsAndRetireConnection(
            connection_id,
            connection,
            now_nanos,
        );
        if (result.close_retired != null) return result;

        result.key_discard_serviced = connection.discardExpiredOneRttKeys(now_nanos);

        result.recovery_serviced = try self.serviceRecoveryTimer(
            connection_id,
            connection,
            now_nanos,
        );
        return result;
    }

    /// Sweep pending work across caller-owned connections.
    ///
    /// This keeps idle/close retirement and recovery timer servicing under the
    /// endpoint lifecycle owner while the caller keeps connection storage and
    /// iteration order. It does not poll output; socket loops should use
    /// `pollDatagramAcrossConnections()` or due-deadline helpers for datagrams.
    pub fn processPendingWorkAcrossConnections(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
    ) Error!EndpointPendingWorkSweepResult {
        var sweep = EndpointPendingWorkSweepResult{};
        for (connections) |view| {
            const pending = try self.processPendingWork(
                view.connection_id,
                view.connection,
                now_nanos,
            );
            if (pending.idle_retired != null) {
                sweep.idle_retired_count += 1;
            }
            if (pending.close_retired != null) {
                sweep.close_retired_count += 1;
            }
            if (pending.key_discard_serviced) {
                sweep.key_discard_serviced_count += 1;
            }
            if (pending.recovery_serviced != null) {
                sweep.recovery_serviced_count += 1;
            }
        }
        return sweep;
    }

    // -----------------------------------------------------------------------
    // Unified processPendingWork + crypto backend drive steps
    // -----------------------------------------------------------------------

    /// Unified pending-work sweep + crypto backend drive + deadline selection.
    ///
    /// Replaces all processPendingWorkAcrossConnectionsAndDriveCryptoBackends*
    /// AndSelectNextDeadline variants (12 combinatorial suffixes).
    pub fn processPendingWorkStepWithCryptoDeadline(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .backend = try self.driveCryptoBackendStep(
                spaces, drive_views, .{ .close_on_error = crypto_opts.close_on_error, .compatible_version = crypto_opts.compatible_version, .output = .select_deadline }, compatibilities, deadline_connections,
            ),
        };
    }

    /// Unified pending-work sweep + crypto backend drive + poll output.
    ///
    /// Replaces all processPendingWorkAcrossConnectionsAndDriveCryptoBackends*
    /// AndPollDatagram{WithInstalledKeyOptions,} variants.
    pub fn processPendingWorkStepWithCryptoPoll(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .backend = try self.driveCryptoBackendStepWithPoll(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos, poll_space,
            ),
        };
    }

    /// Unified pending-work sweep + crypto backend drive + drain output.
    ///
    /// Replaces all processPendingWorkAcrossConnectionsAndDriveCryptoBackends*
    /// AndDrainDatagrams{WithInstalledKeyOptions,} variants.
    pub fn processPendingWorkStepWithCryptoDrain(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .backend = try self.driveCryptoBackendStepWithDrain(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos, poll_space, out,
            ),
        };
    }

    /// Unified pending-work sweep + crypto backend drive + installed-key poll.
    pub fn processPendingWorkStepWithCryptoInstalledKeyPoll(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos,
            ),
        };
    }

    /// Unified pending-work sweep + crypto backend drive + installed-key drain.
    pub fn processPendingWorkStepWithCryptoInstalledKeyDrain(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos, out,
            ),
        };
    }

    /// Process pending work, then select the next endpoint-visible deadline.
    ///
    /// This is the no-output wakeup planning step for socket loops. It applies
    /// endpoint-owned idle/close/recovery work first, then returns the next
    /// deadline from the still caller-owned connection map so callers can
    /// update their timer without duplicating lifecycle ordering.
    pub fn processPendingWorkAcrossConnectionsAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        now_nanos: i64,
    ) Error!EndpointPendingWorkNextDeadlineResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        return .{
            .pending_work = pending_work,
            .next_deadline = self.nextDeadlineAcrossConnections(deadline_connections),
        };
    }

    /// Process one connection's pending work, then select its next deadline.
    ///
    /// This is the single-connection no-output wakeup planning step for simple
    /// socket loops. It applies endpoint-owned idle/close/recovery work first,
    /// then returns the next endpoint-visible deadline without polling output
    /// or driving a backend.
    pub fn processPendingWorkAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!EndpointPendingWorkNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        return .{
            .pending_work = pendingWorkSweepFromSingle(pending_work),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process pending work across connections, then poll installed-key output.
    ///
    /// This is the no-backend cross-connection timer tick for socket loops.
    /// It first sweeps idle/close cleanup and recovery timer service across
    /// caller-owned connections. If no recovery timer was serviced, it does
    /// not poll ordinary queued output; callers should use
    /// `pollDatagramAcrossConnections()` for normal send readiness.
    pub fn processPendingWorkAcrossConnectionsAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!EndpointPendingWorkSweepDatagramResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        if (pending_work.recovery_serviced_count == 0) {
            return .{
                .pending_work = pending_work,
                .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
            };
        }

        return .{
            .pending_work = pending_work,
            .datagram = try self.pollDatagramAcrossConnections(
                poll_views,
                now_nanos,
                poll_space,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
        };
    }

    /// Process pending work across connections, then poll with explicit output options.
    ///
    /// This is the caller-owned connection map form for timer ticks that need
    /// pending recovery work to keep non-default installed-key packetization,
    /// such as accepted 0-RTT recovery probes.
    pub fn processPendingWorkAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkSweepDatagramResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        if (pending_work.recovery_serviced_count == 0) {
            return .{
                .pending_work = pending_work,
                .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
            };
        }

        return .{
            .pending_work = pending_work,
            .datagram = try self.pollDatagramAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
        };
    }

    /// Process pending work across connections, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAcrossConnectionsAndPollDatagram()`. The caller-owned
    /// output slice bounds how much timer-triggered send work one socket-loop
    /// iteration performs.
    pub fn processPendingWorkAcrossConnectionsAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkSweepDatagramDrainResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        if (pending_work.recovery_serviced_count == 0) {
            return .{
                .pending_work = pending_work,
                .drain = .{},
                .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
            };
        }

        return .{
            .pending_work = pending_work,
            .drain = self.drainDatagramsAcrossConnections(
                poll_views,
                now_nanos,
                poll_space,
                out,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
        };
    }

    /// Process pending work across connections, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAcrossConnectionsAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAcrossConnectionsAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        pending_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkSweepDatagramDrainResult {
        const pending_work = try self.processPendingWorkAcrossConnections(
            pending_connections,
            now_nanos,
        );
        if (pending_work.recovery_serviced_count == 0) {
            return .{
                .pending_work = pending_work,
                .drain = .{},
                .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
            };
        }

        return .{
            .pending_work = pending_work,
            .drain = self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
                poll_views,
                now_nanos,
                out,
            ),
            .next_deadline = self.nextDeadlineAcrossReceiveConnections(pending_connections),
        };
    }



















    fn pendingWorkSweepFromSingle(pending_work: EndpointPendingWorkResult) EndpointPendingWorkSweepResult {
        return .{
            .idle_retired_count = if (pending_work.idle_retired != null) 1 else 0,
            .close_retired_count = if (pending_work.close_retired != null) 1 else 0,
            .key_discard_serviced_count = if (pending_work.key_discard_serviced) 1 else 0,
            .recovery_serviced_count = if (pending_work.recovery_serviced != null) 1 else 0,
        };
    }

    /// Process pending work, drive one backend, then select the next deadline.
    ///
    /// This is the single-connection no-output timer/backend planning step.
    /// Terminal idle or close cleanup stops before backend progress; live
    /// connections then drive the caller-owned backend and return the
    /// post-backend endpoint-visible deadline without polling datagrams.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .next_deadline = self.nextDeadline(connection_id, connection),
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
            ),
        };
    }

    /// Process pending work, drive one close-propagating backend, then select a deadline.
    ///
    /// This is the OrClose form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndSelectNextDeadline()`.
    /// Terminal idle or close cleanup stops before backend progress. Live
    /// connections continue into backend drive, where peer transport-parameter
    /// errors queue CONNECTION_CLOSE before returning.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .next_deadline = self.nextDeadline(connection_id, connection),
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
            ),
        };
    }

    /// Process pending work, drive one compatible-version backend, then select a deadline.
    ///
    /// This is the single-connection RFC 9368-compatible no-output
    /// timer/backend planning step. Terminal idle or close cleanup stops
    /// before backend progress; live connections then apply compatible Version
    /// Information through backend drive and return the post-backend deadline.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .next_deadline = self.nextDeadline(connection_id, connection),
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Process pending work, drive one compatible-version backend across
    /// ordered packet number spaces, then select the next deadline.
    ///
    /// This is the single-connection cross-space form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline()`.
    pub fn processPendingWorkAndDriveCryptoBackendAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .next_deadline = self.nextDeadline(connection_id, connection),
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
                connection_id,
                connection,
                backend_spaces,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Process pending work, drive one compatible-version close path, then select a deadline.
    ///
    /// This is the close-propagating RFC 9368-compatible form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline()`.
    /// Terminal idle or close cleanup stops before backend progress. Live
    /// connections continue into the compatible OrClose backend drive, where
    /// peer Version Information errors queue CONNECTION_CLOSE before returning.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointPendingWorkCryptoBackendNextDeadlineResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .next_deadline = self.nextDeadline(connection_id, connection),
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }
    /// Process pending work, drive one backend, then poll installed-key output.
    ///
    /// This is the single-connection output-polling form for no-new-datagram
    /// socket-loop ticks. Terminal idle or close cleanup stops before backend
    /// progress; live connections then drive the caller-owned backend and poll
    /// one installed-key datagram.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process pending work, drive one backend, then drain installed-key output.
    ///
    /// This is the single-connection bounded-output form for no-new-datagram
    /// socket-loop ticks. Terminal idle or close cleanup stops the step before
    /// backend progress; live connections then drive the caller-owned backend
    /// and drain installed-key output with the caller-provided work budget.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process pending work, drive one backend across ordered packet number
    /// spaces, then poll installed-key output.
    ///
    /// This is the single-connection cross-space form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagram()`.
    /// Process pending work, drive one backend across ordered packet number
    /// spaces, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendAcrossSpacesAndPollDatagram()`.
    /// Process pending work, drive close-propagating backend, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndDrainDatagrams()`.
    /// Terminal idle or close cleanup stops before backend progress; backend
    /// peer transport-parameter errors queue CONNECTION_CLOSE and return
    /// before any installed-key output drain is attempted.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process pending work, drive close-propagating backend, then poll output.
    ///
    /// Terminal idle or close cleanup stops before backend progress; backend
    /// peer transport-parameter errors queue CONNECTION_CLOSE and return
    /// before installed-key output polling.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process pending work, drive one close-propagating backend across ordered
    /// packet number spaces, then poll installed-key output.
    ///
    /// This is the single-connection cross-space form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram()`.
    /// Process pending work, drive one close-propagating backend across ordered
    /// packet number spaces, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagram()`.
    /// Process pending work, drive one compatible-version backend, then drain output.
    ///
    /// This is the single-connection bounded-output form for no-new-datagram
    /// RFC 9368-compatible handshake ticks. Terminal idle or close cleanup
    /// stops before backend progress; live connections then drive the
    /// caller-owned backend with explicit compatible-version rules.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process pending work, drive one compatible-version backend, then poll output.
    ///
    /// This is the single-connection output-polling form for no-new-datagram
    /// RFC 9368-compatible handshake ticks.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process pending work, drive compatible-version close path, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams()`.
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// any installed-key output drain is attempted.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process pending work, drive compatible-version close path, then poll output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// installed-key output polling.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process pending work, drive one backend, then poll explicit installed-key output.
    ///
    /// This is the explicit-output form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagram()`.
    /// Terminal idle or close cleanup stops before backend progress; live
    /// connections preserve caller-selected installed-key output views.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                poll_views,
                now_nanos,
            ),
        };
    }

    /// Process pending work, drive one backend, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                poll_views,
                now_nanos,
                out,
            ),
        };
    }

    /// Process pending work, drive one backend across ordered packet number
    /// spaces, then poll explicit installed-key output.
    ///
    /// This is the single-connection cross-space form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendAcrossSpacesAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, &drive_views, .{}, &.{}, poll_views, now_nanos),
        };
    }

    /// Process pending work, drive one backend across ordered packet number
    /// spaces, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendAcrossSpacesAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendAcrossSpacesAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(backend_spaces, &drive_views, .{}, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process pending work, drive one close-propagating backend, then poll explicit output.
    ///
    /// Peer transport-parameter errors return before output polling. Successful
    /// live ticks preserve caller-selected installed-key output views.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                poll_views,
                now_nanos,
            ),
        };
    }

    /// Process pending work, drive one close-propagating backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                poll_views,
                now_nanos,
                out,
            ),
        };
    }

    /// Process pending work, drive one close-propagating backend across ordered
    /// packet number spaces, then poll explicit installed-key output.
    ///
    /// This is the single-connection cross-space form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos),
        };
    }

    /// Process pending work, drive one close-propagating backend across ordered
    /// packet number spaces, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendAcrossSpacesOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process pending work, drive one compatible-version backend, then poll explicit output.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_views,
                now_nanos,
            ),
        };
    }

    /// Process pending work, drive one compatible-version backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_views,
                now_nanos,
                out,
            ),
        };
    }

    /// Process pending work, drive one compatible-version close path, then poll explicit output.
    ///
    /// Peer Version Information errors return before installed-key output polling.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!EndpointPendingWorkCryptoBackendDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .datagram = null,
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_views,
                now_nanos,
            ),
        };
    }

    /// Process pending work, drive one compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processPendingWorkAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkCryptoBackendDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const pending_sweep = pendingWorkSweepFromSingle(pending_work);
        if (pending_work.idle_retired != null or pending_work.close_retired != null) {
            return .{
                .pending_work = pending_sweep,
                .backend = .{
                    .backend = .{},
                    .drain = .{},
                },
            };
        }

        return .{
            .pending_work = pending_sweep,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_views,
                now_nanos,
                out,
            ),
        };
    }

    /// Process pending work and poll the installed-key datagram caused by recovery.
    ///
    /// Normal queued output should use `pollDatagram()` directly. This helper
    /// only polls after a due loss/PTO timer was serviced, so timer wakeups in
    /// socket loops can be handled without duplicating endpoint lifecycle
    /// ordering.
    pub fn processPendingWorkAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointPendingWorkDatagramResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const serviced = pending_work.recovery_serviced orelse return .{
            .pending_work = pending_work,
            .datagram = null,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
        if (serviced.timer.space != options.recoveryPacketNumberSpace()) return error.InvalidPacket;

        return .{
            .pending_work = pending_work,
            .datagram = try self.pollDatagram(connection_id, connection, now_nanos, options),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process pending work and drain installed-key datagrams caused by recovery.
    ///
    /// This is the bounded-output form of `processPendingWorkAndPollDatagram()`.
    /// It only drains after a due loss/PTO timer was serviced and keeps the
    /// caller-owned output slice as the per-iteration work budget.
    pub fn processPendingWorkAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointPendingWorkDatagramDrainResult {
        const pending_work = try self.processPendingWork(connection_id, connection, now_nanos);
        const serviced = pending_work.recovery_serviced orelse return .{
            .pending_work = pending_work,
            .drain = .{},
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
        if (serviced.timer.space != options.recoveryPacketNumberSpace()) return error.InvalidPacket;

        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = options.destination_connection_id,
            .source_connection_id = options.source_connection_id,
        }};
        return .{
            .pending_work = pending_work,
            .drain = self.drainDatagramsAcrossConnections(
                &poll_views,
                now_nanos,
                options.space,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    fn installedKeyOptionsMatchRecoveryDeadline(
        deadline: EndpointConnectionDeadline,
        options: EndpointPollInstalledKeyDatagramOptions,
    ) bool {
        if (deadline.kind != .recovery) return false;
        const timer = deadline.recovery orelse return false;
        return timer.space == options.recoveryPacketNumberSpace();
    }

    // -----------------------------------------------------------------------
    // Unified processDueDeadline + crypto backend drive steps
    // -----------------------------------------------------------------------

    /// Unified due-deadline processing + crypto backend drive + deadline selection.
    ///
    /// Replaces all processDueDeadlineAcrossConnectionsAndDriveCryptoBackends*
    /// AndSelectNextDeadline variants.
    pub fn processDueDeadlineStepWithCryptoDeadline(
        self: *EndpointConnectionLifecycle,
        due_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        deadline_connections: []const EndpointConnectionView,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndSelectNextDeadline(
            due_connections,
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStep(
                spaces, drive_views,
                .{ .close_on_error = crypto_opts.close_on_error, .compatible_version = crypto_opts.compatible_version, .output = .select_deadline },
                compatibilities, deadline_connections,
            ),
        };
    }

    /// Unified due-deadline processing + crypto backend drive + poll output.
    pub fn processDueDeadlineStepWithCryptoPoll(
        self: *EndpointConnectionLifecycle,
        due_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndSelectNextDeadline(
            due_connections,
            &.{},
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos, poll_space,
            ),
        };
    }

    /// Unified due-deadline processing + crypto backend drive + drain output.
    pub fn processDueDeadlineStepWithCryptoDrain(
        self: *EndpointConnectionLifecycle,
        due_connections: []const EndpointConnectionReceiveView,
        now_nanos: i64,
        spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        crypto_opts: lifecycle_opts.CryptoDriveStepOptions,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndSelectNextDeadline(
            due_connections,
            &.{},
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(
                spaces, drive_views, crypto_opts, compatibilities,
                poll_views, now_nanos, poll_space, out,
            ),
        };
    }


    /// Process a due recovery deadline with caller-selected installed-key output.
    ///
    /// Use this when Application recovery should poll 0-RTT output instead of
    /// the default 1-RTT mapping from `installedKeyPollOptions()`. Non-recovery
    /// deadlines still run pending work and return no datagram. A packet-space
    /// mismatch is rejected before recovery state is mutated.
    pub fn processDueDeadlineAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkDatagramResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        const pending_datagram = if (deadline.kind == .recovery) pending: {
            if (!installedKeyOptionsMatchRecoveryDeadline(deadline, options)) return error.InvalidPacket;
            break :pending try self.processPendingWorkAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                options,
            );
        } else EndpointPendingWorkDatagramResult{
            .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
            .datagram = null,
        };

        return .{
            .deadline = deadline,
            .pending_work = pending_datagram.pending_work,
            .datagram = pending_datagram.datagram,
        };
    }

    /// Process a due recovery deadline with caller-selected installed-key drain.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndPollDatagramWithInstalledKeyOptions()`. It lets a
    /// socket loop service an Application recovery timer with explicit 0-RTT
    /// output options while preserving the caller-owned drain budget.
    pub fn processDueDeadlineAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkDatagramDrainResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        const pending_drain = if (deadline.kind == .recovery) pending: {
            if (!installedKeyOptionsMatchRecoveryDeadline(deadline, options)) return error.InvalidPacket;
            if (out.len == 0) return error.BufferTooSmall;
            break :pending try self.processPendingWorkAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                options,
                out,
            );
        } else EndpointPendingWorkDatagramDrainResult{
            .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
            .drain = .{},
        };

        return .{
            .deadline = deadline,
            .pending_work = pending_drain.pending_work,
            .drain = pending_drain.drain,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process the due endpoint-visible deadline for one connection handle.
    ///
    /// Socket loops can call this after waking from `nextDeadline()`. Calls
    /// before the current deadline return null and do not touch connection or
    /// endpoint state. Due recovery deadlines that map to installed-key packet
    /// spaces also poll the probe datagram; idle, close, and Initial recovery
    /// deadlines only run pending work.
    pub fn processDueDeadlineAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        destination_connection_id: []const u8,
        source_connection_id: []const u8,
    ) Error!?EndpointDueWorkDatagramResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        const pending_datagram = if (deadline.installedKeyPollOptions(
            destination_connection_id,
            source_connection_id,
        )) |options|
            try self.processPendingWorkAndPollDatagram(connection_id, connection, now_nanos, options)
        else
            EndpointPendingWorkDatagramResult{
                .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
                .datagram = null,
            };

        return .{
            .deadline = deadline,
            .pending_work = pending_datagram.pending_work,
            .datagram = pending_datagram.datagram,
        };
    }

    /// Process the due endpoint-visible deadline and drain installed-key output.
    ///
    /// This is the bounded-output form of `processDueDeadlineAndPollDatagram()`.
    /// Calls before the current deadline return null. Due idle/close deadlines
    /// run pending work and return an empty drain result; due installed-key
    /// recovery deadlines reuse `processPendingWorkAndDrainDatagrams()`.
    pub fn processDueDeadlineAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        destination_connection_id: []const u8,
        source_connection_id: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkDatagramDrainResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        const pending_drain = if (deadline.installedKeyPollOptions(
            destination_connection_id,
            source_connection_id,
        )) |options| pending: {
            if (out.len == 0) return error.BufferTooSmall;
            break :pending try self.processPendingWorkAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                options,
                out,
            );
        } else EndpointPendingWorkDatagramDrainResult{
            .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
            .drain = .{},
        };

        return .{
            .deadline = deadline,
            .pending_work = pending_drain.pending_work,
            .drain = pending_drain.drain,
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one due deadline, then select the connection's next deadline.
    ///
    /// This is the single-connection no-output due-deadline wakeup step for
    /// simple socket loops. It applies due idle/close/recovery work for the
    /// caller-owned connection and returns the connection's next
    /// endpoint-visible deadline after the lifecycle state has been refreshed.
    pub fn processDueDeadlineAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!?EndpointDueWorkNextDeadlineResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        return .{
            .deadline = deadline,
            .pending_work = try self.processPendingWork(
                connection_id,
                connection,
                now_nanos,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process the earliest due deadline, then select the next deadline.
    ///
    /// This is the no-output due-deadline wakeup step for embeddable socket
    /// loops. It processes only the earliest already-due connection from the
    /// caller-owned mutable view slice, then recomputes the next
    /// endpoint-visible deadline from the caller-owned scheduling view.
    pub fn processDueDeadlineAcrossConnectionsAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        due_connections: []const EndpointConnectionReceiveView,
        deadline_connections: []const EndpointConnectionView,
        now_nanos: i64,
    ) Error!?EndpointDueWorkNextDeadlineResult {
        var selected_index: ?usize = null;
        var selected_deadline: ?EndpointConnectionDeadline = null;
        for (due_connections, 0..) |view, index| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (candidate.deadline_nanos > now_nanos) continue;
            if (selected_deadline == null or candidate.deadline_nanos < selected_deadline.?.deadline_nanos) {
                selected_index = index;
                selected_deadline = candidate;
            }
        }

        const index = selected_index orelse return null;
        const view = due_connections[index];
        return .{
            .deadline = selected_deadline.?,
            .pending_work = try self.processPendingWork(
                view.connection_id,
                view.connection,
                now_nanos,
            ),
            .next_deadline = self.nextDeadlineAcrossConnections(deadline_connections),
        };
    }

    /// Process one due deadline, drive one backend, then select the next deadline.
    ///
    /// This is the single-connection no-output due-deadline/backend planning
    /// step for simple socket loops. Terminal idle/close deadlines stop before
    /// backend progress because the caller-owned connection is no longer live.
    /// Live due work continues into backend drive and returns the post-backend
    /// endpoint-visible deadline.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAndSelectNextDeadline(
            connection_id,
            connection,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
            ),
        };
    }

    /// Process one due deadline, drive one close-propagating backend, then select a deadline.
    ///
    /// This is the close-propagating form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndSelectNextDeadline()`.
    /// Terminal idle/close deadlines stop before backend progress. Live due
    /// work continues into the OrClose backend drive, where backend peer
    /// transport-parameter errors queue CONNECTION_CLOSE before returning.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAndSelectNextDeadline(
            connection_id,
            connection,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
            ),
        };
    }
    /// Process one due deadline, drive one compatible-version backend, then select a deadline.
    ///
    /// This is the RFC 9368-compatible single-connection no-output form of the
    /// due-deadline backend planning step. Terminal idle/close deadlines stop
    /// before backend progress; live due work continues into compatible-version
    /// backend drive before the lifecycle recomputes the next wakeup.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAndSelectNextDeadline(
            connection_id,
            connection,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Process one due deadline, drive one compatible-version backend across
    /// ordered packet number spaces, then select a deadline.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline()`.
    pub fn processDueDeadlineAndDriveCryptoBackendAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAndSelectNextDeadline(
            connection_id,
            connection,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendAcrossSpacesWithCompatibleVersionAndSelectNextDeadline(
                connection_id,
                connection,
                backend_spaces,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Process one due deadline, drive one compatible-version close path, then select a deadline.
    ///
    /// This is the close-propagating RFC 9368-compatible single-connection
    /// no-output due-deadline backend planning step. Terminal idle/close
    /// deadlines stop before backend progress. Live due work continues into
    /// the compatible OrClose backend drive, where peer Version Information
    /// errors queue CONNECTION_CLOSE before returning.
    /// Unified due-deadline processing with options-struct interface.
    ///
    /// Replaces 10+ processDueDeadline variants:
    ///   processDueDeadlineAndPollDatagram
    ///   processDueDeadlineAndDrainDatagrams
    ///   processDueDeadlineAndSelectNextDeadline
    ///   processDueDeadlineAcrossConnectionsAndSelectNextDeadline
    ///   processDueDeadlineAndDriveCryptoBackendInSpaceAndSelectNextDeadline
    ///   etc.
    /// Unified pending-work processing with options-struct interface.
    ///
    /// Replaces 7+ processPendingWork variants.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!?EndpointDueWorkCryptoBackendNextDeadlineResult {
        const due_work = (try self.processDueDeadlineAndSelectNextDeadline(
            connection_id,
            connection,
            now_nanos,
        )) orelse return null;
        if (due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }






    fn processDueDeadlineAndPollDatagramForBackendOutput(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkDatagramResult {
        const deadline = self.nextDeadline(connection_id, connection) orelse return null;
        if (deadline.deadline_nanos > now_nanos) return null;

        const pending_datagram = if (deadline.kind == .recovery) pending: {
            const timer = deadline.recovery orelse return error.InvalidPacket;
            if (timer.space == .initial) {
                break :pending EndpointPendingWorkDatagramResult{
                    .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
                    .datagram = null,
                };
            }
            if (!installedKeyOptionsMatchRecoveryDeadline(deadline, poll_options)) return error.InvalidPacket;
            break :pending try self.processPendingWorkAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                poll_options,
            );
        } else EndpointPendingWorkDatagramResult{
            .pending_work = try self.processPendingWork(connection_id, connection, now_nanos),
            .datagram = null,
        };

        return .{
            .deadline = deadline,
            .pending_work = pending_datagram.pending_work,
            .datagram = pending_datagram.datagram,
        };
    }

    /// Process a due deadline, drive one backend, then poll installed-key output.
    ///
    /// Due recovery datagrams keep explicit ownership and stop before backend
    /// progress. Terminal idle or close cleanup also stops before backend
    /// progress because the caller-owned connection is no longer live.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{
                .due_work = due_work,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process a due deadline, drive one backend, then drain installed-key output.
    ///
    /// This is the single-connection bounded-output form for timer wakeups.
    /// Due recovery datagrams keep explicit ownership and stop before backend
    /// progress. Terminal idle or close cleanup also stops before backend
    /// progress because the caller-owned connection is no longer live.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{
                .due_work = due_work,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{}, &.{}, &poll_views, now_nanos, poll_options.space, out),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process a due deadline, drive one backend, then poll explicit installed-key output.
    ///
    /// This keeps the due-deadline recovery options separate from the backend
    /// output selection. Use it when a live due deadline should unlock backend
    /// progress, but the next datagram must come from caller-selected output
    /// views such as accepted 0-RTT connections.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{
                .due_work = due_work,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, &drive_views, .{}, &.{}, poll_views, now_nanos),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process a due deadline, drive one backend, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{
                .due_work = due_work,
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, &drive_views, .{}, &.{}, poll_views, now_nanos, out),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process a due deadline, drive one backend across ordered packet number
    /// spaces, then poll installed-key output.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagram()`.
    /// Process a due deadline, drive one backend across ordered packet number
    /// spaces, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendAcrossSpacesAndPollDatagram()`.
    /// Process a due deadline, drive one backend across ordered packet number
    /// spaces, then poll explicit installed-key output.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendAcrossSpacesAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, &drive_views, .{}, &.{}, poll_views, now_nanos),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process a due deadline, drive one backend across ordered packet number
    /// spaces, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendAcrossSpacesAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendAcrossSpacesAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(backend_spaces, &drive_views, .{}, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process a due deadline, drive a close-propagating backend, then poll output.
    ///
    /// Due recovery datagrams and terminal idle/close cleanup stop before
    /// backend progress. Backend peer transport-parameter errors queue
    /// CONNECTION_CLOSE and return before installed-key output polling.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process a due deadline, drive a close-propagating backend, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndDrainDatagrams()`.
    /// Due recovery datagrams and terminal idle/close cleanup stop before
    /// backend progress. Backend peer transport-parameter errors queue
    /// CONNECTION_CLOSE and return before installed-key output draining.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process a due deadline, drive a close-propagating backend, then poll explicit output.
    ///
    /// This is the OrClose form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos),
        };
    }

    /// Process a due deadline, drive a close-propagating backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process a due deadline, drive one close-propagating backend across
    /// ordered packet number spaces, then poll installed-key output.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram()`.
    /// Process a due deadline, drive one close-propagating backend across
    /// ordered packet number spaces, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagram()`.
    /// Process a due deadline, drive one close-propagating backend across
    /// ordered packet number spaces, then poll explicit installed-key output.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos),
        };
    }

    /// Process a due deadline, drive one close-propagating backend across
    /// ordered packet number spaces, then drain explicit installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendAcrossSpacesOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendAcrossSpacesOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(backend_spaces, &drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process a due deadline, drive one compatible-version backend, then poll output.
    ///
    /// This is the single-connection output-polling form for RFC
    /// 9368-compatible timer wakeups.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process a due deadline, drive one compatible-version backend, then drain output.
    ///
    /// This is the single-connection bounded-output form for RFC
    /// 9368-compatible timer wakeups. Due recovery datagrams keep explicit
    /// ownership and stop before backend progress; live no-output deadlines
    /// then drive the caller-owned backend with compatible-version rules.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process a due deadline, drive one compatible-version backend, then poll explicit output.
    ///
    /// This is the RFC 9368-compatible form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos),
        };
    }

    /// Process a due deadline, drive one compatible-version backend, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, &drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
        };
    }

    /// Process a due deadline, drive compatible-version close path, then poll output.
    ///
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// installed-key output polling.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space),
        };
    }

    /// Process a due deadline, drive compatible-version close path, then drain output.
    ///
    /// This is the single-connection OrClose form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams()`.
    /// Peer Version Information errors queue CONNECTION_CLOSE and return before
    /// any installed-key output draining.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = poll_options.destination_connection_id,
            .source_connection_id = poll_options.source_connection_id,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, &poll_views, now_nanos, poll_options.space, out),
        };
    }

    /// Process a due deadline, drive compatible-version close path, then poll explicit output.
    ///
    /// This is the OrClose form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos),
        };
    }

    /// Process a due deadline, drive compatible-version close path, then drain explicit output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        due_options: EndpointPollInstalledKeyDatagramOptions,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAndPollDatagramForBackendOutput(
            connection_id,
            connection,
            now_nanos,
            due_options,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, &drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
        };
    }

    /// Process the earliest due deadline across caller-owned connections.
    ///
    /// The lifecycle still does not own connection storage. Callers pass the
    /// currently live connection views from their map, including the connection
    /// IDs needed for installed-key packet output. If no endpoint-visible
    /// deadline is due at `now_nanos`, this returns null without side effects.
    pub fn processDueDeadlineAcrossConnectionsAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
    ) Error!?EndpointDueWorkDatagramResult {
        var selected_index: ?usize = null;
        var selected_deadline: ?EndpointConnectionDeadline = null;
        for (connections, 0..) |view, index| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (candidate.deadline_nanos > now_nanos) continue;
            if (selected_deadline == null or candidate.deadline_nanos < selected_deadline.?.deadline_nanos) {
                selected_index = index;
                selected_deadline = candidate;
            }
        }

        const index = selected_index orelse return null;
        const view = connections[index];
        return self.processDueDeadlineAndPollDatagram(
            view.connection_id,
            view.connection,
            now_nanos,
            view.destination_connection_id,
            view.source_connection_id,
        );
    }

    /// Process the earliest due deadline with explicit installed-key output options.
    ///
    /// This is the cross-connection form of
    /// `processDueDeadlineAndPollDatagramWithInstalledKeyOptions()`. Each view
    /// owns the installed-key output choice for its connection, so accepted
    /// 0-RTT recovery wakeups can be selected across a caller-owned map without
    /// falling back to the default Application-to-1-RTT mapping.
    pub fn processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!?EndpointDueWorkDatagramResult {
        var selected_index: ?usize = null;
        var selected_deadline: ?EndpointConnectionDeadline = null;
        for (connections, 0..) |view, index| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (candidate.deadline_nanos > now_nanos) continue;
            if (selected_deadline == null or candidate.deadline_nanos < selected_deadline.?.deadline_nanos) {
                selected_index = index;
                selected_deadline = candidate;
            }
        }

        const index = selected_index orelse return null;
        const view = connections[index];
        return self.processDueDeadlineAndPollDatagramWithInstalledKeyOptions(
            view.connection_id,
            view.connection,
            now_nanos,
            view.poll_options,
        );
    }

    /// Process the earliest due deadline across connections and drain output.
    pub fn processDueDeadlineAcrossConnectionsAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkDatagramDrainResult {
        var selected_index: ?usize = null;
        var selected_deadline: ?EndpointConnectionDeadline = null;
        for (connections, 0..) |view, index| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (candidate.deadline_nanos > now_nanos) continue;
            if (selected_deadline == null or candidate.deadline_nanos < selected_deadline.?.deadline_nanos) {
                selected_index = index;
                selected_deadline = candidate;
            }
        }

        const index = selected_index orelse return null;
        const view = connections[index];
        var result = (try self.processDueDeadlineAndDrainDatagrams(
            view.connection_id,
            view.connection,
            now_nanos,
            view.destination_connection_id,
            view.source_connection_id,
            out,
        )) orelse return null;
        for (connections) |deadline_view| {
            const candidate = self.nextDeadline(deadline_view.connection_id, deadline_view.connection) orelse continue;
            if (result.next_deadline == null or candidate.deadline_nanos < result.next_deadline.?.deadline_nanos) {
                result.next_deadline = candidate;
            }
        }
        return result;
    }

    /// Process the earliest due deadline with explicit installed-key draining.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkDatagramDrainResult {
        var selected_index: ?usize = null;
        var selected_deadline: ?EndpointConnectionDeadline = null;
        for (connections, 0..) |view, index| {
            const candidate = self.nextDeadline(view.connection_id, view.connection) orelse continue;
            if (candidate.deadline_nanos > now_nanos) continue;
            if (selected_deadline == null or candidate.deadline_nanos < selected_deadline.?.deadline_nanos) {
                selected_index = index;
                selected_deadline = candidate;
            }
        }

        const index = selected_index orelse return null;
        const view = connections[index];
        var result = (try self.processDueDeadlineAndDrainDatagramsWithInstalledKeyOptions(
            view.connection_id,
            view.connection,
            now_nanos,
            view.poll_options,
            out,
        )) orelse return null;
        for (connections) |deadline_view| {
            const candidate = self.nextDeadline(deadline_view.connection_id, deadline_view.connection) orelse continue;
            if (result.next_deadline == null or candidate.deadline_nanos < result.next_deadline.?.deadline_nanos) {
                result.next_deadline = candidate;
            }
        }
        return result;
    }

    /// Process the earliest due deadline, then drive TLS backends if no datagram was emitted.
    ///
    /// A due recovery wakeup can already allocate a protected datagram. In that
    /// case this step returns immediately with the due datagram and leaves
    /// backend progress for a later loop iteration, preserving one-output
    /// ownership for callers. Terminal idle/close cleanup also stops before
    /// backend progress; live Initial recovery wakeups can continue into backend
    /// drive and installed-key output polling when they emit no datagram.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagram(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, poll_space),
        };
    }

    /// Process the earliest due deadline with explicit output, then drive TLS backends.
    ///
    /// This is the caller-owned connection map form for loops that need
    /// accepted 0-RTT recovery wakeups to retain `.zero_rtt` packetization
    /// before any backend drive is attempted.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos),
        };
    }

    /// Process the earliest due deadline, then drive TLS backends across
    /// ordered packet number spaces if no datagram was emitted.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagram()`.
    /// Process the earliest due deadline with explicit output, then drive TLS
    /// backends across ordered packet number spaces if no datagram was emitted.
    ///
    /// This is the cross-space form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsAcrossSpacesAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, drive_views, .{}, &.{}, poll_views, now_nanos),
        };
    }

    /// Process the earliest due deadline, then drive TLS backends and drain output.
    ///
    /// If the due deadline already emits a recovery datagram or terminally
    /// retires the selected connection, backend work is skipped. Live no-output
    /// deadlines can continue into backend progress and bounded output draining
    /// in one lifecycle-owned step.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagram(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, poll_space, out),
        };
    }

    /// Process the earliest due deadline with explicit output, then drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{}, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process the earliest due deadline, then drive TLS backends across
    /// ordered packet number spaces and drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsAcrossSpacesAndPollDatagram()`.
    /// Process the earliest due deadline with explicit output, then drive TLS
    /// backends across ordered packet number spaces and drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsAcrossSpacesAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsAcrossSpacesAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(backend_spaces, drive_views, .{}, &.{}, poll_views, now_nanos, out),
        };
    }

    /// Process the earliest due deadline, then drive close-propagating TLS backends.
    ///
    /// Backend errors are returned only after a due deadline that did not emit a
    /// datagram. This avoids losing ownership of an allocated recovery datagram
    /// on later backend failure.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagram(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, poll_space),
        };
    }

    /// Process the earliest due deadline with explicit output, then drive close-propagating backends.
    ///
    /// This keeps the selected due recovery wakeup's installed-key output
    /// options, so accepted 0-RTT and other non-default recovery probes can
    /// preserve their packetization before any backend drive is attempted.
    /// Backend errors are returned only after a due deadline that did not emit
    /// a datagram.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos),
        };
    }
    /// Process the earliest due deadline, then drive close-propagating backends and drain output.
    /// Process the earliest due deadline with explicit output, then drive close-propagating backends and drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .close_on_error = true }, &.{}, poll_views, now_nanos, out),
        };
    }
    /// Process the earliest due deadline, then drive compatible-version backends.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagram(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space),
        };
    }

    /// Process the earliest due deadline with explicit output, then drive compatible-version backends.
    ///
    /// This is the RFC 9368-compatible form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceAndPollDatagramWithInstalledKeyOptions()`.
    /// It preserves caller-selected installed-key recovery output before any
    /// compatible-version backend sweep is attempted.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos),
        };
    }

    /// Process the earliest due deadline, then drive compatible-version backends and drain output.
    /// Process the earliest due deadline with explicit output, then drive compatible-version backends and drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
        };
    }

    /// Process the earliest due deadline, then drive compatible-version close path.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionPollView,
        poll_space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagram(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithPoll(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, poll_space),
        };
    }

    /// Process the earliest due deadline with explicit output, then drive compatible-version close path.
    ///
    /// This preserves caller-selected installed-key recovery output before
    /// close-propagating RFC 9368 backend work. Peer Version Information
    /// errors are returned only after a due deadline that did not emit a
    /// datagram.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos),
        };
    }

    /// Process the earliest due deadline, then drive compatible-version close path and drain output.
    /// Process the earliest due deadline with explicit output, then drive compatible-version close path and drain output.
    ///
    /// This is the bounded-output form of
    /// `processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndPollDatagramWithInstalledKeyOptions()`.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsInSpaceWithCompatibleVersionOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_space: PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
        out: []EndpointPolledDatagramResult,
    ) Error!?EndpointDueWorkCryptoBackendDatagramDrainResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyDrain(&.{backend_space}, drive_views, .{ .close_on_error = true, .compatible_version = true }, compatibilities, poll_views, now_nanos, out),
        };
    }

    /// Process the earliest due deadline, then drive compatible-version backends
    /// across ordered packet number spaces and poll output.
    /// Process the earliest due deadline with explicit output, then drive
    /// compatible-version backends across ordered packet number spaces and poll output.
    pub fn processDueDeadlineAcrossConnectionsAndDriveCryptoBackendsAcrossSpacesWithCompatibleVersionAndPollDatagramWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        deadline_connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        backend_spaces: []const PacketNumberSpace,
        drive_views: []const EndpointCryptoBackendDriveView,
        compatibilities: []const VersionCompatibility,
        poll_views: []const EndpointConnectionInstalledKeyPollView,
    ) Error!?EndpointDueWorkCryptoBackendDatagramResult {
        const due_work = (try self.processDueDeadlineAcrossConnectionsAndPollDatagramWithInstalledKeyOptions(
            deadline_connections,
            now_nanos,
        )) orelse return null;
        if (due_work.datagram != null or
            due_work.pending_work.idle_retired != null or
            due_work.pending_work.close_retired != null)
        {
            return .{ .due_work = due_work };
        }
        return .{
            .due_work = due_work,
            .backend = try self.driveCryptoBackendStepWithInstalledKeyPoll(backend_spaces, drive_views, .{ .compatible_version = true }, compatibilities, poll_views, now_nanos),
        };
    }
    /// Service a due Initial/Handshake recovery timer and poll a protected long probe.
    ///
    /// This endpoint event-loop bridge covers long-header PTO/loss wakeups
    /// while the caller still supplies packet-protection keys. Application
    /// timers must use the short-packet helper because 1-RTT packets use the
    /// short header and a different packetization path.
    pub fn serviceRecoveryTimerAndPollProtectedLongDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: ProtectedLongDatagramKeys,
    ) Error!EndpointProtectedLongRecoveryPollResult {
        const serviced = try self.serviceRecoveryTimer(connection_id, connection, now_nanos);
        const deadline = serviced orelse return .{
            .serviced = null,
            .datagram = null,
        };
        if (deadline.timer.space == .application) return error.InvalidPacket;

        const datagram = try self.pollProtectedLongDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
            initial_token,
            keys,
        );
        return .{
            .serviced = deadline,
            .datagram = datagram,
        };
    }

    /// Service a due Handshake recovery timer and poll an installed-key probe.
    ///
    /// This is the TLS-owned-key variant of the long-header recovery wakeup
    /// bridge. The connection owns installed Handshake packet-protection state,
    /// while the endpoint lifecycle owns the recovery timer wakeup and refresh.
    pub fn serviceRecoveryTimerAndPollProtectedHandshakeDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
    ) Error!EndpointProtectedLongRecoveryPollResult {
        const serviced = try self.serviceRecoveryTimer(connection_id, connection, now_nanos);
        const deadline = serviced orelse return .{
            .serviced = null,
            .datagram = null,
        };
        if (deadline.timer.space != .handshake) return error.InvalidPacket;

        const datagram = try self.pollProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
        );
        return .{
            .serviced = deadline,
            .datagram = datagram,
        };
    }

    /// Service a due Application recovery timer and poll an installed-key 0-RTT probe.
    ///
    /// This is the TLS-owned early-data long-packet recovery wakeup bridge.
    /// The connection owns installed local 0-RTT packet-protection state,
    /// while the endpoint lifecycle owns the recovery timer wakeup and refresh.
    pub fn serviceRecoveryTimerAndPollProtectedZeroRttDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
    ) Error!EndpointProtectedLongRecoveryPollResult {
        const serviced = try self.serviceRecoveryTimer(connection_id, connection, now_nanos);
        const deadline = serviced orelse return .{
            .serviced = null,
            .datagram = null,
        };
        if (deadline.timer.space != .application) return error.InvalidPacket;

        const datagram = try self.pollProtectedZeroRttDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
        );
        return .{
            .serviced = deadline,
            .datagram = datagram,
        };
    }

    /// Service a due Application recovery timer and poll a protected 1-RTT probe.
    ///
    /// This is the caller-keyed short-packet endpoint event-loop bridge for
    /// PTO/loss-time wakeups. Initial and Handshake timers still belong on the
    /// long-packet helpers because they require long-header packet protection
    /// and packet-number-space selection.
    pub fn serviceRecoveryTimerAndPollProtectedShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!EndpointProtectedShortRecoveryPollResult {
        const serviced = try self.serviceRecoveryTimer(connection_id, connection, now_nanos);
        const deadline = serviced orelse return .{
            .serviced = null,
            .datagram = null,
        };
        if (deadline.timer.space != .application) return error.InvalidPacket;

        const datagram = try self.pollProtectedShortDatagram(connection_id, connection, now_nanos, dcid, keys);
        return .{
            .serviced = deadline,
            .datagram = datagram,
        };
    }

    /// Service a due Application recovery timer and poll an installed-key 1-RTT probe.
    ///
    /// This is the TLS-owned-key variant of
    /// `serviceRecoveryTimerAndPollProtectedShortDatagram()`. The connection
    /// owns installed 1-RTT packet protection state, while the endpoint
    /// lifecycle owns the recovery timer wakeup and refresh.
    pub fn serviceRecoveryTimerAndPollProtectedShortDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
    ) Error!EndpointProtectedShortRecoveryPollResult {
        const serviced = try self.serviceRecoveryTimer(connection_id, connection, now_nanos);
        const deadline = serviced orelse return .{
            .serviced = null,
            .datagram = null,
        };
        if (deadline.timer.space != .application) return error.InvalidPacket;

        const datagram = try self.pollProtectedShortDatagramWithInstalledKeys(connection_id, connection, now_nanos, dcid);
        return .{
            .serviced = deadline,
            .datagram = datagram,
        };
    }

    /// Apply one connection's idle timeout and retire endpoint state if it closes.
    ///
    /// `Connection.checkIdleTimeouts()` remains the source of truth for the
    /// connection state transition. This endpoint bridge only observes the
    /// active-to-closed idle transition and then removes routes and recovery
    /// timers owned by the lifecycle for `connection_id`.
    pub fn checkIdleTimeoutsAndRetireConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!?EndpointConnectionRetireResult {
        if (connection.connectionState() != .active) {
            try connection.checkIdleTimeouts(now_nanos);
            return null;
        }

        connection.checkIdleTimeouts(now_nanos) catch |err| switch (err) {
            error.ConnectionClosed => return self.retireConnection(connection_id),
            else => return err,
        };
        return null;
    }

    /// Apply one connection's close/drain timeout and retire endpoint state if it closes.
    ///
    /// `Connection.checkCloseTimeouts()` remains the source of truth for the
    /// closing/draining-to-closed transition. This endpoint bridge only observes
    /// that terminal close transition and then removes routes and recovery
    /// timers owned by the lifecycle for `connection_id`.
    pub fn checkCloseTimeoutsAndRetireConnection(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
    ) Error!?EndpointConnectionRetireResult {
        const state = connection.connectionState();
        if (state != .closing and state != .draining) {
            try connection.checkCloseTimeouts(now_nanos);
            return null;
        }

        connection.checkCloseTimeouts(now_nanos) catch |err| switch (err) {
            error.ConnectionClosed => return self.retireConnection(connection_id),
            else => return err,
        };
        return null;
    }

    /// Poll one protected long-header datagram and refresh recovery scheduling.
    ///
    /// This bridge covers Initial, Handshake, and 0-RTT long packets emitted by
    /// a caller-owned connection while the endpoint lifecycle owns route and
    /// timer state. The returned datagram remains allocated by `connection` and
    /// must be freed by the caller. If endpoint timer refresh fails after a
    /// datagram is produced, the helper frees that datagram before returning.
    pub fn pollProtectedLongDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: ProtectedLongDatagramKeys,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedLongDatagram(now_nanos, dcid, scid, initial_token, keys) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process protected long-header packets and refresh endpoint timers.
    ///
    /// The connection still owns packet-number-space routing, ACK/recovery
    /// state, and packet-protection validation. The endpoint lifecycle mirrors
    /// the aggregate recovery timer after successful processing so socket event
    /// loops keep one state owner for routing and timer scheduling.
    pub fn processProtectedLongDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: ProtectedLongDatagramKeys,
        datagram: []const u8,
    ) Error!usize {
        const count = connection.processProtectedLongDatagram(now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return count;
    }

    /// Process protected long-header packets with close propagation and refresh timers.
    ///
    /// This keeps `processProtectedLongDatagram()` success behavior, but uses
    /// the connection's close-propagating protected receive path for
    /// authenticated plaintext frame errors.
    pub fn processProtectedLongDatagramOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: ProtectedLongDatagramKeys,
        datagram: []const u8,
    ) Error!usize {
        const count = connection.processProtectedLongDatagramOrClose(now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return count;
    }

    /// Route and process protected long-header packets.
    ///
    /// This is the lifecycle-owned receive bridge for coalesced Initial,
    /// Handshake, and 0-RTT datagrams when the endpoint owns route selection
    /// but the caller still supplies packet-protection keys. The route must
    /// resolve to `connection_id`; the connection then processes every
    /// protected long packet in the datagram, and the endpoint lifecycle
    /// mirrors the resulting recovery timer.
    pub fn processRoutedProtectedLongDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: ProtectedLongDatagramKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointProtectedLongDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        const processed_packets = try self.processProtectedLongDatagram(
            connection_id,
            connection,
            now_nanos,
            keys,
            datagram,
        );
        return .{
            .route = route,
            .processed_packets = processed_packets,
        };
    }
    /// Poll one caller-keyed Initial/Handshake CRYPTO datagram and refresh timers.
    ///
    /// This direct single-space bridge is for endpoint loops that already hold
    /// caller-supplied Initial or Handshake packet-protection keys and want to
    /// emit exactly one CRYPTO packet-number-space datagram without the
    /// coalescing behavior of `pollProtectedLongDatagram()`. The returned
    /// datagram remains allocated by `connection` and must be freed by the
    /// caller. If endpoint timer refresh fails after a datagram is produced,
    /// the helper frees that datagram before returning.
    pub fn pollProtectedLongCryptoDatagramInSpace(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedLongCryptoDatagramInSpace(space, now_nanos, dcid, scid, initial_token, keys) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Drain caller-keyed Initial/Handshake CRYPTO datagrams into result slots.
    ///
    /// This is the bounded-output form of
    /// `pollProtectedLongCryptoDatagramInSpace()`. The caller owns each
    /// initialized datagram entry. If polling fails after earlier entries were
    /// written, `first_error` preserves that failure while keeping the written
    /// count available for cleanup.
    pub fn drainProtectedLongCryptoDatagramsInSpace(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const datagram = self.pollProtectedLongCryptoDatagramInSpace(
                connection_id,
                connection,
                space,
                now_nanos,
                dcid,
                scid,
                initial_token,
                keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = datagram orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    fn drainProtectedLongDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        keys: ProtectedLongDatagramKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const datagram = self.pollProtectedLongDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
                initial_token,
                keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = datagram orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process one caller-keyed Initial/Handshake datagram and refresh timers.
    ///
    /// Packet-number-space selection, packet authentication, ACK generation,
    /// and CRYPTO reassembly stay inside `Connection`; the endpoint
    /// lifecycle mirrors the resulting aggregate recovery timer after
    /// successful processing.
    pub fn processProtectedLongDatagramInSpace(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedLongDatagramInSpace(space, now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process caller-keyed Initial/Handshake input, then poll one long-header output.
    ///
    /// This is the lightweight socket-loop step for ACK, PING, close, or
    /// already queued CRYPTO responses when no TLS backend drive is needed.
    /// The caller owns any returned datagram.
    pub fn processProtectedLongDatagramInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        );
        const output = try self.pollProtectedLongDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
            initial_token,
            try protectedLongDatagramKeysForSpace(space, send_keys),
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process caller-keyed Initial/Handshake input with close propagation, then poll output.
    ///
    /// Authenticated frame errors queue CONNECTION_CLOSE and poll that close
    /// datagram. Non-closing invalid packets keep the throwing receive path.
    pub fn processProtectedLongDatagramInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedLongDatagramInSpaceOrClose(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output = try self.pollProtectedLongDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
            initial_token,
            try protectedLongDatagramKeysForSpace(space, send_keys),
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }
    /// Process caller-keyed Initial/Handshake input, then drain long-header output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedLongDatagramInSpaceAndPollDatagram()`. The caller owns
    /// each initialized output datagram.
    pub fn processProtectedLongDatagramInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        );
        const output_keys = try protectedLongDatagramKeysForSpace(space, send_keys);
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedLongDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
                initial_token,
                output_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process caller-keyed Initial/Handshake input with close propagation, then drain output.
    ///
    /// Authenticated frame errors queue CONNECTION_CLOSE and drain that close
    /// datagram. Non-closing invalid packets keep the throwing receive path.
    pub fn processProtectedLongDatagramInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedLongDatagramInSpaceOrClose(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output_keys = try protectedLongDatagramKeysForSpace(space, send_keys);
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedLongDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
                initial_token,
                output_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route caller-keyed Initial/Handshake input, then drain long-header output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedLongDatagramInSpaceAndDrainDatagrams(
                connection_id,
                connection,
                space,
                now_nanos,
                receive_keys,
                datagram,
                dcid,
                scid,
                initial_token,
                send_keys,
                out,
            ),
        };
    }
    /// Process caller-keyed long-header input, drive backend, and drain output.
    ///
    /// This is the single-connection socket-loop step for Initial or Handshake
    /// CRYPTO processing when packet-protection keys are still caller-owned. It
    /// authenticates and processes the incoming long-header datagram before
    /// delivering reassembled CRYPTO to `backend`, then drains at most `out.len`
    /// protected long-header CRYPTO datagrams from the same packet-number
    /// space. The caller owns the backend, connection storage, socket send
    /// queue, and each initialized output datagram.
    pub fn processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramDrainResult {
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        );
        return try self.driveCryptoBackendInSpaceAndDrainProtectedLongCryptoDatagrams(
            connection_id,
            connection,
            space,
            backend,
            scratch,
            space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            send_keys,
            out,
        );
    }

    /// Process caller-keyed long-header input, drive backend, and poll output.
    ///
    /// This is the single-connection socket-loop step for Initial or Handshake
    /// CRYPTO processing when packet-protection keys are still caller-owned. It
    /// authenticates and processes the incoming long-header datagram before
    /// delivering reassembled CRYPTO to `backend`, then polls at most one
    /// protected long-header CRYPTO datagram from the same packet-number space.
    pub fn processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramResult {
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        );
        return try self.driveCryptoBackendInSpaceAndPollProtectedLongCryptoDatagram(
            connection_id,
            connection,
            space,
            backend,
            scratch,
            space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            send_keys,
        );
    }

    /// Process caller-keyed long-header input, drive backend, and select a wakeup.
    ///
    /// This is the no-output socket-loop step for Initial or Handshake CRYPTO
    /// processing before packet-protection keys are fully connection-owned.
    /// It authenticates and processes the incoming long-header datagram,
    /// delivers reassembled CRYPTO to `backend`, queues backend-produced CRYPTO
    /// on the connection, refreshes endpoint recovery scheduling, and returns
    /// the next endpoint-visible deadline without polling caller-keyed output.
    pub fn processProtectedLongDatagramInSpaceAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        );
        return try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
            connection_id,
            connection,
            space,
            backend,
            scratch,
        );
    }

    /// Process caller-keyed long-header input through close-propagating backend.
    ///
    /// This preserves the success behavior of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndDrainDatagrams()`,
    /// while using the close-propagating receive and backend-drive paths.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and drain protected close output in the same step.
    pub fn processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramDrainResult {
        self.processProtectedLongDatagramInSpaceOrClose(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainProtectedLongDatagrams(
                    connection_id,
                    connection,
                    now_nanos,
                    dcid,
                    scid,
                    initial_token,
                    try protectedLongDatagramKeysForSpace(space, send_keys),
                    out,
                ),
            };
        };
        return try self.driveCryptoBackendInSpaceOrCloseAndDrainProtectedLongCryptoDatagrams(
            connection_id,
            connection,
            space,
            backend,
            scratch,
            space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            send_keys,
            out,
        );
    }

    /// Process caller-keyed long-header input through close-propagating backend.
    ///
    /// This preserves the success behavior of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndPollDatagram()`,
    /// while using the close-propagating receive and backend-drive paths.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and poll protected close output in the same step.
    pub fn processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!EndpointCryptoBackendDriveProtectedLongDatagramResult {
        self.processProtectedLongDatagramInSpaceOrClose(
            connection_id,
            connection,
            space,
            now_nanos,
            receive_keys,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const output = try self.pollProtectedLongDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
                initial_token,
                try protectedLongDatagramKeysForSpace(space, send_keys),
            );
            return .{
                .backend = .{},
                .datagram = if (output) |bytes| .{
                    .connection_id = connection_id,
                    .datagram = bytes,
                } else null,
            };
        };
        return try self.driveCryptoBackendInSpaceOrCloseAndPollProtectedLongCryptoDatagram(
            connection_id,
            connection,
            space,
            backend,
            scratch,
            space,
            now_nanos,
            dcid,
            scid,
            initial_token,
            send_keys,
        );
    }
    /// Process one caller-keyed Initial/Handshake datagram with close propagation.
    ///
    /// This keeps the single-space protected long success behavior while
    /// queueing CONNECTION_CLOSE for authenticated plaintext frame errors.
    pub fn processProtectedLongDatagramInSpaceOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedLongDatagramInSpaceOrClose(space, now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one caller-keyed Initial/Handshake datagram.
    ///
    /// Socket loops can use this when the endpoint owns route selection while
    /// the caller still supplies long-packet protection keys. The route must
    /// resolve to `connection_id`; the connection then opens the packet in the
    /// requested packet-number space, and the endpoint lifecycle mirrors the
    /// resulting recovery timer.
    pub fn processRoutedProtectedLongDatagramInSpace(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            now_nanos,
            keys,
            datagram,
        );
        return route;
    }
    /// Route caller-keyed long-header input, drive backend, and drain output.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndDrainDatagrams()`.
    /// The endpoint lifecycle owns route validation before the caller-owned
    /// connection processes the packet and backend progress. Caller-owned
    /// connection/backend/socket storage and output datagrams remain outside
    /// the lifecycle.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDriveCryptoBackendAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveProtectedLongDatagramDrainResult {
        const route = try self.processRoutedProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            path,
            now_nanos,
            receive_keys,
            datagram,
        );
        return .{
            .route = route,
            .backend = try self.driveCryptoBackendInSpaceAndDrainProtectedLongCryptoDatagrams(
                connection_id,
                connection,
                space,
                backend,
                scratch,
                space,
                now_nanos,
                dcid,
                scid,
                initial_token,
                send_keys,
                out,
            ),
        };
    }

    /// Route caller-keyed long-header input, drive backend, and poll output.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendAndPollDatagram()`.
    /// The endpoint lifecycle owns route validation before the caller-owned
    /// connection processes the packet and backend progress.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDriveCryptoBackendAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveProtectedLongDatagramResult {
        const route = try self.processRoutedProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            path,
            now_nanos,
            receive_keys,
            datagram,
        );
        return .{
            .route = route,
            .backend = try self.driveCryptoBackendInSpaceAndPollProtectedLongCryptoDatagram(
                connection_id,
                connection,
                space,
                backend,
                scratch,
                space,
                now_nanos,
                dcid,
                scid,
                initial_token,
                send_keys,
            ),
        };
    }

    /// Route caller-keyed long-header input, drive backend, and select a wakeup.
    ///
    /// This is the routed no-output socket-loop step for Initial or Handshake
    /// CRYPTO processing when the endpoint lifecycle owns route validation and
    /// the caller still supplies packet-protection keys. Route errors and
    /// connection-id mismatches fail before packet processing or backend drive.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.processRoutedProtectedLongDatagramInSpace(
            connection_id,
            connection,
            space,
            path,
            now_nanos,
            receive_keys,
            datagram,
        );
        return .{
            .route = route,
            .backend = try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
                connection_id,
                connection,
                space,
                backend,
                scratch,
            ),
        };
    }

    /// Route caller-keyed long-header input through close-propagating backend.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndDrainDatagrams()`.
    /// Route errors or connection-id mismatches fail before packet processing.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and drain protected close output in the same step.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveProtectedLongDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                space,
                now_nanos,
                receive_keys,
                datagram,
                backend,
                scratch,
                dcid,
                scid,
                initial_token,
                send_keys,
                out,
            ),
        };
    }

    /// Route caller-keyed long-header input through close-propagating backend.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndPollDatagram()`.
    /// Route errors or connection-id mismatches fail before packet processing.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and poll protected close output in the same step.
    pub fn processRoutedProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        space: PacketNumberSpace,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        initial_token: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveProtectedLongDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedLongDatagramInSpaceAndDriveCryptoBackendOrCloseAndPollDatagram(
                connection_id,
                connection,
                space,
                now_nanos,
                receive_keys,
                datagram,
                backend,
                scratch,
                dcid,
                scid,
                initial_token,
                send_keys,
            ),
        };
    }
    /// Poll one caller-keyed protected 0-RTT datagram and refresh timers.
    ///
    /// This direct early-data bridge is for endpoint loops that already hold
    /// caller-supplied 0-RTT packet-protection keys and do not need the
    /// coalescing behavior of `pollProtectedLongDatagram()`. The returned
    /// datagram remains allocated by `connection` and must be freed by the
    /// caller. If endpoint timer refresh fails after a datagram is produced,
    /// the helper frees that datagram before returning.
    pub fn pollProtectedZeroRttDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedZeroRttDatagram(now_nanos, dcid, scid, keys) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one caller-keyed protected 0-RTT datagram and refresh timers.
    ///
    /// The caller supplies the 0-RTT receive keys and owns any external
    /// early-data policy. The connection still applies 0-RTT frame
    /// restrictions and Application packet-number state; the endpoint
    /// lifecycle mirrors the resulting aggregate recovery timer.
    pub fn processProtectedZeroRttDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedZeroRttDatagram(now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one caller-keyed protected 0-RTT datagram with close propagation.
    ///
    /// The caller still owns early-data policy. Authenticated 0-RTT plaintext
    /// frame errors queue CONNECTION_CLOSE before `InvalidPacket` is returned.
    pub fn processProtectedZeroRttDatagramOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedZeroRttDatagramOrClose(now_nanos, keys, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one caller-keyed protected 0-RTT datagram.
    ///
    /// Socket loops can use this when the endpoint owns route selection while
    /// the caller still supplies early-data packet-protection keys. The route
    /// must resolve to `connection_id`; the connection then applies 0-RTT
    /// frame restrictions and Application packet-number state, and the
    /// endpoint lifecycle mirrors the resulting recovery timer.
    pub fn processRoutedProtectedZeroRttDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedZeroRttDatagram(
            connection_id,
            connection,
            now_nanos,
            keys,
            datagram,
        );
        return route;
    }

    /// Route and process one caller-keyed protected 0-RTT datagram with close propagation.
    ///
    /// Route ownership and success behavior match
    /// `processRoutedProtectedZeroRttDatagram()`, while authenticated frame
    /// payload errors use the connection close path.
    /// Process caller-keyed 0-RTT input, then poll one caller-keyed short output.
    ///
    /// This combines the common server loop step where an accepted 0-RTT packet
    /// queues an Application-space ACK and the endpoint immediately polls one
    /// 1-RTT short-header datagram. The caller supplies both the 0-RTT receive
    /// keys and 1-RTT send keys.
    pub fn processProtectedZeroRttDatagramAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedZeroRttDatagram(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            datagram,
        );
        const output = try self.pollProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process caller-keyed 0-RTT input, then drain caller-keyed short output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedZeroRttDatagramAndPollShortDatagram()`. The caller owns
    /// each initialized output datagram.
    pub fn processProtectedZeroRttDatagramAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedZeroRttDatagram(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process caller-keyed 0-RTT input with close propagation, then poll output.
    ///
    /// Authenticated 0-RTT frame errors queue CONNECTION_CLOSE and return
    /// before polling ordinary 1-RTT output.
    pub fn processProtectedZeroRttDatagramOrCloseAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedZeroRttDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            datagram,
        );
        const output = try self.pollProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process caller-keyed 0-RTT input with close propagation, then drain output.
    ///
    /// Authenticated 0-RTT frame errors queue CONNECTION_CLOSE and return
    /// before any ordinary 1-RTT output is drained.
    pub fn processProtectedZeroRttDatagramOrCloseAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedZeroRttDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route caller-keyed 0-RTT input, then poll one caller-keyed short output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the endpoint processes the 0-RTT datagram and polls at most
    /// one Application-space short-header datagram for the selected connection.
    pub fn processRoutedProtectedZeroRttDatagramAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedZeroRttDatagramAndPollShortDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                datagram,
                dcid,
                send_keys,
            ),
        };
    }

    /// Route caller-keyed 0-RTT input, then drain caller-keyed short output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the endpoint processes the 0-RTT datagram and drains at most
    /// `out.len` Application-space short-header datagrams for the selected
    /// connection.
    pub fn processRoutedProtectedZeroRttDatagramAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedZeroRttDatagramAndDrainShortDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                datagram,
                dcid,
                send_keys,
                out,
            ),
        };
    }

    /// Route caller-keyed 0-RTT input through close propagation, then poll output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// 0-RTT frame errors stop before ordinary output polling.
    pub fn processRoutedProtectedZeroRttDatagramOrCloseAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedZeroRttDatagramOrCloseAndPollShortDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                datagram,
                dcid,
                send_keys,
            ),
        };
    }

    /// Route caller-keyed 0-RTT input through close propagation, then drain output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// 0-RTT frame errors stop before ordinary output draining.
    pub fn processRoutedProtectedZeroRttDatagramOrCloseAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedZeroRttDatagramOrCloseAndDrainShortDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                datagram,
                dcid,
                send_keys,
                out,
            ),
        };
    }

    /// Poll one caller-keyed protected 1-RTT datagram and refresh timers.
    ///
    /// This bridge is for endpoint loops that still receive packet-protection
    /// keys from a caller or test harness while the endpoint owns route and
    /// recovery-timer state. The returned datagram remains allocated by
    /// `connection` and must be freed by the caller. If endpoint timer refresh
    /// fails after a datagram is produced, the helper frees that datagram
    /// before returning.
    pub fn pollProtectedShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedShortDatagram(now_nanos, dcid, keys) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one caller-keyed protected 1-RTT datagram and refresh timers.
    ///
    /// The caller still supplies packet-protection keys and the connection owns
    /// Application packet-number, ACK, and recovery state. The endpoint
    /// lifecycle mirrors the resulting aggregate recovery timer after
    /// successful processing.
    pub fn processProtectedShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagram(now_nanos, keys, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one caller-keyed protected 1-RTT datagram with close propagation.
    ///
    /// Packet authentication and success behavior match
    /// `processProtectedShortDatagram()`. Authenticated Application plaintext
    /// frame errors queue CONNECTION_CLOSE before `InvalidPacket` is returned.
    pub fn processProtectedShortDatagramOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramOrClose(now_nanos, keys, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one caller-keyed protected 1-RTT datagram.
    ///
    /// Socket loops can use this when the endpoint owns route selection while
    /// the caller still supplies packet-protection keys. The route must resolve
    /// to `connection_id`; the routed destination CID length is then used for
    /// short-header packet protection removal, and the endpoint recovery timer
    /// is refreshed after successful connection processing.
    pub fn processRoutedProtectedShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            keys,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Route/process a path-validation short packet and commit validated path updates.
    ///
    /// The ordinary routed receive helper leaves endpoint path updates to the
    /// caller. This variant is for endpoint loops that want one owner for
    /// protected receive, PATH_RESPONSE validation, route path update, spin-bit
    /// reset, and recovery timer refresh. A path update is committed only when
    /// the packet routes to `connection_id`, authentication/frame processing
    /// succeeds, the routed tuple differs from the stored route, and the
    /// connection consumes at least one outstanding PATH_CHALLENGE.
    pub fn processRoutedProtectedShortDatagramAndUpdatePath(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointPathValidatedShortDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const outstanding_before = connection.outstandingPathChallengeCount();
        try self.processProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            keys,
            route.destination_connection_id.asSlice().len,
            datagram,
        );

        const outstanding_after = connection.outstandingPathChallengeCount();
        const updated_route: ?endpoint.RouteResult = if (route.path_changed and outstanding_after < outstanding_before)
            try self.updateRoutePathFromValidatedDatagramAndResetSpinBit(
                route.destination_connection_id.asSlice(),
                path,
                connection,
            )
        else
            null;

        return .{
            .route = route,
            .updated_route = updated_route,
        };
    }

    /// Route/process a path-validation short packet, update validated paths, and close on frame errors.
    ///
    /// This preserves `processRoutedProtectedShortDatagramAndUpdatePath()`
    /// success behavior while using the close-propagating receive path for
    /// authenticated Application plaintext frame errors. If frame processing
    /// fails, no endpoint path update is committed.
    pub fn processRoutedProtectedShortDatagramAndUpdatePathOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointPathValidatedShortDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const outstanding_before = connection.outstandingPathChallengeCount();
        try self.processProtectedShortDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            keys,
            route.destination_connection_id.asSlice().len,
            datagram,
        );

        const outstanding_after = connection.outstandingPathChallengeCount();
        const updated_route: ?endpoint.RouteResult = if (route.path_changed and outstanding_after < outstanding_before)
            try self.updateRoutePathFromValidatedDatagramAndResetSpinBit(
                route.destination_connection_id.asSlice(),
                path,
                connection,
            )
        else
            null;

        return .{
            .route = route,
            .updated_route = updated_route,
        };
    }

    /// Route and process one caller-keyed protected 1-RTT datagram with close propagation.
    ///
    /// This validates the endpoint route, uses its destination CID length for
    /// packet protection removal, and queues CONNECTION_CLOSE for authenticated
    /// Application plaintext frame errors.
    pub fn processRoutedProtectedShortDatagramOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            keys,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Process caller-keyed 1-RTT input and select the next wakeup.
    ///
    /// This is the no-output socket-loop step for received 1-RTT short
    /// packets when packet-protection keys remain caller-owned. The endpoint
    /// lifecycle refreshes recovery state after receive and returns the next
    /// endpoint-visible deadline without polling ACK, STREAM, close, or PTO
    /// output.
    /// Unified protected short datagram processing with options-struct interface.
    ///
    /// Replaces 5 processProtectedShortDatagram variants:
    ///   processProtectedShortDatagram
    ///   processProtectedShortDatagramOrClose
    ///   processProtectedShortDatagramWithInstalledKeys
    ///   processProtectedShortDatagramWithInstalledKeysOrClose
    ///   processProtectedShortDatagramWithKeyUpdate
    /// Unified routed protected short datagram processing with options-struct interface.
    ///
    /// Replaces 5 processRoutedProtectedShortDatagram variants.
    pub fn processProtectedShortDatagramAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!?EndpointConnectionDeadline {
        try self.processProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        return self.nextDeadline(connection_id, connection);
    }
    /// Route caller-keyed 1-RTT input and select the next wakeup.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the routed destination CID length is used to open the short
    /// packet, and output remains queued for a later caller-keyed poll/drain.
    pub fn processRoutedProtectedShortDatagramAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .next_deadline = try self.processProtectedShortDatagramAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
            ),
        };
    }
    /// Process caller-keyed 1-RTT input, then poll one caller-keyed output.
    ///
    /// This is the one-output socket-loop step for received 1-RTT short
    /// packets when packet-protection keys remain caller-owned. The endpoint
    /// lifecycle refreshes recovery state after receive and after output
    /// polling, and the caller owns any returned datagram.
    pub fn processProtectedShortDatagramAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        const output = try self.pollProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process caller-keyed 1-RTT input with close propagation, then poll output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE and
    /// return before ordinary caller-keyed output polling.
    pub fn processProtectedShortDatagramOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedShortDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output = try self.pollProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Route caller-keyed 1-RTT input, then poll one caller-keyed output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the routed destination CID length is used to open the short
    /// packet, then the selected connection is polled for one Application-space
    /// response such as an ACK.
    pub fn processRoutedProtectedShortDatagramAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
            ),
        };
    }

    /// Route caller-keyed 1-RTT input through close propagation, then poll output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary output polling.
    pub fn processRoutedProtectedShortDatagramOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
            ),
        };
    }

    /// Process caller-keyed 1-RTT input, then drain caller-keyed output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedShortDatagramAndPollDatagram()`. The caller owns each
    /// initialized output datagram.
    pub fn processProtectedShortDatagramAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedShortDatagram(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process caller-keyed 1-RTT input with close propagation, then drain output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE and
    /// return before any ordinary caller-keyed output is drained.
    pub fn processProtectedShortDatagramOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedShortDatagramOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            if (out.len == 0) return error.BufferTooSmall;
        };
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagram(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route caller-keyed 1-RTT input, then drain caller-keyed output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, at most `out.len` Application-space datagrams are emitted
    /// for the selected connection.
    pub fn processRoutedProtectedShortDatagramAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                out,
            ),
        };
    }

    /// Route caller-keyed 1-RTT input through close propagation, then drain output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary output draining.
    pub fn processRoutedProtectedShortDatagramOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.Aes128PacketProtectionKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                out,
            ),
        };
    }

    /// Poll one explicit-key-phase protected 1-RTT datagram and refresh timers.
    ///
    /// Callers supply packet-protection keys and the wire key phase bit for
    /// deterministic key-update flows that do not keep a state object. The
    /// returned datagram remains allocated by `connection` and must be freed
    /// by the caller. If endpoint timer refresh fails after a datagram is
    /// produced, the helper frees that datagram before returning.
    pub fn pollProtectedShortDatagramWithKeyPhase(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        keys: protection.Aes128PacketProtectionKeys,
        key_phase: bool,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedShortDatagramWithKeyPhase(now_nanos, dcid, keys, key_phase) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one explicit key-update protected 1-RTT datagram and refresh timers.
    ///
    /// The caller supplies current and next packet-protection keys plus the
    /// active key phase. The connection owns Application packet-number, ACK,
    /// and recovery state, and the endpoint lifecycle mirrors the resulting
    /// aggregate timer after successful processing.
    pub fn processProtectedShortDatagramWithKeyUpdate(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithKeyUpdate(now_nanos, keys, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one explicit key-update protected 1-RTT datagram with close propagation.
    ///
    /// Key selection and success behavior match
    /// `processProtectedShortDatagramWithKeyUpdate()`, while authenticated
    /// frame payload errors queue CONNECTION_CLOSE.
    pub fn processProtectedShortDatagramWithKeyUpdateOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithKeyUpdateOrClose(now_nanos, keys, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one explicit key-update protected 1-RTT datagram.
    ///
    /// This keeps caller-supplied key-update state on the same endpoint-owned
    /// route and recovery-timer boundary as the other protected short-packet
    /// receive paths. The route must resolve to `connection_id`; the routed
    /// destination CID length is used for short-header packet protection
    /// removal before the endpoint recovery timer is refreshed.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdate(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagramWithKeyUpdate(
            connection_id,
            connection,
            now_nanos,
            keys,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Route and process one explicit key-update protected 1-RTT datagram with close propagation.
    ///
    /// This keeps caller-supplied key-update state on the same endpoint-owned
    /// route boundary, and delegates authenticated frame-payload errors to the
    /// connection close path.
    /// Process explicit key-update 1-RTT input and select the next wakeup.
    ///
    /// This is the no-output form for callers that own current and next
    /// packet-protection keys and only need endpoint timer interest after
    /// receive processing. ACK or data output remains queued for a later
    /// poll/drain step.
    pub fn processProtectedShortDatagramWithKeyUpdateAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!?EndpointConnectionDeadline {
        try self.processProtectedShortDatagramWithKeyUpdate(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        return self.nextDeadline(connection_id, connection);
    }
    /// Route explicit key-update 1-RTT input and select the next wakeup.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the routed destination CID length is used to open the short
    /// packet and output remains queued for a later explicit-phase poll/drain.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdateAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .next_deadline = try self.processProtectedShortDatagramWithKeyUpdateAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
            ),
        };
    }
    /// Process explicit key-update 1-RTT input, then poll one explicit-phase output.
    ///
    /// This is the one-output socket-loop step for callers that own current
    /// and next packet-protection keys rather than a mutable key-phase state.
    /// The receive side uses key-update selection; the output side uses the
    /// caller-provided send keys and wire key-phase bit.
    pub fn processProtectedShortDatagramWithKeyUpdateAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedShortDatagramWithKeyUpdate(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        const output = try self.pollProtectedShortDatagramWithKeyPhase(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
            send_key_phase,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process explicit key-update 1-RTT input with close propagation, then poll output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE and
    /// return before ordinary explicit-phase output polling.
    pub fn processProtectedShortDatagramWithKeyUpdateOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedShortDatagramWithKeyUpdateOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output = try self.pollProtectedShortDatagramWithKeyPhase(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_keys,
            send_key_phase,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Route explicit key-update 1-RTT input, then poll one explicit-phase output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the routed destination CID length is used to open the short
    /// packet, then the selected connection is polled for one response such as
    /// an ACK.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdateAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithKeyUpdateAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                send_key_phase,
            ),
        };
    }

    /// Route explicit key-update 1-RTT input through close propagation, then poll output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary output polling.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdateOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithKeyUpdateOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                send_key_phase,
            ),
        };
    }

    /// Process explicit key-update 1-RTT input, then drain explicit-phase output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedShortDatagramWithKeyUpdateAndPollDatagram()`. The
    /// caller owns each initialized output datagram.
    pub fn processProtectedShortDatagramWithKeyUpdateAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedShortDatagramWithKeyUpdate(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithKeyPhase(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
                send_key_phase,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process explicit key-update 1-RTT input with close propagation, then drain output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE and
    /// return before ordinary explicit-phase output draining.
    pub fn processProtectedShortDatagramWithKeyUpdateOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedShortDatagramWithKeyUpdateOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_keys,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            if (out.len == 0) return error.BufferTooSmall;
        };
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithKeyPhase(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_keys,
                send_key_phase,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route explicit key-update 1-RTT input, then drain explicit-phase output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, at most `out.len` Application-space datagrams are emitted
    /// for the selected connection.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdateAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithKeyUpdateAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                send_key_phase,
                out,
            ),
        };
    }

    /// Route explicit key-update 1-RTT input through close propagation, then drain output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary output draining.
    pub fn processRoutedProtectedShortDatagramWithKeyUpdateOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_keys: protection.ShortPacketKeyUpdateKeys,
        datagram: []const u8,
        dcid: []const u8,
        send_keys: protection.Aes128PacketProtectionKeys,
        send_key_phase: bool,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithKeyUpdateOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_keys,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_keys,
                send_key_phase,
                out,
            ),
        };
    }

    /// Poll one caller-owned key-phase protected 1-RTT datagram and refresh timers.
    ///
    /// This bridge keeps deterministic key-update tests and external
    /// key-phase owners on the same endpoint route/timer lifecycle as other
    /// protected short-packet paths. The returned datagram remains allocated
    /// by `connection` and must be freed by the caller. If endpoint timer
    /// refresh fails after a datagram is produced, the helper frees that
    /// datagram before returning.
    pub fn pollProtectedShortDatagramWithKeyPhaseState(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        key_phase_state: *const protection.Aes128KeyPhaseState,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedShortDatagramWithKeyPhaseState(now_nanos, dcid, key_phase_state) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one caller-owned key-phase protected 1-RTT datagram and refresh timers.
    ///
    /// The key-phase state advances only after packet authentication and frame
    /// processing succeed inside `Connection`. The endpoint lifecycle then
    /// mirrors the resulting aggregate recovery timer.
    pub fn processProtectedShortDatagramWithKeyPhaseState(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithKeyPhaseState(now_nanos, key_phase_state, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one caller-owned key-phase protected 1-RTT datagram with close propagation.
    ///
    /// The key-phase state advances only after authenticated frame processing
    /// succeeds. Classified plaintext frame errors queue CONNECTION_CLOSE and
    /// leave caller-owned key state unchanged.
    pub fn processProtectedShortDatagramWithKeyPhaseStateOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithKeyPhaseStateOrClose(now_nanos, key_phase_state, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one caller-owned key-phase protected 1-RTT datagram.
    ///
    /// The key-phase state still advances only after packet authentication
    /// and frame processing succeed inside `Connection`. The lifecycle helper
    /// first validates endpoint routing, uses the routed destination CID
    /// length for packet protection removal, then mirrors the resulting
    /// aggregate recovery timer.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseState(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            key_phase_state,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Route and process one caller-owned key-phase protected 1-RTT datagram with close propagation.
    ///
    /// This preserves endpoint route validation and only advances key-phase
    /// state after `Connection` accepts the authenticated plaintext frames.
    /// Process caller-owned key-phase 1-RTT input and select the next wakeup.
    ///
    /// This is the no-output form for socket loops that keep key-phase state
    /// outside the connection while still using endpoint-owned route/timer
    /// lifecycle. Key state advances only after authenticated receive succeeds.
    pub fn processProtectedShortDatagramWithKeyPhaseStateAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!?EndpointConnectionDeadline {
        try self.processProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            receive_key_phase_state,
            dcid_len,
            datagram,
        );
        return self.nextDeadline(connection_id, connection);
    }
    /// Route caller-owned key-phase 1-RTT input and select the next wakeup.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or key-phase state advancement. Successful receive preserves any ACK or
    /// data output for a later poll/drain step.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseStateAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .next_deadline = try self.processProtectedShortDatagramWithKeyPhaseStateAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                receive_key_phase_state,
                route.destination_connection_id.asSlice().len,
                datagram,
            ),
        };
    }
    /// Process caller-owned key-phase 1-RTT input, then poll one stateful output.
    ///
    /// The receive state advances only after authenticated packet processing
    /// succeeds. The output side uses the caller-owned send state without
    /// initiating a new key update.
    pub fn processProtectedShortDatagramWithKeyPhaseStateAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            receive_key_phase_state,
            dcid_len,
            datagram,
        );
        const output = try self.pollProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_key_phase_state,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process caller-owned key-phase 1-RTT input with close propagation, then poll output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE,
    /// preserve caller-owned key-phase state, and return before ordinary
    /// stateful output polling.
    pub fn processProtectedShortDatagramWithKeyPhaseStateOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedShortDatagramWithKeyPhaseStateOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_key_phase_state,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output = try self.pollProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            dcid,
            send_key_phase_state,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Route caller-owned key-phase 1-RTT input, then poll one stateful output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or key-phase state advancement.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseStateAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithKeyPhaseStateAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_key_phase_state,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_key_phase_state,
            ),
        };
    }

    /// Route caller-owned key-phase 1-RTT input through close propagation, then poll output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary stateful output polling.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseStateOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithKeyPhaseStateOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                receive_key_phase_state,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_key_phase_state,
            ),
        };
    }

    /// Process caller-owned key-phase 1-RTT input, then drain stateful output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedShortDatagramWithKeyPhaseStateAndPollDatagram()`.
    pub fn processProtectedShortDatagramWithKeyPhaseStateAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedShortDatagramWithKeyPhaseState(
            connection_id,
            connection,
            now_nanos,
            receive_key_phase_state,
            dcid_len,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithKeyPhaseState(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_key_phase_state,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process caller-owned key-phase 1-RTT input with close propagation, then drain output.
    ///
    /// Authenticated Application plaintext errors queue CONNECTION_CLOSE,
    /// preserve caller-owned key-phase state, and return before ordinary
    /// stateful output draining.
    pub fn processProtectedShortDatagramWithKeyPhaseStateOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        dcid_len: usize,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedShortDatagramWithKeyPhaseStateOrClose(
            connection_id,
            connection,
            now_nanos,
            receive_key_phase_state,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            if (out.len == 0) return error.BufferTooSmall;
        };
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithKeyPhaseState(
                connection_id,
                connection,
                now_nanos,
                dcid,
                send_key_phase_state,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route caller-owned key-phase 1-RTT input, then drain stateful output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or key-phase state advancement.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseStateAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithKeyPhaseStateAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_key_phase_state,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_key_phase_state,
                out,
            ),
        };
    }

    /// Route caller-owned key-phase 1-RTT input through close propagation, then drain output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Application frame errors stop before ordinary stateful output draining.
    pub fn processRoutedProtectedShortDatagramWithKeyPhaseStateOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        receive_key_phase_state: *protection.Aes128KeyPhaseState,
        datagram: []const u8,
        dcid: []const u8,
        send_key_phase_state: *const protection.Aes128KeyPhaseState,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithKeyPhaseStateOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                receive_key_phase_state,
                route.destination_connection_id.asSlice().len,
                datagram,
                dcid,
                send_key_phase_state,
                out,
            ),
        };
    }

    /// Poll one installed-key protected Handshake datagram and refresh timers.
    ///
    /// This is the TLS-owned long-packet bridge for endpoint event loops after
    /// a crypto backend has installed Handshake traffic secrets on the
    /// connection. The returned datagram remains allocated by `connection` and
    /// must be freed by the caller. If endpoint timer refresh fails after a
    /// datagram is produced, the helper frees that datagram before returning.
    pub fn pollProtectedHandshakeDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedHandshakeDatagramWithInstalledKeys(now_nanos, dcid, scid) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one installed-key protected Handshake datagram and refresh timers.
    ///
    /// The connection owns installed Handshake keys, packet-number-space state,
    /// ACK generation, and recovery cleanup. The endpoint lifecycle mirrors the
    /// resulting aggregate timer after successful processing.
    pub fn processProtectedHandshakeDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedHandshakeDatagramWithInstalledKeys(now_nanos, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process installed-key Handshake input, drive backend, and drain output.
    ///
    /// This is the single-connection TLS-owned Handshake loop step after a
    /// crypto backend has installed packet-protection keys on `connection`.
    /// It opens one protected Handshake datagram with installed peer keys,
    /// delivers reassembled CRYPTO to `backend`, then drains at most `out.len`
    /// installed-key Handshake datagrams with the installed local keys.
    /// Connection/backend/socket storage and each initialized output datagram
    /// remain caller-owned.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = dcid,
            .source_connection_id = scid,
        }};
        return try self.driveCryptoBackendStepWithDrain(&.{.handshake}, &drive_views, .{}, &.{}, &poll_views, now_nanos, .handshake, out);
    }

    /// Process installed-key Handshake input, drive backend, and poll one output.
    ///
    /// This is the one-output form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndDrainDatagrams()`.
    /// It keeps the connection/backend storage caller-owned while combining
    /// installed-key Handshake receive, backend progress, and one protected
    /// Handshake datagram poll in a single lifecycle-owned step.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );

        return try self.driveCryptoBackendInSpaceAndPollDatagram(
            connection_id,
            connection,
            .handshake,
            backend,
            scratch,
            now_nanos,
            poll_options,
        );
    }

    /// Process installed-key Handshake input through close-propagating backend.
    ///
    /// This preserves the success behavior of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndDrainDatagrams()`,
    /// while using the close-propagating receive and backend-drive paths.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and drain protected close output in the same step.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainProtectedHandshakeDatagramsWithInstalledKeys(
                    connection_id,
                    connection,
                    now_nanos,
                    dcid,
                    scid,
                    out,
                ),
            };
        };

        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = dcid,
            .source_connection_id = scid,
        }};
        return self.driveCryptoBackendsInSpaceOrCloseAndDrainDatagrams(
            .handshake,
            &drive_views,
            &poll_views,
            now_nanos,
            .handshake,
            out,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainProtectedHandshakeDatagramsWithInstalledKeys(
                    connection_id,
                    connection,
                    now_nanos,
                    dcid,
                    scid,
                    out,
                ),
            };
        };
    }

    /// Process installed-key Handshake input through close-propagating backend, then poll output.
    ///
    /// This preserves the success behavior of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndPollDatagram()`,
    /// while using the close-propagating receive and backend-drive paths.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and poll protected close output in the same step.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const output = try self.pollProtectedHandshakeDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                poll_options.destination_connection_id,
                poll_options.source_connection_id,
            );
            return .{
                .backend = .{},
                .datagram = if (output) |bytes| .{
                    .connection_id = connection_id,
                    .datagram = bytes,
                } else null,
            };
        };

        return self.driveCryptoBackendInSpaceOrCloseAndPollDatagram(
            connection_id,
            connection,
            .handshake,
            backend,
            scratch,
            now_nanos,
            poll_options,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const output = try self.pollProtectedHandshakeDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                poll_options.destination_connection_id,
                poll_options.source_connection_id,
            );
            return .{
                .backend = .{},
                .datagram = if (output) |bytes| .{
                    .connection_id = connection_id,
                    .datagram = bytes,
                } else null,
            };
        };
    }

    /// Process one installed-key protected Handshake datagram with close propagation.
    ///
    /// Installed-key lookup and success behavior remain in `Connection`.
    /// Authenticated plaintext frame errors queue CONNECTION_CLOSE before
    /// `InvalidPacket` is returned.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedHandshakeDatagramWithInstalledKeysOrClose(now_nanos, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one installed-key protected Handshake datagram.
    ///
    /// This is the endpoint event-loop receive bridge for TLS-owned Handshake
    /// packet protection keys. The route must resolve to `connection_id`;
    /// the connection then opens the packet with its installed Handshake keys,
    /// and the endpoint lifecycle mirrors the resulting recovery timer.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        return route;
    }

    /// Route and process one installed-key protected Handshake datagram with close propagation.
    ///
    /// This is the endpoint event-loop receive bridge for TLS-owned Handshake
    /// packet protection when authenticated frame-payload peer errors should
    /// produce CONNECTION_CLOSE.
    /// Process installed-key Handshake input, then poll one installed-key output.
    ///
    /// This is the lightweight TLS-owned Handshake socket-loop step for ACK,
    /// PING, close, or already queued CRYPTO output when no backend drive is
    /// needed. The caller owns any returned datagram.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        const output = try self.pollProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process installed-key Handshake input with close propagation, then poll output.
    ///
    /// Authenticated frame errors queue CONNECTION_CLOSE and poll protected
    /// close output instead of ordinary installed-key Handshake output.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const output = try self.pollProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Route installed-key Handshake input, then poll one installed-key output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedHandshakeDatagramWithInstalledKeysAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
                scid,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }
    /// Process installed-key Handshake input, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndPollDatagram()`.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedHandshakeDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process installed-key Handshake input with close propagation, then drain output.
    ///
    /// Authenticated frame errors queue CONNECTION_CLOSE and drain protected
    /// close output instead of ordinary installed-key Handshake output.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedHandshakeDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        return self.drainProtectedHandshakeDatagramsWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
            scid,
            out,
        );
    }

    fn drainProtectedHandshakeDatagramsWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedHandshakeDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                dcid,
                scid,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route installed-key Handshake input, then drain installed-key output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedHandshakeDatagramWithInstalledKeysAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
                scid,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Route installed-key Handshake input through close propagation, then drain output.
    ///
    /// This preserves routed receive behavior while ensuring authenticated
    /// Handshake frame errors stop before ordinary installed-key output draining.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedHandshakeDatagramWithInstalledKeysOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
                scid,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process installed-key Handshake input, drive backend, and select a wakeup.
    ///
    /// This is the no-output TLS-owned Handshake receive/backend step for
    /// socket loops. It authenticates and processes the incoming Handshake
    /// datagram, delivers received CRYPTO to `backend`, queues backend-produced
    /// CRYPTO on the connection, refreshes endpoint recovery scheduling, and
    /// returns the next endpoint-visible deadline without polling output.
    /// Unified Handshake datagram processing with options-struct interface.
    /// Replaces 10 processProtectedHandshakeDatagram variants.
    /// Unified long datagram processing with options-struct interface.
    /// Replaces 4+ processProtectedLongDatagramInSpace variants.
    /// Unified recovery timer service with options-struct interface.
    /// Replaces 5+ serviceRecoveryTimer variants.
    pub fn processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointCryptoBackendDriveNextDeadlineResult {
        try self.processProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        return try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
            connection_id,
            connection,
            .handshake,
            backend,
            scratch,
        );
    }
    /// Route installed-key Handshake input, drive backend, and select a wakeup.
    ///
    /// This is the routed no-output form for socket loops where the endpoint
    /// lifecycle owns route validation but connection/backend storage remains
    /// caller-owned. Route errors and connection-id mismatches fail before
    /// packet processing or backend drive.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.processRoutedProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
        );
        return .{
            .route = route,
            .backend = try self.driveCryptoBackendInSpaceAndSelectNextDeadline(
                connection_id,
                connection,
                .handshake,
                backend,
                scratch,
            ),
        };
    }
    /// Route installed-key Handshake input, drive backend, and drain output.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndDrainDatagrams()`.
    /// The endpoint lifecycle owns route validation before the caller-owned
    /// connection processes the installed-key Handshake datagram and backend
    /// progress. Connection/backend/socket storage and output datagrams remain
    /// caller-owned.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.processRoutedProtectedHandshakeDatagramWithInstalledKeys(
            connection_id,
            connection,
            path,
            now_nanos,
            datagram,
        );
        const drive_views = [_]EndpointCryptoBackendDriveView{.{
            .connection_id = connection_id,
            .connection = connection,
            .backend = backend,
            .scratch = scratch,
        }};
        const poll_views = [_]EndpointConnectionPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .destination_connection_id = dcid,
            .source_connection_id = scid,
        }};
        return .{
            .route = route,
            .backend = try self.driveCryptoBackendStepWithDrain(&.{.handshake}, &drive_views, .{}, &.{}, &poll_views, now_nanos, .handshake, out),
        };
    }

    /// Route installed-key Handshake input, drive backend, and poll one output.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndPollDatagram()`.
    /// The endpoint lifecycle owns route validation before the caller-owned
    /// connection processes the installed-key Handshake datagram and backend
    /// progress. Connection/backend/socket storage and the optional output
    /// datagram remain caller-owned.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                datagram,
                backend,
                scratch,
                poll_options,
            ),
        };
    }

    /// Route installed-key Handshake input through close-propagating backend.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndDrainDatagrams()`.
    /// Route errors and connection-id mismatches fail before packet processing.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and drain protected close output in the same step.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        dcid: []const u8,
        scid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                datagram,
                backend,
                scratch,
                dcid,
                scid,
                out,
            ),
        };
    }

    /// Route installed-key Handshake input through close-propagating backend, then poll output.
    ///
    /// This is the routed socket-loop form of
    /// `processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndPollDatagram()`.
    /// Route errors and connection-id mismatches fail before packet processing.
    /// Authenticated frame errors or backend peer transport-parameter errors
    /// queue and poll protected close output in the same step.
    pub fn processRoutedProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend: CryptoBackend,
        scratch: []u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedHandshakeDatagramWithInstalledKeysAndDriveCryptoBackendOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                datagram,
                backend,
                scratch,
                poll_options,
            ),
        };
    }

    /// Poll one installed-key protected 0-RTT datagram and refresh timers.
    ///
    /// This is the TLS early-data bridge for endpoint event loops after a
    /// crypto backend has installed local 0-RTT traffic secrets on a client
    /// connection. The returned datagram remains allocated by `connection` and
    /// must be freed by the caller. If endpoint timer refresh fails after a
    /// datagram is produced, the helper frees that datagram before returning.
    pub fn pollProtectedZeroRttDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
        scid: []const u8,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedZeroRttDatagramWithInstalledKeys(now_nanos, dcid, scid) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Process one installed-key protected 0-RTT datagram and refresh timers.
    ///
    /// The connection still enforces explicit early-data acceptance through
    /// `acceptZeroRtt()`, validates 0-RTT frame restrictions, and owns
    /// Application packet-number recovery state. The endpoint lifecycle mirrors
    /// the resulting aggregate timer after successful processing.
    pub fn processProtectedZeroRttDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedZeroRttDatagramWithInstalledKeys(now_nanos, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one installed-key protected 0-RTT datagram with close propagation.
    ///
    /// Explicit 0-RTT acceptance remains enforced by `Connection`; accepted
    /// packets with authenticated plaintext frame errors queue CONNECTION_CLOSE.
    pub fn processProtectedZeroRttDatagramWithInstalledKeysOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedZeroRttDatagramWithInstalledKeysOrClose(now_nanos, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one installed-key protected 0-RTT datagram.
    ///
    /// This is the endpoint event-loop receive bridge for TLS early-data
    /// packet protection keys. The route must resolve to `connection_id`;
    /// the connection still enforces 0-RTT acceptance and frame restrictions,
    /// and the endpoint lifecycle mirrors the resulting recovery timer.
    pub fn processRoutedProtectedZeroRttDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedZeroRttDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        return route;
    }

    /// Route and process one installed-key protected 0-RTT datagram with close propagation.
    ///
    /// This keeps TLS early-data receive on the endpoint route boundary while
    /// allowing authenticated frame-payload peer errors to queue CONNECTION_CLOSE.
    /// Process installed-key 0-RTT input, then poll one installed-key short output.
    ///
    /// This is the TLS-owned key variant of
    /// `processProtectedZeroRttDatagramAndPollShortDatagram()`. The connection
    /// owns early-data receive state and 1-RTT send keys; the endpoint owns the
    /// route/timer boundary and returns at most one Application-space response.
    pub fn processProtectedZeroRttDatagramWithInstalledKeysAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedZeroRttDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        const output = try self.pollProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process installed-key 0-RTT input, then drain installed-key short output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedZeroRttDatagramWithInstalledKeysAndPollShortDatagram()`.
    /// The caller owns each initialized output datagram.
    pub fn processProtectedZeroRttDatagramWithInstalledKeysAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedZeroRttDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                dcid,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Process installed-key 0-RTT input with close propagation, then poll output.
    ///
    /// Authenticated 0-RTT frame errors queue CONNECTION_CLOSE and return
    /// before polling ordinary installed-key 1-RTT output.
    pub fn processProtectedZeroRttDatagramWithInstalledKeysOrCloseAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedZeroRttDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        const output = try self.pollProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid,
        );
        return if (output) |bytes| .{
            .connection_id = connection_id,
            .datagram = bytes,
        } else null;
    }

    /// Process installed-key 0-RTT input with close propagation, then drain output.
    ///
    /// Authenticated 0-RTT frame errors queue CONNECTION_CLOSE and return
    /// before any ordinary installed-key 1-RTT output is drained.
    pub fn processProtectedZeroRttDatagramWithInstalledKeysOrCloseAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedZeroRttDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            datagram,
        );
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const output = self.pollProtectedShortDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                dcid,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = .{
                .connection_id = connection_id,
                .datagram = output orelse return result,
            };
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Route installed-key 0-RTT input, then poll one installed-key short output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the endpoint processes accepted early data and polls at most
    /// one installed-key Application-space short-header datagram.
    pub fn processRoutedProtectedZeroRttDatagramWithInstalledKeysAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedZeroRttDatagramWithInstalledKeysAndPollShortDatagram(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
            ),
        };
    }

    /// Route installed-key 0-RTT input, then drain installed-key short output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the endpoint processes accepted early data and drains at
    /// most `out.len` installed-key Application-space short-header datagrams.
    pub fn processRoutedProtectedZeroRttDatagramWithInstalledKeysAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedZeroRttDatagramWithInstalledKeysAndDrainShortDatagrams(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
                out,
            ),
        };
    }

    /// Route installed-key 0-RTT input through close propagation, then poll output.
    ///
    /// This keeps TLS-owned early-data receive on the endpoint route boundary
    /// while ensuring authenticated frame errors stop before ordinary output
    /// polling.
    pub fn processRoutedProtectedZeroRttDatagramWithInstalledKeysOrCloseAndPollShortDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedZeroRttDatagramWithInstalledKeysOrCloseAndPollShortDatagram(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
            ),
        };
    }

    /// Route installed-key 0-RTT input through close propagation, then drain output.
    ///
    /// This keeps TLS-owned early-data receive on the endpoint route boundary
    /// while ensuring authenticated frame errors stop before ordinary output
    /// draining.
    pub fn processRoutedProtectedZeroRttDatagramWithInstalledKeysOrCloseAndDrainShortDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        dcid: []const u8,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedZeroRttDatagramWithInstalledKeysOrCloseAndDrainShortDatagrams(
                connection_id,
                connection,
                now_nanos,
                datagram,
                dcid,
                out,
            ),
        };
    }

    /// Poll one installed-key protected 1-RTT datagram and refresh recovery scheduling.
    ///
    /// This is the endpoint event-loop bridge for the common "connection owns
    /// packet protection keys, endpoint owns timers" boundary. The returned
    /// datagram remains allocated by `connection` and must be freed by the
    /// caller. If timer refresh fails after a datagram is produced, the helper
    /// frees that datagram before returning the error.
    pub fn pollProtectedShortDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid: []const u8,
    ) Error!?[]u8 {
        const datagram = connection.pollProtectedShortDatagramWithInstalledKeys(now_nanos, dcid) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        errdefer if (datagram) |bytes| connection.allocator.free(bytes);
        try self.armRecoveryTimerFromConnection(connection_id, connection);
        return datagram;
    }

    /// Socket-facing installed-key datagram output entrypoint.
    ///
    /// This is the public endpoint-loop name for polling the next packet after
    /// a TLS backend has installed packet-protection keys on `connection`.
    pub fn pollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?[]u8 {
        return switch (options.space) {
            .handshake => self.pollProtectedHandshakeDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                options.destination_connection_id,
                options.source_connection_id,
            ),
            .zero_rtt => self.pollProtectedZeroRttDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                options.destination_connection_id,
                options.source_connection_id,
            ),
            .application => self.pollProtectedShortDatagramWithInstalledKeys(
                connection_id,
                connection,
                now_nanos,
                options.destination_connection_id,
            ),
        };
    }

    /// Poll the first installed-key datagram across caller-owned connections.
    ///
    /// This helper keeps output polling and endpoint recovery-timer mirroring
    /// under the lifecycle owner while preserving caller-owned connection
    /// storage and caller-defined fairness/order. It returns the first
    /// connection in `connections` that emits a protected datagram.
    /// Unified datagram poll with options-struct interface.
    ///
    /// Replaces pollDatagram, pollDatagramWithInstalledKeys,
    /// pollDatagramAcrossConnections, and their variants.
    pub fn pollDatagramAcrossConnections(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            const datagram = try self.pollDatagram(
                view.connection_id,
                view.connection,
                now_nanos,
                .{
                    .space = space,
                    .destination_connection_id = view.destination_connection_id,
                    .source_connection_id = view.source_connection_id,
                },
            );
            if (datagram) |bytes| {
                return .{
                    .connection_id = view.connection_id,
                    .datagram = bytes,
                };
            }
        }
        return null;
    }

    /// Poll the first installed-key datagram using per-connection options.
    ///
    /// This form lets caller-owned connection maps preserve non-default output
    /// choices such as accepted 0-RTT long-header packetization while still
    /// using lifecycle-owned recovery timer mirroring.
    pub fn pollDatagramAcrossConnectionsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
    ) Error!?EndpointPolledDatagramResult {
        for (connections) |view| {
            const datagram = try self.pollDatagram(
                view.connection_id,
                view.connection,
                now_nanos,
                view.poll_options,
            );
            if (datagram) |bytes| {
                return .{
                    .connection_id = view.connection_id,
                    .datagram = bytes,
                };
            }
        }
        return null;
    }

    /// Drain installed-key datagrams into caller-owned result slots.
    ///
    /// The output slice bounds work per socket-loop iteration and gives the
    /// caller explicit ownership of each returned datagram. If polling fails
    /// after earlier datagrams were written, this returns the count together
    /// with `first_error` so callers can release the initialized entries before
    /// surfacing the error.
    pub fn drainDatagramsAcrossConnections(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionPollView,
        now_nanos: i64,
        space: EndpointInstalledKeyDatagramSpace,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const polled = self.pollDatagramAcrossConnections(
                connections,
                now_nanos,
                space,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = polled orelse return result;
            result.datagrams_written += 1;
        }
        return result;
    }

    /// Drain installed-key datagrams using per-connection output options.
    ///
    /// This is the bounded-output form of
    /// `pollDatagramAcrossConnectionsWithInstalledKeyOptions()`.
    pub fn drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connections: []const EndpointConnectionInstalledKeyPollView,
        now_nanos: i64,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        var result = EndpointDatagramDrainResult{};
        while (result.datagrams_written < out.len) {
            const polled = self.pollDatagramAcrossConnectionsWithInstalledKeyOptions(
                connections,
                now_nanos,
            ) catch |err| {
                result.first_error = err;
                return result;
            };
            out[result.datagrams_written] = polled orelse return result;
            result.datagrams_written += 1;
        }
        return result;
    }
    /// Process one installed-key protected 1-RTT datagram and refresh timers.
    ///
    /// ACK processing, loss recovery cleanup, and ACK generation state stay in
    /// the connection. The endpoint lifecycle mirrors the resulting aggregate
    /// loss/PTO timer so socket event loops do not need a separate manual
    /// refresh after every protected receive.
    pub fn processProtectedShortDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithInstalledKeys(now_nanos, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Process one installed-key protected 1-RTT datagram with close propagation.
    ///
    /// Connection-owned key-phase state advances only after authenticated
    /// plaintext frame processing succeeds. Classified frame errors queue
    /// CONNECTION_CLOSE and leave installed key state unchanged.
    pub fn processProtectedShortDatagramWithInstalledKeysOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!void {
        connection.processProtectedShortDatagramWithInstalledKeysOrClose(now_nanos, dcid_len, datagram) catch |err| {
            self.refreshRecoveryTimerAfterConnectionError(connection_id, connection);
            return err;
        };
        try self.armRecoveryTimerFromConnection(connection_id, connection);
    }

    /// Route and process one installed-key protected 1-RTT datagram.
    ///
    /// Socket loops can use this after the connection owns 1-RTT packet
    /// protection keys. The route must resolve to `connection_id`; the routed
    /// destination CID length is used for short-header packet protection
    /// removal, and the endpoint recovery timer is refreshed after successful
    /// connection processing.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeys(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Route and process one installed-key protected 1-RTT datagram with close propagation.
    ///
    /// Socket loops can use this after the connection owns 1-RTT keys and wants
    /// authenticated frame-payload peer errors to produce CONNECTION_CLOSE.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!endpoint.RouteResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        try self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            route.destination_connection_id.asSlice().len,
            datagram,
        );
        return route;
    }

    /// Route and process one installed-key protected 1-RTT datagram, commit a
    /// validated path migration, and propagate close on frame errors.
    ///
    /// This is the installed-key counterpart of
    /// `processRoutedProtectedShortDatagramAndUpdatePathOrClose()`: it uses the
    /// connection's installed 1-RTT keys instead of caller-supplied keys, and
    /// commits a route path update only when the packet routes to
    /// `connection_id`, authentication/frame processing succeeds, the routed
    /// tuple differs from the stored route, and the connection consumes at
    /// least one outstanding PATH_CHALLENGE.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndUpdatePathOrClose(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointPathValidatedShortDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;

        const outstanding_before = connection.outstandingPathChallengeCount();
        try self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            route.destination_connection_id.asSlice().len,
            datagram,
        );

        const outstanding_after = connection.outstandingPathChallengeCount();
        const updated_route: ?endpoint.RouteResult = if (route.path_changed and outstanding_after < outstanding_before)
            try self.updateRoutePathFromValidatedDatagramAndResetSpinBit(
                route.destination_connection_id.asSlice(),
                path,
                connection,
            )
        else
            null;

        return .{
            .route = route,
            .updated_route = updated_route,
        };
    }

    /// Process one installed-key 1-RTT datagram and select the next wakeup.
    ///
    /// This is the no-output receive step for endpoint loops that want to
    /// update timer interest after 1-RTT input without immediately polling
    /// ACK, STREAM, close, or PTO output.
    pub fn processProtectedShortDatagramWithInstalledKeysAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
    ) Error!?EndpointConnectionDeadline {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.nextDeadline(connection_id, connection);
    }
    /// Route/process one installed-key 1-RTT datagram and select the next wakeup.
    ///
    /// Route errors and connection-id mismatches fail before packet processing.
    /// On success, the routed destination CID length is used to open the short
    /// packet and endpoint-visible deadline selection is returned without
    /// polling installed-key output.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
    ) EndpointProtectedDatagramError!EndpointRoutedNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .next_deadline = try self.processProtectedShortDatagramWithInstalledKeysAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
            ),
        };
    }
    /// Process installed-key 1-RTT input, drive a backend, and select a wakeup.
    ///
    /// This is the direct no-output receive-to-backend step for socket loops
    /// that have already selected a connection. It lets post-handshake
    /// Application-space CRYPTO advance through the TLS backend while leaving
    /// ACK and CRYPTO output queued for a later installed-key poll or drain.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceAndSelectNextDeadline(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        );
    }

    /// Process installed-key 1-RTT input through close propagation, drive a backend, and select a wakeup.
    ///
    /// Authenticated Application frame errors or backend peer
    /// transport-parameter errors queue CONNECTION_CLOSE and return the current
    /// wakeup selection instead of failing before deadline selection. Backend
    /// output is not pulled after a peer-parameter close path, leaving the
    /// close frame as the next observable output.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        return self.driveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
    }

    /// Process installed-key 1-RTT input, drive a compatible-version backend, and select a wakeup.
    ///
    /// This extends the no-output receive-to-backend step with RFC 9368
    /// compatible version selection while leaving ACK and backend output queued
    /// for a later installed-key poll or drain.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
        );
    }

    /// Process installed-key 1-RTT input through compatible-version close propagation.
    ///
    /// Authenticated Application frame errors or RFC 9368 peer Version
    /// Information errors queue CONNECTION_CLOSE and return the current wakeup
    /// selection instead of failing before deadline selection.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) Error!EndpointCryptoBackendDriveNextDeadlineResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
        return self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .next_deadline = self.nextDeadline(connection_id, connection),
            };
        };
    }

    /// Route installed-key 1-RTT input, drive a backend, and select a wakeup.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, output remains queued for a later
    /// installed-key output step.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
            ),
        };
    }

    /// Route installed-key 1-RTT input through close propagation and backend drive.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or backend
    /// peer-parameter errors queue CONNECTION_CLOSE and stop before ordinary
    /// deadline selection.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
            ),
        };
    }

    /// Route installed-key 1-RTT input through compatible-version backend drive.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, peer Version Information is handled
    /// by the compatible-version backend path before wakeup selection.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Route installed-key 1-RTT input through compatible-version close propagation.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or peer Version
    /// Information errors queue CONNECTION_CLOSE and stop before ordinary
    /// deadline selection.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveNextDeadlineResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndSelectNextDeadline(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
            ),
        };
    }

    /// Process installed-key 1-RTT input, drive a backend, and poll output.
    ///
    /// This is the direct receive-to-backend-to-output step for socket loops
    /// that have already selected a connection. Application-space backend
    /// output and receive-side ACKs are eligible for the same installed-key
    /// poll step after packet processing.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceAndPollDatagram(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            poll_now_nanos,
            poll_options,
        );
    }

    /// Process installed-key 1-RTT input through close propagation, drive a backend, and poll output.
    ///
    /// Authenticated Application frame errors or backend peer-parameter errors
    /// queue CONNECTION_CLOSE and poll protected close output instead of
    /// ordinary installed-key output. Successful paths preserve the receive-to-backend-to-output
    /// behavior of the non-close-propagating variant.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const polled = try self.pollDatagram(
                connection_id,
                connection,
                poll_now_nanos,
                poll_options,
            );
            return .{
                .backend = .{},
                .datagram = if (polled) |out_datagram| .{
                    .connection_id = connection_id,
                    .datagram = out_datagram,
                } else null,
            };
        };
        return self.driveCryptoBackendInSpaceOrCloseAndPollDatagram(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            poll_now_nanos,
            poll_options,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const polled = try self.pollDatagram(
                connection_id,
                connection,
                poll_now_nanos,
                poll_options,
            );
            return .{
                .backend = .{},
                .datagram = if (polled) |out_datagram| .{
                    .connection_id = connection_id,
                    .datagram = out_datagram,
                } else null,
            };
        };
    }

    /// Process installed-key 1-RTT input, drive a compatible-version backend, and poll output.
    ///
    /// This is the direct receive-to-backend-to-output step for RFC
    /// 9368-compatible handshakes. Application-space backend output and
    /// receive-side ACKs are eligible for the same installed-key poll step
    /// after peer Version Information handling.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
            poll_now_nanos,
            poll_options,
        );
    }

    /// Process installed-key 1-RTT input through compatible-version close propagation and poll output.
    ///
    /// Authenticated Application frame errors or peer Version Information
    /// errors queue CONNECTION_CLOSE and poll protected close output instead of
    /// ordinary installed-key output. Successful paths preserve the receive-to-backend-to-
    /// output behavior of the non-close-propagating variant.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!EndpointCryptoBackendDriveDatagramResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const polled = try self.pollDatagram(
                connection_id,
                connection,
                poll_now_nanos,
                poll_options,
            );
            return .{
                .backend = .{},
                .datagram = if (polled) |out_datagram| .{
                    .connection_id = connection_id,
                    .datagram = out_datagram,
                } else null,
            };
        };
        return self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
            poll_now_nanos,
            poll_options,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            const polled = try self.pollDatagram(
                connection_id,
                connection,
                poll_now_nanos,
                poll_options,
            );
            return .{
                .backend = .{},
                .datagram = if (polled) |out_datagram| .{
                    .connection_id = connection_id,
                    .datagram = out_datagram,
                } else null,
            };
        };
    }

    /// Route installed-key 1-RTT input, drive a backend, and poll output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, the selected connection is driven and
    /// polled for at most one installed-key datagram.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                poll_now_nanos,
                poll_options,
            ),
        };
    }

    /// Route installed-key 1-RTT input through close propagation, drive a backend, and poll output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or backend
    /// peer-parameter errors queue CONNECTION_CLOSE and stop before ordinary
    /// installed-key output polling.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                poll_now_nanos,
                poll_options,
            ),
        };
    }

    /// Route installed-key 1-RTT input, drive a compatible-version backend, and poll output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, peer Version Information is handled
    /// before the selected connection is polled for one installed-key datagram.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_now_nanos,
                poll_options,
            ),
        };
    }

    /// Route installed-key 1-RTT input through compatible-version close propagation and poll output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or peer Version
    /// Information errors queue CONNECTION_CLOSE and stop before ordinary
    /// installed-key output polling.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        poll_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
                poll_now_nanos,
                poll_options,
            ),
        };
    }

    /// Process installed-key 1-RTT input, drive a backend, and drain output.
    ///
    /// This is the bounded-output receive-to-backend step for socket loops
    /// that have already selected a connection. The caller-provided output
    /// slice bounds installed-key output after backend progress.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceAndDrainDatagrams(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            drain_now_nanos,
            poll_options,
            out,
        );
    }

    /// Process installed-key 1-RTT input through close propagation, drive a backend, and drain output.
    ///
    /// Authenticated Application frame errors or backend peer-parameter errors
    /// queue CONNECTION_CLOSE and drain protected close output instead of
    /// ordinary bounded output. Successful paths preserve the bounded receive-to-backend
    /// output behavior of the non-close-propagating variant.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainInstalledKeyDatagrams(
                    connection_id,
                    connection,
                    drain_now_nanos,
                    poll_options,
                    out,
                ),
            };
        };
        return self.driveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            drain_now_nanos,
            poll_options,
            out,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainInstalledKeyDatagrams(
                    connection_id,
                    connection,
                    drain_now_nanos,
                    poll_options,
                    out,
                ),
            };
        };
    }

    /// Process installed-key 1-RTT input, drive a compatible-version backend, and drain output.
    ///
    /// This is the bounded-output receive-to-backend step for RFC
    /// 9368-compatible handshakes. Peer Version Information is handled before
    /// the caller-provided output slice bounds installed-key output.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        return self.driveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
            drain_now_nanos,
            poll_options,
            out,
        );
    }

    /// Process installed-key 1-RTT input through compatible-version close propagation and drain output.
    ///
    /// Authenticated Application frame errors or peer Version Information
    /// errors queue CONNECTION_CLOSE and drain protected close output instead of
    /// ordinary bounded output. Successful paths preserve the bounded receive-to-backend
    /// output behavior of the non-close-propagating variant.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointCryptoBackendDriveDatagramDrainResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainInstalledKeyDatagrams(
                    connection_id,
                    connection,
                    drain_now_nanos,
                    poll_options,
                    out,
                ),
            };
        };
        return self.driveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
            connection_id,
            connection,
            backend_space,
            backend,
            scratch,
            compatibilities,
            drain_now_nanos,
            poll_options,
            out,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            return .{
                .backend = .{},
                .drain = self.drainInstalledKeyDatagrams(
                    connection_id,
                    connection,
                    drain_now_nanos,
                    poll_options,
                    out,
                ),
            };
        };
    }

    /// Route installed-key 1-RTT input, drive a backend, and drain output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, backend progress is applied before
    /// bounded installed-key output draining.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                drain_now_nanos,
                poll_options,
                out,
            ),
        };
    }

    /// Route installed-key 1-RTT input through close propagation, drive a backend, and drain output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or backend
    /// peer-parameter errors queue CONNECTION_CLOSE and stop before ordinary
    /// bounded installed-key output draining.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                drain_now_nanos,
                poll_options,
                out,
            ),
        };
    }

    /// Route installed-key 1-RTT input, drive a compatible-version backend, and drain output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. On success, peer Version Information is handled
    /// before bounded installed-key output draining.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
                drain_now_nanos,
                poll_options,
                out,
            ),
        };
    }

    /// Route installed-key 1-RTT input through compatible-version close propagation and drain output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing
    /// or backend callbacks. Authenticated frame errors or peer Version
    /// Information errors queue CONNECTION_CLOSE and stop before ordinary
    /// bounded installed-key output draining.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        backend_space: PacketNumberSpace,
        backend: CryptoBackend,
        scratch: []u8,
        compatibilities: []const VersionCompatibility,
        drain_now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedCryptoBackendDriveDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .backend = try self.processProtectedShortDatagramWithInstalledKeysAndDriveCryptoBackendInSpaceWithCompatibleVersionOrCloseAndDrainDatagrams(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                backend_space,
                backend,
                scratch,
                compatibilities,
                drain_now_nanos,
                poll_options,
                out,
            ),
        };
    }

    /// Process one installed-key 1-RTT datagram, then poll installed-key output.
    ///
    /// This is the single-connection receive-to-output loop step for callers
    /// that already selected a connection and know the short-header
    /// destination CID length. The helper processes the received packet, then
    /// polls at most one installed-key datagram such as an ACK.
    pub fn processProtectedShortDatagramWithInstalledKeysAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointPolledDatagramResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        const polled = try self.pollDatagram(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        );
        return if (polled) |out_datagram| .{
            .connection_id = connection_id,
            .datagram = out_datagram,
        } else null;
    }

    /// Process one installed-key 1-RTT datagram with close propagation, then poll output.
    ///
    /// Authenticated frame-payload errors queue CONNECTION_CLOSE and poll
    /// protected close output instead of ordinary installed-key output.
    pub fn processProtectedShortDatagramWithInstalledKeysOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) Error!?EndpointPolledDatagramResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
        };
        const polled = try self.pollDatagram(
            connection_id,
            connection,
            now_nanos,
            poll_options,
        );
        return if (polled) |out_datagram| .{
            .connection_id = connection_id,
            .datagram = out_datagram,
        } else null;
    }

    /// Route/process one installed-key 1-RTT datagram and poll installed-key output.
    ///
    /// This is the one-output socket-loop step for a received 1-RTT short
    /// packet after the connection owns packet-protection keys. The helper
    /// validates endpoint routing before packet processing, then polls at most
    /// one Application-space datagram such as an ACK or queued STREAM frame.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithInstalledKeysAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                poll_options,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Route/process one installed-key 1-RTT datagram with close propagation, then poll output.
    ///
    /// Authenticated frame-payload errors queue CONNECTION_CLOSE and poll
    /// protected close output. Route mismatches fail before packet processing.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysOrCloseAndPollDatagram(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .datagram = try self.processProtectedShortDatagramWithInstalledKeysOrCloseAndPollDatagram(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                poll_options,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Process one installed-key 1-RTT datagram, then drain installed-key output.
    ///
    /// This is the bounded-output form of
    /// `processProtectedShortDatagramWithInstalledKeysAndPollDatagram()`.
    /// Returned datagrams remain caller-owned and must be freed by the caller.
    /// Process one installed-key 1-RTT datagram, then drain explicit output.
    ///
    /// This is the bounded-output counterpart of
    /// `processProtectedShortDatagramWithInstalledKeysAndPollDatagram()`,
    /// preserving the caller-selected installed-key packetization options for
    /// every drained datagram.
    pub fn processProtectedShortDatagramWithInstalledKeysAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        try self.processProtectedShortDatagramWithInstalledKeys(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        );
        const poll_views = [_]EndpointConnectionInstalledKeyPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .poll_options = poll_options,
        }};
        return self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
            &poll_views,
            now_nanos,
            out,
        );
    }

    /// Process one installed-key 1-RTT datagram with close propagation, then drain output.
    ///
    /// Authenticated frame-payload errors queue CONNECTION_CLOSE and return
    /// before output draining so callers do not receive partial output after a
    /// failed receive step.
    /// Process one installed-key 1-RTT datagram through close propagation, then drain explicit output.
    ///
    /// Authenticated frame-payload errors queue CONNECTION_CLOSE and drain
    /// protected close output instead of ordinary installed-key output.
    pub fn processProtectedShortDatagramWithInstalledKeysOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        dcid_len: usize,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) Error!EndpointDatagramDrainResult {
        self.processProtectedShortDatagramWithInstalledKeysOrClose(
            connection_id,
            connection,
            now_nanos,
            dcid_len,
            datagram,
        ) catch |err| {
            if (err != error.InvalidPacket or connection.connectionState() != .closing) return err;
            if (out.len == 0) return error.BufferTooSmall;
        };
        return self.drainInstalledKeyDatagrams(
            connection_id,
            connection,
            now_nanos,
            poll_options,
            out,
        );
    }

    fn drainInstalledKeyDatagrams(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        now_nanos: i64,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointDatagramDrainResult {
        const poll_views = [_]EndpointConnectionInstalledKeyPollView{.{
            .connection_id = connection_id,
            .connection = connection,
            .poll_options = poll_options,
        }};
        return self.drainDatagramsAcrossConnectionsWithInstalledKeyOptions(
            &poll_views,
            now_nanos,
            out,
        );
    }

    /// Route/process one installed-key 1-RTT datagram and drain installed-key output.
    ///
    /// This is the bounded-output socket-loop step for a received 1-RTT short
    /// packet after the connection owns packet-protection keys. The helper
    /// validates endpoint routing before packet processing, then drains at most
    /// `out.len` Application-space datagrams such as ACKs or queued STREAM
    /// data. Returned datagrams remain caller-owned and must be freed by the
    /// caller.
    /// Route/process one installed-key 1-RTT datagram and drain explicit output.
    ///
    /// Route selection and packet processing match
    /// `processRoutedProtectedShortDatagramWithInstalledKeysAndDrainDatagrams()`,
    /// while output packetization uses the full caller-provided options.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithInstalledKeysAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                poll_options,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Route/process one installed-key 1-RTT datagram with close propagation, then drain output.
    ///
    /// Authenticated frame-payload errors queue CONNECTION_CLOSE and return
    /// before output draining so callers do not receive partial output after a
    /// failed receive step. Route mismatches fail before packet processing.
    /// Route/process one installed-key 1-RTT datagram through close propagation and drain explicit output.
    ///
    /// Route errors and connection-id mismatches fail before packet processing;
    /// authenticated frame errors stop before any installed-key output drain.
    pub fn processRoutedProtectedShortDatagramWithInstalledKeysOrCloseAndDrainDatagramsWithInstalledKeyOptions(
        self: *EndpointConnectionLifecycle,
        connection_id: u64,
        connection: *Connection,
        path: endpoint.Udp4Tuple,
        now_nanos: i64,
        datagram: []const u8,
        poll_options: EndpointPollInstalledKeyDatagramOptions,
        out: []EndpointPolledDatagramResult,
    ) EndpointProtectedDatagramError!EndpointRoutedDatagramDrainResult {
        const route = try self.routeDatagram(path, datagram);
        if (route.connection_id != connection_id) return error.InvalidPacket;
        return .{
            .route = route,
            .drain = try self.processProtectedShortDatagramWithInstalledKeysOrCloseAndDrainDatagramsWithInstalledKeyOptions(
                connection_id,
                connection,
                now_nanos,
                route.destination_connection_id.asSlice().len,
                datagram,
                poll_options,
                out,
            ),
            .next_deadline = self.nextDeadline(connection_id, connection),
        };
    }

    /// Retire all routes and any armed recovery timer for one connection handle.
    pub fn retireConnection(self: *EndpointConnectionLifecycle, connection_id: u64) EndpointConnectionRetireResult {
        _ = self.ecn_paths.resetConnection(connection_id);
        return .{
            .routes_retired = self.router.retireConnectionRoutes(connection_id),
            .recovery_timer_disarmed = self.recovery_timers.disarmConnection(connection_id),
        };
    }
};
