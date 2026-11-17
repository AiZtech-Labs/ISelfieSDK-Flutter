import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:iselfie_sdk/src/platform/message_mappers.dart';
import 'package:iselfie_sdk/src/platform/messages.g.dart';

void main() {
  group('environment', () {
    test('production and development carry only their kind', () {
      expect(ISelfieEnvironment.production.toMessage().kind, EnvironmentKindMessage.production);
      expect(ISelfieEnvironment.development.toMessage().kind, EnvironmentKindMessage.development);
      expect(ISelfieEnvironment.production.toMessage().customUrl, isNull);
    });

    test('custom carries its URL', () {
      final message = ISelfieEnvironment.custom(Uri.parse('https://staging.example.com'))
          .toMessage();

      expect(message.kind, EnvironmentKindMessage.custom);
      expect(message.customUrl, 'https://staging.example.com');
    });

    test('each environment exposes its API base URL', () {
      expect(ISelfieEnvironment.production.baseUrl.host, 'consumer-api.iselfie.ai');
      expect(ISelfieEnvironment.development.baseUrl.host, 'dev-api.iselfie.ai');
    });
  });

  test('every entitlement source and log level has a wire value', () {
    expect(
      ISelfieEntitlementSource.values.map((source) => source.toMessage()),
      EntitlementSourceMessage.values,
    );
    expect(ISelfieLogLevel.values.map((level) => level.toMessage()), LogLevelMessage.values);
  });

  group('test options', () {
    test('the defaults match the native SDKs', () {
      final message = const CardioTestOptions().toMessage();

      expect(message.language, CardioLanguageMessage.english);
      expect(message.style.palette.isDark, isFalse);
      expect(message.style.darkPalette?.isDark, isTrue);
      expect(message.showLanguageSelector, isTrue);
      expect(message.instructionPageHidden, isFalse);
      expect(message.instructionContent, isNull);
      expect(message.displayResults, isFalse);
      expect(message.timeZoneId, isNull);
      expect(message.terminateTestIfConditionPersisted, isTrue);
      expect(message.testTerminationTimeOut, 7.0);
      expect(message.progressBarPosition, ProgressBarPositionMessage.top);
      expect(message.enableMobileCameraSwap, isFalse);
    });

    test('every option reaches the wire', () {
      final message = const CardioTestOptions(
        language: CardioLanguage.arabic,
        style: CardioStyle.dark,
        showLanguageSelector: false,
        instructionPage: CardioInstructionPage(hidden: true, allowsDontShowAgain: true),
        displayResults: true,
        timeZoneId: 'America/Sao_Paulo',
        enableResultSharing: true,
        disableAudio: true,
        disableMotionDetection: true,
        disableLightCheck: true,
        disableDistanceCheck: true,
        terminateTestIfConditionPersisted: false,
        testTerminationTimeOut: Duration(milliseconds: 4500),
        progressBarPosition: CardioProgressBarPosition.bottom,
        enableMobileCameraSwap: true,
      ).toMessage();

      expect(message.language, CardioLanguageMessage.arabic);
      expect(message.style.palette.isDark, isTrue);
      expect(message.style.darkPalette, isNull);
      expect(message.showLanguageSelector, isFalse);
      expect(message.instructionPageHidden, isTrue);
      expect(message.instructionPageAllowsDontShowAgain, isTrue);
      expect(message.displayResults, isTrue);
      expect(message.timeZoneId, 'America/Sao_Paulo');
      expect(message.enableResultSharing, isTrue);
      expect(message.disableAudio, isTrue);
      expect(message.disableMotionDetection, isTrue);
      expect(message.disableLightCheck, isTrue);
      expect(message.disableDistanceCheck, isTrue);
      expect(message.terminateTestIfConditionPersisted, isFalse);
      expect(message.testTerminationTimeOut, 4.5);
      expect(message.progressBarPosition, ProgressBarPositionMessage.bottom);
      expect(message.enableMobileCameraSwap, isTrue);
    });
  });

  group('style', () {
    test('colors travel as ARGB, with the gradient stops in order', () {
      final message = CardioStyle(
        palette: CardioPalette.light.copyWith(
          buttonColor: const Color(0x80FF0000),
          pageBackgroundColors: const [Color(0xFF000001), Color(0xFF000002)],
        ),
        fontFamily: 'Avenir Next',
      ).toMessage();

      expect(message.palette.buttonColor, 0x80FF0000);
      expect(message.palette.pageBackgroundColors, [0xFF000001, 0xFF000002]);
      expect(message.palette.primaryTextColor, 0xFF000000);
      expect(message.darkPalette, isNull);
      expect(message.fontFamily, 'Avenir Next');
    });

    test('the presets are the web SDK defaults', () {
      expect(CardioStyle.dark.toMessage().palette.buttonColor, 0xFF9427EA);
      expect(CardioStyle.light.toMessage().palette.secondaryTextColor, 0xFF434651);
      expect(CardioStyle.system.palette, same(CardioPalette.light));
      expect(CardioStyle.system.darkPalette, same(CardioPalette.dark));
    });
  });

  group('instruction content', () {
    test('items and html translations, with the direction only when given', () {
      final message = CardioInstructionContent([
        CardioInstructionTranslation(
          language: CardioLanguage.english,
          header: 'Before you start',
          body: CardioInstructionItems([
            CardioInstructionItem(
              title: 'Sit still',
              subtitle: 'Rest for a minute',
              iconUrl: Uri.parse('https://example.com/a.png'),
            ),
          ]),
        ),
        const CardioInstructionTranslation(
          language: CardioLanguage.arabic,
          header: '<b>قبل</b>',
          body: CardioInstructionHtml('<p>…</p>'),
          textDirection: TextDirection.ltr,
        ),
      ]).toMessage();

      expect(message[0].language, CardioLanguageMessage.english);
      expect(message[0].isRightToLeft, isNull);
      expect(message[0].html, isNull);
      expect(message[0].items?.single.title, 'Sit still');
      expect(message[0].items?.single.iconUrl, 'https://example.com/a.png');
      expect(message[1].isRightToLeft, isFalse);
      expect(message[1].html, '<p>…</p>');
      expect(message[1].items, isNull);
    });

    test('reads the web SDK JSON like the native SDKs', () {
      final content = CardioInstructionContent.fromWebJson({
        'type': 'text',
        'instructions': [
          {
            'lang': 'es-MX',
            'direction': 'rtl',
            'header': 'Antes de empezar',
            'content': [
              {'title': 'Quieto', 'subtitle': 'Un minuto', 'icon': ''},
              {'subtitle': 'sin título: se descarta'},
            ],
          },
          {'lang': 'xx', 'header': 'Fallback', 'content': <Object>[]},
        ],
      })!;

      final spanish = content.translations[0];
      expect(spanish.language, CardioLanguage.spanish);
      expect(spanish.isRightToLeft, isTrue);
      final items = (spanish.body as CardioInstructionItems).items;
      expect(items.single.title, 'Quieto');
      expect(items.single.iconUrl, isNull);
      expect(content.translations[1].language, CardioLanguage.english);
    });

    test('rejects JSON in another shape', () {
      expect(CardioInstructionContent.fromWebJson({'type': 'video', 'instructions': []}), isNull);
      expect(CardioInstructionContent.fromWebJson({'type': 'html', 'instructions': []}), isNull);
      expect(
        CardioInstructionContent.fromWebJson({
          'type': 'html',
          'instructions': [
            {'lang': 'en', 'header': 'h', 'content': 42},
          ],
        }),
        isNull,
      );
    });
  });

  group('test outcome', () {
    test('a result keeps every metric, the date in UTC and the raw response', () {
      final outcome = CardioTestOutcomeMessage(
        result: CardioResultMessage(
          testId: 'abc',
          createdAtMillis: 1767225600000,
          heartRate: 72,
          heartRateConfidence: 'high',
          bloodPressure: BloodPressureMessage(systolic: 120, diastolic: 80, label: 'Normal'),
          spo2: 98,
          hrv: 40,
          respiratoryRate: 16,
          appUserId: 'user-1',
          elapsedSeconds: 30.5,
          rawJson: '{"_id":"abc","hi":null}',
        ),
      ).toModel();

      final result = (outcome as CardioTestCompleted).result;
      expect(result.testId, 'abc');
      expect(result.createdAt, DateTime.utc(2026));
      expect(result.heartRate, 72);
      expect(
        result.bloodPressure,
        const CardioBloodPressure(systolic: 120, diastolic: 80, label: 'Normal'),
      );
      expect(result.respiratoryRate, 16);
      expect(result.elapsed, const Duration(milliseconds: 30500));
      expect(result.raw, {'_id': 'abc', 'hi': null});
    });

    test('a metric the plan leaves out stays null', () {
      final outcome = CardioTestOutcomeMessage(
        result: CardioResultMessage(heartRate: 72, rawJson: '{}'),
      ).toModel();

      final result = (outcome as CardioTestCompleted).result;
      expect(result.bloodPressure, isNull);
      expect(result.spo2, isNull);
    });

    test('each failure kind becomes its type, with the error where there is one', () {
      CardioScanFailure failure(CardioScanFailureKindMessage kind, [CardioErrorMessage? error]) =>
          (CardioTestOutcomeMessage(
                    failure: CardioScanFailureMessage(kind: kind, error: error),
                  ).toModel()
                  as CardioTestFailed)
              .failure;

      final limit = CardioErrorMessage(code: 'AIZERR002', message: 'limit');
      expect(
        failure(CardioScanFailureKindMessage.unavailable, limit),
        const UnavailableFailure(
          CardioError(code: CardioErrorCode.trialUsageLimitExceeded, message: 'limit'),
        ),
      );
      expect(failure(CardioScanFailureKindMessage.resultError, limit), isA<ResultErrorFailure>());
      expect(
        failure(CardioScanFailureKindMessage.tooManyInvalidFrames),
        isA<TooManyInvalidFramesFailure>(),
      );
      expect(failure(CardioScanFailureKindMessage.interrupted), isA<InterruptedFailure>());
      expect(
        failure(CardioScanFailureKindMessage.cameraPermissionDenied),
        isA<CameraPermissionDeniedFailure>(),
      );
      expect(failure(CardioScanFailureKindMessage.cancelled).code, CardioErrorCode.testCancelled);
    });

    test('a status carries its step and, when failed, the failure', () {
      final status = CardioTestStatusMessage(
        step: CardioTestStepMessage.failed,
        failure: CardioScanFailureMessage(kind: CardioScanFailureKindMessage.interrupted),
      ).toModel();

      expect(status.step, CardioTestStep.failed);
      expect(status.step.webName, 'error');
      expect(status.failure, isA<InterruptedFailure>());
    });
  });

  group('availability', () {
    test('available has no error', () {
      final model = AvailabilityMessage(isAvailable: true).toModel();

      expect(model, const ISelfieAvailability(isAvailable: true));
    });

    test('a known error code becomes its enum value', () {
      final model = AvailabilityMessage(
        isAvailable: false,
        error: CardioErrorMessage(code: 'AIZERR002', message: 'Trial usage limit exceeded'),
      ).toModel();

      expect(model.isAvailable, isFalse);
      expect(model.error?.code, CardioErrorCode.trialUsageLimitExceeded);
      expect(model.error?.message, 'Trial usage limit exceeded');
    });

    test('an unknown or missing code keeps the message without a code', () {
      final unknown = CardioErrorMessage(code: 'AIZERR999', message: 'new').toModel();
      final missing = CardioErrorMessage(message: 'no code').toModel();

      expect(unknown.code, isNull);
      expect(unknown.message, 'new');
      expect(missing.code, isNull);
    });
  });
}
