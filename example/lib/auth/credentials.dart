import 'package:iselfie_sdk/iselfie_sdk.dart';

/// The test organization the example signs in with. EXAMPLE ONLY: a real app never holds the API
/// key — its backend mints the access tokens.
class ExampleCredentials {
  const ExampleCredentials({
    required this.organizationId,
    required this.apiKey,
    required this.isProduction,
  });

  final String organizationId;
  final String apiKey;
  final bool isProduction;

  ISelfieEnvironment get environment =>
      isProduction ? ISelfieEnvironment.production : ISelfieEnvironment.development;
}
