import 'package:meta/meta.dart';

/// Which iSelfie backend the SDK talks to — the native SDKs' `ISelfieCardio.Environment`.
///
/// Leave it out of [ISelfieCardio.initialize] to use the environment the native SDK was built
/// for (production in every published release).
@immutable
sealed class ISelfieEnvironment {
  const ISelfieEnvironment();

  static const ISelfieEnvironment production = ProductionEnvironment();
  static const ISelfieEnvironment development = DevelopmentEnvironment();

  /// Any other deployment (e.g. a regional or staging backend). Must be https: the native SDK
  /// refuses plain http except for a backend on the same machine (localhost).
  const factory ISelfieEnvironment.custom(Uri url) = CustomEnvironment;

  /// The API base URL of this environment — e.g. for the integrator's backend, which mints the
  /// access token there (`POST /sdk/central/access-token`).
  Uri get baseUrl;
}

final class ProductionEnvironment extends ISelfieEnvironment {
  const ProductionEnvironment();

  @override
  Uri get baseUrl => Uri.parse('https://consumer-api.iselfie.ai');

  @override
  String toString() => 'ISelfieEnvironment.production';
}

final class DevelopmentEnvironment extends ISelfieEnvironment {
  const DevelopmentEnvironment();

  @override
  Uri get baseUrl => Uri.parse('https://dev-api.iselfie.ai');

  @override
  String toString() => 'ISelfieEnvironment.development';
}

final class CustomEnvironment extends ISelfieEnvironment {
  const CustomEnvironment(this.url);

  final Uri url;

  @override
  Uri get baseUrl => url;

  @override
  bool operator ==(Object other) => other is CustomEnvironment && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'ISelfieEnvironment.custom($url)';
}
