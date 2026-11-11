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
    final grown = dealt.grownBy([landed], blocks: {const Cell(5, 0)});
    final state = GameState.fresh(rushSpec, dealt).copyWith(puzzle: grown, drops: 1, removed: const {0});
    final saved = SavedGame.fromState(state);
    expect(saved.drops, 1);
    expect(saved.dropped, [landed.cells]);
    expect(saved.blocks, [const Cell(5, 0)]);
    final json = saved.toJson();
    expect(json['dropped'], [
      [6, 6, 7, 6],
    ]);
    expect(json['blocks'], [5, 0]);
    final back = SavedGame.fromJson(json)!;
    expect(back, saved);
    expect(back.hashCode, saved.hashCode);
    final rebuilt = back.rebuild(dealt)!;
    expect(rebuilt.arrowCount, 5);
    expect(rebuilt.arrows.last.heading, Direction.right);
    expect(rebuilt.blocks, {const Cell(5, 0)});
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
    // Bad blocks or a bad count are read as none.
    final odd = SavedGame.fromJson({...base, 'blocks': [1], 'drops': -2})!;
    expect(odd.blocks, isEmpty);
    expect(odd.drops, 0);
  });

  test('landed arrows that cannot be on the board are refused', () {
    final dealt = rushPuzzle();
    SavedGame withDropped(List<List<Cell>> dropped, {List<Cell> blocks = const []}) => SavedGame(
          level: 130,
          seed: rushSpec.seed,
          removed: const [],
          mistakes: 0,
          hintsLeft: 3,
          elapsedMs: 0,
          drops: 1,
          dropped: dropped,
          blocks: blocks,
        );
    expect(withDropped([const [Cell(7, 7), Cell(8, 7)]]).rebuild(dealt), isNull, reason: 'off the board');
    expect(withDropped([const [Cell(5, 5), Cell(7, 5)]]).rebuild(dealt), isNull, reason: 'not neighbours');
    expect(withDropped([const [Cell(5, 5), Cell(6, 5), Cell(5, 5)]]).rebuild(dealt), isNull, reason: 'a cell twice');
    expect(withDropped(const [], blocks: const [Cell(9, 9)]).rebuild(dealt), isNull, reason: 'a block off the board');
    final mirrored = Puzzle(width: 8, height: 8, arrows: const [], mirrors: {const Cell(4, 4): Mirror.slash});
    expect(withDropped(const [], blocks: const [Cell(4, 4)]).rebuild(mirrored), isNull, reason: 'a block on a mirror');
  });

  test('a growing board: ids run on, the latest arrow owns a cell, blocks take room', () {
    final dealt = rushPuzzle();
    // An arrow landing where arrow 0 used to be (it has left).
    final again = ArrowPiece(id: 4, cells: const [Cell(1, 0), Cell(2, 0)], heading: Direction.right);
    final grown = dealt.grownBy([again], blocks: {const Cell(7, 7)});
    expect(grown.grows, isTrue);
    expect(dealt.grows, isFalse);
    expect(grown.arrowAt(const Cell(1, 0)), 4);
    expect(grown.isBlock(const Cell(7, 7)), isTrue);
    expect(grown.isBlock(const Cell(6, 7)), isFalse);
    expect(grown.freeCellCount, 63);
    // Arrow 0's cells are 4's now: with 0 out, the new arrow can go.
    expect(grown.canExit(4, const {0}), isTrue);
    expect(grown.blocks, {const Cell(7, 7)});
  });
}
