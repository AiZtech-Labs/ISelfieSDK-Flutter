import 'dart:ui' show Color;

import 'package:iselfie_sdk/iselfie_sdk.dart';

/// Sample values the example offers, to try each option of the SDK.
abstract final class ExampleSamples {
  static const _brand = Color(0xFF00897B);

  /// The brand color on both looks, a soft gradient in light mode, and a system font.
  static final brandStyle = CardioStyle(
    palette: CardioPalette.light.copyWith(
      pageBackgroundColors: const [Color(0xFFE0F2F1), Color(0xFFFFFFFF)],
      buttonColor: _brand,
      iconColor: _brand,
    ),
    darkPalette: CardioPalette.dark.copyWith(
      pageBackgroundColors: const [Color(0xFF00332E), Color(0xFF000000)],
      buttonColor: _brand,
      iconColor: _brand,
    ),
  );

  /// Typed instructions, one translation per language.
  static final itemInstructions = CardioInstructionContent([
    CardioInstructionTranslation(
      language: CardioLanguage.english,
      header: 'Before your heart check',
      body: const CardioInstructionItems([
        CardioInstructionItem(title: 'Sit down and rest', subtitle: 'For about a minute'),
        CardioInstructionItem(title: 'Good light on your face', subtitle: 'Face a window or lamp'),
        CardioInstructionItem(title: 'Hold the phone still', subtitle: 'At eye level'),
      ]),
    ),
    CardioInstructionTranslation(
      language: CardioLanguage.spanish,
      header: 'Antes de tu control cardíaco',
      body: const CardioInstructionItems([
        CardioInstructionItem(title: 'Siéntate y descansa', subtitle: 'Durante un minuto'),
        CardioInstructionItem(title: 'Buena luz en tu cara', subtitle: 'Frente a una ventana'),
        CardioInstructionItem(
          title: 'Sostén el teléfono quieto',
          subtitle: 'A la altura de los ojos',
        ),
      ]),
    ),
    CardioInstructionTranslation(
      language: CardioLanguage.arabic,
      header: 'قبل فحص القلب',
      body: const CardioInstructionItems([
        CardioInstructionItem(title: 'اجلس واسترح', subtitle: 'لمدة دقيقة تقريبًا'),
        CardioInstructionItem(title: 'إضاءة جيدة على وجهك'),
        CardioInstructionItem(title: 'ثبّت الهاتف', subtitle: 'على مستوى العينين'),
      ]),
    ),
  ]);

  /// HTML instructions in the web SDK's JSON shape, read with fromWebJson.
  static final htmlInstructions = CardioInstructionContent.fromWebJson({
    'type': 'html',
    'instructions': [
      {
        'lang': 'en',
        'direction': 'ltr',
        'header': '<b>Your clinic</b> asks you to',
        'content':
            '<ul><li>Rest for <b>5 minutes</b></li><li>Avoid coffee before the test</li>'
            '<li>Remove your glasses</li></ul>',
      },
      {
        'lang': 'es',
        'direction': 'ltr',
        'header': '<b>Tu clínica</b> te pide',
        'content':
            '<ul><li>Descansar <b>5 minutos</b></li><li>Evitar el café antes</li>'
            '<li>Quitarte las gafas</li></ul>',
      },
    ],
  })!;

  /// Time zones for the result page's date (null: the device's).
  static const timeZones = <String?>[null, 'America/Sao_Paulo', 'Asia/Riyadh', 'UTC'];
}
