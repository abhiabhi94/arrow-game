import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('toggles vibration and theme', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const SettingsScreen());
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(settingsProvider).hapticsOn, isFalse);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(settingsProvider).themeChoice, ThemeChoice.dark);
  });

  testWidgets('reset progress asks first, then wipes', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(
      tester,
      const SettingsScreen(),
      seed: <String, Object>{'arrow_level_1_done': true, 'arrow_level_1_stars': 3},
    );
    final progress = container.read(progressProvider.notifier);
    expect(progress.totalStars, 3);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(progress.totalStars, 3);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(progress.totalStars, 0);
  });
}
