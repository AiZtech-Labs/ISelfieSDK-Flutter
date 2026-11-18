/// Optional values to prefill the sign-in screen, read at build time from config/example.json
/// (git-ignored; copy config/example.json.template) through `--dart-define-from-file`. Without
/// them the app starts with an empty form.
abstract final class ExampleConfig {
  static const String organizationId = String.fromEnvironment('ISELFIE_ORG_ID');
  static const String apiKey = String.fromEnvironment('ISELFIE_API_KEY');
  static const String _environment = String.fromEnvironment(
    'ISELFIE_ENV',
    defaultValue: 'development',
  );

  static bool get isProduction => _environment == 'production';
}
