import 'package:meta/meta.dart';

import 'cardio_result.dart';
import 'cardio_scan_failure.dart';

/// How a test ended: with the vitals, or with the reason it didn't produce them.
@immutable
sealed class CardioTestOutcome {
  const CardioTestOutcome();
}

final class CardioTestCompleted extends CardioTestOutcome {
  const CardioTestCompleted(this.result);

  final CardioResult result;

  @override
  String toString() => 'CardioTestCompleted($result)';
}

final class CardioTestFailed extends CardioTestOutcome {
  const CardioTestFailed(this.failure);

  final CardioScanFailure failure;

  @override
  String toString() => 'CardioTestFailed($failure)';
}
