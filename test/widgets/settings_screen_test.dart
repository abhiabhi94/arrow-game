import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/riddle_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:arrow_game/screens/credits_screen.dart';
import 'package:arrow_game/screens/onboarding_screen.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:arrow_game/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('toggles music, volume, sound effects, haptic feedback and theme', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const SettingsScreen());
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();
    expect(container.read(settingsProvider).sfxOn, isFalse);

    await tester.tap(find.byType(Switch).at(2));
    await tester.pump();
    expect(container.read(settingsProvider).hapticsOn, isFalse);

    await tester.drag(find.byType(Slider), const Offset(-300, 0));
    await tester.pump();
    expect(container.read(settingsProvider).musicVolume, lessThan(0.3));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(container.read(settingsProvider).musicOn, isFalse);
    expect(find.byType(Slider), findsNothing);

    await tester.scrollUntilVisible(find.text('Dark'), 200);
    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(settingsProvider).themeChoice, ThemeChoice.dark);
    await tester.scrollUntilVisible(find.text('How to play'), 200);
    expect(find.text('How to play'), findsOneWidget);
  });

  testWidgets('no time limit is on by default, and extra time waits for a clock', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const SettingsScreen());
    expect(container.read(settingsProvider).noTimeLimit, isTrue);
    await tester.scrollUntilVisible(find.text('Extra time'), 200);
    SwitchListTile tile(String title) =>
        tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));
    expect(tile('No time limit').value, isTrue);
    // Nothing to stretch while there is no clock.
    expect(tile('Extra time').onChanged, isNull);

    await tester.tap(find.text('No time limit'));
    await tester.pump();
    expect(container.read(settingsProvider).noTimeLimit, isFalse);
    expect(tile('Extra time').onChanged, isNotNull);
    await tester.tap(find.text('Extra time'));
    await tester.pump();
    expect(container.read(settingsProvider).extraTime, isTrue);
  });

  testWidgets('picks a language, with the device as the default', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const SettingsScreen());
    expect(container.read(settingsProvider).languageChoice, LanguageChoice.system);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('हिन्दी'));
    await tester.pump();
    expect(container.read(settingsProvider).languageChoice, LanguageChoice.hindi);

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(container.read(settingsProvider).languageChoice, LanguageChoice.english);
  });

  testWidgets('opens the credits and the walkthrough', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const SettingsScreen());
    // Both rows sit below a phone's fold since the accessibility card.
    await tester.scrollUntilVisible(find.text('Music credits'), 200);
    await tester.tap(find.text('Music credits'));
    await tester.pumpAndSettle();
    expect(find.byType(CreditsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('How to play'), 200);
    await tester.tap(find.text('How to play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('reset progress asks first, then wipes', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(
      tester,
      const SettingsScreen(),
      seed: <String, Object>{
        'arrow_level_1_done': true,
        'arrow_level_1_stars': 3,
        RiddleDeckRepository.solvedKey: 5,
        SavedGameRepository.key: '{"level":2,"seed":15855,"removed":[1],"mistakes":0,"hintsLeft":3,"elapsedMs":10}',
        IntroRepository.key: ['mirrors'],
      },
    );
    final progress = container.read(progressProvider.notifier);
    expect(progress.totalStars, 3);
    expect(container.read(introProvider), {ChapterRule.mirrors});
    expect(container.read(riddleDeckProvider).solved, 5);
    expect(container.read(savedGameProvider)?.level, 2);

    // The accessibility card pushed the reset card below a phone's fold.
    await tester.scrollUntilVisible(find.text('Reset progress'), 200);
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
    expect(container.read(savedGameProvider), isNull);
    // The riddle tally is progress too, and so are the chapter cards seen.
    expect(container.read(riddleDeckProvider).solved, 0);
    expect(container.read(introProvider), isEmpty);
  });

  testWidgets('a desktop window keeps the cards phone-wide and centred', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, const SettingsScreen());
    expect(tester.takeException(), isNull);
    final card = tester.getRect(find.byType(Switch).first);
    expect(card.right, lessThanOrEqualTo((1440 + kMaxContentWidth) / 2));
    await tester.scrollUntilVisible(find.text('How to play'), 200);
    final title = tester.getRect(find.text('How to play'));
    expect(title.left, greaterThanOrEqualTo((1440 - kMaxContentWidth) / 2));
  });
}
