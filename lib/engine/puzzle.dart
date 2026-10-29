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
/// * **Mirrors** ([mirrors]): a diagonal in a cell. No arrow sits on one,
///   and an arrow sliding into one turns a right angle and carries on, so
///   its ray ([rayOf]) bends: the way out is read off the board, not off
///   the head alone. A mirror blocks nothing.
/// * **Locks** ([locks]): a locked arrow also waits for its *key* arrow to
///   leave, wherever on the board that key is. One more edge in the graph.
/// * **Hidden heads** ([hidden]): the arrow is drawn without its head until
///   a neighbouring arrow leaves (see [revealedBy]) or a hint lights it. The
///   rules are untouched; what changes is what the player can see — and a
///   tap on it while it is hidden is not charged (see [revealersOf]).
/// * **Pairs** ([pairs]): two tethered arrows leave together on one tap, so
///   both of their paths have to be clear, and each waits for whatever the
///   other waits for. The graph treats the pair as one node.
///
/// A **cube** level ([faceSizes] set, see [Puzzle.cube]) is six faces laid
/// side by side in one strip, each a rectangle of its own size — six equal
/// squares on a cube, three pairs of rectangles on a box. An arrow's way out
/// ends at its own face's edge — it leaves the block there — so the faces
/// never get in each other's way, and every rule above works face by face
/// unchanged. The player sees one face at a time and turns the block to
/// reach the others.
library;

import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';
import 'mirror.dart';

class Puzzle {
  Puzzle({
    required this.width,
    required this.height,
    required List<ArrowPiece> arrows,
    Map<Cell, Mirror> mirrors = const <Cell, Mirror>{},
    Map<int, int> locks = const <int, int>{},
    Set<int> hidden = const <int>{},
    Map<int, int> pairs = const <int, int>{},
    List<(int, int)>? faceSizes,
  })  : arrows = List<ArrowPiece>.unmodifiable(arrows),
        faceSizes = faceSizes == null ? null : List<(int, int)>.unmodifiable(faceSizes),
        mirrors = Map<Cell, Mirror>.unmodifiable(mirrors),
        locks = Map<int, int>.unmodifiable(locks),
        hidden = Set<int>.unmodifiable(hidden),
        pairs = Map<int, int>.unmodifiable(_symmetric(pairs)),
        assert(width > 0 && height > 0),
        assert(faceSizes == null ||
            (faceSizes.fold<int>(0, (w, f) => w + f.$1) == width &&
                faceSizes.fold<int>(0, (h, f) => f.$2 > h ? f.$2 : h) == height)) {
    if (faceSizes != null) {
      var x = 0;
      for (final (w, _) in faceSizes) {
        _origins.add(x);
        x += w;
      }
    }
    for (final c in mirrors.keys) {
      assert(c.isInside(width, height) && faceOfCell(c) >= 0, 'mirror $c is off the board');
      _occupancy[c] = kMirror;
    }
    for (var i = 0; i < arrows.length; i++) {
      assert(arrows[i].id == i, 'arrow ids must be their index');
      for (final c in arrows[i].cells) {
        assert(c.isInside(width, height) && faceOfCell(c) >= 0, '$c is off the board');
        assert(!_occupancy.containsKey(c), '$c is used twice (an arrow or a mirror)');
        _occupancy[c] = i;
      }
    }
    for (final a in arrows) {
      final face = faceOfCell(a.head);
      assert(a.cells.every((c) => faceOfCell(c) == face), 'arrow ${a.id} straddles two faces');
      _faces.add(face);
      final trace = traceRay(
        head: a.head,
        heading: a.heading,
        width: faceWidthOf(face),
        height: faceHeightOf(face),
        originX: faceOriginOf(face),
        mirrorAt: (c) => this.mirrors[c],
      );
      assert(trace != null, 'arrow ${a.id} is sent round in a ring');
      assert(trace!.cells.every((c) => _occupancy[c] != a.id), 'arrow ${a.id} is in its own way');
      _rays.add(List<Cell>.unmodifiable(trace!.cells));
      _exitHeadings.add(trace.exitHeading);
    }
    final lockIds = this.locks.keys.toList()..sort();
    for (var n = 0; n < lockIds.length; n++) {
      final locked = lockIds[n];
      final key = this.locks[locked]!;
      assert(locked != key, 'arrow $locked is its own key');
      assert(locked >= 0 && locked < arrows.length && key >= 0 && key < arrows.length);
      assert(_faces[locked] == _faces[key], 'lock $locked and its key are on different faces');
      _lockNumbers[locked] = n + 1;
      _lockNumbers.putIfAbsent(key, () => n + 1);
    }
    for (final e in this.pairs.entries) {
      assert(e.key != e.value, 'arrow ${e.key} is tethered to itself');
      assert(this.pairs[e.value] == e.key, 'pairs must be symmetric');
      assert(_faces[e.key] == _faces[e.value], 'pair ${e.key} straddles two faces');
    }
    for (final h in this.hidden) {
      assert(h >= 0 && h < arrows.length);
    }
  }

