import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:iselfie_sdk/src/platform/iselfie_sdk_platform.dart';
import 'package:iselfie_sdk/src/platform/messages.g.dart';
import 'package:iselfie_sdk/src/platform/pigeon_iselfie_sdk.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _RecordingPlatform extends ISelfieSdkPlatform with MockPlatformInterfaceMixin {
  final calls = <String, Object?>{};

  @override
  Future<ISelfieAvailability> initialize({
    required String accessToken,
    required String organizationId,
    String? appUserId,
    ISelfieEnvironment? environment,
    required ISelfieEntitlementSource entitlementSource,
  }) async {
    calls['initialize'] = (
      accessToken: accessToken,
      organizationId: organizationId,
      appUserId: appUserId,
      environment: environment,
      entitlementSource: entitlementSource,
    );
    return const ISelfieAvailability(isAvailable: true);
  }

  @override
  Future<bool> isInitialized() async => true;

  @override
  Future<void> setLogLevel(ISelfieLogLevel level) async => calls['setLogLevel'] = level;

  @override
  Future<CardioTestOutcome> startCardioTest({
    required CardioTestOptions options,
    void Function(CardioTestStatus status)? onStatus,
  }) async {
    calls['startCardioTest'] = options;
    onStatus?.call(const CardioTestStatus(CardioTestStep.completed));
    return const CardioTestCompleted(CardioResult(heartRate: 72));
  }

  @override
  Future<bool> isInstructionPageDismissedByUser() async => true;

  @override
  Future<void> resetInstructionPageDontShowAgain() async =>
      calls['resetInstructionPageDontShowAgain'] = true;
}

/// A host API whose test stays open until [finish] is called.
class _OpenTestHostApi extends ISelfieCardioHostApi {
  final _outcome = Completer<CardioTestOutcomeMessage>();

  @override
  Future<CardioTestOutcomeMessage> startCardioTest(CardioTestOptionsMessage options) =>
      _outcome.future;

  void finish() => _outcome.complete(
    CardioTestOutcomeMessage(
      failure: CardioScanFailureMessage(kind: CardioScanFailureKindMessage.cancelled),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultPlatform = ISelfieSdkPlatform.instance;
  late _RecordingPlatform platform;

  setUp(() => ISelfieSdkPlatform.instance = platform = _RecordingPlatform());

  test('the default platform goes through Pigeon', () {
    expect(defaultPlatform, isA<PigeonISelfieSdk>());
  });

  test('initialize forwards every argument, with the defaults left to the native SDK', () async {
    final availability = await ISelfieCardio.initialize(
      accessToken: 'token',
      organizationId: 'org',
    );

    expect(availability.isAvailable, isTrue);
    expect(platform.calls['initialize'], (
      accessToken: 'token',
      organizationId: 'org',
      appUserId: null,
      environment: null,
      entitlementSource: ISelfieEntitlementSource.auto,
    ));
  });

  test('isInitialized and setLogLevel reach the platform', () async {
    expect(await ISelfieCardio.isInitialized(), isTrue);

    await ISelfieCardio.setLogLevel(ISelfieLogLevel.basic);
    expect(platform.calls['setLogLevel'], ISelfieLogLevel.basic);
  });

  test('startCardioTest passes the options and relays status and outcome', () async {
    final statuses = <CardioTestStatus>[];
    const options = CardioTestOptions(language: CardioLanguage.spanish);

    final outcome = await ISelfieCardio.startCardioTest(options: options, onStatus: statuses.add);

    expect(platform.calls['startCardioTest'], same(options));
    expect(statuses, [const CardioTestStatus(CardioTestStep.completed)]);
    expect(outcome, isA<CardioTestCompleted>());
    expect((outcome as CardioTestCompleted).result.heartRate, 72);
  });

  test('the instruction page\'s "don\'t show again" reaches the platform', () async {
    expect(await ISelfieCardio.isInstructionPageDismissedByUser(), isTrue);

    await ISelfieCardio.resetInstructionPageDontShowAgain();
    expect(platform.calls['resetInstructionPageDontShowAgain'], isTrue);
  });

  test('a second test while one is open is refused, and allowed once it closes', () async {
    final hostApi = _OpenTestHostApi();
    final sdk = PigeonISelfieSdk(hostApi: hostApi);

    final first = sdk.startCardioTest(options: const CardioTestOptions());
    await expectLater(
      sdk.startCardioTest(options: const CardioTestOptions()),
      throwsA(isA<StateError>()),
    );

    hostApi.finish();
    expect(await first, isA<CardioTestFailed>());
  });
}
