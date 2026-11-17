import 'package:meta/meta.dart';

@immutable
class CardioBloodPressure {
  const CardioBloodPressure({required this.systolic, required this.diastolic, this.label});

  /// mmHg.
  final int systolic;

  /// mmHg.
  final int diastolic;

  /// Server classification, e.g. "Normal".
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is CardioBloodPressure &&
      other.systolic == systolic &&
      other.diastolic == diastolic &&
      other.label == label;

  @override
  int get hashCode => Object.hash(systolic, diastolic, label);

  @override
  String toString() => '$systolic/$diastolic${label == null ? '' : ' ($label)'}';
}

/// The vitals of a completed test. Every metric is optional: the server leaves out (null) the
/// ones the organization's plan doesn't include, and a measurement can also be missing on its own.
@immutable
class CardioResult {
  const CardioResult({
    this.testId,
    this.createdAt,
    this.heartRate,
    this.heartRateConfidence,
    this.bloodPressure,
    this.spo2,
    this.hrv,
    this.respiratoryRate,
    this.appUserId,
    this.elapsed,
    this.raw = const {},
  });

  /// Id of the test stored on the iSelfie server (also sent in the webhook).
  final String? testId;

  /// When the server stored the test (UTC).
  final DateTime? createdAt;

  /// Beats per minute.
  final int? heartRate;

  /// Server confidence for the heart rate, e.g. "medium".
  final String? heartRateConfidence;

  final CardioBloodPressure? bloodPressure;

  /// Blood oxygen saturation, in %.
  final int? spo2;

  /// Heart rate variability, in ms.
  final int? hrv;

  /// Breaths per minute.
  final int? respiratoryRate;

  /// The appUserId this test was recorded with.
  final String? appUserId;

  /// How long the signal collection took.
  final Duration? elapsed;

  /// The full server response, for fields this type doesn't model yet.
  final Map<String, Object?> raw;

  @override
  String toString() =>
      'CardioResult(hr: $heartRate, bp: $bloodPressure, spo2: $spo2, hrv: $hrv, '
      'rr: $respiratoryRate, testId: $testId)';
}
