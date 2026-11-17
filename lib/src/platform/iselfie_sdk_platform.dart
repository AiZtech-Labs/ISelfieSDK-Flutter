import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../models/availability.dart';
import '../models/cardio_test_options.dart';
import '../models/cardio_test_outcome.dart';
import '../models/cardio_test_status.dart';
import '../models/entitlement_source.dart';
import '../models/environment.dart';
import '../models/log_level.dart';
import 'pigeon_iselfie_sdk.dart';

/// The seam between the public API and the native SDKs. The default implementation talks to
/// them through Pigeon; tests swap in a fake via [instance].
abstract class ISelfieSdkPlatform extends PlatformInterface {
  ISelfieSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ISelfieSdkPlatform _instance = PigeonISelfieSdk();

  static ISelfieSdkPlatform get instance => _instance;

  static set instance(ISelfieSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<ISelfieAvailability> initialize({
    required String accessToken,
    required String organizationId,
    String? appUserId,
    ISelfieEnvironment? environment,
    required ISelfieEntitlementSource entitlementSource,
  });

  Future<bool> isInitialized();

  Future<void> setLogLevel(ISelfieLogLevel level);

  Future<CardioTestOutcome> startCardioTest({
    required CardioTestOptions options,
    void Function(CardioTestStatus status)? onStatus,
  });

  Future<bool> isInstructionPageDismissedByUser();

  Future<void> resetInstructionPageDontShowAgain();
}
