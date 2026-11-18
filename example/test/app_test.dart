import 'package:flutter_test/flutter_test.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
// The test swaps the native side for a fake, which only the plugin's platform seam allows.
// ignore: implementation_imports
import 'package:iselfie_sdk/src/platform/iselfie_sdk_platform.dart';
import 'package:iselfie_sdk_example/app.dart';
import 'package:iselfie_sdk_example/auth/credentials.dart';
import 'package:iselfie_sdk_example/auth/credentials_store.dart';
import 'package:material_ui/material_ui.dart';
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

class _MemoryStore implements ExampleCredentialsStore {
  _MemoryStore([this.credentials]);

  ExampleCredentials? credentials;

  @override
  Future<ExampleCredentials?> load() async => credentials;

  @override
  Future<void> save(ExampleCredentials value) async => credentials = value;

  @override
  Future<void> clear() async => credentials = null;
}

const _saved = ExampleCredentials(organizationId: 'org-1', apiKey: 'key-1', isProduction: false);

void main() {
  setUp(() => ISelfieSdkPlatform.instance = _FakePlatform());

  testWidgets('without saved credentials it opens on the sign-in screen', (tester) async {
    await tester.pumpWidget(ExampleApp(store: _MemoryStore()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with a test organization'), findsOneWidget);
    expect(find.text('Organization ID'), findsOneWidget);
    expect(find.text('API key'), findsOneWidget);
  });

  testWidgets('the sign-in form requires both fields', (tester) async {
    await tester.pumpWidget(ExampleApp(store: _MemoryStore()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(2));
  });

  testWidgets('with saved credentials it opens on the test screen, and signing out forgets them', (
    tester,
  ) async {
    final store = _MemoryStore(_saved);
    await tester.pumpWidget(ExampleApp(store: store));
    await tester.pump();

    expect(find.text('Organization: org-1'), findsOneWidget);
    expect(find.text('Sign in with a test organization'), findsNothing);

    // Let the automatic initialize finish (the token request fails in tests: no network).
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(store.credentials, isNull);
    expect(find.text('Sign in with a test organization'), findsOneWidget);
  });
}
