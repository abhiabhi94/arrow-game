import 'dart:convert';

import 'package:arrow_game/data/daily.dart';
import 'package:arrow_game/providers/daily_provider.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';
import '../support/semantics.dart';

/// Opening a board from home must not spin up the real generator/timer.
final List<Override> _gameOverride = [
  gameProvider.overrideWith(
    (ref, level) => GameNotifier(
      sampleSpecFor(level),
      puzzle: samplePuzzle(),
      onCleared: level == 0
          ? (_, ms, stars) => ref.read(dailyProvider.notifier).recordCompletion(ms, stars)
          : ref.read(progressProvider.notifier).recordCompletion,
      onSnapshot: ref.read(savedGameProvider.notifier).record,
      autoTick: false,
    ),
  ),
  ...silentFeedback(),
];

final _day = DateTime(2026, 10, 22, 9);

List<Override> _fixedDay() => [
      dailyProvider.overrideWith(
        (ref) => DailyNotifier(
          ref.watch(dailyRepositoryProvider),
          levelsCleared: () => ref.read(progressProvider.notifier).levelsCleared,
          clock: () => _day,
        ),
      ),
    ];

void main() {
  testWidgets('the daily card says what today holds and opens the daily board', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(
      tester,
      const HomeScreen(),
      extraOverrides: [..._gameOverride, ..._fixedDay()],
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('DAILY BOARD'), findsOneWidget);
    expect(find.text('5 minutes, 90 arrows, Lines rules. A fresh deal every day — yours alone.'), findsOneWidget);
    expect(find.text('No streak yet · Next board in 15h 0m'), findsOneWidget);
    expect(find.text('Play today'), findsOneWidget);

    await tester.tap(find.text('Play today'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Daily board'), findsOneWidget);
    expect(find.text('Lines'), findsOneWidget);
    expect(container.read(gameProvider(0)).spec.isDaily, isTrue);
  });

  testWidgets('a cleared daily shows the best time and the streak; the card offers a replay', (tester) async {
    await usePhoneSurface(tester);
    final day = dayIndexOf(_day);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        DailyRepository.saltKey: 7,
        DailyRepository.streakKey: 3,
        DailyRepository.lastKey: day,
        DailyRepository.bestKey(day): 143000,
        DailyRepository.starsKey(day): 2,
        'arrow_level_1_done': true,
        for (var l = 1; l <= 25; l++) 'arrow_level_${l}_done': true,
      },
      extraOverrides: [..._gameOverride, ..._fixedDay()],
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Cleared today · Best today 2:23 · 3 day streak · Next board in 15h 0m'), findsOneWidget);
    expect(find.text('Play it again'), findsOneWidget);
    // 25 levels cleared: the daily is dealt with the Mirrors chapter's rules.
    expect(find.textContaining('Mirrors rules'), findsOneWidget);
  });

  testWidgets('a daily board left mid-way is offered on the daily card, not the hero', (tester) async {
    await usePhoneSurface(tester);
    final day = dayIndexOf(_day);
    // The seed the daily will be dealt with under this salt.
    final seed = dailySeed(day, 7);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        DailyRepository.saltKey: 7,
        SavedGameRepository.key: jsonEncode({
          'level': 0,
          'seed': seed,
          'removed': [0],
          'mistakes': 0,
          'hintsLeft': 3,
          'elapsedMs': 30000,
        }),
      },
      extraOverrides: [..._gameOverride, ..._fixedDay()],
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('PICK UP WHERE YOU LEFT OFF'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    // Yesterday's board, though, is nothing to come back to.
  });

  testWidgets('the trail is headed by its chapters', (tester) async {
    await usePhoneSurface(tester);
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const HomeScreen(), extraOverrides: [..._gameOverride, ..._fixedDay()]);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Chapter 1 · Lines'), findsOneWidget);
    expect(find.text('Chapter 2 · Mirrors', skipOffstage: false), findsOneWidget);
    expect(find.text('Chapter 5 · Pairs', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Levels 41–60', skipOffstage: false), findsOneWidget);
    // Only the first band is on screen; the rest are down the trail.
    final headings = semanticsNodes(tester, RegExp(r'^Chapter \d'));
    expect(headings, isNotEmpty);
    expect(headings.first.label, 'Chapter 1 · Lines. Levels 1–20. One rule: tap an arrow with a clear path and it slides out.');
    // The bands sit above their first level, in order down the trail.
    final band2 = tester.getRect(find.text('Chapter 2 · Mirrors', skipOffstage: false)).top;
    final node20 = tester.getRect(find.text('20', skipOffstage: false)).top;
    final node21 = tester.getRect(find.text('21', skipOffstage: false)).top;
    expect(band2, greaterThan(node20));
    expect(band2, lessThan(node21));
    handle.dispose();
  });
}
