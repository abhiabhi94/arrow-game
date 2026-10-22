import 'package:arrow_game/engine/board_shape.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain has no walls', () {
    expect(wallsFor(BoardShape.plain, 10, 14), isEmpty);
  });

  test('every shape stays inside the board and keeps the outer band clear', () {
    for (final shape in BoardShape.values) {
      for (final (w, h) in <(int, int)>[(9, 12), (20, 30), (33, 52), (42, 64)]) {
        final walls = wallsFor(shape, w, h);
        for (final c in walls) {
          expect(c.isInside(w, h), isTrue, reason: '$shape $w x $h $c');
        }
        // Something to aim at along every edge: the first and last rows and
        // columns are never walls except at cut corners, and even then
        // the middle of every edge is open.
        expect(walls.contains(Cell(w ~/ 2, 0)), isFalse, reason: '$shape $w x $h top');
        expect(walls.contains(Cell(w ~/ 2, h - 1)), isFalse, reason: '$shape $w x $h bottom');
        expect(walls.contains(Cell(0, h ~/ 2)), isFalse, reason: '$shape $w x $h left');
        expect(walls.contains(Cell(w - 1, h ~/ 2)), isFalse, reason: '$shape $w x $h right');
        if (shape != BoardShape.plain) {
          expect(walls, isNotEmpty, reason: '$shape $w x $h');
          // A shape takes a bite, never the board.
          expect(walls.length, lessThan(w * h ~/ 3), reason: '$shape $w x $h');
        }
      }
    }
  });

  test('corners cuts the four corners, hole the middle, cross the corner blocks', () {
    final corners = wallsFor(BoardShape.corners, 20, 30);
    expect(corners.contains(const Cell(0, 0)), isTrue);
    expect(corners.contains(const Cell(19, 29)), isTrue);
    expect(corners.contains(const Cell(10, 15)), isFalse);

    final hole = wallsFor(BoardShape.hole, 20, 30);
    expect(hole.contains(const Cell(10, 15)), isTrue);
    expect(hole.contains(const Cell(0, 0)), isFalse);
    expect(hole.contains(const Cell(2, 15)), isFalse);

    final cross = wallsFor(BoardShape.cross, 20, 30);
    expect(cross.contains(const Cell(0, 0)), isTrue);
    expect(cross.contains(const Cell(19, 0)), isTrue);
    expect(cross.contains(const Cell(10, 0)), isFalse);
    expect(cross.contains(const Cell(0, 15)), isFalse);

    final pillars = wallsFor(BoardShape.pillars, 20, 30);
    // Pillars are 2x2 blocks: every wall has a wall beside it and below or above.
    for (final c in pillars) {
      final beside = pillars.contains(Cell(c.x + 1, c.y)) || pillars.contains(Cell(c.x - 1, c.y));
      final stacked = pillars.contains(Cell(c.x, c.y + 1)) || pillars.contains(Cell(c.x, c.y - 1));
      expect(beside && stacked, isTrue, reason: '$c');
    }
    expect(pillars.length % 4, 0);
  });
}
