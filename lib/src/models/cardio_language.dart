/// Language of the test's screens and voice guidance (web SDK: `language`).
enum CardioLanguage {
  english('en'),
  spanish('es'),
  arabic('ar');

  const CardioLanguage(this.code);

  /// The web SDK's language code.
  final String code;

  bool get isRightToLeft => this == arabic;

  /// The language's own name, for a language picker.
  String get displayName => switch (this) {
    english => 'English',
    spanish => 'Español',
    arabic => 'العربية',
  };

  /// From a language code ("en", "es-MX", "ar"); anything else is English, like the native SDKs.
  static CardioLanguage fromCode(String code) {
    final base = code.toLowerCase().split(RegExp('[-_]')).first;
    return values.firstWhere((language) => language.code == base, orElse: () => english);
  }
}
