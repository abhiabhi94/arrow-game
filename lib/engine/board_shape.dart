/// Board shapes: which cells of a width×height rectangle are *walls* — dead
/// cells no arrow may sit on or slide through. Pure Dart (no Flutter).
///
/// A wall never changes the one rule of the game: an arrow leaves when the
/// cells from its head to the edge are empty. The generator simply never
/// aims a head at a wall, so every arrow on a shaped board still has a way
/// out — the walls change where the ways out *are*. A ring board's arrows all
/// face outward; a cross board's corners are gone, so a run along the middle
/// has a shorter way off the side than off the end. The point is variety the
/// player can see at a glance, not a new rule to learn: a wall looks like a
/// hole in the page, and a hole is self-explanatory.
library;

import 'cell.dart';

/// The shapes a level can be dealt on. [plain] is the rectangle every level
/// before the Shapes chapter uses.
enum BoardShape {
  plain,

  /// The four corners cut off diagonally — an octagon.
  corners,

  /// A rectangular hole in the middle — a ring.
  hole,

  /// The four corner blocks removed — a plus sign.
  cross,

  /// A lattice of 2×2 pillars standing in the board.
  pillars,
}

/// The wall cells of a [shape] on a [width]×[height] board. Empty for
/// [BoardShape.plain]. Every shape keeps a band of at least three free cells
/// along each outer edge, so the generator always has somewhere to aim.
Set<Cell> wallsFor(BoardShape shape, int width, int height) {
  final out = <Cell>{};
  switch (shape) {
    case BoardShape.plain:
      break;
    case BoardShape.corners:
      // A corner is cut when it is fewer than `cut` steps from both of its
      // two edges put together: the diagonal of an octagon.
      final cut = (width < height ? width : height) * 3 ~/ 10;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final dx = x < width - 1 - x ? x : width - 1 - x;
          final dy = y < height - 1 - y ? y : height - 1 - y;
          if (dx + dy < cut) out.add(Cell(x, y));
        }
      }
    case BoardShape.hole:
      // The hole takes the middle third each way, leaving a ring of at
      // least three cells.
      final hw = width ~/ 3;
      final hh = height ~/ 3;
      final x0 = (width - hw) ~/ 2;
      final y0 = (height - hh) ~/ 2;
      for (var y = y0; y < y0 + hh; y++) {
        for (var x = x0; x < x0 + hw; x++) {
          out.add(Cell(x, y));
        }
      }
    case BoardShape.cross:
      final cw = width ~/ 4;
      final ch = height ~/ 4;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final inX = x < cw || x >= width - cw;
          final inY = y < ch || y >= height - ch;
          if (inX && inY) out.add(Cell(x, y));
        }
      }
    case BoardShape.pillars:
      // 2×2 pillars on a lattice about nine cells apart, never within three
      // cells of an edge, staggered row by row so no column is walled off.
      const pitch = 9;
      var row = 0;
      for (var y = 3; y + 1 < height - 3; y += pitch) {
        final shift = row.isOdd ? pitch ~/ 2 : 0;
        for (var x = 3 + shift; x + 1 < width - 3; x += pitch) {
          out.addAll(<Cell>[Cell(x, y), Cell(x + 1, y), Cell(x, y + 1), Cell(x + 1, y + 1)]);
        }
        row++;
      }
  }
  return out;
}
