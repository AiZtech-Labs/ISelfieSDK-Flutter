// The contract between the Dart API and the native iSelfie SDKs (Android: ai.iselfie:iselfie-sdk,
// iOS: ISelfieSDK). Pigeon generates the Dart, Kotlin and Swift code that carries these calls, so
// the three sides can't drift apart. After editing this file, regenerate with:
//
//   dart run pigeon --input pigeon/messages.dart
//
// These are wire types only — the public Dart API lives in lib/src and maps to and from them, so
// the shape of these messages can change without breaking integrators.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'iselfie_sdk',
    dartOut: 'lib/src/platform/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/ai/iselfie/sdk/flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'ai.iselfie.sdk.flutter'),
    swiftOut: 'ios/iselfie_sdk/Sources/iselfie_sdk/Messages.g.swift',
  ),
)
/// Which iSelfie backend the native SDK talks to.
enum EnvironmentKindMessage { production, development, custom }

class EnvironmentMessage {
  EnvironmentMessage({required this.kind, this.customUrl});

  EnvironmentKindMessage kind;

  /// Only for [EnvironmentKindMessage.custom].
  String? customUrl;
}

enum EntitlementSourceMessage { auto, rbac, legacy }

enum LogLevelMessage { off, basic, verbose }

class InitializeRequest {
  InitializeRequest({
    required this.accessToken,
    required this.organizationId,
    this.appUserId,
    this.environment,
    required this.entitlementSource,
  });

  String accessToken;
  String organizationId;
  String? appUserId;

  /// Null: the environment the native SDK binary was built for.
  EnvironmentMessage? environment;
  EntitlementSourceMessage entitlementSource;
}

class CardioErrorMessage {
  CardioErrorMessage({this.code, required this.message});

  /// The web SDK's error code (e.g. "AIZERR002"), or null when the error has none.
  String? code;
  String message;
}

class AvailabilityMessage {
  AvailabilityMessage({required this.isAvailable, this.error});

  bool isAvailable;
  CardioErrorMessage? error;
}

// region Ready-made test

enum CardioLanguageMessage { english, spanish, arabic }

/// Colors are ARGB 32-bit values (0xAARRGGBB).
class CardioPaletteMessage {
  CardioPaletteMessage({
    required this.pageBackgroundColors,
    required this.cardBackgroundColor,
    required this.cardHeaderBackgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.iconColor,
    required this.isDark,
  });

  List<int> pageBackgroundColors;
  int cardBackgroundColor;
  int cardHeaderBackgroundColor;
  int primaryTextColor;
  int secondaryTextColor;
  int buttonColor;
  int buttonTextColor;
  int iconColor;
  bool isDark;
}

class CardioStyleMessage {
  CardioStyleMessage({required this.palette, this.darkPalette, this.fontFamily});

  CardioPaletteMessage palette;

  /// Used instead of [palette] while the device is in dark mode; null: [palette] always.
  CardioPaletteMessage? darkPalette;

  /// A font family the platform knows; null: the system font.
  String? fontFamily;
}

class InstructionItemMessage {
  InstructionItemMessage({required this.title, this.subtitle, this.iconUrl});

  String title;
  String? subtitle;
  String? iconUrl;
}

/// One language of the custom instructions. Exactly one of [html] and [items] is set.
class InstructionTranslationMessage {
  InstructionTranslationMessage({
    required this.language,
    this.isRightToLeft,
    required this.header,
    this.html,
    this.items,
  });

  CardioLanguageMessage language;

  /// Null: the language's own direction.
  bool? isRightToLeft;
  String header;
  String? html;
  List<InstructionItemMessage>? items;
}

enum ProgressBarPositionMessage { top, bottom }

