/// How the plan check decides — the web SDK's `entitlementSource`. Leave it at [auto] unless
/// told otherwise.
enum ISelfieEntitlementSource {
  /// Follows the server's entitlement block whenever the server says it's enforcing it,
  /// otherwise the legacy plan check — the one that never disagrees with the server.
  auto,

  /// Follows the server's entitlement block whenever the server sends one.
  rbac,

  /// Always the legacy plan check (the web SDK's pre-2.0 behaviour).
  legacy,
}
