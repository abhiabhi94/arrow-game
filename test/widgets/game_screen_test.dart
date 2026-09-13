import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/widgets/arrow_view.dart';
import 'package:arrow_game/widgets/level_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// A short, fused level so tests can clear/fail it in a few taps, with the
/// real timer off (the tests drive the clock through [GameNotifier.tick]).
const _spec = LevelSpec(
  level: 7,
  targetHits: 3,
  timeLimitMs: 30000,
  reverseChance: 0.5,
  arrowTimeoutMs: 2000,
);

List<Override> _overrides({LevelSpec spec = _spec}) => [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          spec,
          onCleared: ref.read(progressProvider.notifier).recordCompletion,
          random: Random(7),
          autoTick: false,
        ),
      ),
    ];

Future<ProviderContainer> _pumpGame(WidgetTester tester, {int level = 7, LevelSpec spec = _spec}) async {
  await usePhoneSurface(tester);
  final container = await pumpApp(tester, GameScreen(level: level), extraOverrides: _overrides(spec: spec));
  await _settle(tester, 300);
  return container;
}

/// Pumps a frame (mounting any new widgets) and then advances the clock by
/// [ms], so animations started on mount are flushed before the test ends.
Future<void> _settle(WidgetTester tester, int ms) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> _start(WidgetTester tester) async {
  await tester.tap(find.text('Go!'));
  await _settle(tester, 400);
}

String _padLabel(Direction d) => switch (d) {
      Direction.up => 'Up',
      Direction.right => 'Right',
      Direction.down => 'Down',
      Direction.left => 'Left',
    };

Future<void> _tapPad(WidgetTester tester, Direction d) async {
  await tester.tap(find.bySemanticsLabel(_padLabel(d)));
  await _settle(tester, 500);
}

