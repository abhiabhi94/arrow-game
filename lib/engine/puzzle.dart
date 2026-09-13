/// A board of arrows and the rules for sliding them out. Pure Dart.
///
/// An arrow can exit when every cell on its [ArrowPiece.exitRay] is free of
/// other (still present) arrows. Because arrows leave the board entirely, the
/// "who blocks whom" relation is fixed for the life of a puzzle; a puzzle is
/// solvable exactly when that relation has no cycle.
library;

import 'arrow_piece.dart';
import 'cell.dart';

class Puzzle {
  Puzzle({required this.width, required this.height, required List<ArrowPiece> arrows})
      : arrows = List<ArrowPiece>.unmodifiable(arrows),
        assert(width > 0 && height > 0) {
    for (var i = 0; i < arrows.length; i++) {
      assert(arrows[i].id == i, 'arrow ids must be their index');
      for (final c in arrows[i].cells) {
        assert(c.isInside(width, height), '$c is off the board');
        assert(!_occupancy.containsKey(c), '$c is used by two arrows');
        _occupancy[c] = i;
      }
    }
  }

  final int width;
  final int height;
  final List<ArrowPiece> arrows;
  final Map<Cell, int> _occupancy = <Cell, int>{};

  int get arrowCount => arrows.length;

  /// The id of the arrow covering [c], or null if the cell is empty.
  int? arrowAt(Cell c) => _occupancy[c];

  /// Ids of the arrows sitting on [id]'s exit ray (present or not).
  Set<int> blockersOf(int id) {
    final out = <int>{};
    for (final c in arrows[id].exitRay(width, height)) {
      final other = _occupancy[c];
      if (other != null && other != id) out.add(other);
    }
    return out;
  }

  /// Whether [id] can slide out now, with [removed] arrows already gone.
  bool canExit(int id, Set<int> removed) =>
      blockersOf(id).every(removed.contains);

  /// The first ray cell still occupied by another arrow, or null if clear.
  Cell? firstBlockedCell(int id, Set<int> removed) {
    for (final c in arrows[id].exitRay(width, height)) {
      final other = _occupancy[c];
      if (other != null && other != id && !removed.contains(other)) return c;
    }
    return null;
  }

  /// Every arrow that can exit now.
  List<int> removable(Set<int> removed) => <int>[
        for (final a in arrows)
          if (!removed.contains(a.id) && canExit(a.id, removed)) a.id,
      ];

  /// A greedy solving order, or null when the puzzle cannot be finished.
  List<int>? solvingOrder() {
    final removed = <int>{};
    final order = <int>[];
    while (removed.length < arrows.length) {
      final next = removable(removed);
      if (next.isEmpty) return null;
      // Take one at a time so the order stays a plain sequence of moves.
      removed.add(next.first);
      order.add(next.first);
    }
    return order;
  }

  bool get isSolvable => solvingOrder() != null;

  /// The best arrow to suggest: a removable one that frees the most other
  /// arrows (ties → lowest id). Null once nothing can move or all are gone.
  int? hintFor(Set<int> removed) {
    int? best;
    var bestScore = -1;
    for (final id in removable(removed)) {
      var score = 0;
      for (final other in arrows) {
        if (other.id == id || removed.contains(other.id)) continue;
        if (blockersOf(other.id).contains(id)) score++;
      }
      if (score > bestScore) {
        best = id;
        bestScore = score;
      }
    }
    return best;
  }

  /// How long the longest "must go before" chain is (1 for a lone arrow).
  /// Only meaningful for a solvable puzzle.
  int get dependencyDepth {
    final memo = <int, int>{};
    int depth(int id) => memo.putIfAbsent(id, () {
          var deepest = 0;
          for (final b in blockersOf(id)) {
            final d = depth(b);
            if (d > deepest) deepest = d;
          }
          return deepest + 1;
        });
    var max = 0;
    for (final a in arrows) {
      final d = depth(a.id);
      if (d > max) max = d;
    }
    return max;
  }

  /// A rough "how tangled is this" number used to pick the most interesting
  /// of several generated candidates: deep chains and few free starting moves
  /// score high.
  int get difficultyScore {
    final free = removable(const <int>{}).length;
    var edges = 0;
    for (final a in arrows) {
      edges += blockersOf(a.id).length;
    }
    return dependencyDepth * 4 + (arrows.length - free) * 4 + edges;
  }
}
