import 'package:meta/meta.dart';

import 'cardio_instruction_content.dart';
import 'cardio_language.dart';
import 'cardio_style.dart';

/// Where the progress bar sits on the camera preview.
enum CardioProgressBarPosition { top, bottom }

/// The page shown before the scan — mandatory in some jurisdictions, so it's shown unless the app
/// turns it off (web SDK: `instructionPage`).
@immutable
class CardioInstructionPage {
  const CardioInstructionPage({
    this.hidden = false,
    this.content,
    this.allowsDontShowAgain = false,
  });

  /// Skips the page: the test opens straight on the scan.
  final bool hidden;

  /// Your own instructions instead of the default tips (web SDK: `instructionContent`).
  final CardioInstructionContent? content;

  /// Shows an "I understand. Don't show this again." checkbox; once ticked, later tests on this
  /// device go straight to the scan. Off by default: only turn it on where the user may skip it.
  /// `ISelfieCardio.resetInstructionPageDontShowAgain()` shows it again.
  final bool allowsDontShowAgain;
}

/// Options of the ready-made test — the web SDK's `options` and `styles`, with the same names
/// and defaults where the platforms allow (same as the native SDKs' `CardioTestOptions`).
@immutable
class CardioTestOptions {
  const CardioTestOptions({
    this.language = CardioLanguage.english,
    this.style = CardioStyle.system,
    this.showLanguageSelector = true,
    this.instructionPage = const CardioInstructionPage(),
    this.displayResults = false,
    this.timeZoneId,
    this.enableResultSharing = false,
    this.disableAudio = false,
    this.disableMotionDetection = false,
    this.disableLightCheck = false,
    this.disableDistanceCheck = false,
    this.terminateTestIfConditionPersisted = true,
    this.testTerminationTimeOut = const Duration(seconds: 7),
    this.progressBarPosition = CardioProgressBarPosition.top,
    this.enableMobileCameraSwap = false,
  });

  /// Language of the screens and the voice guidance.
  final CardioLanguage language;

  /// Colors and font of the screens. Follows the device's light/dark setting by default.
  final CardioStyle style;

  /// Lets the user change the language on the instructions page. Turn it off when your app
  /// already sets [language].
  final bool showLanguageSelector;

  final CardioInstructionPage instructionPage;

  /// Shows a result page after the scan (vitals, how each one reads, the wellness disclaimer).
  /// The test then completes when the user closes it. Off by default: the test closes and hands
  /// the result to the app.
  final bool displayResults;

  /// IANA time zone of the date on the result page (e.g. "America/Sao_Paulo"); null: the
  /// device's.
  final String? timeZoneId;

  /// A share button on the result page (an image of the result). Needs [displayResults].
  final bool enableResultSharing;

  /// Turns off the voice guidance.
  final bool disableAudio;

  /// Stops checking that the phone and the face hold still.
  final bool disableMotionDetection;

  /// Stops checking that the face is well lit.
  final bool disableLightCheck;

  /// Stops checking the distance to the face.
  final bool disableDistanceCheck;

  /// Ends the test when a bad condition (face missing, too dark…) lasts [testTerminationTimeOut].
  final bool terminateTestIfConditionPersisted;

  final Duration testTerminationTimeOut;

  final CardioProgressBarPosition progressBarPosition;

  /// Shows a button to switch between the front and back cameras.
  final bool enableMobileCameraSwap;
}
