import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// The app's light theme (the default look).
ThemeData buildLightTheme() => _buildTheme(ArrowPalette.light, Brightness.light);

/// The app's dark theme — same rounded, friendly shapes on deep indigo surfaces.
ThemeData buildDarkTheme() => _buildTheme(ArrowPalette.dark, Brightness.dark);

/// Builds the app's Material 3 theme — rounded, friendly, and colourful.
/// Uses Nunito (rounded, warm) for a playful feel while staying readable.
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

  final textTheme = GoogleFonts.nunitoTextTheme().apply(
    bodyColor: p.textInk,
    displayColor: p.textInk,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.backgroundSoft,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: p.textInk,
      titleTextStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w800,
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
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 18),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primaryLight, width: 1.5),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.textInk,
      contentTextStyle: GoogleFonts.nunito(
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
  );
}
