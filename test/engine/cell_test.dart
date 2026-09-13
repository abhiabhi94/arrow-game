import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('step follows screen coordinates', () {
    const c = Cell(2, 2);
    expect(c.step(Direction.up), const Cell(2, 1));
    expect(c.step(Direction.right), const Cell(3, 2));
    expect(c.step(Direction.down), const Cell(2, 3));
    expect(c.step(Direction.left), const Cell(1, 2));
  });

  test('isInside, directionTo, equality and toString', () {
    expect(const Cell(0, 0).isInside(3, 3), isTrue);
    expect(const Cell(2, 2).isInside(3, 3), isTrue);
    expect(const Cell(3, 0).isInside(3, 3), isFalse);
    expect(const Cell(-1, 0).isInside(3, 3), isFalse);
    expect(const Cell(0, 3).isInside(3, 3), isFalse);
    expect(const Cell(1, 1).directionTo(const Cell(1, 0)), Direction.up);
    expect(const Cell(1, 1).directionTo(const Cell(2, 2)), isNull);
    expect(const Cell(1, 1).directionTo(const Cell(1, 1)), isNull);
    expect(const Cell(4, 5), const Cell(4, 5));
    expect(const Cell(4, 5).hashCode, const Cell(4, 5).hashCode);
    expect(const Cell(4, 5), isNot(const Cell(5, 4)));
    expect(const Cell(4, 5).toString(), '(4,5)');
  });

  test('directions: opposite, quarter turns, axis', () {
    for (final d in Direction.values) {
      expect(d.opposite.opposite, d);
    }
    expect(Direction.up.opposite, Direction.down);
    expect(Direction.left.opposite, Direction.right);
    expect(Direction.right.quarterTurns, 1);
    expect(Direction.left.isHorizontal, isTrue);
    expect(Direction.down.isHorizontal, isFalse);
  });
}
