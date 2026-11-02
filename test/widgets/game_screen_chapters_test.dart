import 'dart:convert';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/providers/daily_provider.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

List<Override> _overrides() => [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          sampleSpecFor(level),
          puzzle: samplePuzzle(),
          savedGame: ref.read(savedGameProvider.notifier).forLevel(level),
          onCleared: level == 0
              ? (_, ms, stars) => ref.read(dailyProvider.notifier).recordCompletion(ms, stars)
              : ref.read(progressProvider.notifier).recordCompletion,
          onSnapshot: ref.read(savedGameProvider.notifier).record,
          autoTick: false,
        ),
      ),
      progressProvider.overrideWith(
        (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: true),
      ),
      ...silentFeedback(),
    ];

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  Map<String, Object> seed = const {},
}) async {
  await usePhoneSurface(tester);
  final container = await pumpApp(tester, screen, seed: seed, extraOverrides: _overrides());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

/// Taps the centre of grid [cell] on the 4-column sample board.
Future<void> _tapCell(WidgetTester tester, Cell cell) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint)).first;
  final rect = tester.getRect(board);
  final cs = rect.width / 4;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}

void main() {
  testWidgets('a chapter\'s first level opens on its card, over the paused board', (tester) async {
    final container = await _pump(tester, const GameScreen(level: 21));
    expect(find.text('Mirrors'), findsOneWidget);
    expect(find.text('Arrows bounce off mirrors.'), findsNWidgets(2)); // the card's line and the one under the board
    expect(find.text('Got it'), findsOneWidget);
    expect(container.read(gameProvider(21)).phase, GamePhase.paused);
    // Two boards on screen: the level's and the card's picture.
    expect(find.byType(PuzzleBoard), findsNWidgets(2));
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Mirrors'), findsNothing);
    expect(container.read(gameProvider(21)).phase, GamePhase.playing);
    // The line under the board stays.
    expect(find.text('Arrows bounce off mirrors.'), findsOneWidget);
    // Pausing again does not bring the card back.
    container.read(gameProvider(21).notifier).pause();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mirrors'), findsNothing);
    expect(find.text('Paused'), findsOneWidget);
  });

  for (final (level, title) in <(int, String)>[(41, 'The key goes first. Then the lock opens.'), (61, 'Clear an arrow beside it to see where it points.'), (81, 'One tap, both go. Both paths must be clear.')]) {
    testWidgets('level $level opens on its chapter card', (tester) async {
      // The earlier chapters' cards were dismissed on their own levels.
      final before = chapters.where((c) => c.index >= 2 && c.lastLevel < level).map((c) => c.rule.name).toList();
      await _pump(tester, GameScreen(level: level), seed: {IntroRepository.key: before});
      expect(find.text(title), findsOneWidget);
      expect(ruleTaughtAt(level), isNotNull);
      await tester.pump(const Duration(milliseconds: 400));
    });
  }

  testWidgets('a card once dismissed is not shown again, cleared or not; only the line stays', (tester) async {
    final container = await _pump(
      tester,
      const GameScreen(level: 41),
      seed: const {
        'arrow_level_41_done': true,
        IntroRepository.key: ['mirrors', 'locks'],
      },
    );
    expect(find.text('The key goes first. Then the lock opens.'), findsNothing);
    expect(container.read(gameProvider(41)).phase, GamePhase.playing);
    expect(find.text('A locked arrow waits for its key.'), findsOneWidget);
  });

  testWidgets('a player already past a chapter is shown every card owed, one after another', (tester) async {
    // Forty-five levels cleared before the chapters arrived: opening level
    // 46 brings the Mirrors card, then the Locks card, then the level.
    final container = await _pump(
      tester,
      const GameScreen(level: 46),
      seed: {for (var l = 1; l <= 45; l++) 'arrow_level_${l}_done': true},
    );
    expect(find.text('Mirrors'), findsOneWidget);
    expect(find.text('Arrows bounce off mirrors.'), findsOneWidget);
    expect(container.read(gameProvider(46)).phase, GamePhase.paused);
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Mirrors'), findsNothing);
    expect(find.text('The key goes first. Then the lock opens.'), findsOneWidget);
    expect(container.read(gameProvider(46)).phase, GamePhase.paused);
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Got it'), findsNothing);
    expect(container.read(gameProvider(46)).phase, GamePhase.playing);
    // Both are remembered: the next level opens straight onto the board.
    expect(container.read(introProvider), {ChapterRule.mirrors, ChapterRule.locks});
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getStringList(IntroRepository.key), ['mirrors', 'locks']);
    // Not the Fog card: that chapter is still ahead.
    expect(find.text('Clear an arrow beside it to see where it points.'), findsNothing);
  });

  testWidgets('the daily board brings the cards of the chapter it borrows from', (tester) async {
    await _pump(
      tester,
      const GameScreen.daily(),
      seed: {for (var l = 1; l <= 25; l++) 'arrow_level_${l}_done': true},
    );
    expect(find.text('Arrows bounce off mirrors.'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Got it'), findsNothing);
    expect(find.text('Daily board'), findsOneWidget);
  });

  testWidgets('a level coming back from a saved game shows the welcome, not the card', (tester) async {
    final resumed = await _pump(
      tester,
      const GameScreen(level: 61),
      seed: <String, Object>{
        SavedGameRepository.key: jsonEncode(const {
          'level': 61,
          'seed': 61 * 7919 + 17,
          'removed': [0],
          'mistakes': 0,
          'hintsLeft': 3,
          'elapsedMs': 1000,
        }),
      },
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Clear an arrow beside it to see where it points.'), findsNothing);
    expect(resumed.read(gameProvider(61)).resumeOffered, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('a plain level has no card and no line', (tester) async {
    await _pump(tester, const GameScreen(level: 22), seed: const {IntroRepository.key: ['mirrors']});
    expect(find.text('Got it'), findsNothing);
    expect(find.textContaining('mirrors'), findsNothing);
  });

  testWidgets('the daily board is titled by the day and ends without a next level', (tester) async {
    final container = await _pump(tester, const GameScreen.daily());
    expect(find.text('Daily board'), findsOneWidget);
    expect(find.text('Lines'), findsOneWidget);
    expect(find.text('Got it'), findsNothing);
    // Solve the sample board: 0, 1, then 2.
    await _tapCell(tester, const Cell(1, 1));
    await _tapCell(tester, const Cell(3, 3));
    await _tapCell(tester, const Cell(1, 3));
    expect(container.read(gameProvider(0)).phase, GamePhase.cleared);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Level cleared!'), findsOneWidget);
    expect(find.text("Today's board is done. Come back tomorrow for a new one."), findsOneWidget);
    expect(find.text('Next level'), findsNothing);
    expect(find.text('New best time!'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    final daily = container.read(dailyProvider);
    expect(daily.clearedToday, isTrue);
    expect(daily.streak, 1);
    expect(daily.starsToday, 3);
  });
}
