import 'dart:convert';

import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
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
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Arrow'), findsOneWidget);
    expect(find.bySemanticsLabel('0 of 60 stars'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget); // the hero card
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('Your journey'), findsOneWidget);
    for (var level = 1; level <= 20; level++) {
      expect(find.text('$level', skipOffstage: false), findsOneWidget, reason: 'node $level');
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
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.lock_rounded, skipOffstage: false), findsNWidgets(19));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump(const Duration(milliseconds: 800));
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
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.bySemanticsLabel('2 of 60 stars'), findsOneWidget);
    expect(find.text('0:21'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded, skipOffstage: false), findsNWidgets(18));
    // The hero card points at level 2 now; the node names it too.
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('Two Ways Out'), findsNWidgets(2));
  });

  testWidgets('tapping a tile opens the game; the play card too', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen(), extraOverrides: _gameOverride);
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Tight Corners'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
  });

  testWidgets('a level left mid-way takes the hero card and opens on tap', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        SavedGameRepository.key: jsonEncode(const {
          'level': 3,
          'removed': [0, 1],
          'mistakes': 0,
          'hintsLeft': 3,
          'elapsedMs': 30000,
        }),
      },
      extraOverrides: _gameOverride,
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('PICK UP WHERE YOU LEFT OFF'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('2 of 12 arrows out · 0:30 on the clock'), findsOneWidget);
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('Level 3'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
  });

  testWidgets('with every level cleared the hero offers a replay', (tester) async {
    await usePhoneSurface(tester);
    final seed = <String, Object>{
      for (var l = 1; l <= 20; l++) ...{
        'arrow_level_${l}_done': true,
        'arrow_level_${l}_stars': 3,
      },
    };
    await pumpApp(tester, const HomeScreen(), seed: seed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Every level cleared — legend!'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.bySemanticsLabel('60 of 60 stars'), findsOneWidget);
  });

  testWidgets('settings button opens settings', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
