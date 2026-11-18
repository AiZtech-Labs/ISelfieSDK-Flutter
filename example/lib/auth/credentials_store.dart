import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'credentials.dart';

/// Where the example keeps the credentials between launches. Tests swap in an in-memory one.
abstract class ExampleCredentialsStore {
  Future<ExampleCredentials?> load();
  Future<void> save(ExampleCredentials credentials);
  Future<void> clear();
}

/// Keychain on iOS, encrypted storage on Android.
class SecureExampleCredentialsStore implements ExampleCredentialsStore {
  SecureExampleCredentialsStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _organizationIdKey = 'iselfie_example_org_id';
  static const _apiKeyKey = 'iselfie_example_api_key';
  static const _environmentKey = 'iselfie_example_env';

  @override
  Future<ExampleCredentials?> load() async {
    final values = await _storage.readAll();
    final organizationId = values[_organizationIdKey];
    final apiKey = values[_apiKeyKey];
    if (organizationId == null || organizationId.isEmpty || apiKey == null || apiKey.isEmpty) {
      return null;
    }
    return ExampleCredentials(
      organizationId: organizationId,
      apiKey: apiKey,
      isProduction: values[_environmentKey] == 'production',
    );
  }

  @override
  Future<void> save(ExampleCredentials credentials) async {
    await _storage.write(key: _organizationIdKey, value: credentials.organizationId);
    await _storage.write(key: _apiKeyKey, value: credentials.apiKey);
    await _storage.write(
      key: _environmentKey,
      value: credentials.isProduction ? 'production' : 'development',
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _organizationIdKey);
    await _storage.delete(key: _apiKeyKey);
    await _storage.delete(key: _environmentKey);
  }
}
