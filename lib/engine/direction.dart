/// The four grid directions. Pure Dart (no Flutter).
library;

/// Ordered clockwise from [up].
enum Direction { up, right, down, left }

extension DirectionX on Direction {
  /// The direction 180° away.
  Direction get opposite => Direction.values[(index + 2) % 4];

  /// Clockwise quarter turns from [Direction.up]; rotates an "up" glyph.
  int get quarterTurns => index;

  /// Unit vector (dx, dy) in grid coordinates (y grows downwards).
  (int, int) get vector => switch (this) {
        Direction.up => (0, -1),
        Direction.right => (1, 0),
        Direction.down => (0, 1),
        Direction.left => (-1, 0),
      };

  /// Whether this direction runs along the x axis.
  bool get isHorizontal =>
      this == Direction.left || this == Direction.right;
}
