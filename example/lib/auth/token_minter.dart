import 'dart:convert';
import 'dart:io';

import 'package:iselfie_sdk/iselfie_sdk.dart';

/// EXAMPLE ONLY — mints the SDK access token from the API key
/// (`POST /sdk/central/access-token`). In a real app this call lives on the integrator's
/// backend and the app only receives the token: the API key must never ship inside an app.
abstract final class ExampleTokenMinter {
  /// The access token, or null when the API refused the credentials or couldn't be reached.
  static Future<String?> mint({
    required ISelfieEnvironment environment,
    required String organizationId,
    required String apiKey,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        environment.baseUrl.resolve('/sdk/central/access-token'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'organizationId': organizationId, 'apikey': apiKey}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) return null;
      final token = (jsonDecode(body) as Map<String, dynamic>)['access_token'];
      return token is String && token.isNotEmpty ? token : null;
    } on Exception {
      return null;
    } finally {
      client.close();
    }
  }
}