class CardioTestOptionsMessage {
  CardioTestOptionsMessage({
    required this.language,
    required this.style,
    required this.showLanguageSelector,
    required this.instructionPageHidden,
    required this.instructionPageAllowsDontShowAgain,
    this.instructionContent,
    required this.displayResults,
    this.timeZoneId,
    required this.enableResultSharing,
    required this.disableAudio,
    required this.disableMotionDetection,
    required this.disableLightCheck,
    required this.disableDistanceCheck,
    required this.terminateTestIfConditionPersisted,
    required this.testTerminationTimeOut,
    required this.progressBarPosition,
    required this.enableMobileCameraSwap,
  });

  CardioLanguageMessage language;
  CardioStyleMessage style;
  bool showLanguageSelector;
  bool instructionPageHidden;
  bool instructionPageAllowsDontShowAgain;

  /// Null: the default tips.
  List<InstructionTranslationMessage>? instructionContent;
  bool displayResults;

  /// IANA id (e.g. "America/Sao_Paulo"); null: the device's time zone.
  String? timeZoneId;
  bool enableResultSharing;
  bool disableAudio;
  bool disableMotionDetection;
  bool disableLightCheck;
  bool disableDistanceCheck;
  bool terminateTestIfConditionPersisted;
  double testTerminationTimeOut;
  ProgressBarPositionMessage progressBarPosition;
  bool enableMobileCameraSwap;
}

class BloodPressureMessage {
  BloodPressureMessage({required this.systolic, required this.diastolic, this.label});

  int systolic;
  int diastolic;
  String? label;
}

class CardioResultMessage {
  CardioResultMessage({
    this.testId,
    this.createdAtMillis,
    this.heartRate,
    this.heartRateConfidence,
    this.bloodPressure,
    this.spo2,
    this.hrv,
    this.respiratoryRate,
    this.appUserId,
    this.elapsedSeconds,
    required this.rawJson,
  });

  String? testId;

  /// Milliseconds since the epoch, UTC.
  int? createdAtMillis;
  int? heartRate;
  String? heartRateConfidence;
  BloodPressureMessage? bloodPressure;
  int? spo2;
  int? hrv;
  int? respiratoryRate;
  String? appUserId;
  double? elapsedSeconds;

  /// The full server response as JSON (it can hold any JSON value, which a typed message can't).
  String rawJson;
}

enum CardioScanFailureKindMessage {
  unavailable,
  resultError,
  tooManyInvalidFrames,
  interrupted,
  cameraPermissionDenied,
  cancelled,
}

class CardioScanFailureMessage {
  CardioScanFailureMessage({required this.kind, this.error});

  CardioScanFailureKindMessage kind;

  /// Only for [CardioScanFailureKindMessage.unavailable] and [CardioScanFailureKindMessage.resultError].
  CardioErrorMessage? error;
}

/// Exactly one of the two is set.
class CardioTestOutcomeMessage {
  CardioTestOutcomeMessage({this.result, this.failure});

  CardioResultMessage? result;
  CardioScanFailureMessage? failure;
}

enum CardioTestStepMessage {
  instructions,
  started,
  inProgress,
  processing,
  completed,
  failed,
  cancelled,
}

class CardioTestStatusMessage {
  CardioTestStatusMessage({required this.step, this.failure});

  CardioTestStepMessage step;

  /// Only for [CardioTestStepMessage.failed].
  CardioScanFailureMessage? failure;
}

// endregion

@HostApi()
abstract class ISelfieCardioHostApi {
  @async
  AvailabilityMessage initialize(InitializeRequest request);

  bool isInitialized();

  void setLogLevel(LogLevelMessage level);

  /// Checks the plan, opens the native test and answers when it closes — with the vitals or the
  /// failure. Fails with "test-in-progress" while another test is open.
  @async
  CardioTestOutcomeMessage startCardioTest(CardioTestOptionsMessage options);

  /// Whether the user on this device chose "Don't show this again" on the instructions page.
  bool isInstructionPageDismissedByUser();

  /// Shows the instructions page again from the next test on.
  void resetInstructionPageDontShowAgain();
}

/// Native → Dart: the steps of the open test.
@FlutterApi()
abstract class ISelfieCardioFlutterApi {
  void onTestStatus(CardioTestStatusMessage status);
}
