import 'package:arrow_game/engine/drops.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

/// Taps every arrow that can go, in id order, letting each drop that glows
/// land, until the level ends.
void _clearAll(GameNotifier n) {
  for (var guard = 0; guard < 100 && n.state.isPlaying; guard++) {
    final p = n.state.puzzle!;
    final free = p.removable(n.state.removed);
    if (free.isNotEmpty) {
      n.tapArrow(free.first);
    } else {
      n.tick(kDropWarnMs);
    }
  }
}

/// Plays on until the next drop has glowed and landed.
void _landNext(GameNotifier n) {
  final before = n.state.drops;
  for (var guard = 0; guard < 100 && n.state.drops == before; guard++) {
    n.tick(100);
  }
}

void main() {
  test('a drop lands when its time comes, growing the board', () {
    final snaps = <GameState>[];
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false, onSnapshot: snaps.add);
    final dealt = n.state.puzzle!;
    expect(n.state.dropsLeft, 2);
    n.tick(900);
    expect(n.state.drops, 0);
    expect(n.state.incoming, isEmpty);
    // Due: the cells it will land on glow first.
    n.tick(100);
    expect(n.state.drops, 0);
    expect(n.state.incoming, isNotEmpty);
    final glowing = n.state.incoming;
    n.tick(kDropWarnMs - 100);
    expect(n.state.drops, 0);
    // Then it lands, exactly where it glowed.
    n.tick(100);
    expect(n.state.drops, 1);
    expect(n.state.incoming, isEmpty);
    expect(n.state.dropsLeft, 1);
    final grown = n.state.puzzle!;
    expect(
      <Object>{for (final a in grown.arrows.skip(4)) ...a.cells, ...grown.blocks},
      glowing,
    );
    expect(grown.arrowCount, greaterThan(dealt.arrowCount));
    expect(grown.arrowCount, lessThanOrEqualTo(dealt.arrowCount + 2));
    expect(grown.blocks.length, lessThanOrEqualTo(1));
    expect(n.state.dealtArrows, dealt.arrowCount);
    expect(snaps.last.drops, 1);
    // The same drop the engine plans for this board.
    final planned = planDrop(dealt, const <int>{}, rushSpec.drops!, dropRandom(rushSpec, 0))!;
    expect([for (final a in grown.arrows.skip(4)) a.cells], [for (final a in planned.arrows) a.cells]);
    n.dispose();
  });

  test('the board running low brings the next drop at once, and the level clears only after the last', () {
    var cleared = 0;
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false, onCleared: (_, _, _) => cleared++);
    // Down to three arrows: the first drop is on its way at once, glowing,
    // and lands once the glow is over.
    n.tapArrow(0);
    expect(n.state.incoming, isNotEmpty);
    expect(n.state.drops, 0);
    n.tick(kDropWarnMs);
    expect(n.state.drops, 1);
    _clearAll(n);
    // Every arrow out and every drop landed: cleared, once.
    expect(n.state.drops, 2);
    expect(n.state.phase, GamePhase.cleared);
    expect(n.state.removed.length, n.state.puzzle!.arrowCount);
    expect(cleared, 1);
    n.dispose();
  });

  test('a restart puts the dealt board back, and the drops start again', () {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    _landNext(n);
    expect(n.state.drops, 1);
    n.restart();
    expect(n.state.drops, 0);
    expect(n.state.puzzle!.arrowCount, 4);
    expect(n.state.puzzle!.blocks, isEmpty);
    // Its own second again, not what was left of the last one's.
    n.tick(500);
    expect(n.state.incoming, isEmpty);
    n.tick(500);
    expect(n.state.incoming, isNotEmpty);
    // A restart in the middle of the glow takes the drop with it.
    n.restart();
    expect(n.state.incoming, isEmpty);
    n.tick(kDropWarnMs);
    expect(n.state.drops, 0);
    n.dispose();
  });

  test('with no time limit the drops still come, and no time is counted', () {
    final n = GameNotifier(rushSpec.untimed(), puzzle: rushPuzzle(), autoTick: false);
    _landNext(n);
    expect(n.state.drops, 1);
    expect(n.state.elapsedMs, 0);
    n.dispose();
  });

  test('nothing lands while paused', () {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false)..pause();
    n.tick(5000);
    expect(n.state.drops, 0);
    expect(n.state.incoming, isEmpty);
    // Nor while paused in the middle of its glow.
    n.resume();
    n.tick(1000);
    expect(n.state.incoming, isNotEmpty);
    n.pause();
    n.tick(5000);
    expect(n.state.drops, 0);
    n.dispose();
  });

  test('a drop with no room waits for the player to make some', () {
    // Every cell of a 3×3 taken, and four arrows on it so the board is not
    // running low: the drop is due but has nowhere to go.
    final full = fullPuzzle();
    const spec = LevelSpec(
      level: 140,
      width: 3,
      height: 3,
      arrows: 4,
      minLength: 2,
      maxLength: 3,
      timeLimitMs: 60000,
      drops: LevelDrops(count: 1, everyMs: 1000, arrows: 2, maxLength: 2),
    );
    final n = GameNotifier(spec, puzzle: full, autoTick: false);
    n.tick(3000);
    expect(n.state.drops, 0);
    n.dispose();
  });

  test('a saved Rush game comes back with what had landed on it', () {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    _landNext(n);
    n.tapArrow(1);
    final saved = SavedGame.fromJson(SavedGame.fromState(n.state).toJson())!;
    expect(saved.drops, 1);
    expect(saved.dropped, isNotEmpty);
    final before = n.state.puzzle!;
    n.dispose();
    final back = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false, savedGame: saved);
    expect(back.state.phase, GamePhase.paused);
    expect(back.state.resumeOffered, isTrue);
    expect(back.state.drops, 1);
    expect(back.state.dealtArrows, 4);
    expect(back.state.removed, {1});
    final p = back.state.puzzle!;
    expect(p.arrowCount, before.arrowCount);
    expect(p.blocks, before.blocks);
    expect([for (final a in p.arrows) a.cells], [for (final a in before.arrows) a.cells]);
    // And the next drop is still to come.
    back.resume();
    _landNext(back);
    expect(back.state.drops, 2);
    back.dispose();
  });

  test('a saved Rush game whose drops cannot be on the board is not resumed', () {
    final saved = SavedGame(
      level: rushSpec.level,
      seed: rushSpec.seed,
      removed: const [0],
      mistakes: 0,
      hintsLeft: 3,
      elapsedMs: 100,
      drops: 1,
      dropped: const [],
      blocks: const [],
    );
    // More drops than the level has.
    final tooMany = SavedGame(
      level: rushSpec.level,
      seed: rushSpec.seed,
      removed: const [0],
      mistakes: 0,
      hintsLeft: 3,
      elapsedMs: 100,
      drops: 5,
    );
    final ok = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false, savedGame: saved);
    expect(ok.state.resumeOffered, isTrue);
    ok.dispose();
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false, savedGame: tooMany);
    expect(n.state.resumeOffered, isFalse);
    expect(n.state.removed, isEmpty);
    n.dispose();
  });

  test('a grown board is the old one grown, not a new one', () {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    final before = n.state;
    _landNext(n);
    expect(n.state.grewFrom(before), isTrue);
    expect(before.grewFrom(n.state), isFalse);
    final grown = n.state;
    n.restart();
    expect(n.state.grewFrom(grown), isFalse);
    n.dispose();
  });
}
