// Translates between the public Dart types and the Pigeon wire types, so neither leaks into the
// other.
import 'dart:convert';

import '../models/availability.dart';
import '../models/cardio_error.dart';
import '../models/cardio_instruction_content.dart';
import '../models/cardio_language.dart';
import '../models/cardio_result.dart';
import '../models/cardio_scan_failure.dart';
import '../models/cardio_style.dart';
import '../models/cardio_test_options.dart';
import '../models/cardio_test_outcome.dart';
import '../models/cardio_test_status.dart';
import '../models/entitlement_source.dart';
import '../models/environment.dart';
import '../models/log_level.dart';
import 'messages.g.dart';

// region Dart → native

extension EnvironmentToMessage on ISelfieEnvironment {
  EnvironmentMessage toMessage() => switch (this) {
    ProductionEnvironment() => EnvironmentMessage(kind: EnvironmentKindMessage.production),
    DevelopmentEnvironment() => EnvironmentMessage(kind: EnvironmentKindMessage.development),
    CustomEnvironment(:final url) => EnvironmentMessage(
      kind: EnvironmentKindMessage.custom,
      customUrl: url.toString(),
    ),
  };
}

extension EntitlementSourceToMessage on ISelfieEntitlementSource {
  EntitlementSourceMessage toMessage() => switch (this) {
    ISelfieEntitlementSource.auto => EntitlementSourceMessage.auto,
    ISelfieEntitlementSource.rbac => EntitlementSourceMessage.rbac,
    ISelfieEntitlementSource.legacy => EntitlementSourceMessage.legacy,
  };
}

extension LogLevelToMessage on ISelfieLogLevel {
  LogLevelMessage toMessage() => switch (this) {
    ISelfieLogLevel.off => LogLevelMessage.off,
    ISelfieLogLevel.basic => LogLevelMessage.basic,
    ISelfieLogLevel.verbose => LogLevelMessage.verbose,
  };
}

extension CardioLanguageToMessage on CardioLanguage {
  CardioLanguageMessage toMessage() => switch (this) {
    CardioLanguage.english => CardioLanguageMessage.english,
    CardioLanguage.spanish => CardioLanguageMessage.spanish,
    CardioLanguage.arabic => CardioLanguageMessage.arabic,
  };
}

extension CardioPaletteToMessage on CardioPalette {
  CardioPaletteMessage toMessage() => CardioPaletteMessage(
    pageBackgroundColors: [for (final color in pageBackgroundColors) color.toARGB32()],
    cardBackgroundColor: cardBackgroundColor.toARGB32(),
    cardHeaderBackgroundColor: cardHeaderBackgroundColor.toARGB32(),
    primaryTextColor: primaryTextColor.toARGB32(),
    secondaryTextColor: secondaryTextColor.toARGB32(),
    buttonColor: buttonColor.toARGB32(),
    buttonTextColor: buttonTextColor.toARGB32(),
    iconColor: iconColor.toARGB32(),
    isDark: isDark,
  );
}

extension CardioStyleToMessage on CardioStyle {
  CardioStyleMessage toMessage() => CardioStyleMessage(
    palette: palette.toMessage(),
    darkPalette: darkPalette?.toMessage(),
    fontFamily: fontFamily,
  );
}

extension CardioInstructionContentToMessage on CardioInstructionContent {
  List<InstructionTranslationMessage> toMessage() => [
    for (final translation in translations)
      InstructionTranslationMessage(
        language: translation.language.toMessage(),
        isRightToLeft: translation.textDirection == null ? null : translation.isRightToLeft,
        header: translation.header,
        html: switch (translation.body) {
          CardioInstructionHtml(:final html) => html,
          CardioInstructionItems() => null,
        },
        items: switch (translation.body) {
          CardioInstructionItems(:final items) => [
            for (final item in items)
              InstructionItemMessage(
                title: item.title,
                subtitle: item.subtitle,
                iconUrl: item.iconUrl?.toString(),
              ),
          ],
          CardioInstructionHtml() => null,
        },
      ),
  ];
}

extension ProgressBarPositionToMessage on CardioProgressBarPosition {
  ProgressBarPositionMessage toMessage() => switch (this) {
    CardioProgressBarPosition.top => ProgressBarPositionMessage.top,
    CardioProgressBarPosition.bottom => ProgressBarPositionMessage.bottom,
  };
}

