# Upstreaming the zmosh quicz fork

## Purpose

This plan describes how to upstream the reusable quicz work carried by zmosh
without merging the zmosh integration branch wholesale. It is independent of
zmosh Q3: Q3 keeps the tagged quicz dependency immutable and requires no quicz
changes.

The end state is either:

- the required behavior lands upstream and zmosh repins to an upstream commit;
  or
- upstream accepts an equivalent API and zmosh adapts to it before dropping the
  fork.

## Verified baseline

Snapshot verified on 2026-08-19:

- common base: `b435220` (`v0.1.0` release commit);
- zmosh dependency: `zmosh-quic-q2-1`, peeled to
  `fc99692500610f1aa45aa8205bef0d239fe83eda`;
- current upstream `main`: `f0bd0d29df58a73becb409086e30f44d02eda12c`;
- fork delta: 17 commits, 15 source files, approximately 3,492 insertions and
  310 deletions, including tests;
- `git cherry upstream/main zmosh-quic-q2-1` reports all 17 commits as absent
  by patch identity.

Upstream has advanced by 30 commits since the common base. Most are CLI/runtime
work. Commit `7aec3878` modifies `src/quic/tls13_client_transport.zig`, so the
TLS/client-transport portions must be ported onto current upstream rather than
blindly cherry-picked.

## Upstreaming rules

1. Do not merge `zmosh/q2-egress` into upstream.
2. Start every PR branch from a freshly fetched `upstream/main`.
3. Split the fork into the logical series below. Keep each PR reviewable and
   independently green.
4. Preserve the final behavior and regression tests, but do not preserve
   superseded intermediate implementations merely to retain commit history.
5. Separate correctness fixes from new public APIs when a source commit mixes
   them.
6. Prefer upstream's naming and API shape when it provides the same atomicity,
   ownership, routing, and fail-closed guarantees.
7. Do not move the zmosh production pin until the relevant upstream series has
   landed and the zmosh exact-pin gates pass.

## Proposed PR series

### 1. TLS/PSK controls and secret ownership

Source commits:

- `e8f721e` — public `setClientPskIdentity` API;
- `de10701` — explicit session-resumption disablement;
- `77b5007` — TLS, PSK, and packet-protection secret wiping;
- `fa6c4c0` — wipe through the objects that actually own the secrets.

Upstream behavior:

- embedders configure an external-PSK identity without mutating handshake
  internals;
- disabling resumption is an enforced invariant, including ticket handling and
  early-data behavior;
- connection and TLS teardown zeroize retained secrets and key generations;
- transport and token-policy owners wipe their own storage before release.

This may be presented as two PRs: PSK/resumption controls and secret teardown.
Port carefully around upstream commit `7aec3878`.

### 2. Address-neutral endpoint and native IPv6 support

Source commits:

- `3525ad5` — family-neutral `UdpAddress`/`UdpTuple` routing;
- `3a75a8b` — neutral lifecycle route/process entry points;
- `e42c63e` — scoped IPv6, neutral token binding, and Initial acceptance.

Upstream behavior:

- endpoint routing and lifecycle processing support IPv4 and native IPv6;
- IPv6 scope IDs participate in identity and token binding;
- IPv4-mapped IPv6 addresses remain losslessly represented;
- compatibility wrappers preserve existing IPv4 call sites where practical;
- Initial acceptance, route publication, path updates, and address-validation
  tokens all use one address-neutral representation.

Because the token binding changes a serialized security boundary, document its
exact 23-byte format and retain the IPv4/IPv6 golden tests.

### 3. Final conservative stream-send progress API

Source history:

- `f8950a0` introduced a more complex ACK-gap/timestamp design;
- `501f09c` replaced it with the final conservative backlog metric.

Do not submit both implementations. Reconstruct one PR from the final tree that
exposes:

- accepted offset;
- oldest unsettled offset;
- conservative `outstandingBytes()`;
- correct queue, loss, retransmission, FIN, reset, and ACK behavior.

The API must remain read-only and must not mutate recovery state.

### 4. Bounded pending-Retry admission

Source commits:

- `8c7cc2f` — bounded single pending-Retry slot;
- `653d247` — exact stored-exchange matching and commit contract;
- the `PendingRetrySlot.storedToken(now_nanos)` portion of `7ac9bf9`.

Upstream behavior:

- classify Initials before allocating connection-sized state;
- bind the pending exchange to path, version, original DCID, client SCID,
  Retry SCID, and exact token;
- reissue the stored Retry without extending its absolute expiry;
- validate without consuming, then consume only on exact transactional commit;
- expose an expiry-aware, read-only stored-token view.

