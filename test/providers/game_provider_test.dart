import 'dart:math';

import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_haptics.dart';

const _spec = LevelSpec(level: 1, targetHits: 3, timeLimitMs: 5000);
const _fused = LevelSpec(
  level: 7,
  targetHits: 3,
  timeLimitMs: 5000,
  arrowTimeoutMs: 1000,
);

GameNotifier _notifier(
  LevelSpec spec, {
  HapticsService? haptics,
  ClearedCallback? onCleared,
}) =>
    GameNotifier(
      spec,
      haptics: haptics,
      onCleared: onCleared,
      random: Random(42),
      autoTick: false,
    );

/// The correct answer for the current arrow.
Direction _right(GameNotifier n) => n.state.arrow!.answer;

/// Any wrong answer for the current arrow.
Direction _wrong(GameNotifier n) => _right(n).opposite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts in the intro; start deals an arrow and enters play', () {
    final n = _notifier(_spec);
    expect(n.state.phase, GamePhase.ready);
    expect(n.state.arrow, isNull);
    n.answer(Direction.up); // ignored before start
    expect(n.state.hits, 0);

    n.start();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.arrow, isNotNull);
    expect(n.state.arrow!.id, 0);

    n.start(); // idempotent
    expect(n.state.arrow!.id, 0);
    n.dispose();
  });

  test('hits advance the target and streak; the last one clears the level',
      () {
    final cleared = <(int, int, int)>[];
    final engine = RecordingHapticEngine();
    final n = _notifier(
      _spec,
      haptics: HapticsService(() => true, engine: engine),
      onCleared: (l, ms, stars) => cleared.add((l, ms, stars)),
    );
    n.start();
    n.tick(1200);
    n.answer(_right(n));
    expect(n.state.hits, 1);
    expect(n.state.streak, 1);
    expect(n.state.lastOutcome, Outcome.hit);
    expect(n.state.outcomeToken, 1);
    expect(n.state.arrow!.id, 1);
    expect(n.state.arrowAgeMs, 0);

    n.answer(_right(n));
    n.answer(_right(n));
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.hits, 3);
    expect(n.state.bestStreak, 3);
    expect(n.state.stars, 3);
    expect(n.state.isOver, isTrue);
    expect(cleared, [(1, 1200, 3)]);
    expect(engine.calls, ['selection', 'light', 'light', 'medium']);

    // Nothing moves after the end.
    n.answer(_right(n));
    n.tick(1000);
    expect(n.state.hits, 3);
    expect(n.state.elapsedMs, 1200);
    n.dispose();
  });

  test('a wrong swipe costs a life, resets the streak and deals a new arrow',
      () {
    final engine = RecordingHapticEngine();
    final n = _notifier(_spec, haptics: HapticsService(() => true, engine: engine));
    n.start();
    n.answer(_right(n));
    expect(n.state.streak, 1);
    n.answer(_wrong(n));
    expect(n.state.mistakes, 1);
    expect(n.state.livesLeft, 2);
    expect(n.state.streak, 0);
    expect(n.state.bestStreak, 1);
    expect(n.state.lastOutcome, Outcome.miss);
    expect(n.state.arrow!.id, 2);
    expect(n.state.phase, GamePhase.playing);
    expect(engine.calls.last, 'heavy');
    n.dispose();
  });

  test('the third mistake ends the level out of lives', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(_spec, haptics: HapticsService(() => true, engine: engine));
    n.start();
    n.answer(_wrong(n));
    n.answer(_wrong(n));
    expect(n.state.phase, GamePhase.playing);
    n.answer(_wrong(n));
    expect(n.state.phase, GamePhase.outOfLives);
    expect(n.state.livesLeft, 0);
    expect(n.state.stars, 0);
    expect(engine.calls.last, 'vibrate');
    n.dispose();
  });

  test('stars reflect mistakes on a clear', () {
    final n = _notifier(_spec);
    n.start();
    n.answer(_wrong(n));
    n.answer(_right(n));
    n.answer(_right(n));
    n.answer(_right(n));
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.stars, 2);
    n.dispose();
  });

  test('the clock runs out into timeUp', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(_spec, haptics: HapticsService(() => true, engine: engine));
    n.start();
    n.tick(4900);
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.remainingMs, 100);
    n.tick(100);
    expect(n.state.phase, GamePhase.timeUp);
    expect(n.state.elapsedMs, 5000);
    expect(n.state.remainingMs, 0);
    expect(engine.calls.last, 'vibrate');
    n.dispose();
  });

  test('a burnt fuse counts as a mistake and deals a new arrow', () {
    final n = _notifier(_fused);
    n.start();
    n.tick(500);
    expect(n.state.fuseFraction, closeTo(0.5, 1e-9));
    n.tick(500);
    expect(n.state.mistakes, 1);
    expect(n.state.arrow!.id, 1);
    expect(n.state.arrowAgeMs, 0);
    expect(n.state.elapsedMs, 1000);
    expect(n.state.lastOutcome, Outcome.miss);
    // Three burnt fuses lose the level.
    n.tick(1000);
    n.tick(1000);
    expect(n.state.phase, GamePhase.outOfLives);
    n.dispose();
  });

  test('time up wins over a fuse that burns on the same tick', () {
    const spec = LevelSpec(level: 7, targetHits: 3, timeLimitMs: 1000, arrowTimeoutMs: 1000);
    final n = _notifier(spec);
    n.start();
    n.tick(1000);
    expect(n.state.phase, GamePhase.timeUp);
    expect(n.state.mistakes, 0);
    n.dispose();
  });

  test('pause freezes the clock and input; resume continues', () {
    final n = _notifier(_spec);
    n.pause(); // no-op before start
    expect(n.state.phase, GamePhase.ready);
    n.start();
    n.tick(1000);
    n.pause();
    expect(n.state.phase, GamePhase.paused);
    n.tick(1000);
    n.answer(_right(n));
    expect(n.state.elapsedMs, 1000);
    expect(n.state.hits, 0);
    n.resume();
    expect(n.state.phase, GamePhase.playing);
    n.resume(); // no-op
    n.tick(500);
    expect(n.state.elapsedMs, 1500);
    n.dispose();
  });

  test('restart throws the attempt away and starts fresh at once', () {
    final n = _notifier(_spec);
    n.start();
    n.tick(2000);
    n.answer(_wrong(n));
    n.answer(_wrong(n));
    n.answer(_wrong(n));
    expect(n.state.phase, GamePhase.outOfLives);

    n.restart();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.mistakes, 0);
    expect(n.state.hits, 0);
    expect(n.state.elapsedMs, 0);
    expect(n.state.arrow!.id, 0);
    expect(n.state.outcomeToken, 0);
    n.dispose();
  });

  test('gameProvider wires haptics and records progress on a clear', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    // Keep the auto-disposed family alive for the test.
    final sub = container.listen(gameProvider(1), (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(gameProvider(1).notifier);
    expect(notifier.spec.level, 1);
    expect(notifier.haptics, isNotNull);
    notifier.start();
    notifier.pause(); // stop the real timer from advancing the clock
    notifier.resume();
    for (var i = 0; i < notifier.spec.targetHits; i++) {
      notifier.answer(notifier.state.arrow!.answer);
    }
    expect(notifier.state.phase, GamePhase.cleared);
    await Future<void>.delayed(Duration.zero);
    final progress = container.read(progressProvider.notifier).progressFor(1);
    expect(progress.completed, isTrue);
    expect(progress.stars, 3);
    expect(prefs.getBool('arrow_level_1_done'), isTrue);
  });
}
