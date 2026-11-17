import 'dart:ui' show Color;

import 'package:meta/meta.dart';

/// The colors of the test's screens (instructions, results, dialogs).
///
/// Start from [CardioPalette.light] or [CardioPalette.dark] — the web SDK's defaults, the same as
/// the native SDKs' — and change what you need with [copyWith].
@immutable
class CardioPalette {
  const CardioPalette({
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

  /// The web SDK's dark mode defaults (its default look).
  static const dark = CardioPalette(
    pageBackgroundColors: [Color(0xFF210D2F), Color(0xFF050110)],
    cardBackgroundColor: Color(0xFF0F0921),
    cardHeaderBackgroundColor: Color(0xFF0C0418),
    primaryTextColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xCCF9F9FA),
    buttonColor: Color(0xFF9427EA),
    buttonTextColor: Color(0xFFFFFFFF),
    iconColor: Color(0xFF9427EA),
    isDark: true,
  );

  /// The web SDK's light mode defaults.
  static const light = CardioPalette(
    pageBackgroundColors: [Color(0xFFFFFFFF)],
    cardBackgroundColor: Color(0xFFFFFFFF),
    cardHeaderBackgroundColor: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF000000),
    secondaryTextColor: Color(0xFF434651),
    buttonColor: Color(0xFF000000),
    buttonTextColor: Color(0xFFFFFFFF),
    iconColor: Color(0xFF000000),
    isDark: false,
  );

  /// Background of the whole screen. Two or more colors draw a top-to-bottom gradient; a single
  /// color is a plain background.
  final List<Color> pageBackgroundColors;

  /// Background of the main card.
  final Color cardBackgroundColor;

  /// Background of the card's header.
  final Color cardHeaderBackgroundColor;

  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color iconColor;

  /// Whether the colors are dark — the status bar and system chrome are drawn to match.
  final bool isDark;

  CardioPalette copyWith({
    List<Color>? pageBackgroundColors,
    Color? cardBackgroundColor,
    Color? cardHeaderBackgroundColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? buttonColor,
    Color? buttonTextColor,
    Color? iconColor,
    bool? isDark,
  }) {
    return CardioPalette(
      pageBackgroundColors: pageBackgroundColors ?? this.pageBackgroundColors,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      cardHeaderBackgroundColor: cardHeaderBackgroundColor ?? this.cardHeaderBackgroundColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      iconColor: iconColor ?? this.iconColor,
      isDark: isDark ?? this.isDark,
    );
  }
}

/// The look of the test's screens — the web SDK's `styles` and `isDarkMode`.
///
/// ```dart
/// // The brand color on both the light and the dark look:
/// final style = CardioStyle(
///   palette: CardioPalette.light.copyWith(buttonColor: brand),
///   darkPalette: CardioPalette.dark.copyWith(buttonColor: brand),
///   fontFamily: 'Avenir Next',
/// );
/// ```
@immutable
class CardioStyle {
  const CardioStyle({required this.palette, this.darkPalette, this.fontFamily});

  /// Follows the device's light/dark setting (the default).
  static const system = CardioStyle(palette: CardioPalette.light, darkPalette: CardioPalette.dark);

  /// Always the web SDK's light colors.
  static const light = CardioStyle(palette: CardioPalette.light);

  /// Always the web SDK's dark colors (the web SDK's default look).
  static const dark = CardioStyle(palette: CardioPalette.dark);

  /// The colors in light mode — or always, when [darkPalette] is null.
  final CardioPalette palette;

  /// The colors while the device is in dark mode; null: [palette] always.
  final CardioPalette? darkPalette;

  /// Font family for all text, as the platform knows it (e.g. "Avenir Next" on iOS, "serif" or
  /// "sans-serif-condensed" on Android); null: the system font. Fonts bundled as Flutter assets
  /// aren't visible to the native screens — the app has to register them natively.
  final String? fontFamily;

  CardioStyle copyWith({CardioPalette? palette, CardioPalette? darkPalette, String? fontFamily}) {
    return CardioStyle(
      palette: palette ?? this.palette,
      darkPalette: darkPalette ?? this.darkPalette,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
