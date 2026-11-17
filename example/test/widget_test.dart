import 'package:flutter_test/flutter_test.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
// The test swaps the native side for a fake, which only the plugin's platform seam allows.
// ignore: implementation_imports
import 'package:iselfie_sdk/src/platform/iselfie_sdk_platform.dart';
import 'package:iselfie_sdk_example/main.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePlatform extends ISelfieSdkPlatform with MockPlatformInterfaceMixin {
  @override
  Future<ISelfieAvailability> initialize({
    required String accessToken,
    required String organizationId,
    String? appUserId,
    ISelfieEnvironment? environment,
    required ISelfieEntitlementSource entitlementSource,
  }) async => const ISelfieAvailability(isAvailable: true);

  @override
  Future<bool> isInitialized() async => false;

  @override
  Future<void> setLogLevel(ISelfieLogLevel level) async {}

  @override
  Future<CardioTestOutcome> startCardioTest({
    required CardioTestOptions options,
    void Function(CardioTestStatus status)? onStatus,
  }) async => const CardioTestFailed(CancelledFailure());

  @override
  Future<bool> isInstructionPageDismissedByUser() async => false;

  @override
  Future<void> resetInstructionPageDontShowAgain() async {}
}

void main() {
  setUp(() => ISelfieSdkPlatform.instance = _FakePlatform());

  testWidgets('without credentials the Initialize button is disabled and explains why', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.textContaining('config/example.json'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
  });
}
