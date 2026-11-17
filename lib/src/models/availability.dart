import 'package:meta/meta.dart';

import 'cardio_error.dart';

/// Same meaning as the web SDK's `isAvailable`: whether a test can start, and if not, why.
@immutable
class ISelfieAvailability {
  const ISelfieAvailability({required this.isAvailable, this.error});

  final bool isAvailable;

  /// Why a test can't start (null when available).
  final CardioError? error;

  @override
  bool operator ==(Object other) =>
      other is ISelfieAvailability && other.isAvailable == isAvailable && other.error == error;

  @override
  int get hashCode => Object.hash(isAvailable, error);

  @override
  String toString() =>
      isAvailable ? 'ISelfieAvailability(available)' : 'ISelfieAvailability(unavailable: $error)';
}
