import 'package:arrow_game/main.dart';
import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/ui/colors.dart';
import 'package:arrow_game/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(dark.colorScheme.primary, ArrowPalette.dark.primary);
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
