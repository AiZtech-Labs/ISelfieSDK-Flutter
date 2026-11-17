import 'package:meta/meta.dart';

import 'cardio_scan_failure.dart';

/// The steps of the test, in order — the web SDK's status messages (`iselfietest-status`).
enum CardioTestStep {
  /// The "Before you start" page is showing.
  instructions('instructions'),

  /// The user started the test (the scan screen opened).
  started('started'),

  /// The camera is on and the scan is running.
  inProgress('in-progress'),

  /// The scan has its frames; the server is computing the vitals.
  processing('processing'),

  /// The vitals are back.
  completed('complete'),

  /// The test failed; it's showing why, with the option to restart.
  failed('error'),

  /// The user closed the test, or went back from the scan to the instructions.
  cancelled('cancelled');

  const CardioTestStep(this.webName);

  /// The web SDK's name for this step.
  final String webName;
}

/// Where the open test is.
@immutable
class CardioTestStatus {
  const CardioTestStatus(this.step, {this.failure});

  final CardioTestStep step;

  /// Why it failed — only for [CardioTestStep.failed].
  final CardioScanFailure? failure;

  @override
  bool operator ==(Object other) =>
      other is CardioTestStatus && other.step == step && other.failure == failure;

  @override
  int get hashCode => Object.hash(step, failure);

  @override
  String toString() => 'CardioTestStatus(${step.webName}${failure == null ? '' : ', $failure'})';
}