  /// A block built from its six (or any number of) [faces], each a board of
  /// its own of any size: laid side by side in one strip along the top, the
  /// ids and cells of each face shifted past the ones before it. The strip
  /// is as tall as the tallest face; below a shorter face is no cell at all.
  factory Puzzle.cube(List<Puzzle> faces) {
    assert(faces.isNotEmpty);
    final arrows = <ArrowPiece>[];
    final mirrors = <Cell, Mirror>{};
    final locks = <int, int>{};
    final hidden = <int>{};
    final pairs = <int, int>{};
    for (var f = 0; f < faces.length; f++) {
      final face = faces[f];
      assert(face.faceSizes == null, 'a face is a flat board');
      final dx = faces.take(f).fold<int>(0, (x, p) => x + p.width);
      final base = arrows.length;
      Cell shift(Cell c) => Cell(c.x + dx, c.y);
      for (final a in face.arrows) {
        arrows.add(ArrowPiece(id: base + a.id, cells: <Cell>[for (final c in a.cells) shift(c)], heading: a.heading));
      }
      for (final e in face.mirrors.entries) {
        mirrors[shift(e.key)] = e.value;
      }
      for (final e in face.locks.entries) {
        locks[base + e.key] = base + e.value;
      }
      for (final h in face.hidden) {
        hidden.add(base + h);
      }
      for (final e in face.pairs.entries) {
        pairs[base + e.key] = base + e.value;
      }
    }
    return Puzzle(
      width: faces.fold<int>(0, (w, p) => w + p.width),
      height: faces.fold<int>(0, (h, p) => p.height > h ? p.height : h),
      arrows: arrows,
      mirrors: mirrors,
      locks: locks,
      hidden: hidden,
      pairs: pairs,
      faceSizes: <(int, int)>[for (final p in faces) (p.width, p.height)],
    );
  }

  /// The occupancy mark of a mirror cell.
  static const int kMirror = -1;

  final int width;
  final int height;

  /// The width and height of each face of a block, in the strip's order,
  /// or null for a flat board.
  final List<(int, int)>? faceSizes;
  final List<ArrowPiece> arrows;

  /// The mirrors on the board: never occupied, slid through with a turn.
  final Map<Cell, Mirror> mirrors;

  /// Locked arrow id → the key arrow it waits for.
  final Map<int, int> locks;

  /// Arrows whose head is drawn only once revealed.
  final Set<int> hidden;

  /// Tethered arrows, both ways: `pairs[a] == b` and `pairs[b] == a`.
  final Map<int, int> pairs;

  final Map<Cell, int> _occupancy = <Cell, int>{};
  final List<List<Cell>> _rays = <List<Cell>>[];
  final List<Direction> _exitHeadings = <Direction>[];
  final Map<int, int> _lockNumbers = <int, int>{};
  final List<int> _faces = <int>[];

  /// Where each face starts in the strip.
  final List<int> _origins = <int>[];

  static Map<int, int> _symmetric(Map<int, int> pairs) {
    final out = <int, int>{};
    for (final e in pairs.entries) {
      out[e.key] = e.value;
      out[e.value] = e.key;
    }
    return out;
  }

  int get arrowCount => arrows.length;

  /// Whether this is a cube level: [faceSizes] faces, played one at a time.
  bool get isCube => faceSizes != null;

  /// How many faces the board has: six on a block, one flat.
  int get faceCount => faceSizes?.length ?? 1;

  /// The size of [face], the board the player sees at once (the whole
  /// board when flat).
  int faceWidthOf(int face) => faceSizes == null ? width : faceSizes![face].$1;
  int faceHeightOf(int face) => faceSizes == null ? height : faceSizes![face].$2;

  /// A block's width, height and depth in cells, read off its front (face
  /// 0) and its right side (face 1): the box the faces fold up into.
  (int, int, int) get blockSize =>
      (faceWidthOf(0), faceHeightOf(0), faceCount > 1 ? faceWidthOf(1) : faceWidthOf(0));

  /// The column of the strip [face] starts at.
  int faceOriginOf(int face) => faceSizes == null ? 0 : _origins[face];

