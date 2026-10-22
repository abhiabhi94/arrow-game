import 'package:arrow_game/engine/board_shape.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain has no walls', () {
    expect(wallsFor(BoardShape.plain, 10, 14), isEmpty);
  });

  test('every shape stands in the interior with a clear band along every edge', () {
    for (final shape in BoardShape.values) {
      for (final (w, h) in <(int, int)>[(10, 13), (12, 16), (20, 30), (33, 52), (42, 64)]) {
        final walls = wallsFor(shape, w, h);
        for (final c in walls) {
          expect(c.isInside(w, h), isTrue, reason: '$shape $w x $h $c');
          expect(c.x, inInclusiveRange(3, w - 4), reason: '$shape $w x $h $c');
          expect(c.y, inInclusiveRange(3, h - 4), reason: '$shape $w x $h $c');
        }
        if (shape != BoardShape.plain) {
          expect(walls, isNotEmpty, reason: '$shape $w x $h');
          // A shape takes a bite, never the board.
          expect(walls.length, lessThan(w * h ~/ 3), reason: '$shape $w x $h');
        }
      }
    }
  });

  test('hole is the middle, pillars and bars are small and spread out, blocks are five', () {
    final hole = wallsFor(BoardShape.hole, 20, 30);
    expect(hole.contains(const Cell(10, 15)), isTrue);
    expect(hole.contains(const Cell(2, 15)), isFalse);

    final pillars = wallsFor(BoardShape.pillars, 20, 30);
    // Pillars are 2x2 blocks: every wall has a wall beside it and below or above.
    for (final c in pillars) {
      final beside = pillars.contains(Cell(c.x + 1, c.y)) || pillars.contains(Cell(c.x - 1, c.y));
      final stacked = pillars.contains(Cell(c.x, c.y + 1)) || pillars.contains(Cell(c.x, c.y - 1));
      expect(beside && stacked, isTrue, reason: '$c');
    }
    expect(pillars.length % 4, 0);

    final bars = wallsFor(BoardShape.bars, 30, 40);
    // A bar is one cell tall: nothing above or below it is a wall.
    for (final c in bars) {
      expect(bars.contains(Cell(c.x, c.y + 1)), isFalse, reason: '$c');
    }
    expect(bars.length % 4, 0);

    final blocks = wallsFor(BoardShape.blocks, 40, 60);
    expect(blocks, hasLength(5 * 9));
    expect(blocks.contains(const Cell(20, 30)), isTrue);
    // On a small board the blocks shrink to 2x2, and the ones that would
    // reach the edge band are clipped to it.
    expect(wallsFor(BoardShape.blocks, 10, 13).length, inInclusiveRange(4, 5 * 4));
  });
}