extension CardioTestOptionsToMessage on CardioTestOptions {
  CardioTestOptionsMessage toMessage() => CardioTestOptionsMessage(
    language: language.toMessage(),
    style: style.toMessage(),
    showLanguageSelector: showLanguageSelector,
    instructionPageHidden: instructionPage.hidden,
    instructionPageAllowsDontShowAgain: instructionPage.allowsDontShowAgain,
    instructionContent: instructionPage.content?.toMessage(),
    displayResults: displayResults,
    timeZoneId: timeZoneId,
    enableResultSharing: enableResultSharing,
    disableAudio: disableAudio,
    disableMotionDetection: disableMotionDetection,
    disableLightCheck: disableLightCheck,
    disableDistanceCheck: disableDistanceCheck,
    terminateTestIfConditionPersisted: terminateTestIfConditionPersisted,
    testTerminationTimeOut: testTerminationTimeOut.inMilliseconds / 1000,
    progressBarPosition: progressBarPosition.toMessage(),
    enableMobileCameraSwap: enableMobileCameraSwap,
  );
}

// endregion

// region Native → Dart

extension CardioErrorFromMessage on CardioErrorMessage {
  CardioError toModel() => CardioError(code: CardioErrorCode.fromValue(code), message: message);
}

extension AvailabilityFromMessage on AvailabilityMessage {
  ISelfieAvailability toModel() =>
      ISelfieAvailability(isAvailable: isAvailable, error: error?.toModel());
}

extension CardioResultFromMessage on CardioResultMessage {
  CardioResult toModel() => CardioResult(
    testId: testId,
    createdAt: createdAtMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(createdAtMillis!, isUtc: true),
    heartRate: heartRate,
    heartRateConfidence: heartRateConfidence,
    bloodPressure: bloodPressure == null
        ? null
        : CardioBloodPressure(
            systolic: bloodPressure!.systolic,
            diastolic: bloodPressure!.diastolic,
            label: bloodPressure!.label,
          ),
    spo2: spo2,
    hrv: hrv,
    respiratoryRate: respiratoryRate,
    appUserId: appUserId,
    elapsed: elapsedSeconds == null
        ? null
        : Duration(microseconds: (elapsedSeconds! * Duration.microsecondsPerSecond).round()),
    raw: _decodeRaw(rawJson),
  );

  static Map<String, Object?> _decodeRaw(String json) {
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}

extension CardioScanFailureFromMessage on CardioScanFailureMessage {
  CardioScanFailure toModel() {
    // The native side always sends an error with these two; the fallback only guards the wire.
    CardioError requireError() => error?.toModel() ?? const CardioError(message: 'Unknown error');
    return switch (kind) {
      CardioScanFailureKindMessage.unavailable => UnavailableFailure(requireError()),
      CardioScanFailureKindMessage.resultError => ResultErrorFailure(requireError()),
      CardioScanFailureKindMessage.tooManyInvalidFrames => const TooManyInvalidFramesFailure(),
      CardioScanFailureKindMessage.interrupted => const InterruptedFailure(),
      CardioScanFailureKindMessage.cameraPermissionDenied => const CameraPermissionDeniedFailure(),
      CardioScanFailureKindMessage.cancelled => const CancelledFailure(),
    };
  }
}

extension CardioTestStatusFromMessage on CardioTestStatusMessage {
  CardioTestStatus toModel() {
    final step = switch (this.step) {
      CardioTestStepMessage.instructions => CardioTestStep.instructions,
      CardioTestStepMessage.started => CardioTestStep.started,
      CardioTestStepMessage.inProgress => CardioTestStep.inProgress,
      CardioTestStepMessage.processing => CardioTestStep.processing,
      CardioTestStepMessage.completed => CardioTestStep.completed,
      CardioTestStepMessage.failed => CardioTestStep.failed,
      CardioTestStepMessage.cancelled => CardioTestStep.cancelled,
    };
    return CardioTestStatus(step, failure: failure?.toModel());
  }
}

extension CardioTestOutcomeFromMessage on CardioTestOutcomeMessage {
  CardioTestOutcome toModel() {
    if (result case final result?) return CardioTestCompleted(result.toModel());
    if (failure case final failure?) return CardioTestFailed(failure.toModel());
    // Never sent by the native side; treated like a failure the app can still handle.
    return CardioTestFailed(
      ResultErrorFailure(const CardioError(message: 'The test ended without a result')),
    );
  }
}

// endregion
