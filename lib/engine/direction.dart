/// The four swipe directions. Pure Dart (no Flutter).
library;

/// Ordered clockwise from [up] so [DirectionX.quarterTurns] is just the index.
enum Direction { up, right, down, left }

extension DirectionX on Direction {
  /// The direction 180° away — what a reverse arrow asks for.
  Direction get opposite => Direction.values[(index + 2) % 4];

  /// Clockwise quarter turns from [Direction.up]; rotates an "up" glyph.
  int get quarterTurns => index;

  /// Unit vector (dx, dy) with screen coordinates (y grows downwards).
  (int, int) get vector => switch (this) {
        Direction.up => (0, -1),
        Direction.right => (1, 0),
        Direction.down => (0, 1),
        Direction.left => (-1, 0),
      };
}

/// Resolves a swipe delta to a [Direction], or null when the movement is
/// shorter than [minDistance] (an accidental tap or a jitter). Ties go to the
/// horizontal axis, but a tie is a measure-zero event in practice.
Direction? directionFromSwipe(double dx, double dy, {double minDistance = 24}) {
  final ax = dx.abs();
  final ay = dy.abs();
  if (ax < minDistance && ay < minDistance) return null;
  if (ax >= ay) return dx > 0 ? Direction.right : Direction.left;
  return dy > 0 ? Direction.down : Direction.up;
}
