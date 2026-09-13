import 'package:flutter/material.dart';

/// Playful, modern colour tokens. Two palettes — a cheerful light one and a
/// deep indigo dark one — share the same field names so widgets read them
/// through [ArrowPalette] / `context.palette` without caring which is active.
///
/// The raw `_l*` (light) and `_d*` (dark) values are private; widgets never
/// touch them directly — they read the theme-aware fields on [ArrowPalette].

// ---------------------------------------------------------------------------
// Light palette values.
// ---------------------------------------------------------------------------

// Surfaces
const Color _lBackgroundSoft = Color(0xFFF4F3FF); // soft lavender white
const Color _lSurface = Color(0xFFFFFFFF);
const Color _lCardTint = Color(0xFFFBFAFF);
const Color _lOutlineSoft = Color(0xFFDAD7F2);
const Color _lScrim = Color(0x8A1B1834);

// Brand accents
const Color _lPrimary = Color(0xFF6C5CE7);
const Color _lPrimaryDark = Color(0xFF5647C4);
const Color _lPrimaryLight = Color(0xFFA29BFE);
const Color _lAccentCoral = Color(0xFFFF6B6B);
const Color _lAccentSun = Color(0xFFFFC53D);
const Color _lAccentMint = Color(0xFF32D296);

// Semantic
const Color _lSuccessGreen = Color(0xFF22C55E);
const Color _lErrorRed = Color(0xFFEF4444);

// Text
const Color _lTextInk = Color(0xFF2D2A4A);
const Color _lTextMuted = Color(0xFF6E6A8F);
const Color _lTextFaint = Color(0xFFA6A2C4);

// Board: a white card with faint grid lines; arrows cycle through a small
// set of saturated inks so neighbours read as different pieces.
const Color _lBoardSurface = Color(0xFFFFFFFF);
const Color _lGridLine = Color(0xFFE4E0FF);
const Color _lBoardBorder = Color(0xFFDAD7F2);
const Color _lHintGlow = Color(0x66FFC53D);
const Color _lBlockedFlash = Color(0x80FF6B6B);
const List<Color> _lArrowInks = <Color>[
  Color(0xFF2D2A4A), // ink
  Color(0xFF6C5CE7), // indigo
  Color(0xFFFF6B6B), // coral
  Color(0xFF12A876), // green
  Color(0xFFE0A100), // amber
  Color(0xFF0EA5E9), // sky
  Color(0xFFD946EF), // magenta
  Color(0xFF8B5E34), // brown
];

// HUD
const Color _lHeartFull = Color(0xFFFF6B6B);
const Color _lHeartEmpty = Color(0xFFDAD7F2);
const Color _lTimerTrack = Color(0xFFE4E0FF);
const Color _lTimerFill = Color(0xFF32D296);
const Color _lTimerWarn = Color(0xFFFF6B6B);
const Color _lStar = Color(0xFFFFC53D);
const Color _lStarEmpty = Color(0xFFDAD7F2);

// ---------------------------------------------------------------------------
// Dark palette values. Deep indigo-charcoal surfaces, lightened accents/text
// so contrast holds up on a dark background.
// ---------------------------------------------------------------------------

const Color _dBackgroundSoft = Color(0xFF131120);
const Color _dSurface = Color(0xFF201D30);
const Color _dCardTint = Color(0xFF262238);
const Color _dOutlineSoft = Color(0xFF322E4A);
const Color _dScrim = Color(0xB3000000);

const Color _dPrimary = Color(0xFF7A6BF2);
const Color _dPrimaryDark = Color(0xFF5647C4);
const Color _dPrimaryLight = Color(0xFFB7AEFF);
const Color _dAccentCoral = Color(0xFFFF7B7B);
const Color _dAccentSun = Color(0xFFFFCE52);
const Color _dAccentMint = Color(0xFF3FE0A6);

const Color _dSuccessGreen = Color(0xFF34D058);
const Color _dErrorRed = Color(0xFFFF6B6B);

const Color _dTextInk = Color(0xFFEAE7F7);
const Color _dTextMuted = Color(0xFFA9A4CC);
const Color _dTextFaint = Color(0xFF6E6A8F);

const Color _dBoardSurface = Color(0xFF201D30);
const Color _dGridLine = Color(0xFF322E4A);
const Color _dBoardBorder = Color(0xFF3A3560);
const Color _dHintGlow = Color(0x80FFCE52);
const Color _dBlockedFlash = Color(0x99FF7B7B);
const List<Color> _dArrowInks = <Color>[
  Color(0xFFEAE7F7), // near-white ink
  Color(0xFFB7AEFF), // lavender
  Color(0xFFFF7B7B), // coral
  Color(0xFF3FE0A6), // mint
  Color(0xFFFFCE52), // sun
  Color(0xFF5BC6F5), // sky
  Color(0xFFE879F9), // magenta
  Color(0xFFD2A679), // tan
];