void main() {
  testWidgets('shows the intro with rules, then plays after Go!', (tester) async {
    final container = await _pumpGame(tester);
    expect(find.byType(LevelIntro), findsOneWidget);
    expect(find.text('Short Fuse'), findsNWidgets(2)); // app bar + intro card
    expect(find.text('3 arrows'), findsOneWidget);
    expect(find.text('30s on the clock'), findsOneWidget);
    expect(find.text('Coral arrows: go the opposite way'), findsOneWidget);
    expect(find.byType(ArrowView), findsNothing);

    await _start(tester);
    final state = container.read(gameProvider(7));
    expect(state.phase, GamePhase.playing);
    expect(find.byType(LevelIntro), findsNothing);
    expect(find.byType(ArrowView), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
  });

  testWidgets('tapping the pad scores hits and clears the level with stars', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);

    for (var i = 0; i < 3; i++) {
      await _tapPad(tester, notifier.state.arrow!.answer);
    }
    expect(notifier.state.phase, GamePhase.cleared);
    await _settle(tester, 1000);
    expect(find.text('Level cleared!'), findsOneWidget);
    expect(find.text('Flawless run — three stars!'), findsOneWidget);
    expect(find.text('New best time!'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
    expect(container.read(progressProvider.notifier).progressFor(7).stars, 3);

    await tester.tap(find.text('Play again'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(find.text('Level cleared!'), findsNothing);
    await _settle(tester, 3000);
  });

  testWidgets('a swipe on the arena answers the arrow', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);
    final answer = notifier.state.arrow!.answer;
    final (vx, vy) = answer.vector;
    final arrowCenter = tester.getCenter(find.byType(ArrowView));
    await tester.dragFrom(arrowCenter, Offset(vx * 80.0, vy * 80.0));
    await _settle(tester, 500);
    expect(notifier.state.hits, 1);
    expect(find.text('1/3'), findsOneWidget);

    // A tiny wobble is not a swipe.
    await tester.dragFrom(arrowCenter, const Offset(5, 5));
    await _settle(tester, 500);
    expect(notifier.state.hits, 1);
    expect(notifier.state.mistakes, 0);
  });

  testWidgets('three wrong taps lose the lives and offer a retry', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);

    for (var i = 0; i < 3; i++) {
      await _tapPad(tester, notifier.state.arrow!.answer.opposite);
    }
    expect(notifier.state.phase, GamePhase.outOfLives);
    expect(find.text('Out of lives'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(3));

    await tester.tap(find.text('Retry'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(notifier.state.mistakes, 0);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
  });

  testWidgets('running out the clock shows time up with a retry', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);
    notifier.tick(30000);
    await _settle(tester, 400);
    expect(find.text("Time's up!"), findsOneWidget);
    expect(find.text('So close — 0 of 3. One more go?'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('pause overlay freezes play; resume and quit work', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);

    await tester.tap(find.byTooltip('Pause'));
    await _settle(tester, 400);
    expect(find.text('Paused'), findsOneWidget);
    expect(notifier.state.phase, GamePhase.paused);

    await tester.tap(find.text('Resume'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
  });

  testWidgets('backgrounding the app pauses the game', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(notifier.state.phase, GamePhase.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(notifier.state.phase, GamePhase.paused);
    await tester.tap(find.text('Quit level'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('a burnt fuse costs a life and the streak badge appears on a run', (tester) async {
    final container = await _pumpGame(tester);
    await _start(tester);
    final notifier = container.read(gameProvider(7).notifier);
    notifier.tick(2000);
    await _settle(tester, 500);
    expect(notifier.state.mistakes, 1);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('2 lives left'), findsNothing); // semantics only, not text
    expect(find.bySemanticsLabel('2 lives left'), findsOneWidget);
  });

  testWidgets('a long streak shows the badge and cheer', (tester) async {
    const long = LevelSpec(level: 1, targetHits: 20, timeLimitMs: 60000);
    final container = await _pumpGame(tester, level: 1, spec: long);
    await _start(tester);
    final notifier = container.read(gameProvider(1).notifier);
    for (var i = 0; i < 5; i++) {
      await _tapPad(tester, notifier.state.arrow!.answer);
    }
    expect(find.text('×5'), findsOneWidget);
    expect(find.text('On fire!'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await _tapPad(tester, notifier.state.arrow!.answer);
    }
    expect(find.text('Unstoppable!'), findsOneWidget);
  });

  testWidgets('the ghost arrow hides its glyph after a moment', (tester) async {
    const ghosts = LevelSpec(level: 10, targetHits: 5, timeLimitMs: 60000, ghostChance: 0.85);
    final container = await _pumpGame(tester, level: 10, spec: ghosts);
    await _start(tester);
    final notifier = container.read(gameProvider(10).notifier);
    // Deal until a ghost comes up (85% chance each; seeded so it's quick).
    while (notifier.state.arrow!.kind.name != 'ghost') {
      await _tapPad(tester, notifier.state.arrow!.answer);
    }
    expect(find.text('?'), findsNothing);
    notifier.tick(kGhostVisibleMs);
    await _settle(tester, 300);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('decoy arrows wear a misleading word', (tester) async {
    const decoys = LevelSpec(level: 13, targetHits: 5, timeLimitMs: 60000, decoyChance: 0.85);
    final container = await _pumpGame(tester, level: 13, spec: decoys);
    await _start(tester);
    final notifier = container.read(gameProvider(13).notifier);
    while (notifier.state.arrow!.decoyLabel == null) {
      await _tapPad(tester, notifier.state.arrow!.answer);
    }
    final label = _padLabel(notifier.state.arrow!.decoyLabel!).toUpperCase();
    expect(find.text(label), findsOneWidget);
  });

  testWidgets('the last level has no Next button and a finale message', (tester) async {
    const quick = LevelSpec(level: totalLevels, targetHits: 1, timeLimitMs: 30000);
    final container = await _pumpGame(tester, level: totalLevels, spec: quick);
    await _start(tester);
    final notifier = container.read(gameProvider(totalLevels).notifier);
    await _tapPad(tester, notifier.state.arrow!.answer);
    await _settle(tester, 1000);
    expect(find.text('Next level'), findsNothing);
    expect(find.text('You beat every level. Legend!'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('Next level replaces the screen with the following level', (tester) async {
    const quick = LevelSpec(level: 2, targetHits: 1, timeLimitMs: 30000);
    final container = await _pumpGame(tester, level: 2, spec: quick);
    await _start(tester);
    final notifier = container.read(gameProvider(2).notifier);
    await _tapPad(tester, notifier.state.arrow!.answer);
    await _settle(tester, 1000);
    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(find.text('Level 3'), findsOneWidget);
    // Only the app bar: the intro card names the (overridden) spec.
    expect(find.text('Quick Hands'), findsOneWidget);
  });

  testWidgets('dark theme renders the game', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const GameScreen(level: 20), extraOverrides: _overrides(), themeMode: ThemeMode.dark);
    await _settle(tester, 300);
    expect(find.text('Level 20'), findsOneWidget);
    expect(find.text('Grand Finale'), findsOneWidget); // app bar (intro shows the overridden spec's name)
  });
}
