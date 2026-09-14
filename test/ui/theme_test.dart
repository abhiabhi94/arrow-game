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
