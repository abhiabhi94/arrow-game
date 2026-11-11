import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/drops.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// The Rush, 101-150: new arrows land while the board is played, and from
// 126 blocks with them.
void main() {
  rushChecks(from: kFirstRushLevel, to: kFirstCubeLevel - 1);

  test('blocks land only in the second half of the Rush', () {
    for (var level = kFirstRushLevel; level < kFirstCubeLevel; level++) {
      final drops = specForLevel(level).drops!;
      expect(drops.blocks > 0, level >= kFirstBlocksLevel, reason: 'level $level');
    }
  });

  test('a drop plans the same on the same board, and blocks shut nobody in', () {
    final spec = specForLevel(140);
    final dealt = dealtLevel(140);
    final a = planDrop(dealt, const <int>{}, spec.drops!, dropRandom(spec, 0))!;
    final b = planDrop(dealt, const <int>{}, spec.drops!, dropRandom(spec, 0))!;
    expect([for (final x in a.arrows) x.cells], [for (final x in b.arrows) x.cells]);
    expect(a.blocks, b.blocks);
    expect(a.blocks, isNotEmpty);
    final grown = a.landOn(dealt);
    expect(grown.grows, isTrue);
    expect(grown.arrowCount, dealt.arrowCount + a.arrows.length);
    for (final x in grown.arrows) {
      expect(grown.rayOf(x.id).any(grown.isBlock), isFalse, reason: '$x');
    }
    expect(grown.isSolvable, isTrue);
  });

  test('a full board takes no drop', () {
    // Every cell taken: nowhere for the shape to land.
    final spec = specForLevel(102);
    final full = Puzzle(width: 3, height: 3, arrows: [
      for (var x = 0; x < 3; x++)
        ArrowPiece(id: x, cells: [Cell(x, 0), Cell(x, 1), Cell(x, 2)], heading: Direction.down),
    ]);
    expect(planDrop(full, const <int>{}, spec.drops!, dropRandom(spec, 0)), isNull);
    // With one column out, there is room again.
    final drop = planDrop(full, const <int>{1}, spec.drops!, dropRandom(spec, 0));
    expect(drop, isNull, reason: 'one column is narrower than every shape');
    final roomy = planDrop(full, const <int>{0, 1, 2}, spec.drops!, dropRandom(spec, 0));
    expect(roomy, isNotNull);
    expect(roomy!.arrows.first.id, 3, reason: 'ids run on from the board');
  });
}
