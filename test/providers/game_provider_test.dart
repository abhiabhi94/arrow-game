import 'dart:async';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:arrow_game/services/sfx_service.dart';
import 'package:fake_async/fake_async.dart';
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
  SnapshotCallback? onSnapshot,
  SavedGame? savedGame,
}) =>
    GameNotifier(
      sampleSpec,
      puzzle: samplePuzzle(),
      savedGame: savedGame,
      haptics: haptics,
      sfx: sfx,
      onCleared: onCleared,
      onSnapshot: onSnapshot,
      autoTick: false,
    );

/// A notifier on [blockedPuzzle], where arrows 1 to 4 are each blocked by
/// arrow 0 — the board for the rules about spending an allowance.
GameNotifier _blockedNotifier({
  HapticsService? haptics,
  SnapshotCallback? onSnapshot,
}) =>
    GameNotifier(
      blockedSpecFor(1),
      puzzle: blockedPuzzle(),
      haptics: haptics,
      onSnapshot: onSnapshot,
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
    // Every exit whooshes, the streak climbing, and the clear sings.
    expect(sfxBackend.calls, hasLength(4));
    expect(sfxBackend.calls.first, '$kWhooshSound@1.00');
    expect(sfxBackend.calls[2], '$kWhooshSound@1.12');
    expect(sfxBackend.calls.last, '$kWinSound@1.00');

    // Nothing moves after the end.
    n.tick(1000);
    expect(n.state.elapsedMs, 1200);
    n.dispose();
  });

  test('a blocked arrow bumps, costs a life and records the blocking cell', () {
    fakeAsync((async) {
      final engine = RecordingHapticEngine();
      final sfxBackend = RecordingSfxBackend();
      final n = _notifier(
        haptics: HapticsService(() => true, engine: engine),
        sfx: SfxService(() => true, backend: sfxBackend),
      );
      n.tapArrow(2);
      expect(n.state.mistakes, 1);
      expect(n.state.livesLeft, 2);
      expect(n.state.removed, isEmpty);
      expect(n.state.lastOutcome, MoveOutcome.blocked);
      expect(n.state.blockedCell, const Cell(1, 1));
      expect(n.state.phase, GamePhase.playing);
      // The finger gets a tick at once; the crash lands when the arrow does.
      expect(engine.calls, ['selection']);
      expect(sfxBackend.calls, isEmpty);
      async.elapse(const Duration(milliseconds: 160)); // 180 ms in for 0.4 of a cell
      expect(sfxBackend.calls, isEmpty);
      async.elapse(const Duration(milliseconds: 25));
      expect(engine.calls, ['selection', 'crash']);
      expect(sfxBackend.calls, ['$kBumpSound@1.00']);

      // A later exit clears the blocked marker.
      n.tapArrow(0);
      expect(n.state.blockedCell, isNull);
      expect(sfxBackend.calls.last, '$kWhooshSound@1.00');
      n.dispose();
    });
  });

  test('the third blocked tap ends the level out of lives', () {
    fakeAsync((async) {
      final engine = RecordingHapticEngine();
      final n = _blockedNotifier(haptics: HapticsService(() => true, engine: engine));
      n.tapArrow(1);
      n.tapArrow(2);
      expect(n.state.phase, GamePhase.playing);
      n.tapArrow(3);
      expect(n.state.phase, GamePhase.outOfLives);
      expect(n.state.livesLeft, 0);
      async.elapse(const Duration(seconds: 1));
      // Two quick taps: the first impact is superseded by the second.
      expect(engine.calls, ['selection', 'selection', 'selection', 'vibrate']);
      n.tapArrow(0); // ignored after the end
      expect(n.state.removed, isEmpty);
      n.dispose();
    });
  });

  test('a second run at the same arrow is free', () {
    final n = _blockedNotifier();
    n.tapArrow(1);
    expect(n.state.mistakes, 1);
    // The board taught this lesson already; it does not charge twice.
    n.tapArrow(1);
    n.tapArrow(1);
    expect(n.state.mistakes, 1);
    expect(n.state.livesLeft, 2);
    expect(n.state.phase, GamePhase.playing);
    // Still a bump, though: the move is recorded and the board reacts.
    expect(n.state.lastOutcome, MoveOutcome.blocked);
    expect(n.state.moveToken, 3);
    // A different arrow is a new lesson, and costs.
    n.tapArrow(2);
    expect(n.state.mistakes, 2);
    n.dispose();
  });

  test('keepGoing buys one more mistake, then asks again', () {
    final n = _blockedNotifier();
    n.tick(4000);
    n.tapArrow(1);
    n.tapArrow(2);
    n.tapArrow(3);
    expect(n.state.phase, GamePhase.outOfLives);
    expect(n.state.continues, 0);

    n.keepGoing();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.continues, 1);
    expect(n.state.elapsedMs, 4000); // the clock picks up where it stopped
    expect(n.state.livesLeft, 0);

    // A dead end already paid for stays free, and asks nothing.
    n.tapArrow(2);
    expect(n.state.mistakes, 3);
    expect(n.state.phase, GamePhase.playing);

    // A fresh one ends the attempt again, and asks again.
    n.tapArrow(4);
    expect(n.state.mistakes, 4);
    expect(n.state.phase, GamePhase.outOfLives);
    n.keepGoing();
    expect(n.state.continues, 2);
    expect(n.state.phase, GamePhase.playing);

    // The clock is still a real ending.
    n.tick(30000);
    expect(n.state.phase, GamePhase.timeUp);
    n.dispose();
  });

  test('a clear after playing on still counts as a clear', () {
    final n = _blockedNotifier();
    n.tapArrow(1);
    n.tapArrow(2);
    n.tapArrow(3);
    n.keepGoing();
    n.tapArrow(0); // the wall goes, freeing the rest
    n.tapArrow(1);
    n.tapArrow(2);
    n.tapArrow(3);
    n.tapArrow(4);
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.stars, greaterThan(0));
    n.dispose();
  });

  test('keepGoing does nothing outside the out-of-lives ending', () {
    final n = _blockedNotifier();
    n.keepGoing();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.continues, 0);
    n.dispose();
  });

  test('a restart or disposal drops a pending crash', () {
    fakeAsync((async) {
      final engine = RecordingHapticEngine();
      final n = _notifier(haptics: HapticsService(() => true, engine: engine));
      n.tapArrow(2);
      n.restart();
      async.elapse(const Duration(seconds: 1));
      expect(engine.calls, ['selection']);
      n.tapArrow(2);
      n.dispose();
      async.elapse(const Duration(seconds: 1));
      expect(engine.calls, ['selection', 'selection']);
    });
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
    final n = _blockedNotifier();
    n.tick(2000);
    n.useHint();
    n.tapArrow(1);
    n.tapArrow(2);
    n.tapArrow(3);
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

  test('snapshots after moves, hints, pauses, restarts, endings and disposal', () {
    final shots = <GameState>[];
    final n = _notifier(onSnapshot: shots.add);
    n.tick(500);
    n.tapArrow(2); // blocked
    expect(shots, hasLength(1));
    expect(shots.last.mistakes, 1);
    expect(shots.last.elapsedMs, 500);
    n.useHint();
    expect(shots, hasLength(2));
    expect(shots.last.hintsLeft, 2);
    n.pause();
    expect(shots, hasLength(3));
    expect(shots.last.phase, GamePhase.paused);
    n.resume();
    n.tapArrow(0);
    n.tapArrow(0); // already gone: nothing to record
    n.tapArrow(1);
    expect(shots, hasLength(5));
    expect(shots.last.removed, {0, 1});
    n.restart();
    expect(shots, hasLength(6));
    expect(shots.last.removed, isEmpty);
    n.tick(30000);
    expect(shots.last.phase, GamePhase.timeUp);
    n.dispose();
    expect(shots, hasLength(8));
    expect(shots.last.phase, GamePhase.timeUp);
  });

  test('a fitting saved game comes back paused with the resume offer', () {
    const saved = SavedGame(level: 1, seed: sampleSeed, removed: [1], mistakes: 1, hintsLeft: 2, elapsedMs: 7000);
    final n = _notifier(savedGame: saved);
    expect(n.state.phase, GamePhase.paused);
    expect(n.state.resumeOffered, isTrue);
    expect(n.state.removed, {1});
    expect(n.state.mistakes, 1);
    expect(n.state.hintsLeft, 2);
    expect(n.state.elapsedMs, 7000);
    n.tick(1000); // the clock waits for the answer
    expect(n.state.elapsedMs, 7000);
    n.resume();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.resumeOffered, isFalse);
    n.tick(1000);
    expect(n.state.elapsedMs, 8000);
    n.dispose();
  });

  test('"start over" from the offer is a plain restart', () {
    const saved = SavedGame(level: 1, seed: sampleSeed, removed: [1], mistakes: 0, hintsLeft: 3, elapsedMs: 7000);
    final n = _notifier(savedGame: saved);
    n.restart();
    expect(n.state.phase, GamePhase.playing);
    expect(n.state.resumeOffered, isFalse);
    expect(n.state.removed, isEmpty);
    expect(n.state.elapsedMs, 0);
    n.dispose();
  });

  test('a saved game that does not fit is ignored', () {
    const cases = <SavedGame>[
      SavedGame(level: 2, seed: 15855, removed: [1], mistakes: 0, hintsLeft: 3, elapsedMs: 10), // other level
      SavedGame(level: 1, seed: sampleSeed + 1, removed: [1], mistakes: 0, hintsLeft: 3, elapsedMs: 10), // this level, re-dealt
      SavedGame(level: 1, seed: sampleSeed, removed: [], mistakes: 0, hintsLeft: 3, elapsedMs: 10), // nothing done
      SavedGame(level: 1, seed: sampleSeed, removed: [7], mistakes: 0, hintsLeft: 3, elapsedMs: 10), // no such arrow
      SavedGame(level: 1, seed: sampleSeed, removed: [0, 1, 2], mistakes: 0, hintsLeft: 3, elapsedMs: 10), // already cleared
      SavedGame(level: 1, seed: sampleSeed, removed: [1], mistakes: 3, hintsLeft: 3, elapsedMs: 10), // out of lives
      SavedGame(level: 1, seed: sampleSeed, removed: [1], mistakes: 0, hintsLeft: 4, elapsedMs: 10), // too many hints
      SavedGame(level: 1, seed: sampleSeed, removed: [1], mistakes: 0, hintsLeft: 3, elapsedMs: 30000), // time up
    ];
    for (final saved in cases) {
      final n = _notifier(savedGame: saved);
      expect(n.state.phase, GamePhase.playing, reason: '$saved');
      expect(n.state.removed, isEmpty, reason: '$saved');
      n.dispose();
    }
  });

  test('a saved game is applied once the board lands', () async {
    const saved = SavedGame(level: 1, seed: sampleSeed, removed: [0], mistakes: 0, hintsLeft: 3, elapsedMs: 100);
    final completer = Completer<Puzzle>();
    final n = GameNotifier(
      sampleSpec,
      builder: (_) => completer.future,
      savedGame: saved,
      autoTick: false,
    );
    expect(n.state.isLoading, isTrue);
    completer.complete(samplePuzzle());
    await n.ready;
    expect(n.state.phase, GamePhase.paused);
    expect(n.state.resumeOffered, isTrue);
    expect(n.state.removed, {0});
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