const Color _dHeartFull = Color(0xFFFF7B7B);
const Color _dHeartEmpty = Color(0xFF3A3560);
const Color _dTimerTrack = Color(0xFF2C2942);
const Color _dTimerFill = Color(0xFF3FE0A6);
const Color _dTimerWarn = Color(0xFFFF7B7B);
const Color _dStar = Color(0xFFFFCE52);
const Color _dStarEmpty = Color(0xFF3A3560);

// ---------------------------------------------------------------------------
// Palette — the theme-aware bundle of every colour token.
// ---------------------------------------------------------------------------

@immutable
class ArrowPalette {
  const ArrowPalette({
    required this.backgroundSoft,
    required this.surface,
    required this.cardTint,
    required this.outlineSoft,
    required this.scrim,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accentCoral,
    required this.accentSun,
    required this.accentMint,
    required this.successGreen,
    required this.errorRed,
    required this.textInk,
    required this.textMuted,
    required this.textFaint,
    required this.boardSurface,
    required this.gridLine,
    required this.boardBorder,
    required this.hintGlow,
    required this.blockedFlash,
    required this.arrowInks,
    required this.heartFull,
    required this.heartEmpty,
    required this.timerTrack,
    required this.timerFill,
    required this.timerWarn,
    required this.star,
    required this.starEmpty,
  });

  final Color backgroundSoft;
  final Color surface;
  final Color cardTint;
  final Color outlineSoft;
  final Color scrim;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accentCoral;
  final Color accentSun;
  final Color accentMint;
  final Color successGreen;
  final Color errorRed;
  final Color textInk;
  final Color textMuted;
  final Color textFaint;
  final Color boardSurface;
  final Color gridLine;
  final Color boardBorder;
  final Color hintGlow;
  final Color blockedFlash;

  /// Inks for arrow pieces; arrow `i` uses `arrowInks[i % length]`.
  final List<Color> arrowInks;
  final Color heartFull;
  final Color heartEmpty;
  final Color timerTrack;
  final Color timerFill;
  final Color timerWarn;
  final Color star;
  final Color starEmpty;

  static const ArrowPalette light = ArrowPalette(
    backgroundSoft: _lBackgroundSoft,
    surface: _lSurface,
    cardTint: _lCardTint,
    outlineSoft: _lOutlineSoft,
    scrim: _lScrim,
    primary: _lPrimary,
    primaryDark: _lPrimaryDark,
    primaryLight: _lPrimaryLight,
    accentCoral: _lAccentCoral,
    accentSun: _lAccentSun,
    accentMint: _lAccentMint,
    successGreen: _lSuccessGreen,
    errorRed: _lErrorRed,
    textInk: _lTextInk,
    textMuted: _lTextMuted,
    textFaint: _lTextFaint,
    boardSurface: _lBoardSurface,
    gridLine: _lGridLine,
    boardBorder: _lBoardBorder,
    hintGlow: _lHintGlow,
    blockedFlash: _lBlockedFlash,
    arrowInks: _lArrowInks,
    heartFull: _lHeartFull,
    heartEmpty: _lHeartEmpty,
    timerTrack: _lTimerTrack,
    timerFill: _lTimerFill,
    timerWarn: _lTimerWarn,
    star: _lStar,
    starEmpty: _lStarEmpty,
  );

  static const ArrowPalette dark = ArrowPalette(
    backgroundSoft: _dBackgroundSoft,
    surface: _dSurface,
    cardTint: _dCardTint,
    outlineSoft: _dOutlineSoft,
    scrim: _dScrim,
    primary: _dPrimary,
    primaryDark: _dPrimaryDark,
    primaryLight: _dPrimaryLight,
    accentCoral: _dAccentCoral,
    accentSun: _dAccentSun,
    accentMint: _dAccentMint,
    successGreen: _dSuccessGreen,
    errorRed: _dErrorRed,
    textInk: _dTextInk,
    textMuted: _dTextMuted,
    textFaint: _dTextFaint,
    boardSurface: _dBoardSurface,
    gridLine: _dGridLine,
    boardBorder: _dBoardBorder,
    hintGlow: _dHintGlow,
    blockedFlash: _dBlockedFlash,
    arrowInks: _dArrowInks,
    heartFull: _dHeartFull,
    heartEmpty: _dHeartEmpty,
    timerTrack: _dTimerTrack,
    timerFill: _dTimerFill,
    timerWarn: _dTimerWarn,
    star: _dStar,
    starEmpty: _dStarEmpty,
  );
}

/// Reads the active [ArrowPalette] for the current theme brightness.
extension ArrowPaletteX on BuildContext {
  ArrowPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? ArrowPalette.dark
      : ArrowPalette.light;
}