The one-slot policy is intentionally narrow. Ask upstream whether it belongs as
an optional endpoint utility. If upstream rejects the policy object, retain the
same guarantees in zmosh-local admission code before removing the fork.

### 5. Path-validation and migration correctness

Source commits and portions:

- `238a57b` — bind each outstanding challenge to its candidate path;
- `470c4bd` — fail closed and authorize commits by that path's own count;
- `7093988` — cover every PATH_RESPONSE-capable receive root with one hint
  scope;
- `d854133` — use the arrival path's bound-challenge count in feed/update;
- path preservation and path-bound pending-response portions of `7ac9bf9`;
- `{data, path}` PATH_RESPONSE deduplication from `fc99692`.

This is the highest-priority correctness/security series. Required invariants:

- a response validates only the path to which its challenge was bound;
- a missing or wrong arrival-path hint cannot consume a bound challenge;
- legacy unbound challenges never authorize route migration;
- receive-path hint scopes cover all public roots and are never accidentally
  nested;
- timeout requeue preserves the challenge destination;
- pending PATH_RESPONSE state preserves the arrival path;
- duplicate suppression keys on both challenge data and path;
- route mutation occurs only after the candidate path's own validation state
  commits.

Keep the packet-level wrong-path, null-hint, replay, delayed-response, timeout,
and per-receive-root tests with this series.

### 6. Atomic routed egress and emitted-frame metadata

Source commits and portions:

- atomic `path_override` egress and neutral changed-path challenge processing
  from `7ac9bf9`;
- `emitted_ping` from `fc99692`.

Upstream behavior:

- return the datagram and any route override as one atomic result derived from
  the packet actually built;
- use the committed route only when the result has no override;
- accept caller-generated challenge bytes in the address-neutral changed-path
  receive entry;
- report whether those bytes were actually queued;
- report `emitted_ping` only when the emitted packet contains PING, not merely
  when a PING remains pending.

This is a public integration API, not just a zmosh convenience: callers cannot
safely infer a datagram's destination or contents by inspecting pending
connection arrays. Upstream may choose a differently named metadata/result
type, but the result must stay atomic with datagram construction.

## Dependency and submission order

Use independent lanes where possible:

1. Submit TLS/PSK controls and secret ownership independently.
2. Submit the final stream-progress API independently.
3. Land address-neutral endpoint support before the Retry and migration series.
4. Land path-validation correctness before atomic routed-egress metadata.
5. Land bounded Retry after its address-neutral token/path prerequisites.

Open a design issue before the larger address-neutral and atomic-egress PRs if
the maintainer prefers API review before code. Correctness fixes should remain
small enough to review from failing regression to fix.

## Per-PR workflow

For each logical PR:

1. Fetch `upstream/main` and record the exact base SHA.
2. Create a clean topic branch from that SHA.
3. Add or port the smallest failing regression first.
4. Port the final implementation, resolving current-upstream changes rather
   than restoring old surrounding code.
5. Run:

   ```sh
   zig build test --summary all
   zig fmt --check build.zig src examples
   git diff --check
   ```

6. Confirm public API documentation and compatibility wrappers match the final
   implementation.
7. Record the upstream PR, review decisions, and landed SHA in this document.

## zmosh repin and fork-removal gate

Do not consider the upstreaming effort complete merely because PRs are open.
After all behavior required by zmosh is available upstream:

1. inventory every quicz symbol used by zmosh against the landed upstream API;
2. adapt zmosh where upstream accepted an equivalent API shape;
3. repin zmosh to an immutable upstream commit or release;
4. run the complete zmosh Debug, ReleaseSafe, check, format, SLOC, and Bats
   gates;
5. verify native IPv6, Retry rollback, migration, routed retransmission,
   keepalive accounting, secret teardown, and stream progress specifically;
6. remove the fork pin only after those exact-pin gates are green.

## Explicit non-goals

- No quicz change is part of zmosh Q3.
- Do not rewrite or move the immutable `zmosh-quic-q2-1` tag.
- Do not mix zmosh gateway/session protocol code into quicz.
- Do not require upstream to adopt zmosh-specific names when an equivalent,
  testable API preserves the contract.
- Do not drop a fork behavior merely to reduce the number of upstream PRs.

## Progress ledger

| Series | Upstream issue/PR | Landed SHA | zmosh adapted | Status |
| --- | --- | --- | --- | --- |
| TLS/PSK controls and secret ownership | — | — | No | Not started |
| Address-neutral endpoint and IPv6 | — | — | No | Not started |
| Stream-send progress | — | — | No | Not started |
| Pending-Retry admission | — | — | No | Not started |
| Path validation and migration | — | — | No | Not started |
| Atomic routed egress metadata | — | — | No | Not started |