  /// The face [c] lies on (0 on a flat board), or -1 for a cell of the
  /// strip that is on no face (below a shorter face, or off the strip).
  int faceOfCell(Cell c) {
    final sizes = faceSizes;
    if (sizes == null) return 0;
    if (c.x < 0 || c.y < 0) return -1;
    for (var f = 0; f < sizes.length; f++) {
      final x = c.x - _origins[f];
      if (x < sizes[f].$1) return x >= 0 && c.y < sizes[f].$2 ? f : -1;
    }
    return -1;
  }

  /// The face arrow [id] lies on (0 on a flat board).
  int faceOf(int id) => _faces[id];

  /// [c] as seen on its own face: the column counted from the face's left
  /// edge.
  Cell onFace(Cell c) => faceSizes == null ? c : Cell(c.x - _origins[faceOfCell(c)], c.y);

  /// The ids of the arrows on [face].
  List<int> arrowsOn(int face) => <int>[
        for (var id = 0; id < arrows.length; id++)
          if (_faces[id] == face) id,
      ];

  /// Cells an arrow may use: the board less its mirrors.
  int get freeCellCount =>
      (faceSizes?.fold<int>(0, (n, f) => n + f.$1 * f.$2) ?? width * height) - mirrors.length;

  /// Whether the board has any of the chapter twists on it.
  bool get hasFeatures =>
      mirrors.isNotEmpty || locks.isNotEmpty || hidden.isNotEmpty || pairs.isNotEmpty;

  /// The id of the arrow covering [c], or null if the cell is empty or a
  /// mirror.
  int? arrowAt(Cell c) {
    final id = _occupancy[c];
    return id == null || id == kMirror ? null : id;
  }

  bool isMirror(Cell c) => _occupancy[c] == kMirror;

  /// The mirror in [c], or null.
  Mirror? mirrorAt(Cell c) => mirrors[c];

  /// The cells arrow [id] slides through on its way off the board: from the
  /// cell past its head to the edge, turning at every mirror (the mirror
  /// cells are on it). Empty for a head on the edge facing out.
  List<Cell> rayOf(int id) => _rays[id];

  /// The way arrow [id] is going as it leaves the edge: its heading, unless
  /// a mirror turned it.
  Direction exitHeadingOf(int id) => _exitHeadings[id];

  /// Whether arrow [id]'s way out turns at a mirror.
  bool bends(int id) => _rays[id].any(isMirror);

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

  /// Ids of the arrows sitting on [id]'s exit ray (present or not). A
  /// mirror on it is no blocker.
  Set<int> blockersOf(int id) {
    final out = <int>{};
    for (final c in _rays[id]) {
      final other = _occupancy[c];
      if (other != null && other != kMirror && other != id) out.add(other);
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
      if (other != null && other != kMirror && other != id && !removed.contains(other)) return c;
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
  /// With [face] given, an arrow on that face is suggested when one can go —
  /// the face the player is looking at — and one elsewhere only when not.
  int? hintFor(Set<int> removed, {int? face}) {
    var open = removable(removed);
    if (face != null) {
      final here = <int>[for (final id in open) if (_faces[id] == face) id];
      if (here.isNotEmpty) open = here;
    }
    int? best;
    var bestScore = -1;
    for (final id in open) {
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
        final next = c.step(d);
        // Across a face's edge is another face of the block, not a neighbour.
        if (faceOfCell(next) != _faces[id]) continue;
        final other = _occupancy[next];
        if (other != null && other != kMirror && other != id) out.add(other);
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

  /// The arrows that can uncover [id]'s head: its neighbours that are able
  /// to leave before it — not its tethered partner, which leaves with it,
  /// and none that waits, however far down the chain, for [id] (or its
  /// partner) to go first. What the board points at after a tap on a
  /// hidden arrow. Empty only when nothing but a hint will do.
  Set<int> revealersOf(int id) {
    final group = exitGroup(id);
    return <int>{
      for (final n in neighboursOf(id))
        if (!group.contains(n) && !_waitsFor(n, group)) n,
    };
  }

  /// Whether [id] waits, directly or down the chain, for any of [targets].
  bool _waitsFor(int id, List<int> targets) {
    final seen = <int>{};
    final stack = <int>[id];
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      if (!seen.add(cur)) continue;
      for (final d in dependenciesOf(cur)) {
        if (targets.contains(d)) return true;
        stack.add(d);
      }
    }
    return false;
  }

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
            if (!n.isInside(width, height) || faceOfCell(n) != _faces[id] || own.contains(n)) continue;
            final other = _occupancy[n];
            if (other != null &&
                other != kMirror &&
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
