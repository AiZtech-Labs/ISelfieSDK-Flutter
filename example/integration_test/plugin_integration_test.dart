// Runs on a device against the real native SDK: flutter test integration_test
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native SDK answers through the plugin', (tester) async {
    await ISelfieCardio.setLogLevel(ISelfieLogLevel.off);
    expect(await ISelfieCardio.isInitialized(), isFalse);
  });

  testWidgets('a malformed custom environment is refused before any request', (tester) async {
    final availability = await ISelfieCardio.initialize(
      accessToken: 'token',
      organizationId: 'org',
      environment: ISelfieEnvironment.custom(Uri.parse('http://example.com')),
    );

    expect(availability.isAvailable, isFalse);
    expect(availability.error?.message, contains('https'));
  });
}
