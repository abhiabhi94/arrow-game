import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/mirror.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  final landed = ArrowPiece(id: 4, cells: const [Cell(6, 6), Cell(7, 6)], heading: Direction.right);

  test('what landed on a Rush board survives a JSON round trip', () {
    final dealt = rushPuzzle();
    final grown = dealt.grownBy([landed], mirrors: {const Cell(5, 1): Mirror.backslash});
    final state = GameState.fresh(rushSpec, dealt).copyWith(puzzle: grown, drops: 1, removed: const {0});
    final saved = SavedGame.fromState(state);
    expect(saved.drops, 1);
    expect(saved.dropped, [landed.cells]);
    expect(saved.mirrors, {const Cell(5, 1): Mirror.backslash});
    final json = saved.toJson();
    expect(json['dropped'], [
      [6, 6, 7, 6],
    ]);
    expect(json['mirrors'], [5, 1, Mirror.backslash.index]);
    final back = SavedGame.fromJson(json)!;
    expect(back, saved);
    expect(back.hashCode, saved.hashCode);
    final rebuilt = back.rebuild(dealt)!;
    expect(rebuilt.arrowCount, 5);
    expect(rebuilt.arrows.last.heading, Direction.right);
    expect(rebuilt.mirrors, {const Cell(5, 1): Mirror.backslash});
    // A board nothing landed on is the dealt board itself.
    expect(SavedGame.fromState(GameState.fresh(rushSpec, dealt)).rebuild(dealt), same(dealt));
    // An ordinary snapshot writes none of it.
    expect(SavedGame.fromState(GameState.fresh(sampleSpec, samplePuzzle())).toJson().containsKey('dropped'), isFalse);
  });

  test('a snapshot whose landed arrows are garbled is not read', () {
    final base = <String, Object?>{
      'level': 130,
      'seed': rushSpec.seed,
      'removed': <int>[],
      'mistakes': 0,
      'hintsLeft': 3,
      'elapsedMs': 0,
    };
    expect(SavedGame.fromJson({...base, 'dropped': [[1, 2, 3]]}), isNull);
    expect(SavedGame.fromJson({...base, 'dropped': [[1, 2]]}), isNull, reason: 'one cell is no arrow');
    expect(SavedGame.fromJson({...base, 'dropped': ['x']}), isNull);
    // Garbled mirrors or a bad count are read as none; a mirror of no kind
    // is not read at all.
    final odd = SavedGame.fromJson({...base, 'mirrors': [1], 'drops': -2})!;
    expect(odd.mirrors, isEmpty);
    expect(SavedGame.fromJson({...base, 'mirrors': [1, 1, 9]}), isNull);
    expect(odd.drops, 0);
  });

  test('landed arrows that cannot be on the board are refused', () {
    final dealt = rushPuzzle();
    SavedGame withDropped(List<List<Cell>> dropped, {Map<Cell, Mirror> mirrors = const {}}) => SavedGame(
          level: 130,
          seed: rushSpec.seed,
          removed: const [],
          mistakes: 0,
          hintsLeft: 3,
          elapsedMs: 0,
          drops: 1,
          dropped: dropped,
          mirrors: mirrors,
        );
    expect(withDropped([const [Cell(7, 7), Cell(8, 7)]]).rebuild(dealt), isNull, reason: 'off the board');
    expect(withDropped([const [Cell(5, 5), Cell(7, 5)]]).rebuild(dealt), isNull, reason: 'not neighbours');
    expect(withDropped([const [Cell(5, 5), Cell(6, 5), Cell(5, 5)]]).rebuild(dealt), isNull, reason: 'a cell twice');
    expect(withDropped(const [], mirrors: {const Cell(9, 9): Mirror.slash}).rebuild(dealt), isNull, reason: 'a mirror off the board');
    final mirrored = Puzzle(width: 8, height: 8, arrows: const [], mirrors: {const Cell(4, 4): Mirror.slash});
    expect(withDropped(const [], mirrors: {const Cell(4, 4): Mirror.slash}).rebuild(mirrored), isNull, reason: 'on a mirror');
    expect(withDropped(const [], mirrors: {const Cell(1, 0): Mirror.slash}).rebuild(dealt), isNull, reason: 'where an arrow sits');
  });

  test('a growing board: ids run on, the latest arrow owns a cell, a mirror turns ways out', () {
    final dealt = rushPuzzle();
    // An arrow landing where arrow 0 used to be (it has left).
    final again = ArrowPiece(id: 4, cells: const [Cell(1, 0), Cell(2, 0)], heading: Direction.right);
    final grown = dealt.grownBy([again], mirrors: {const Cell(4, 2): Mirror.slash});
    expect(grown.grows, isTrue);
    expect(dealt.grows, isFalse);
    expect(grown.arrowAt(const Cell(1, 0)), 4);
    expect(grown.isMirror(const Cell(4, 2)), isTrue);
    expect(grown.freeCellCount, 63);
    // Arrow 0's cells are 4's now: with 0 out, the new arrow can go.
    expect(grown.canExit(4, const {0}), isTrue);
    // Mirrors landing in front of an arrow that has left can send its old
    // way out back through its own cells: nothing to anyone, and a growing
    // board allows it (a dealt one would not).
    final back = Puzzle(
      width: 5,
      height: 5,
      arrows: [ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1)], heading: Direction.right)],
    ).grownBy(const [], mirrors: {
      const Cell(3, 1): Mirror.backslash,
      const Cell(3, 3): Mirror.slash,
      const Cell(1, 3): Mirror.backslash,
    });
    expect(back.rayOf(0), contains(const Cell(1, 1)));
  });
}
