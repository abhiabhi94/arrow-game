/// Mirrors: a diagonal across a cell that turns an arrow's path by a
/// right angle. Pure Dart (no Flutter).
///
/// A mirror never changes the one rule of the game — an arrow leaves when
/// every cell of its path is empty — it changes where the path *goes*: an
/// arrow sliding into a mirror cell turns and carries on, so its way out
/// may run up a column it was never pointing along. No arrow sits on a
/// mirror, and a mirror blocks nothing; it is a bend in the road, drawn on
/// the board for everyone to see. The player reads the bounce the way
/// they read a heading, and the board is as honest as it looks: a
/// diagonal line turns an arrow, nothing more.
library;

import 'cell.dart';
import 'direction.dart';

/// The two ways a diagonal can lie in a cell.
enum Mirror {
  /// `/`: bottom-left to top-right. Right turns up, up turns right, left
  /// turns down, down turns left.
  slash,

  /// `\`: top-left to bottom-right. Right turns down, down turns right,
  /// left turns up, up turns left.
  backslash,
}

extension MirrorX on Mirror {
  /// The way an arrow travelling [d] leaves this mirror.
  Direction reflect(Direction d) => switch (this) {
        Mirror.slash => switch (d) {
            Direction.right => Direction.up,
            Direction.up => Direction.right,
            Direction.left => Direction.down,
            Direction.down => Direction.left,
          },
        Mirror.backslash => switch (d) {
            Direction.right => Direction.down,
            Direction.down => Direction.right,
            Direction.left => Direction.up,
            Direction.up => Direction.left,
          },
      };
}

/// An arrow's way off the board: the cells it slides through from the one
/// past its head to the last inside the board, turning at every mirror,
/// and the heading it leaves the edge with.
class RayTrace {
  const RayTrace(this.cells, this.exitHeading);

  final List<Cell> cells;
  final Direction exitHeading;
}

/// Follows a head at [head] pointing [heading] off a [width]×[height] board
/// through the mirrors [mirrorAt] reports, or null when the path never
/// leaves: four mirrors can send it round in a ring. Every cell entered is
/// in the trace, the mirror cells too — the arrow slides through them.
RayTrace? traceRay({
  required Cell head,
  required Direction heading,
  required int width,
  required int height,
  required Mirror? Function(Cell) mirrorAt,
}) {
  final cells = <Cell>[];
  var d = heading;
  var c = head.step(d);
  // A loop can only close at a mirror, entered the same way as before.
  final turned = <(Cell, Direction)>{};
  while (c.isInside(width, height)) {
    cells.add(c);
    final m = mirrorAt(c);
    if (m != null) {
      if (!turned.add((c, d))) return null;
      d = m.reflect(d);
    }
    c = c.step(d);
  }
  return RayTrace(cells, d);
}
