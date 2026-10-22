/// Board shapes: which cells of a width×height rectangle are *walls* — solid
/// cells no arrow may sit on or slide through. Pure Dart (no Flutter).
///
/// A wall never changes the one rule of the game: an arrow leaves when the
/// cells from its head to the edge are empty. The generator simply never
/// aims a head at a wall, so every arrow on a walled board still has a
/// clear way out — the walls change where the ways out *are*, and what the
/// arrows have to wrap around. Every shape stands in the board's interior:
/// walls that reach in from the edge (a cut corner, a cross) take away
/// most of the headings near them, and the boards came out loose.
library;

import 'cell.dart';

/// The shapes a level can be dealt on. [plain] is the rectangle every level
/// before the Walls chapter uses.
enum BoardShape {
  plain,

  /// A rectangular hole in the middle — a ring.
  hole,

  /// A lattice of 2×2 pillars standing in the board.
  pillars,

  /// Short horizontal bars, staggered row by row.
  bars,

  /// Five 3×3 blocks, set like the pips on a die.
  blocks,
}

/// The wall cells of a [shape] on a [width]×[height] board. Empty for
/// [BoardShape.plain]. Every shape keeps at least three free cells between
/// a wall and the edge, so the generator always has somewhere to aim.
Set<Cell> wallsFor(BoardShape shape, int width, int height) {
  final out = <Cell>{};
  void block(int x0, int y0, int w, int h) {
    for (var y = y0; y < y0 + h; y++) {
      for (var x = x0; x < x0 + w; x++) {
        if (x >= 3 && y >= 3 && x < width - 3 && y < height - 3) out.add(Cell(x, y));
      }
    }
  }

  switch (shape) {
    case BoardShape.plain:
      break;
    case BoardShape.hole:
      // The hole takes the middle third each way, leaving a ring of at
      // least three cells.
      final hw = width ~/ 3;
      final hh = height ~/ 3;
      block((width - hw) ~/ 2, (height - hh) ~/ 2, hw, hh);
    case BoardShape.pillars:
      // 2×2 pillars on a lattice about nine cells apart, staggered row by
      // row so no column is walled off.
      const pitch = 9;
      var row = 0;
      for (var y = 3; y + 1 < height - 3; y += pitch) {
        final shift = row.isOdd ? pitch ~/ 2 : 0;
        for (var x = 3 + shift; x + 1 < width - 3; x += pitch) {
          block(x, y, 2, 2);
        }
        row++;
      }
    case BoardShape.bars:
      // Bars four cells long, one tall, every seventh row, staggered.
      const pitch = 7;
      var row = 0;
      for (var y = 4; y < height - 3; y += pitch) {
        final shift = row.isOdd ? 5 : 0;
        for (var x = 3 + shift; x + 3 < width - 3; x += 10) {
          block(x, y, 4, 1);
        }
        row++;
      }
    case BoardShape.blocks:
      // Five 3×3 blocks: the corners of the inner board and its centre.
      final size = width < 12 || height < 12 ? 2 : 3;
      final xs = <int>[width ~/ 4, width ~/ 2, width - width ~/ 4 - 1];
      final ys = <int>[height ~/ 4, height ~/ 2, height - height ~/ 4 - 1];
      for (final (i, j) in <(int, int)>[(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)]) {
        block(xs[i] - size ~/ 2, ys[j] - size ~/ 2, size, size);
      }
  }
  return out;
}
