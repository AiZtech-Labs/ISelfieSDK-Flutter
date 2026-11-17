import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

import 'example_samples.dart';

enum ExampleStyle { system, light, dark, brand }

enum ExampleInstructions { defaultTips, customItems, customHtml }

/// What the example's options form edits; [toOptions] turns it into the SDK's options.
class ExampleSettings extends ChangeNotifier {
  CardioLanguage language = CardioLanguage.english;
  bool showLanguageSelector = true;
  ExampleStyle style = ExampleStyle.system;
  String fontFamily = '';

  bool instructionsHidden = false;
  ExampleInstructions instructions = ExampleInstructions.defaultTips;
  bool allowsDontShowAgain = false;

  bool displayResults = false;
  bool enableResultSharing = false;
  String? timeZoneId;

  bool disableAudio = false;
  bool disableMotionDetection = false;
  bool disableLightCheck = false;
  bool disableDistanceCheck = false;
  bool terminateTestIfConditionPersisted = true;
  int testTerminationTimeOutSeconds = 7;
  CardioProgressBarPosition progressBarPosition = CardioProgressBarPosition.top;
  bool enableMobileCameraSwap = false;

  void update(void Function(ExampleSettings settings) change) {
    change(this);
    notifyListeners();
  }

  CardioTestOptions toOptions() {
    final baseStyle = switch (style) {
      ExampleStyle.system => CardioStyle.system,
      ExampleStyle.light => CardioStyle.light,
      ExampleStyle.dark => CardioStyle.dark,
      ExampleStyle.brand => ExampleSamples.brandStyle,
    };
    final font = fontFamily.trim();
    return CardioTestOptions(
      language: language,
      style: font.isEmpty ? baseStyle : baseStyle.copyWith(fontFamily: font),
      showLanguageSelector: showLanguageSelector,
      instructionPage: CardioInstructionPage(
        hidden: instructionsHidden,
        content: switch (instructions) {
          ExampleInstructions.defaultTips => null,
          ExampleInstructions.customItems => ExampleSamples.itemInstructions,
          ExampleInstructions.customHtml => ExampleSamples.htmlInstructions,
        },
        allowsDontShowAgain: allowsDontShowAgain,
      ),
      displayResults: displayResults,
      timeZoneId: timeZoneId,
      enableResultSharing: enableResultSharing,
      disableAudio: disableAudio,
      disableMotionDetection: disableMotionDetection,
      disableLightCheck: disableLightCheck,
      disableDistanceCheck: disableDistanceCheck,
      terminateTestIfConditionPersisted: terminateTestIfConditionPersisted,
      testTerminationTimeOut: Duration(seconds: testTerminationTimeOutSeconds),
      progressBarPosition: progressBarPosition,
      enableMobileCameraSwap: enableMobileCameraSwap,
    );
  }
}
