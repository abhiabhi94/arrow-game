/// A board of arrows and the rules for sliding them out. Pure Dart.
///
/// An arrow can exit when every cell on its [ArrowPiece.exitRay] is free of
/// other (still present) arrows. Because arrows leave the board entirely, the
/// "who blocks whom" relation is fixed for the life of a puzzle; a puzzle is
/// solvable exactly when that relation has no cycle.
///
/// Later chapters add four things to a board, each a small twist on that one
/// relation rather than a second rule:
///
/// * **Walls** ([walls]): solid cells. No arrow sits on one and no arrow
///   slides through one — a head is never aimed at a wall, so every ray
///   runs clear of them to the edge ([rayOf]). They shape the board (a
///   hole in the middle, pillars, bars, blocks) and the arrows go around.
/// * **Locks** ([locks]): a locked arrow also waits for its *key* arrow to
///   leave, wherever on the board that key is. One more edge in the graph.
/// * **Hidden heads** ([hidden]): the arrow is drawn without its head until
///   a neighbouring arrow leaves (see [revealedBy]) or a hint lights it. The
///   rules are untouched; what changes is what the player can see.
/// * **Pairs** ([pairs]): two tethered arrows leave together on one tap, so
///   both of their paths have to be clear, and each waits for whatever the
///   other waits for. The graph treats the pair as one node.
library;

import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';

class Puzzle {
  Puzzle({
    required this.width,
    required this.height,
    required List<ArrowPiece> arrows,
    Set<Cell> walls = const <Cell>{},
    Map<int, int> locks = const <int, int>{},
    Set<int> hidden = const <int>{},
    Map<int, int> pairs = const <int, int>{},
  })  : arrows = List<ArrowPiece>.unmodifiable(arrows),
        walls = Set<Cell>.unmodifiable(walls),
        locks = Map<int, int>.unmodifiable(locks),
        hidden = Set<int>.unmodifiable(hidden),
        pairs = Map<int, int>.unmodifiable(_symmetric(pairs)),
        assert(width > 0 && height > 0) {
    for (final c in walls) {
      assert(c.isInside(width, height), 'wall $c is off the board');
      _occupancy[c] = kWall;
    }
    for (var i = 0; i < arrows.length; i++) {
      assert(arrows[i].id == i, 'arrow ids must be their index');
      for (final c in arrows[i].cells) {
        assert(c.isInside(width, height), '$c is off the board');
        assert(!_occupancy.containsKey(c), '$c is used twice (an arrow or a wall)');
        _occupancy[c] = i;
      }
    }
    for (final a in arrows) {
      final ray = a.exitRay(width, height);
      assert(ray.every((c) => _occupancy[c] != kWall), 'arrow ${a.id} aims at a wall');
      _rays.add(List<Cell>.unmodifiable(ray));
    }
    final lockIds = this.locks.keys.toList()..sort();
    for (var n = 0; n < lockIds.length; n++) {
      final locked = lockIds[n];
      final key = this.locks[locked]!;
      assert(locked != key, 'arrow $locked is its own key');
      assert(locked >= 0 && locked < arrows.length && key >= 0 && key < arrows.length);
      _lockNumbers[locked] = n + 1;
      _lockNumbers.putIfAbsent(key, () => n + 1);
    }
    for (final e in this.pairs.entries) {
      assert(e.key != e.value, 'arrow ${e.key} is tethered to itself');
      assert(this.pairs[e.value] == e.key, 'pairs must be symmetric');
    }
    for (final h in this.hidden) {
      assert(h >= 0 && h < arrows.length);
    }
  }

  /// The occupancy mark of a wall cell.
  static const int kWall = -1;

  final int width;
  final int height;
  final List<ArrowPiece> arrows;

  /// Dead cells: never occupied, never slid through.
  final Set<Cell> walls;

  /// Locked arrow id → the key arrow it waits for.
  final Map<int, int> locks;

  /// Arrows whose head is drawn only once revealed.
  final Set<int> hidden;

  /// Tethered arrows, both ways: `pairs[a] == b` and `pairs[b] == a`.
  final Map<int, int> pairs;

