import 'package:iselfie_sdk/iselfie_sdk.dart';

/// The example's test organization, read at build time from config/example.json (git-ignored;
/// copy config/example.json.template) through `--dart-define-from-file`.
abstract final class ExampleConfig {
  static const String organizationId = String.fromEnvironment('ISELFIE_ORG_ID');
  static const String apiKey = String.fromEnvironment('ISELFIE_API_KEY');
  static const String _environment = String.fromEnvironment(
    'ISELFIE_ENV',
    defaultValue: 'development',
  );

  static ISelfieEnvironment get environment =>
      _environment == 'production' ? ISelfieEnvironment.production : ISelfieEnvironment.development;

  static bool get isComplete => organizationId.isNotEmpty && apiKey.isNotEmpty;
}
