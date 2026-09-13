import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  test('fresh state', () {
    final s = GameState.fresh(sampleSpec, samplePuzzle());
    expect(s.level, 1);
    expect(s.phase, GamePhase.playing);
    expect(s.isPlaying, isTrue);
    expect(s.isOver, isFalse);
    expect(s.livesLeft, 3);
    expect(s.hintsLeft, maxHints);
    expect(s.hintArrowId, isNull);
    expect(s.remainingMs, 30000);
    expect(s.timeFraction, 1.0);
    expect(s.arrowsOut, 0);
    expect(s.arrowsTotal, 3);
    expect(s.progress, 0);
    expect(s.stars, 0);
    expect(s.blockedCell, isNull);
    expect(s.lastOutcome, MoveOutcome.none);
  });

  test('derived values and copyWith clears', () {
    final s = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(
      removed: const {0},
      mistakes: 1,
      elapsedMs: 12000,
      hintArrowId: 2,
      blockedCell: const Cell(1, 1),
    );
    expect(s.livesLeft, 2);
    expect(s.remainingMs, 18000);
    expect(s.timeFraction, closeTo(0.6, 1e-9));
    expect(s.progress, closeTo(1 / 3, 1e-9));
    expect(s.hintArrowId, 2);
    expect(s.blockedCell, const Cell(1, 1));
    final cleared = s.copyWith(clearHint: true, clearBlocked: true);
    expect(cleared.hintArrowId, isNull);
    expect(cleared.blockedCell, isNull);
    // Passing a value alongside the clear flag still clears.
    expect(s.copyWith(clearHint: true, hintArrowId: 1).hintArrowId, isNull);
  });

  test('remaining time clamps at zero', () {
    final s = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(elapsedMs: 99999);
    expect(s.remainingMs, 0);
  });

  test('stars only count once cleared; terminal phases are over', () {
    final base = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(mistakes: 1);
    expect(base.stars, 0);
    expect(base.copyWith(phase: GamePhase.cleared).stars, 2);
    for (final p in [GamePhase.cleared, GamePhase.outOfLives, GamePhase.timeUp]) {
      expect(base.copyWith(phase: p).isOver, isTrue);
    }
    for (final p in [GamePhase.playing, GamePhase.paused]) {
      expect(base.copyWith(phase: p).isOver, isFalse);
    }
  });
}