  final Map<Cell, int> _occupancy = <Cell, int>{};
  final List<List<Cell>> _rays = <List<Cell>>[];
  final Map<int, int> _lockNumbers = <int, int>{};

  static Map<int, int> _symmetric(Map<int, int> pairs) {
    final out = <int, int>{};
    for (final e in pairs.entries) {
      out[e.key] = e.value;
      out[e.value] = e.key;
    }
    return out;
  }

  int get arrowCount => arrows.length;

  /// Cells an arrow may use: the board less its walls.
  int get freeCellCount => width * height - walls.length;

  /// Whether the board has any of the chapter twists on it.
  bool get hasFeatures =>
      walls.isNotEmpty || locks.isNotEmpty || hidden.isNotEmpty || pairs.isNotEmpty;

  /// The id of the arrow covering [c], or null if the cell is empty or a wall.
  int? arrowAt(Cell c) {
    final id = _occupancy[c];
    return id == null || id == kWall ? null : id;
  }

  bool isWall(Cell c) => _occupancy[c] == kWall;

  /// The cells arrow [id] slides through on its way off the board: from the
  /// cell past its head to the edge. Never a wall. Empty for a head on the
  /// edge facing out.
  List<Cell> rayOf(int id) => _rays[id];

  /// The arrow tethered to [id], or null.
  int? partnerOf(int id) => pairs[id];

  /// The key [id] waits for, or null when it is not locked.
  int? keyOf(int id) => locks[id];

  /// The number drawn on a lock and on its key so the two can be matched by
  /// eye: locks are numbered 1, 2, 3… by the locked arrow's id. Null for an
  /// arrow that is neither.
  int? lockNumber(int id) => _lockNumbers[id];

  /// The arrows [id] is the key of (usually one).
  List<int> locksOpenedBy(int id) => <int>[
        for (final e in locks.entries)
          if (e.value == id) e.key,
      ];

  /// The arrows that leave when [id] is tapped: itself and its partner.
  List<int> exitGroup(int id) {
    final partner = pairs[id];
    return partner == null ? <int>[id] : <int>[id, partner];
  }

  /// Ids of the arrows sitting on [id]'s exit ray (present or not).
  Set<int> blockersOf(int id) {
    final out = <int>{};
    for (final c in _rays[id]) {
      final other = _occupancy[c];
      if (other != null && other != id) out.add(other);
    }
    return out;
  }

  /// Everything [id] waits for before it can go: the arrows on its ray, its
  /// key, and — tethered — the same for its partner. Never [id] itself or
  /// its partner.
  Set<int> dependenciesOf(int id) {
    final out = <int>{};
    for (final member in exitGroup(id)) {
      out.addAll(blockersOf(member));
      final key = locks[member];
      if (key != null) out.add(key);
    }
    out.remove(id);
    final partner = pairs[id];
    if (partner != null) out.remove(partner);
    return out;
  }

  /// Whether [id] can slide out now, with [removed] arrows already gone.
  bool canExit(int id, Set<int> removed) =>
      dependenciesOf(id).every(removed.contains);

  /// The first ray cell still occupied by another arrow, or null if clear.
  Cell? firstBlockedCell(int id, Set<int> removed) {
    for (final c in _rays[id]) {
      final other = _occupancy[c];
      if (other != null && other != id && !removed.contains(other)) return c;
    }
    return null;
  }

  /// The key still holding [id] shut, or null when it is unlocked or the key
  /// has left.
  int? lockHolding(int id, Set<int> removed) {
    final key = locks[id];
    return key == null || removed.contains(key) ? null : key;
  }

  /// Why a tap on [id] fails right now, in the order the board explains it:
  /// its own path, then its lock, then its partner's path and lock. Null when
  /// it can go.
  TapBlock? blockOf(int id, Set<int> removed) {
    for (final member in exitGroup(id)) {
      final cell = firstBlockedCell(member, removed);
      if (cell != null) return TapBlock(arrow: member, cell: cell);
      final key = lockHolding(member, removed);
      if (key != null) return TapBlock(arrow: member, key: key);
    }
    return null;
  }

