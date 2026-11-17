import 'package:meta/meta.dart';

import '../models/availability.dart';
import '../models/cardio_test_options.dart';
import '../models/cardio_test_outcome.dart';
import '../models/cardio_test_status.dart';
import '../models/entitlement_source.dart';
import '../models/environment.dart';
import '../models/log_level.dart';
import 'iselfie_sdk_platform.dart';
import 'message_mappers.dart';
import 'messages.g.dart';

/// [ISelfieSdkPlatform] over the native SDKs, through the Pigeon-generated channels.
class PigeonISelfieSdk extends ISelfieSdkPlatform {
  PigeonISelfieSdk({@visibleForTesting ISelfieCardioHostApi? hostApi})
    : _hostApi = hostApi ?? ISelfieCardioHostApi();

  final ISelfieCardioHostApi _hostApi;
  final _statusRelay = _StatusRelay();

  @override
  Future<ISelfieAvailability> initialize({
    required String accessToken,
    required String organizationId,
    String? appUserId,
    ISelfieEnvironment? environment,
    required ISelfieEntitlementSource entitlementSource,
  }) async {
    final availability = await _hostApi.initialize(
      InitializeRequest(
        accessToken: accessToken,
        organizationId: organizationId,
        appUserId: appUserId,
        environment: environment?.toMessage(),
        entitlementSource: entitlementSource.toMessage(),
      ),
    );
    return availability.toModel();
  }

  @override
  Future<bool> isInitialized() => _hostApi.isInitialized();

  @override
  Future<void> setLogLevel(ISelfieLogLevel level) => _hostApi.setLogLevel(level.toMessage());

  @override
  Future<CardioTestOutcome> startCardioTest({
    required CardioTestOptions options,
    void Function(CardioTestStatus status)? onStatus,
  }) async {
    // One test at a time, like the native SDKs: a second call while one is open would otherwise
    // take over the first one's status listener.
    if (_statusRelay.isListening) {
      throw StateError('A cardio test is already open');
    }
    _statusRelay.listen(onStatus);
    try {
      final outcome = await _hostApi.startCardioTest(options.toMessage());
      return outcome.toModel();
    } finally {
      _statusRelay.stop();
    }
  }

  @override
  Future<bool> isInstructionPageDismissedByUser() => _hostApi.isInstructionPageDismissedByUser();

  @override
  Future<void> resetInstructionPageDontShowAgain() => _hostApi.resetInstructionPageDontShowAgain();
}

/// Receives the native test's status messages and hands them to the current test's listener.
class _StatusRelay implements ISelfieCardioFlutterApi {
  void Function(CardioTestStatus status)? _listener;
  bool _isListening = false;
  bool _isRegistered = false;

  bool get isListening => _isListening;

  void listen(void Function(CardioTestStatus status)? listener) {
    // Registered lazily: the channel needs the Flutter binding, which isn't up when the plugin's
    // default instance is created.
    if (!_isRegistered) {
      ISelfieCardioFlutterApi.setUp(this);
      _isRegistered = true;
    }
    _listener = listener;
    _isListening = true;
  }

  void stop() {
    _listener = null;
    _isListening = false;
  }

  @override
  void onTestStatus(CardioTestStatusMessage status) => _listener?.call(status.toModel());
}
