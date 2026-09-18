import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  test('snapshots a state and survives a JSON round trip', () {
    final state = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(
      removed: const {2, 0},
      mistakes: 1,
      hintsLeft: 2,
      elapsedMs: 12345,
    );
    final saved = SavedGame.fromState(state);
    expect(saved.level, 1);
    expect(saved.seed, sampleSpec.seed);
    expect(saved.removed, [0, 2]);
    expect(saved.arrowsOut, 2);
    expect(saved.mistakes, 1);
    expect(saved.hintsLeft, 2);
    expect(saved.elapsedMs, 12345);
    expect(saved.hasProgress, isTrue);
    final back = SavedGame.fromJson(saved.toJson());
    expect(back, saved);
    expect(back.hashCode, saved.hashCode);
    expect(back.toString(), 'SavedGame(level 1, 2 out, 1 slips, 12345ms)');
  });

  test('nothing done yet is not progress', () {
    final saved = SavedGame.fromState(GameState.fresh(sampleSpec, samplePuzzle()));
    expect(saved.hasProgress, isFalse);
    expect(saved.copyWithHint().hasProgress, isTrue);
  });

  test('rejects malformed JSON', () {
    expect(SavedGame.fromJson(const {}), isNull);
    expect(SavedGame.fromJson(const {'level': '1', 'removed': [], 'mistakes': 0, 'hintsLeft': 3, 'elapsedMs': 0}), isNull);
    expect(SavedGame.fromJson(const {'level': 1, 'removed': ['a'], 'mistakes': 0, 'hintsLeft': 3, 'elapsedMs': 0}), isNull);
    expect(SavedGame.fromJson(const {'level': 1, 'removed': [], 'mistakes': 0, 'hintsLeft': 3, 'elapsedMs': 0}), isNull);
    expect(SavedGame.fromJson(const {'level': 1, 'seed': 7936, 'removed': [], 'mistakes': 0, 'hintsLeft': 3, 'elapsedMs': 0}), isNotNull);
  });

  test('a snapshot without a seed is one written before a level could be re-dealt, and is not trusted', () {
    // Its arrows out may belong to a board the level no longer deals.
    final legacy = SavedGame.fromState(GameState.fresh(sampleSpec, samplePuzzle())).toJson()..remove('seed');
    expect(SavedGame.fromJson(legacy), isNull);
  });

  test('equality looks at the arrows out as a set', () {
    const a = SavedGame(level: 2, seed: 15855, removed: [1, 3], mistakes: 0, hintsLeft: 3, elapsedMs: 10);
    const b = SavedGame(level: 2, seed: 15855, removed: [3, 1], mistakes: 0, hintsLeft: 3, elapsedMs: 10);
    const c = SavedGame(level: 2, seed: 15855, removed: [3], mistakes: 0, hintsLeft: 3, elapsedMs: 10);
    expect(a, b);
    expect(a, isNot(c));
  });
}

extension on SavedGame {
  SavedGame copyWithHint() =>
      SavedGame(level: level, seed: seed, removed: removed, mistakes: mistakes, hintsLeft: hintsLeft - 1, elapsedMs: elapsedMs);
}
