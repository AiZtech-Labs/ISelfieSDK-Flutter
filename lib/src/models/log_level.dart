/// How much of the API traffic the native SDK logs (Android: Logcat tag "ISelfieSDK"; iOS:
/// subsystem "ai.iselfie.sdk").
enum ISelfieLogLevel {
  /// Nothing (default).
  off,

  /// One line per call: method, URL, HTTP status and duration. No request/response bodies, so
  /// no health data and no app user id — safe to leave on.
  basic,

  /// Full request and response bodies (credentials masked, signal arrays summarized). They
  /// contain health measurements and the app user id: debug builds only, never production.
  verbose,
}
