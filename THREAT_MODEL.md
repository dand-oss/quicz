# quicz Threat Model

quicz 的威胁模型：明确 trust boundary、每种在本库范围内可防御的攻击类型、对应的代码+测试引用，以及 integrator（嵌入式使用者）必须自行承担的安全职责。文档目标是让安全审计者能按图索骥核对每一层防御。

## Scope

- **In scope**：QUIC v1/v2 传输（RFC 9000 / RFC 9369）、TLS 1.3 握手与包保护（RFC 8446 / RFC 9001）、丢包恢复与拥塞控制（RFC 9002）、HTTP/3 应用层（RFC 9114）。
- **Out of scope**：socket 生命周期（由 runtime/调用方负责）、TLS 证书策略（由调用方配置）、应用业务逻辑、部署防火墙/网络拓扑。

## Trust boundary

- **入站 UDP datagram = hostile**。攻击者完全控制 wire 输入：可构造畸形包、分片、重放、伪造源地址、任意注入。所有入站路径都按不可信数据严格解析 + 认证。
- **调用方（嵌入 quicz 的应用）= trusted**。应用提供的配置、证书、回调不视为攻击面。
- **边界**：`endpoint` feed datagram 的入口（`endpoint.zig` / `endpoint_lifecycle.zig` 的 `processDatagram` / `receiveDatagramStep`）。凡是跨过此边界的字节都必须先通过解析长度校验 + AEAD/密钥认证，才允许影响连接状态。

## Defends against

### Amplification attack（RFC 9000 §8.1）

- **3x anti-amplification budget**：server 在 peer 地址验证前发送量 ≤ 收到的 3 倍。
  - 代码：`src/quic/connection_rules.zig`（`AntiAmplification`）、`src/quic/connection.zig`（`antiAmplificationLimitRemaining` / `recordPeerAddressBytesReceived`）。
  - 测试：`connection_tests.zig` "server anti-amplification limit disarms PTO until more peer bytes arrive" 等。
- **Retry 地址验证**：server 用 Retry 包 + AEAD 认证 token 验证 source address，未验证前不放大。
  - 代码：`src/quic/endpoint.zig` / `src/quic/endpoint_lifecycle.zig`（Retry 构造与 token 校验）、`src/quic/protection.zig`（Retry Integrity Tag）。
  - 测试：`connection_tests.zig` retry 场景、`tls13_server_endpoint_tests.zig`。

### Packet injection / spoofing

- **CID 路由 + TLS 1.3 AEAD 包保护**：short-header 包用 server 发布的 CID 路由，payload 必须过 AEAD 认证才被接受；未认证包无法注入合法流。
  - 代码：`src/quic/protection.zig`（`unprotect*`）、`src/quic/connection.zig`（`processProtectedShortDatagram`）。
  - 测试：`connection_tests.zig` 注入/篡改/tamper 场景（AEAD 认证失败拒绝）。
- **Initial 密钥派生绑定 Original DCID（RFC 9001 §5.2）**：client Initial 的密钥由 client 选择的 DCID 派生，攻击者无法预知/复用，防止伪造 Initial 前缀。
  - 代码：`src/quic/protection.zig`（`deriveInitialSecrets`）、`src/quic/tls13_server_transport.zig`（`setOriginalDestinationConnectionId`）。
  - 测试：`connection_tests.zig` Initial 密钥派生测试。

### Stateless reset token 猜测

- 16 字节 stateless reset token（2^128 暴力不可行），经 NEW_CONNECTION_ID transport parameter 协商。
  - 代码：`src/quic/packet.zig`（`matchesStatelessReset`）、`src/quic/connection.zig`（token 匹配状态）、`src/quic/connection_config.zig`。
  - 测试：`connection_tests.zig` stateless reset token 匹配/拒绝；`examples/stateless_reset.zig`、`examples/tls13_stateless_reset_loopback.zig`。

### Version negotiation 降级

- `version_information` 校验 chosen/available/reserved，拒绝降级攻击（RFC 9369 §3）。
  - 代码：`src/quic/connection_version.zig`、`src/quic/connection.zig`。
  - 测试：`quic_v2_test.zig`、`connection_tests.zig` version negotiation / v2 场景。

### Transport parameter hostile value

- 范围校验（max_udp_payload / ack_delay / streams）、duplicate 检测、CID len ≤ 20。
  - 代码：`src/quic/connection_config.zig`、`src/quic/connection_rules.zig`。
  - 测试：`connection_tests.zig` transport parameter 校验。
- **max_idle_timeout cap（已修复，commit f7c89b4）**：hostile peer 可传极大 max_idle_timeout，若不做 cap 会 ms→ns 乘法溢出导致无意义/异常 deadline。已 cap 到安全上限。
  - 代码：`src/quic/connection_config.zig`（idle timeout 归一/封顶）。
  - 测试：`connection_tests.zig` hostile max_idle_timeout 溢出防护。

### Retry token 伪造

- Retry token 用 AEAD 认证（绑定 kind/lifetime/address），无法伪造。
  - 代码：`src/quic/endpoint.zig` / `endpoint_lifecycle.zig`（token 签发与校验）、`src/quic/protection.zig`。
  - 测试：`connection_tests.zig` retry token 伪造拒绝。

## Integrator responsibilities

以下不在 quicz 库内，由嵌入方（runtime / 应用）负责：

- socket bind / 超时 / 并发上限；
- TLS 证书验证策略（`ca_bundle`、`server_name`、`insecure_skip_verify` 的选用）；
- idle timeout、连接数、流数上限配置；
- 部署级防护（防火墙、DDoS、NAT 处理）。

## Residual risks

1. **fuzz 覆盖不足**：现有 fuzz 主要覆盖解析层，无 handshake/transfer 交互 fuzz，无 OSS-Fuzz 持续集成。加大交互面 fuzz + OSS-Fuzz 是首要加固项。
2. **HTTP/3 应用层**：RFC 9114 在 scope 内，但 QPACK 等应用层解析的威胁面未单独建模。
3. **证书策略默认值**：`insecure_skip_verify` 或空 `ca_bundle` 会跳过证书验证，属 integrator 责任，但库默认应偏保守。

## 攻防对照小结

| 攻击 | 防御层 | 状态 |
|---|---|---|
| 放大攻击 | anti-amplification 3x + Retry 地址验证 | 已实现 + 测试 |
| 包注入/伪造 | CID 路由 + AEAD + Initial 密钥绑定 DCID | 已实现 + 测试 |
| stateless reset token 猜测 | 16 字节 token | 已实现 + 测试 |
| 版本降级 | version_information 校验 | 已实现 + 测试 |
| transport parameter 恶意值 | 范围校验 + max_idle_timeout cap | 已实现 + 测试 |
| Retry token 伪造 | AEAD 认证 | 已实现 + 测试 |