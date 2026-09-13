import 'package:flutter/material.dart';

import 'colors.dart';

/// The bundled typeface (see pubspec `fonts:`): Google Sans Flex, static
/// instances 400–800, so headings can go bold without a fake-bold pass.
const String kFontFamily = 'GoogleSansFlex';

/// The app's light theme (the default look).
ThemeData buildLightTheme() => _buildTheme(ArrowPalette.light, Brightness.light);

/// The app's dark theme — same rounded, friendly shapes on deep indigo surfaces.
ThemeData buildDarkTheme() => _buildTheme(ArrowPalette.dark, Brightness.dark);

/// Builds the app's Material 3 theme — clean, rounded, and warm.
ThemeData _buildTheme(ArrowPalette p, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: brightness,
    primary: p.primary,
    secondary: p.accentCoral,
    tertiary: p.accentMint,
    error: p.errorRed,
    surface: p.surface,
  );

  final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
  final textTheme = base.textTheme.apply(
    fontFamily: kFontFamily,
    bodyColor: p.textInk,
    displayColor: p.textInk,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: kFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.backgroundSoft,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: p.textInk,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: p.textInk,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primaryLight, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.textInk,
      contentTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: p.surface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.primary : p.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? p.primaryLight
            : p.textFaint,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.primary,
      inactiveTrackColor: p.outlineSoft,
      thumbColor: p.primary,
    ),
  );
}