  /// Every arrow that can exit now (both halves of a pair are listed).
  List<int> removable(Set<int> removed) => <int>[
        for (final a in arrows)
          if (!removed.contains(a.id) && canExit(a.id, removed)) a.id,
      ];

  /// A greedy solving order, or null when the puzzle cannot be finished. A
  /// pair appears as its two ids back to back.
  List<int>? solvingOrder() {
    final removed = <int>{};
    final order = <int>[];
    while (removed.length < arrows.length) {
      final next = removable(removed);
      if (next.isEmpty) return null;
      // Take one at a time so the order stays a plain sequence of moves.
      for (final id in exitGroup(next.first)) {
        removed.add(id);
        order.add(id);
      }
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
      final group = exitGroup(id);
      var score = 0;
      for (final other in arrows) {
        if (group.contains(other.id) || removed.contains(other.id)) continue;
        if (dependenciesOf(other.id).any(group.contains)) score++;
      }
      if (score > bestScore) {
        best = id;
        bestScore = score;
      }
    }
    return best;
  }

  /// The arrows whose cells touch [id]'s cells orthogonally.
  Set<int> neighboursOf(int id) {
    final out = <int>{};
    for (final c in arrows[id].cells) {
      for (final d in Direction.values) {
        final other = _occupancy[c.step(d)];
        if (other != null && other != kWall && other != id) out.add(other);
      }
    }
    return out;
  }

  /// The hidden arrows a sighted player can read now: those with a
  /// neighbour among [removed]. An arrow leaving uncovers the ones beside it.
  Set<int> revealedBy(Set<int> removed) => <int>{
        for (final h in hidden)
          if (neighboursOf(h).any(removed.contains)) h,
      };

  /// How long the longest "must go before" chain is (1 for a lone arrow).
  /// Only meaningful for a solvable puzzle.
  int get dependencyDepth {
    final memo = <int, int>{};
    int depth(int id) => memo.putIfAbsent(id, () {
          var deepest = 0;
          for (final b in dependenciesOf(id)) {
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

  /// How many moves were open before each move of a greedy solve (lowest
  /// id first — the reverse of the generator's placement order). The width
  /// of the player's choice at every step: a profile of 1s is a forced
  /// sequence, big numbers mean lots of obvious taps. A pair is one move.
  List<int> openMoveProfile() {
    final deps = <List<int>>[for (final a in arrows) dependenciesOf(a.id).toList()];
    final removed = List<bool>.filled(arrows.length, false);
    final profile = <int>[];
    var left = arrows.length;
    while (left > 0) {
      var open = 0;
      var first = -1;
      for (var id = 0; id < arrows.length; id++) {
        if (removed[id]) continue;
        final partner = pairs[id];
        // The pair is counted once, on its lower id.
        if (partner != null && partner < id) continue;
        var canGo = true;
        for (final b in deps[id]) {
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
      for (final id in exitGroup(first)) {
        removed[id] = true;
        left--;
      }
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
                other != kWall &&
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
      removed.addAll(exitGroup(open.first));
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
      edges += dependenciesOf(a.id).length;
    }
    return dependencyDepth * 4 + (arrows.length - free) * 4 + edges;
  }
}

/// Why a tap failed: the [arrow] whose way was not clear — the one tapped,
/// or its tethered partner — and either the [cell] it ran into or the [key]
/// still holding its lock shut. Exactly one of the two is set.
class TapBlock {
  const TapBlock({required this.arrow, this.cell, this.key})
      : assert((cell == null) != (key == null), 'a block is a cell or a key');

  final int arrow;
  final Cell? cell;
  final int? key;

  bool get isLock => key != null;

  @override
  bool operator ==(Object other) =>
      other is TapBlock && other.arrow == arrow && other.cell == cell && other.key == key;

  @override
  int get hashCode => Object.hash(arrow, cell, key);

  @override
  String toString() => 'TapBlock(arrow $arrow, ${cell ?? 'key $key'})';
}
