import 'dart:ui' show TextDirection;

import 'package:meta/meta.dart';

import 'cardio_language.dart';

/// One tip of the custom instructions.
@immutable
class CardioInstructionItem {
  const CardioInstructionItem({required this.title, this.subtitle, this.iconUrl});

  final String title;
  final String? subtitle;

  /// An image for the item's icon; null for none.
  final Uri? iconUrl;
}

/// What a translation of the instructions shows.
@immutable
sealed class CardioInstructionBody {
  const CardioInstructionBody();
}

/// A list of tips (web SDK: type "text").
final class CardioInstructionItems extends CardioInstructionBody {
  const CardioInstructionItems(this.items);

  final List<CardioInstructionItem> items;
}

/// An HTML fragment (web SDK: type "html"), shown as a page without scripts.
final class CardioInstructionHtml extends CardioInstructionBody {
  const CardioInstructionHtml(this.html);

  final String html;
}

/// The instructions in one language.
@immutable
class CardioInstructionTranslation {
  const CardioInstructionTranslation({
    required this.language,
    required this.header,
    required this.body,
    this.textDirection,
  });

  final CardioLanguage language;

  /// Text shown above the instructions (for [CardioInstructionHtml], an HTML fragment too).
  final String header;

  final CardioInstructionBody body;

  /// The text direction; null: the language's own (right to left for Arabic).
  final TextDirection? textDirection;

  bool get isRightToLeft => switch (textDirection) {
    TextDirection.rtl => true,
    TextDirection.ltr => false,
    null => language.isRightToLeft,
  };
}

/// Your own instructions instead of the default tips, per language — the web SDK's
/// `instructionContent`. The test shows the translation for its current language, falling back
/// to English, then to the first one.
@immutable
class CardioInstructionContent {
  const CardioInstructionContent(this.translations);

  final List<CardioInstructionTranslation> translations;

  /// Reads the web SDK's `instructionContent` object as is (e.g. the same JSON your web
  /// integration uses): `{ type: "text" | "html", instructions: [{ lang, direction, header,
  /// content }] }`. Null when it isn't in that shape — the same rules as the native SDKs.
  static CardioInstructionContent? fromWebJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type != 'text' && type != 'html') return null;
    final entries = json['instructions'];
    if (entries is! List) return null;

    final translations = <CardioInstructionTranslation>[];
    for (final entry in entries) {
      if (entry is! Map) return null;
      final lang = entry['lang'];
      final header = entry['header'];
      if (lang is! String || header is! String) return null;

      final CardioInstructionBody body;
      final content = entry['content'];
      if (type == 'html') {
        if (content is! String) return null;
        body = CardioInstructionHtml(content);
      } else {
        if (content is! List) return null;
        body = CardioInstructionItems([
          for (final item in content)
            if (item is Map && item['title'] is String)
              CardioInstructionItem(
                title: item['title'] as String,
                subtitle: item['subtitle'] is String ? item['subtitle'] as String : null,
                iconUrl: switch (item['icon']) {
                  final String icon when icon.isNotEmpty => Uri.tryParse(icon),
                  _ => null,
                },
              ),
        ]);
      }

      final direction = entry['direction'];
      translations.add(
        CardioInstructionTranslation(
          language: CardioLanguage.fromCode(lang),
          header: header,
          body: body,
          textDirection: direction is String
              ? (direction.toLowerCase() == 'rtl' ? TextDirection.rtl : TextDirection.ltr)
              : null,
        ),
      );
    }
    return translations.isEmpty ? null : CardioInstructionContent(translations);
  }
}
