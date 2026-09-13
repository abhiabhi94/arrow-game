/// One sliding arrow: a path of grid cells with an arrowhead at one end.
/// Pure Dart (no Flutter).
library;

import 'cell.dart';
import 'direction.dart';

class ArrowPiece {
  ArrowPiece({required this.id, required this.cells, required this.heading})
      : assert(cells.isNotEmpty, 'an arrow needs at least one cell'),
        assert(_isPath(cells), 'cells must be a chain of orthogonal neighbours'),
        assert(
          cells.length == 1 ||
              cells[cells.length - 2].directionTo(cells.last) == heading,
          'the head must point along the last segment',
        );

  /// Stable id within a puzzle (also its index in [Puzzle.arrows]).
  final int id;

  /// The cells the arrow occupies, ordered tail → head. Consecutive cells are
  /// orthogonal neighbours; no cell repeats.
  final List<Cell> cells;

  /// Where the arrowhead points — the direction the piece slides when tapped.
  final Direction heading;

  Cell get head => cells.last;
  Cell get tail => cells.first;
  int get length => cells.length;

  bool occupies(Cell c) => cells.contains(c);

  /// The cells the head must travel through to leave a [width]×[height]
  /// board, from the cell just past the head to the last cell inside the
  /// board (empty when the head is already on the edge facing out).
  List<Cell> exitRay(int width, int height) {
    final ray = <Cell>[];
    var c = head.step(heading);
    while (c.isInside(width, height)) {
      ray.add(c);
      c = c.step(heading);
    }
    return ray;
  }

  static bool _isPath(List<Cell> cells) {
    if (cells.toSet().length != cells.length) return false;
    for (var i = 1; i < cells.length; i++) {
      if (cells[i - 1].directionTo(cells[i]) == null) return false;
    }
    return true;
  }

  @override
  String toString() => 'Arrow#$id(${cells.join('→')} ${heading.name})';
}
