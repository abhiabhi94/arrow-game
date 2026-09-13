/// A grid coordinate. Pure Dart (no Flutter).
library;

import 'direction.dart';

class Cell {
  const Cell(this.x, this.y);

  final int x;
  final int y;

  /// The neighbouring cell one step in [d].
  Cell step(Direction d) {
    final (dx, dy) = d.vector;
    return Cell(x + dx, y + dy);
  }

  /// Whether this cell lies inside a [width]×[height] board.
  bool isInside(int width, int height) =>
      x >= 0 && y >= 0 && x < width && y < height;

  /// The direction from this cell to an adjacent [other], or null when the two
  /// are not orthogonal neighbours.
  Direction? directionTo(Cell other) {
    for (final d in Direction.values) {
      if (step(d) == other) return d;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is Cell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x,$y)';
}
