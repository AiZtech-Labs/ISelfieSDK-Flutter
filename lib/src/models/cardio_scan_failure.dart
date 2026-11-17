import 'package:meta/meta.dart';

import 'cardio_error.dart';

/// Why a test ended without vitals. Switch over it to tell the cases apart:
///
/// ```dart
/// switch (failure) {
///   case UnavailableFailure(:final error): showMessage(error.code); // nothing was shown
///   case CancelledFailure(): break; // the user closed the test
///   default: break; // the user saw why in the test before closing it
/// }
/// ```
@immutable
sealed class CardioScanFailure {
  const CardioScanFailure();

  /// The web SDK's code for this failure, when it has one.
  CardioErrorCode? get code;
}

/// The plan or the token doesn't allow a test right now. Checked before anything opens, so
/// nothing was shown to the user: the app decides what to tell them.
final class UnavailableFailure extends CardioScanFailure {
  const UnavailableFailure(this.error);

  final CardioError error;

  @override
  CardioErrorCode? get code => error.code;

  @override
  bool operator ==(Object other) => other is UnavailableFailure && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'UnavailableFailure($error)';
}

/// The scan finished but no vitals came back (quota used up at the results call, network,
/// measurement rejected by the server…).
final class ResultErrorFailure extends CardioScanFailure {
  const ResultErrorFailure(this.error);

  final CardioError error;

  @override
  CardioErrorCode? get code => error.code;

  @override
  bool operator ==(Object other) => other is ResultErrorFailure && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'ResultErrorFailure($error)';
}

/// The face was not usable (missing, too far/close, too dark, off-center) for too long.
final class TooManyInvalidFramesFailure extends CardioScanFailure {
  const TooManyInvalidFramesFailure();

  @override
  CardioErrorCode? get code => null;

  @override
  String toString() => 'TooManyInvalidFramesFailure';
}

/// The camera was interrupted (phone call, app in the background…) for longer than allowed.
final class InterruptedFailure extends CardioScanFailure {
  const InterruptedFailure();

  @override
  CardioErrorCode? get code => null;

  @override
  String toString() => 'InterruptedFailure';
}

/// The user didn't allow the camera (now, or earlier in Settings). The app can point them to
/// Settings to turn it on.
final class CameraPermissionDeniedFailure extends CardioScanFailure {
  const CameraPermissionDeniedFailure();

  @override
  CardioErrorCode? get code => null;

  @override
  String toString() => 'CameraPermissionDeniedFailure';
}

/// The user closed the test (the web SDK's AIZERR011).
final class CancelledFailure extends CardioScanFailure {
  const CancelledFailure();

  @override
  CardioErrorCode? get code => CardioErrorCode.testCancelled;

  @override
  String toString() => 'CancelledFailure';
}
