import 'models/availability.dart';
import 'models/cardio_scan_failure.dart';
import 'models/cardio_test_options.dart';
import 'models/cardio_test_outcome.dart';
import 'models/cardio_test_status.dart';
import 'models/entitlement_source.dart';
import 'models/environment.dart';
import 'models/log_level.dart';
import 'platform/iselfie_sdk_platform.dart';

/// SDK entry point — the Flutter counterpart of the native SDKs' `ISelfieCardio` and of the web
/// SDK's `ISelfieTestSDK({ ... })`.
///
/// Call [initialize] once (e.g. when the screen that hosts the scan opens). Every scan re-checks
/// the organization's plan, and at the end the native SDK sends the signal to the iSelfie API,
/// which returns the vitals, counts the test and fires the organization's webhook — exactly like
/// the web SDK.
///
/// Authentication: an SDK **access token**, minted by the integrator's backend from its API key
/// (`POST /sdk/central/access-token` with `organizationId` + `apikey`). Never ship the API key in
/// the app. Tokens are renewed automatically before they lapse.
abstract final class ISelfieCardio {
  /// Verifies the access token and checks the organization's plan. Calling it again replaces the
  /// previous session (e.g. with a new token).
  ///
  /// [appUserId] identifies the end user in the organization's results and webhooks: use an
  /// opaque internal id, never an email or a document number. [environment] defaults to the one
  /// the native SDK was built for (production in every published release).
  ///
  /// Refusals (invalid token, plan limits…) come back as an [ISelfieAvailability] with an error,
  /// not as an exception.
  static Future<ISelfieAvailability> initialize({
    required String accessToken,
    required String organizationId,
    String? appUserId,
    ISelfieEnvironment? environment,
    ISelfieEntitlementSource entitlementSource = ISelfieEntitlementSource.auto,
  }) {
    return ISelfieSdkPlatform.instance.initialize(
      accessToken: accessToken,
      organizationId: organizationId,
      appUserId: appUserId,
      environment: environment,
      entitlementSource: entitlementSource,
    );
  }

  /// Whether [initialize] succeeded and a session is active.
  static Future<bool> isInitialized() => ISelfieSdkPlatform.instance.isInitialized();

  /// Off by default. Example: `if (kDebugMode) ISelfieCardio.setLogLevel(ISelfieLogLevel.verbose)`.
  static Future<void> setLogLevel(ISelfieLogLevel level) =>
      ISelfieSdkPlatform.instance.setLogLevel(level);

  /// Opens the ready-made test — instructions, scan and, with
  /// [CardioTestOptions.displayResults], the result page — full screen over the app, and
  /// completes when it closes. Call it after [initialize].
  ///
  /// It checks the organization's plan first and opens only when a test is allowed; otherwise it
  /// completes right away with an [UnavailableFailure] and nothing was shown to the user (web
  /// SDK: `startCardioTest()` rejecting with the code).
  ///
  /// ```dart
  /// final outcome = await ISelfieCardio.startCardioTest();
  /// switch (outcome) {
  ///   case CardioTestCompleted(:final result): print(result.heartRate);
  ///   case CardioTestFailed(:final failure): print(failure);
  /// }
  /// ```
  ///
  /// [onStatus] follows every step of the test (the web SDK's status messages). One test at a
  /// time: calling this while a test is open throws a [StateError].
  ///
  /// On Android the test runs in its own screen: if the system kills the app while the test is
  /// in the background, the future never completes. The organization's webhook stays the
  /// result of record.
  static Future<CardioTestOutcome> startCardioTest({
    CardioTestOptions options = const CardioTestOptions(),
    void Function(CardioTestStatus status)? onStatus,
  }) {
    return ISelfieSdkPlatform.instance.startCardioTest(options: options, onStatus: onStatus);
  }

  /// Whether the user on this device chose "Don't show this again" on the instructions page
  /// (only offered with [CardioInstructionPage.allowsDontShowAgain]).
  static Future<bool> isInstructionPageDismissedByUser() =>
      ISelfieSdkPlatform.instance.isInstructionPageDismissedByUser();

  /// Shows the instructions page again from the next test on — e.g. for a "Show instructions"
  /// setting in your app.
  static Future<void> resetInstructionPageDontShowAgain() =>
      ISelfieSdkPlatform.instance.resetInstructionPageDontShowAgain();
}
