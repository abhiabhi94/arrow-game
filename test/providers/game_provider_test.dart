import 'dart:async';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:arrow_game/services/sfx_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_haptics.dart';
import '../support/fake_sfx.dart';
import '../support/sample_puzzle.dart';

GameNotifier _notifier({
  HapticsService? haptics,
  SfxService? sfx,
  ClearedCallback? onCleared,
}) =>
    GameNotifier(
      sampleSpec,
      puzzle: samplePuzzle(),
      haptics: haptics,
      sfx: sfx,
      onCleared: onCleared,
      autoTick: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts playing at once with the puzzle and three hints', () {
    final n = _notifier();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.arrowsTotal, 3);
    expect(n.state.hintsLeft, 3);
    n.dispose();
  });

  test('without a puzzle it loads first, ignoring input until the board lands', () async {
    final completer = Completer<Puzzle>();
    final n = GameNotifier(sampleSpec, builder: (_) => completer.future, autoTick: false);
    expect(n.state.isLoading, isTrue);
    n.tapArrow(0);
    n.useHint();
    n.restart();
    n.tick(1000);
    expect(n.state.isLoading, isTrue);
    expect(n.state.elapsedMs, 0);

    completer.complete(samplePuzzle());
    await n.ready;
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.arrowsTotal, 3);
    n.dispose();
  });

  test('a board that lands after disposal is dropped', () async {
    final completer = Completer<Puzzle>();
    final n = GameNotifier(sampleSpec, builder: (_) => completer.future, autoTick: false);
    n.dispose();
    completer.complete(samplePuzzle());
    await Future<void>.delayed(Duration.zero);
    expect(n.ready, doesNotComplete);
  });

  test('a free arrow slides out; the last one clears the level', () {
    final cleared = <(int, int, int)>[];
    final engine = RecordingHapticEngine();
    final sfxBackend = RecordingSfxBackend();
    final n = _notifier(
      haptics: HapticsService(() => true, engine: engine),
      sfx: SfxService(() => true, backend: sfxBackend),
      onCleared: (l, ms, stars) => cleared.add((l, ms, stars)),
    );
    n.tick(1200);
    n.tapArrow(1);
    expect(n.state.removed, {1});
    expect(n.state.arrowsOut, 1);
    expect(n.state.lastMoveId, 1);
    expect(n.state.lastOutcome, MoveOutcome.exited);
    expect(n.state.moveToken, 1);

    n.tapArrow(1); // already gone: ignored
    expect(n.state.moveToken, 1);

    n.tapArrow(0);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.stars, 3);
    expect(n.state.isOver, isTrue);
    expect(cleared, [(1, 1200, 3)]);
    expect(engine.calls, ['light', 'light', 'medium']);
    // Every exit zups, the streak climbing.
    expect(sfxBackend.calls, hasLength(3));
    expect(sfxBackend.calls.first, '$kZipSound@1.00');
    expect(sfxBackend.calls.last, '$kZipSound@1.12');

    // Nothing moves after the end.
    n.tick(1000);
    expect(n.state.elapsedMs, 1200);
    n.dispose();
  });

  test('a blocked arrow bumps, costs a life and records the blocking cell', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(haptics: HapticsService(() => true, engine: engine));
    n.tapArrow(2);
    expect(n.state.mistakes, 1);
    expect(n.state.livesLeft, 2);
    expect(n.state.removed, isEmpty);
    expect(n.state.lastOutcome, MoveOutcome.blocked);
    expect(n.state.blockedCell, const Cell(1, 1));
    expect(n.state.phase, GamePhase.playing);
    expect(engine.calls.last, 'heavy');

    // A later exit clears the blocked marker.
    n.tapArrow(0);
    expect(n.state.blockedCell, isNull);
    n.dispose();
  });

  test('the third blocked tap ends the level out of lives', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(haptics: HapticsService(() => true, engine: engine));
    n.tapArrow(2);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.playing);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.outOfLives);
    expect(n.state.livesLeft, 0);
    expect(engine.calls.last, 'vibrate');
    n.tapArrow(0); // ignored after the end
    expect(n.state.removed, isEmpty);
    n.dispose();
  });

  test('stars reflect mistakes on a clear', () {
    final n = _notifier();
    n.tapArrow(2); // blocked
    n.tapArrow(0);
    n.tapArrow(1);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.stars, 2);
    n.dispose();
  });

  test('the clock runs out into timeUp', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(haptics: HapticsService(() => true, engine: engine));
    n.tick(29900);
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.remainingMs, 100);
    n.tick(100);
    expect(n.state.phase, GamePhase.timeUp);
    expect(n.state.remainingMs, 0);
    expect(engine.calls.last, 'vibrate');
    n.dispose();
  });

  test('hints point at the best free arrow, three per attempt', () {
    final engine = RecordingHapticEngine();
    final n = _notifier(haptics: HapticsService(() => true, engine: engine));
    n.useHint();
    expect(n.state.hintArrowId, 0); // frees arrow 2
    expect(n.state.hintsLeft, 2);
    expect(engine.calls, ['selection']);
    n.useHint(); // a hint is already showing
    expect(n.state.hintsLeft, 2);

    n.tapArrow(0); // any tap clears the hint
    expect(n.state.hintArrowId, isNull);
    n.useHint();
    expect(n.state.hintArrowId, 1);
    n.tapArrow(1);
    n.useHint();
    expect(n.state.hintsLeft, 0);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.cleared);
    n.useHint(); // no hints left / not playing
    expect(n.state.hintsLeft, 0);
    n.dispose();
  });

  test('a hint is a no-op when nothing can move', () {
    final n = _notifier();
    n.tapArrow(0);
    n.tapArrow(1);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.cleared);
    n.dispose();
  });

  test('pause freezes the clock and input; resume continues', () {
    final n = _notifier();
    n.tick(1000);
    n.pause();
    expect(n.state.phase, GamePhase.paused);
    n.tick(1000);
    n.tapArrow(0);
    n.useHint();
    expect(n.state.elapsedMs, 1000);
    expect(n.state.removed, isEmpty);
    expect(n.state.hintsLeft, 3);
    n.resume();
    expect(n.state.phase, GamePhase.playing);
    n.resume(); // no-op
    n.pause();
    n.pause(); // no-op
    n.resume();
    n.tick(500);
    expect(n.state.elapsedMs, 1500);
    n.dispose();
  });

  test('restart keeps the same puzzle and resets everything else', () {
    final n = _notifier();
    n.tick(2000);
    n.useHint();
    n.tapArrow(2);
    n.tapArrow(2);
    n.tapArrow(2);
    expect(n.state.phase, GamePhase.outOfLives);
    final puzzle = n.state.puzzle;

    n.restart();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.puzzle, same(puzzle));
    expect(n.state.mistakes, 0);
    expect(n.state.hintsLeft, 3);
    expect(n.state.elapsedMs, 0);
    expect(n.state.moveToken, 0);
    n.dispose();
  });

  test('gameProvider builds the level puzzle, wires haptics + sfx and records progress', () async {
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
    expect(notifier.spec, same(specForLevel(1)));
    expect(notifier.haptics, isNotNull);
    expect(notifier.sfx, isNotNull);
    await notifier.ready;
    expect(notifier.state.arrowsTotal, specForLevel(1).arrows);
    notifier.pause(); // stop the real timer from advancing the clock
    notifier.resume();
    for (final id in notifier.state.puzzle!.solvingOrder()!) {
      notifier.tapArrow(id);
    }
    expect(notifier.state.phase, GamePhase.cleared);
    await Future<void>.delayed(Duration.zero);
    final progress = container.read(progressProvider.notifier).progressFor(1);
    expect(progress.completed, isTrue);
    expect(progress.stars, 3);
    expect(prefs.getBool('arrow_level_1_done'), isTrue);
  });
}
