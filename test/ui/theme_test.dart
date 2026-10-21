import 'dart:math';

import 'package:arrow_game/main.dart';
import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/ui/colors.dart';
import 'package:arrow_game/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The grid lines are a 1 px hairline on the page, so they need real contrast
// against the page to show up at all — the light palette once sat 16 levels
// off and the lattice vanished on the web build.
int _channelGap(Color a, Color b) {
  final gaps = [
    (a.r - b.r).abs(),
    (a.g - b.g).abs(),
    (a.b - b.b).abs(),
  ];
  return (gaps.reduce((x, y) => x > y ? x : y) * 255).round();
}

/// WCAG relative luminance, for the contrast ratio below.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  test('light and dark themes carry their palettes', () {
    final light = buildLightTheme();
    final dark = buildDarkTheme();
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.useMaterial3, isTrue);
    expect(light.scaffoldBackgroundColor, ArrowPalette.light.backgroundSoft);
    expect(dark.scaffoldBackgroundColor, ArrowPalette.dark.backgroundSoft);
    expect(light.colorScheme.primary, ArrowPalette.light.primary);
    expect(light.textTheme.bodyMedium?.fontFamily, kFontFamily);
    expect(dark.appBarTheme.titleTextStyle?.fontFamily, kFontFamily);
    expect(dark.colorScheme.primary, ArrowPalette.dark.primary);
  });

  test('grid lines stand off the page in both palettes', () {
    for (final palette in [ArrowPalette.light, ArrowPalette.dark]) {
      expect(_channelGap(palette.gridLine, palette.backgroundSoft), greaterThanOrEqualTo(40));
      // Still a lattice under the ink, not a second drawing on top of it.
      expect(
        _channelGap(palette.gridLine, palette.backgroundSoft),
        lessThan(_channelGap(palette.arrowInk, palette.backgroundSoft) ~/ 2),
      );
    }
  });

  test('accent ink is readable on the bright accents in both palettes', () {
    // The hint badge is amber in both themes. Drawing its count in the
    // palette's own textInk made it near-white on amber in the dark theme,
    // which is invisible; onAccent stays dark in both.
    for (final palette in [ArrowPalette.light, ArrowPalette.dark]) {
      for (final accent in [palette.accentSun, palette.accentCoral, palette.accentMint]) {
        expect(
          _contrast(palette.onAccent, accent),
          greaterThanOrEqualTo(4.5),
          reason: 'onAccent on $accent',
        );
      }
      // Never a worse choice than the body ink the badge used to use — in
      // the dark theme that ink sits at 1.2:1 on the amber, i.e. invisible.
      expect(
        _contrast(palette.onAccent, palette.accentSun),
        greaterThanOrEqualTo(_contrast(palette.textInk, palette.accentSun)),
      );
    }
  });

  test('a pill label is readable on its own wash in both palettes', () {
    // The riddle card's chips are a 14% wash of the primary. Lettering them
    // in the primary itself put "6 letters" at 4.0:1 on the light theme and
    // 3.4:1 on the dark one, where it was barely there; chipInk steps away
    // from the wash in each palette instead.
    for (final palette in [ArrowPalette.light, ArrowPalette.dark]) {
      final wash = Color.alphaBlend(
        palette.primary.withValues(alpha: 0.14),
        palette.surface,
      );
      expect(
        _contrast(palette.chipInk, wash),
        greaterThanOrEqualTo(4.5),
        reason: 'chipInk on its wash',
      );
      expect(
        _contrast(palette.chipInk, wash),
        greaterThan(_contrast(palette.primary, wash)),
      );
    }
  });

  test('lettering clears 4.5:1 and the bars 3:1 in both palettes', () {
    // The audit's pins. Each pairing is one that shipped under the line:
    // white on the dark primary (4.0), the primary as lettering on the light
    // page (4.4), mint as lettering on white (1.9), the error red (3.8), the
    // coral clock digits (2.5), the mint bar on its track (1.5).
    for (final palette in [ArrowPalette.light, ArrowPalette.dark]) {
      final name = palette == ArrowPalette.light ? 'light' : 'dark';
      // White sits on the primary: filled buttons, the hero card, a current node.
      expect(_contrast(Colors.white, palette.primary), greaterThanOrEqualTo(4.5), reason: '$name primary');
      expect(_contrast(Colors.white, palette.primaryDark), greaterThanOrEqualTo(4.5), reason: '$name primaryDark');
      // The primary as lettering, on the page and on a surface.
      for (final bg in [palette.surface, palette.backgroundSoft]) {
        expect(_contrast(palette.primaryInk, bg), greaterThanOrEqualTo(4.5), reason: '$name primaryInk');
        expect(_contrast(palette.successInk, bg), greaterThanOrEqualTo(4.5), reason: '$name successInk');
        expect(_contrast(palette.errorRed, bg), greaterThanOrEqualTo(4.5), reason: '$name errorRed');
        expect(_contrast(palette.textMuted, bg), greaterThanOrEqualTo(4.5), reason: '$name textMuted');
        expect(_contrast(palette.timerWarn, bg), greaterThanOrEqualTo(4.5), reason: '$name timerWarn');
      }
      // The play pill is white in both themes.
      expect(_contrast(palette.primaryDark, Colors.white), greaterThanOrEqualTo(4.5));
      // A cleared node's number on the mint.
      expect(_contrast(palette.onAccent, palette.accentMint), greaterThanOrEqualTo(4.5));
      // The clock's bar against its track, both colours it wears.
      expect(_contrast(palette.timerFill, palette.timerTrack), greaterThanOrEqualTo(3), reason: '$name timerFill');
      expect(_contrast(palette.timerWarn, palette.timerTrack), greaterThanOrEqualTo(3), reason: '$name timerWarn bar');
    }
  });

  test('themeModeFor maps every choice', () {
    expect(themeModeFor(ThemeChoice.system), ThemeMode.system);
    expect(themeModeFor(ThemeChoice.light), ThemeMode.light);
    expect(themeModeFor(ThemeChoice.dark), ThemeMode.dark);
  });

  testWidgets('context.palette follows the theme brightness', (tester) async {
    late ArrowPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Builder(builder: (context) {
          seen = context.palette;
          return const SizedBox();
        }),
      ),
    );
    expect(seen, same(ArrowPalette.dark));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(builder: (context) {
          seen = context.palette;
          return const SizedBox();
        }),
      ),
    );
    await tester.pumpAndSettle(); // the theme change is animated
    expect(seen, same(ArrowPalette.light));
  });
}
