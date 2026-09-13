import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/home_screen.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// Opening a level from home must not spin up the real generator/timer.
final List<Override> _gameOverride = [
  gameProvider.overrideWith(
    (ref, level) => GameNotifier(
      sampleSpecFor(level),
      puzzle: samplePuzzle(),
      autoTick: false,
    ),
  ),
];

void main() {
  testWidgets('renders title, stars tally, play card and 20 tiles', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Arrow'), findsOneWidget);
    expect(find.text('0 of 60 stars'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget); // the play card
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    for (var level = 1; level <= 20; level++) {
      expect(find.text('$level'), findsOneWidget, reason: 'tile $level');
    }
  });

  testWidgets('locked levels show a lock and do not open', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      extraOverrides: [
        progressProvider.overrideWith(
          (ref) => ProgressNotifier(
            ref.watch(progressRepositoryProvider),
            unlockAllLevels: false,
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(19));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('cleared levels show stars and best time; next unlocks', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        'arrow_level_1_done': true,
        'arrow_level_1_stars': 2,
        'arrow_level_1_best': 21000,
        'arrow_level_1_count': 1,
      },
      extraOverrides: [
        progressProvider.overrideWith(
          (ref) => ProgressNotifier(
            ref.watch(progressRepositoryProvider),
            unlockAllLevels: false,
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 of 60 stars'), findsOneWidget);
    expect(find.text('0:21'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(18));
    // The play card points at level 2 now.
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('Two Ways Out'), findsOneWidget);
  });

  testWidgets('tapping a tile opens the game; the play card too', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen(), extraOverrides: _gameOverride);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Tight Corners'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('First Steps'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
  });

  testWidgets('settings button opens settings', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
