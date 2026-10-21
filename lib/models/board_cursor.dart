/// Moving a keyboard cursor from arrow to arrow. Pure Dart (no Flutter).
///
/// The arrows are drawn on a canvas, so a keyboard has nothing to Tab to. The
/// game screen keeps a cursor instead — the arrow a ring is drawn around —
/// and the arrow keys move it to the nearest arrow in that direction, by the
/// arrows' heads; Enter slides the arrow under it out. Jumping arrow to
/// arrow rather than cell to cell is what makes a 57×92 board usable from a
/// keyboard at all, and the direction keys are the natural way to say "the
/// one to the left of this".
library;

import '../engine/direction.dart';
import '../engine/puzzle.dart';

/// The arrow the cursor should land on, moving [direction] from [from] among
/// the arrows of [puzzle] still on the board (not in [removed]), or null when
/// nothing lies that way.
///
/// With no [from] the cursor starts at the first arrow in reading order:
/// topmost head, then leftmost. A [from] that has left the board still
/// anchors the step — the cursor stays where the arrow was until it moves.
int? cursorStep(Puzzle puzzle, Set<int> removed, int? from, Direction direction) {
  if (from == null) return firstArrow(puzzle, removed);
  final here = puzzle.arrows[from].head;
  final (dx, dy) = direction.vector;
  int? best;
  var bestScore = double.infinity;
  for (final arrow in puzzle.arrows) {
    if (arrow.id == from || removed.contains(arrow.id)) continue;
    final ox = arrow.head.x - here.x;
    final oy = arrow.head.y - here.y;
    // How far it lies along the direction asked for, and how far off to the
    // side. Only arrows in front count; of those, the near and straight win,
    // and a dead heat goes to the one first in reading order.
    final forward = ox * dx + oy * dy;
    if (forward <= 0) continue;
    final sideways = (ox * dy - oy * dx).abs();
    final score = forward + sideways * 2.0;
    if (score < bestScore || (score == bestScore && _readsBefore(puzzle, arrow.id, best!))) {
      bestScore = score;
      best = arrow.id;
    }
  }
  return best;
}

/// Whether [a]'s head comes before [b]'s in reading order (top row first,
/// then left to right).
bool _readsBefore(Puzzle puzzle, int a, int b) {
  final ha = puzzle.arrows[a].head;
  final hb = puzzle.arrows[b].head;
  return ha.y < hb.y || (ha.y == hb.y && ha.x < hb.x);
}

/// The first arrow still on the board in reading order (topmost head, then
/// leftmost), or null when the board is empty.
int? firstArrow(Puzzle puzzle, Set<int> removed) {
  int? best;
  for (final arrow in puzzle.arrows) {
    if (removed.contains(arrow.id)) continue;
    if (best == null || _readsBefore(puzzle, arrow.id, best)) best = arrow.id;
  }
  return best;
}
