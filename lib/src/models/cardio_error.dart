import 'package:meta/meta.dart';

/// The web SDK's error codes, shared by the native SDKs.
enum CardioErrorCode {
  trialExpired('AIZERR001'),
  trialUsageLimitExceeded('AIZERR002'),
  subscriptionUsageLimitExceeded('AIZERR003'),
  noActiveSubscription('AIZERR004'),
  domainNotAllowedOrInvalidKey('AIZERR005'),
  invalidOrganizationId('AIZERR007'),
  invalidAccessToken('AIZERR008'),
  invalidApiKey('AIZERR009'),
  productNotEntitled('AIZERR010'),
  testCancelled('AIZERR011'),
  serviceUnreachable('AIZERR012');

  const CardioErrorCode(this.value);

  /// The code as the API and the web SDK spell it, e.g. "AIZERR002".
  final String value;

  /// The code for [value], or null when it's missing or this version doesn't know it.
  static CardioErrorCode? fromValue(String? value) {
    for (final code in values) {
      if (code.value == value) return code;
    }
    return null;
  }
}

/// Why something the SDK was asked to do didn't happen.
@immutable
class CardioError implements Exception {
  const CardioError({this.code, required this.message});

  /// The web SDK's error code, or null when the error has none (e.g. a malformed environment).
  final CardioErrorCode? code;

  /// A description in English, for logs — not meant to be shown to the user as is.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is CardioError && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'CardioError(${code?.value ?? 'no code'}): $message';
}
