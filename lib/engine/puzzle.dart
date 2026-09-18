/// A board of arrows and the rules for sliding them out. Pure Dart.
///
/// An arrow can exit when every cell on its [ArrowPiece.exitRay] is free of
/// other (still present) arrows. Because arrows leave the board entirely, the
/// "who blocks whom" relation is fixed for the life of a puzzle; a puzzle is
/// solvable exactly when that relation has no cycle.
library;

import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';

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

  /// How many arrows were playable before each move of a greedy solve (lowest
  /// id first — the reverse of the generator's placement order). The width
  /// of the player's choice at every step: a profile of 1s is a forced
  /// sequence, big numbers mean lots of obvious taps.
  List<int> openMoveProfile() {
    final blockers = <List<int>>[for (final a in arrows) blockersOf(a.id).toList()];
    final removed = List<bool>.filled(arrows.length, false);
    final profile = <int>[];
    for (var step = 0; step < arrows.length; step++) {
      var open = 0;
      var first = -1;
      for (var id = 0; id < arrows.length; id++) {
        if (removed[id]) continue;
        var canGo = true;
        for (final b in blockers[id]) {
          if (!removed[b]) {
            canGo = false;
            break;
          }
        }
        if (!canGo) continue;
        open++;
        if (first < 0) first = id;
      }
      if (first < 0) break; // unsolvable: nothing can move
      profile.add(open);
      removed[first] = true;
    }
    return profile;
  }

  /// The average of [openMoveProfile]: how many taps were available at a
  /// typical moment. Lower is a tighter, more thoughtful puzzle.
  double get meanOpenMoves {
    final profile = openMoveProfile();
    if (profile.isEmpty) return 0;
    return profile.fold<int>(0, (s, n) => s + n) / profile.length;
  }

  /// The haystack: how many arrows the board holds for every one that can
  /// go at a typical moment — [arrowCount] over [meanOpenMoves]. This is
  /// what the hunt for the next move costs the player, and it is the number
  /// that keeps climbing on the late levels: [meanOpenMoves] on its own
  /// drifts *up* with board size in this generator (2.2 on a 228-arrow board
  /// is the tightest it deals, 2.8 on a 304-arrow one), so two open moves
  /// among three hundred arrows is a harder find than two among two hundred
  /// even though the count is the same. Zero for an unsolvable board.
  double get arrowsPerOpenMove {
    final open = meanOpenMoves;
    return open == 0 ? 0 : arrows.length / open;
  }

  /// How exposed the arrows a player can actually play are, averaged over a
  /// greedy solve: the fraction of a playable arrow's own cells that touch
  /// an arrow which cannot move yet.
  ///
  /// This is the fat-finger number. On a late board a cell is drawn at about
  /// a dozen pixels, a quarter of a fingertip, so a tap aimed at a playable
  /// arrow can easily land one cell off. Where that neighbour is a blocked
  /// arrow it costs a life; where it is empty or another playable arrow it
  /// costs nothing. Lower is kinder, and it varies a lot between boards that
  /// are otherwise equally tight, so the generator picks on it.
  double get openTapRisk {
    final removed = <int>{};
    var considered = 0;
    var risk = 0.0;
    while (removed.length < arrows.length) {
      final open = removable(removed);
      if (open.isEmpty) break;
      for (final id in open) {
        final own = arrows[id].cells.toSet();
        var exposed = 0;
        for (final c in own) {
          for (final d in Direction.values) {
            final n = c.step(d);
            if (!n.isInside(width, height) || own.contains(n)) continue;
            final other = _occupancy[n];
            if (other != null &&
                other != id &&
                !removed.contains(other) &&
                !canExit(other, removed)) {
              exposed++;
              break;
            }
          }
        }
        risk += exposed / own.length;
        considered++;
      }
      removed.add(open.first);
    }
    return considered == 0 ? 0 : risk / considered;
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
