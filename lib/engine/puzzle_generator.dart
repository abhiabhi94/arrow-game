/// Procedural puzzles that are solvable by construction. Pure Dart.
///
/// Arrows are placed one by one onto an empty board, roughly inside-out. A
/// new arrow may point at free cells (it can leave as soon as everything
/// placed after it across its path is gone) *or straight at an arrow already
/// there* (it waits for that one). The one rule is that the "waits for"
/// graph stays a DAG: a placement is accepted only when nothing the new
/// arrow waits for is itself, however indirectly, waiting for an arrow that
/// will now wait for the newcomer. A DAG is solvable, so every board is.
/// A final pass grows tails into leftover gaps under the same rule. Several
/// candidate boards are generated; the fullest, then tightest, wins.
///
/// Tightness: an arrow that waits for nobody is "open" — a tap available the
/// moment everything across its path is gone. The count of open arrows while
/// building is the width of the player's choice at the matching moment of
/// the game. Whenever it exceeds the level's `openMoves`, new arrows are
/// pushed to lie across open rays, closing them, so the board never offers
/// more than a few taps at once.
///
/// Hot loops run on flat typed-data grids rather than hashed cell sets: the
/// big late boards enumerate every cell for every placement.
library;

import 'dart:math';
import 'dart:typed_data';

import '../models/level_spec.dart';
import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';
import 'puzzle.dart';

/// Candidate boards generated per puzzle, scaled down for big boards so a
/// level still opens quickly: 24 for a handful of arrows, down to
/// [kMinCandidates].
int candidatesFor(int arrows) => (600 ~/ arrows).clamp(kMinCandidates, 24);
const int kMinCandidates = 5;

/// Valid head placements grown per arrow; the best-scoring body wins.
const int kPlacementChoices = 14;

/// Open-ray starting cells tried per arrow while closing.
const int kClosingChoices = 24;

/// Score bonus for a body step that keeps going straight. Real boards are
/// mostly long runs with the occasional bend, which also packs more in.
const double kStraightBias = 4.0;

/// Placement score per open arrow a body closes while the board has more
/// open arrows than the level wants, and the (small) bonus otherwise.
const int kCloseBonus = 16;
const int kCloseBonusRelaxed = 3;

/// Body-growth pull towards a cell on an open ray while closing is wanted.
const double kCloseStepBias = 6.0;

/// How far past the level's nominal maximum a tail may grow while soaking
/// up gaps in the final pass.
const int kGapTailSlack = 8;

class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds a puzzle for [spec]. Always solvable. Tries several boards and
  /// keeps the one with the most arrows (the spec's count when the board has
  /// room — the level table is tested for that). Ties go to a board that
  /// holds the level's choice within [startSlack] and [widestSlack] of
  /// `openMoves` at the start and at its widest, then to the fewest moves
  /// open at a typical moment, then to tangle.
  Puzzle generate(LevelSpec spec) {
    Puzzle? best;
    var bestHeld = false;
    var bestOpen = double.infinity;
    var bestTangle = 0;
    final candidates = candidatesFor(spec.arrows);
    for (var i = 0; i < candidates; i++) {
      final p = _Builder(spec, _random).build();
      final profile = p.openMoveProfile();
      final held = holdsChoice(spec, profile);
      final open = profile.isEmpty ? 0.0 : profile.fold<int>(0, (s, n) => s + n) / profile.length;
      final tangle = p.difficultyScore;
      if (best == null ||
          p.arrowCount > best.arrowCount ||
          (p.arrowCount == best.arrowCount &&
              (held && !bestHeld ||
                  (held == bestHeld &&
                      (open < bestOpen || (open == bestOpen && tangle > bestTangle)))))) {
        best = p;
        bestHeld = held;
        bestOpen = open;
        bestTangle = tangle;
      }
    }
    return best!;
  }

  /// Whether an [openMoveProfile] keeps the player's choice within the slack
  /// the levels are allowed over `openMoves`: at the first move and at the
  /// widest moment. The cap is soft while building; this is the hard line.
  static bool holdsChoice(LevelSpec spec, List<int> profile) {
    if (profile.isEmpty) return true;
    return profile.first <= spec.openMoves + startSlack &&
        profile.reduce(max) <= spec.openMoves + widestSlack;
  }

  /// How far past `openMoves` the first move may spread.
  static const int startSlack = 3;

  /// How far past `openMoves` the widest moment may spread.
  static const int widestSlack = 5;
}

/// One candidate board under construction.
class _Builder {
  _Builder(this.spec, this.random)
      : w = spec.width,
        h = spec.height,
        owner = Int32List(spec.width * spec.height)..fillRange(0, spec.width * spec.height, -1),
        rayOwners = List<List<int>>.generate(spec.width * spec.height, (_) => <int>[]),
        scratch = Uint8List(spec.width * spec.height),
        seen = Uint8List(spec.arrows + 1);

  final LevelSpec spec;
  final Random random;
  final int w;
  final int h;

  /// Cell → placement index of the arrow on it, or -1.
  final Int32List owner;

  /// Per cell, the placement indices of the arrows whose exit ray covers it.
  final List<List<int>> rayOwners;

  /// Per-growth "used by the arrow being grown" marks (cleared after use).
  final Uint8List scratch;

  /// Visited marks for [_reaches].
  final Uint8List seen;

  final List<ArrowPiece> placed = <ArrowPiece>[];

  /// Per placed arrow, the placed arrows on its ray — what it waits for.
  final List<List<int>> waits = <List<int>>[];

  /// How many placed arrows wait for nobody right now.
  int openCount = 0;

  bool inside(int x, int y) => x >= 0 && y >= 0 && x < w && y < h;
  int idx(int x, int y) => y * w + x;
  bool free(int x, int y) => inside(x, y) && owner[idx(x, y)] < 0;

  /// Whether the board currently offers more open arrows than the level
  /// wants, so the next arrow should close some.
  bool get wantClosing => openCount >= spec.openMoves;

  /// Open arrows whose ray covers cell [k].
  int openOn(int k) {
    var n = 0;
    for (final o in rayOwners[k]) {
      if (waits[o].isEmpty) n++;
    }
    return n;
  }

  /// Whether any arrow in [from] waits, however indirectly, for one in [goal].
  bool _reaches(Iterable<int> from, Set<int> goal) {
    if (goal.isEmpty) return false;
    seen.fillRange(0, placed.length, 0);
    final stack = <int>[...from];
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      if (goal.contains(i)) return true;
      if (seen[i] != 0) continue;
      seen[i] = 1;
      stack.addAll(waits[i]);
    }
    return false;
  }

  /// Every cell from just past ([x],[y]) to the edge in [d], packed.
  List<int> _rayCells(int x, int y, Direction d) {
    final (dx, dy) = d.vector;
    final out = <int>[];
    for (var cx = x + dx, cy = y + dy; inside(cx, cy); cx += dx, cy += dy) {
      out.add(idx(cx, cy));
    }
    return out;
  }

  /// Free cells at the start of [ray] before the first arrow on it.
  int _freeAhead(List<int> ray) {
    var n = 0;
    for (final k in ray) {
      if (owner[k] >= 0) break;
      n++;
    }
    return n;
  }

  /// Whether an arrow with this [body] and [ray] keeps the graph a DAG: the
  /// arrows it would wait for (on its ray) must not already wait for any of
  /// the arrows whose rays the body lies across (those will wait for it).
  bool _acyclic(List<Cell> body, List<int> ray) {
    final waiters = <int>{};
    for (final c in body) {
      waiters.addAll(rayOwners[idx(c.x, c.y)]);
    }
    return !_reaches(<int>[for (final k in ray) if (owner[k] >= 0) owner[k]], waiters);
  }

  Puzzle build() {
    while (placed.length < spec.arrows) {
      final id = placed.length;
      // Two ways to make an arrow, the better-scoring one wins: grown behind
      // a sampled head, or (while closing) grown out from an open ray.
      var best = _placeOne(id);
      if (wantClosing) {
        final closing = _placeClosing(id, _targetLength(id));
        if (closing != null && (best == null || closing.$2 > best.$2)) best = closing;
      }
      if (best == null) break;
      _commit(best.$1);
    }
    _fillGaps();
    // Reverse: the first arrow placed is the last one out (roughly — an
    // arrow may point at an earlier one and so leave before it).
    final ordered = placed.reversed.toList();
    final arrows = <ArrowPiece>[
      for (var i = 0; i < ordered.length; i++)
        ArrowPiece(id: i, cells: ordered[i].cells, heading: ordered[i].heading),
    ];
    return Puzzle(width: w, height: h, arrows: arrows);
  }

  /// Registers that arrow [by] now sits on cell [k]: every arrow whose ray
  /// runs through it waits for [by] from now on.
  void _cover(int k, int by) {
    owner[k] = by;
    for (final o in rayOwners[k]) {
      if (waits[o].contains(by)) continue;
      if (waits[o].isEmpty) openCount--;
      waits[o].add(by);
    }
  }

  void _commit(ArrowPiece piece) {
    final index = placed.length;
    placed.add(piece);
    final ray = _rayCells(piece.head.x, piece.head.y, piece.heading);
    final ahead = <int>[];
    for (final k in ray) {
      if (owner[k] >= 0 && !ahead.contains(owner[k])) ahead.add(owner[k]);
    }
    waits.add(ahead);
    if (ahead.isEmpty) openCount++;
    for (final c in piece.cells) {
      _cover(idx(c.x, c.y), index);
    }
    for (final k in ray) {
      rayOwners[k].add(index);
    }
  }

  /// Where arrow [id] sits on the inside-out ramp: 0 for the first placed
  /// (the last out), 1 for the last placed.
  double _ramp(int id) => spec.arrows <= 1 ? 1.0 : id / (spec.arrows - 1);

  /// Inner pieces (placed first, out last) are short; outer ones wrap
  /// around them and run long — the nested look of a good board.
  int _targetLength(int id) {
    final span = spec.maxLength - spec.minLength;
    final centre = spec.minLength + span * _ramp(id);
    return (centre + (random.nextDouble() - 0.5) * span * 0.6)
        .round()
        .clamp(spec.minLength, spec.maxLength);
  }

  (ArrowPiece, int)? _placeOne(int id) {
    // Every (head, heading) whose head and the cell behind it are free,
    // weighted so deep heads come first: filling from the inside out keeps
    // the free area an outer ring every later ray can reach. While the board
    // should close open rays, heads on or next to one weigh extra so the
    // walk starts where it can do that. A head on the edge facing out can
    // never be blocked — a free tap for the whole game — so while closing
    // those are a last resort.
    final closing = wantClosing;
    final heads = <int>[]; // packed: idx * 4 + heading
    final weights = <int>[];
    var totalWeight = 0;
    for (final allowEdgeHeads in <bool>[!closing, true]) {
      if (heads.isNotEmpty) break;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final k = idx(x, y);
          if (owner[k] >= 0) continue;
          for (final d in Direction.values) {
            final (dx, dy) = d.vector;
            if (!free(x - dx, y - dy)) continue;
            if (!allowEdgeHeads && !inside(x + dx, y + dy)) continue;
            final depth = min(min(x, w - 1 - x), min(y, h - 1 - y));
            var weight = (depth + 1) * (depth + 1);
            if (closing && (openOn(k) > 0 || openOn(idx(x - dx, y - dy)) > 0)) {
              weight *= 4;
            }
            heads.add(k * 4 + d.index);
            weights.add(weight);
            totalWeight += weight;
          }
        }
      }
    }
    if (heads.isEmpty) return null;

    final ramp = _ramp(id);
    final closeBonus = closing ? kCloseBonus : kCloseBonusRelaxed;

    ArrowPiece? best;
    // A plain literal: dart2js treats `-1 << 30` as unsigned 32-bit (a huge
    // positive number), which silently produced empty boards on the web.
    var bestScore = -1000000000;
    final choices = min(kPlacementChoices, heads.length);
    for (var i = 0; i < choices; i++) {
      // Weighted sample without replacement by swapping the pick to the end.
      var roll = random.nextInt(totalWeight);
      var pick = 0;
      for (; pick < heads.length - 1 - i; pick++) {
        roll -= weights[pick];
        if (roll < 0) break;
      }
      final packed = heads[pick];
      final last = heads.length - 1 - i;
      totalWeight -= weights[pick];
      heads[pick] = heads[last];
      weights[pick] = weights[last];
      heads[last] = packed;

      final hx = (packed ~/ 4) % w;
      final hy = (packed ~/ 4) ~/ w;
      final heading = Direction.values[packed % 4];
      final ray = _rayCells(hx, hy, heading);
      final body = _growBody(hx, hy, heading, ray, _targetLength(id), closing);
      if (body.length < spec.minLength || !_acyclic(body, ray)) continue;
      // Crossing existing rays makes this arrow a blocker now and a longer
      // body packs the board. A long clear ray of its own is good early
      // (later arrows will cross it) and bad late (those cells would stay
      // empty), so its weight flips sign along the ramp. Closing open
      // arrows is what keeps the player's choice narrow, so it pays the most.
      var score = body.length + (_freeAhead(ray) * (1 - 2 * ramp)).round();
      score += _crossingScore(body, closeBonus);
      if (score > bestScore) {
        bestScore = score;
        best = ArrowPiece(id: id, cells: body, heading: heading);
      }
    }
    return best == null ? null : (best, bestScore);
  }

  /// What [body] earns for the rays it lies across: a little per ray, and
  /// [closeBonus] per open arrow it closes.
  int _crossingScore(List<Cell> body, int closeBonus) {
    var score = 0;
    final closed = <int>{};
    for (final c in body) {
      final k = idx(c.x, c.y);
      score += 3 * rayOwners[k].length;
      for (final o in rayOwners[k]) {
        if (waits[o].isEmpty) closed.add(o);
      }
    }
    return score + closeBonus * closed.length;
  }

  /// Scores a candidate body step onto cell [k] at ([nx],[ny]) when going
  /// straight would land on ([sx],[sy]): the same way for a walk grown
  /// behind a head and for one grown out from a ray cell.
  double _stepScore(int k, int nx, int ny, int sx, int sy, bool closing) =>
      (nx == sx && ny == sy ? kStraightBias : 0) +
      3.0 * _hugging(nx, ny) +
      2.0 * rayOwners[k].length +
      (closing ? kCloseStepBias * openOn(k) : 0) +
      random.nextDouble() * 1.5;

  /// While the board has more open arrows than the level wants: a body
  /// grown *out from a free cell on an open arrow's ray*, so it is certain
  /// to close that arrow, with the head chosen afterwards at whichever end
  /// keeps the graph a DAG. Tries a few open rays and keeps the best body;
  /// null when none of them fits (a fragment too small for
  /// [LevelSpec.minLength]), in which case the caller falls back to growing
  /// behind a head.
  (ArrowPiece, int)? _placeClosing(int id, int target) {
    // Open arrows with a ray to lie across (a head on the edge has none).
    final open = <int>[
      for (var i = 0; i < placed.length; i++)
        if (waits[i].isEmpty && placed[i].exitRay(w, h).isNotEmpty) i,
    ];
    ArrowPiece? best;
    var bestScore = -1000000000;
    for (var attempt = 0; attempt < kClosingChoices && open.isNotEmpty; attempt++) {
      final o = open[random.nextInt(open.length)];
      final ray = placed[o].exitRay(w, h);
      final start = ray[random.nextInt(ray.length)];
      final path = _growFrom(start, target);
      if (path.length < spec.minLength) continue;
      for (final piece in _orientations(id, path)) {
        final score = piece.length + _crossingScore(piece.cells, kCloseBonus);
        if (score > bestScore) {
          bestScore = score;
          best = piece;
        }
      }
    }
    return best == null ? null : (best, bestScore);
  }

  /// Grows a self-avoiding walk through free cells out from [start] at both
  /// ends alternately, up to [target] cells, with the usual step scoring.
  List<Cell> _growFrom(Cell start, int target) {
    final path = <Cell>[start];
    scratch[idx(start.x, start.y)] = 1;
    var stuck = 0;
    var atFront = true;
    while (path.length < target && stuck < 2) {
      final end = atFront ? path.first : path.last;
      final prev = path.length == 1 ? end : (atFront ? path[1] : path[path.length - 2]);
      // Straight on means stepping away from prev in the same direction.
      final sx = end.x + (end.x - prev.x);
      final sy = end.y + (end.y - prev.y);
      Cell? next;
      var bestStep = double.negativeInfinity;
      for (final d in Direction.values) {
        final (ox, oy) = d.vector;
        final nx = end.x + ox;
        final ny = end.y + oy;
        if (!free(nx, ny) || scratch[idx(nx, ny)] != 0) continue;
        final score = _stepScore(idx(nx, ny), nx, ny, sx, sy, true);
        if (score > bestStep) {
          bestStep = score;
          next = Cell(nx, ny);
        }
      }
      if (next == null) {
        stuck++;
      } else {
        stuck = 0;
        if (atFront) {
          path.insert(0, next);
        } else {
          path.add(next);
        }
        scratch[idx(next.x, next.y)] = 1;
      }
      atFront = !atFront;
    }
    for (final c in path) {
      scratch[idx(c.x, c.y)] = 0;
    }
    return path;
  }

  /// The ways to read [path] as an arrow: head at either end, provided the
  /// ray beyond that end is at least one cell (a head on the edge can never
  /// be blocked), does not run back across the path, and keeps the graph a
  /// DAG.
  List<ArrowPiece> _orientations(int id, List<Cell> path) {
    final out = <ArrowPiece>[];
    for (final cells in <List<Cell>>[path, path.reversed.toList()]) {
      final head = cells.last;
      final heading = cells[cells.length - 2].directionTo(head)!;
      final ray = _rayCells(head.x, head.y, heading);
      if (ray.isEmpty) continue;
      if (cells.any((c) => ray.contains(idx(c.x, c.y)))) continue;
      if (!_acyclic(cells, ray)) continue;
      out.add(ArrowPiece(id: id, cells: cells, heading: heading));
    }
    return out;
  }

  /// How many of a cell's four neighbours are off the board, occupied, or
  /// part of the arrow being grown (marked in [scratch]).
  int _hugging(int x, int y) {
    var n = 0;
    for (final d in Direction.values) {
      final (dx, dy) = d.vector;
      final nx = x + dx;
      final ny = y + dy;
      if (!inside(nx, ny) || owner[idx(nx, ny)] >= 0 || scratch[idx(nx, ny)] != 0) n++;
    }
    return n;
  }

  /// Grows a self-avoiding walk backwards from the head until it reaches
  /// [target] cells or runs out of room. Each step scores: keep going
  /// straight, hug arrows/the border (that is what nests pieces tightly, ring
  /// inside ring, with no gaps), sit on existing exit rays (a dependency)
  /// and, when [closing], reach for cells on open rays. A little noise keeps
  /// boards from looking machine-made. The arrow's own ray line is off
  /// limits. Returns tail → head.
  List<Cell> _growBody(
    int hx,
    int hy,
    Direction heading,
    List<int> ray,
    int target,
    bool closing,
  ) {
    final (dx, dy) = heading.vector;
    final body = <Cell>[Cell(hx - dx, hy - dy), Cell(hx, hy)];
    // Mark the head, the cell behind it and the ray as taken for this walk.
    final marked = <int>[idx(hx, hy), idx(hx - dx, hy - dy), ...ray];
    for (final m in marked) {
      scratch[m] = 1;
    }
    while (body.length < target) {
      final tail = body.first;
      final (sx, sy) = body[1].directionTo(tail)!.vector;
      Cell? next;
      var bestStep = double.negativeInfinity;
      for (final d in Direction.values) {
        final (ox, oy) = d.vector;
        final nx = tail.x + ox;
        final ny = tail.y + oy;
        if (!free(nx, ny) || scratch[idx(nx, ny)] != 0) continue;
        final score = _stepScore(idx(nx, ny), nx, ny, tail.x + sx, tail.y + sy, closing);
        if (score > bestStep) {
          bestStep = score;
          next = Cell(nx, ny);
        }
      }
      if (next == null) break;
      body.insert(0, next);
      final m = idx(next.x, next.y);
      marked.add(m);
      scratch[m] = 1;
    }
    for (final m in marked) {
      scratch[m] = 0;
    }
    return body;
  }

  /// Grows arrows' tails into leftover free cells until nothing fits. A tail
  /// cell never changes an arrow's head or exit ray, so the only thing it can
  /// do is block *other* arrows' rays — fine as long as none of those is
  /// something this arrow (indirectly) waits for, which would be a cycle.
  /// Filling pockets this way is what packs the board and tangles it; a cell
  /// on an open ray is worth the most, since it takes a tap away.
  void _fillGaps() {
    final maxLength = spec.maxLength + kGapTailSlack;
    var grew = true;
    while (grew) {
      grew = false;
      final order = List<int>.generate(placed.length, (i) => i)..shuffle(random);
      for (final i in order) {
        final piece = placed[i];
        if (piece.length >= maxLength) continue;
        final tail = piece.tail;
        final straight = piece.cells[1].directionTo(tail);
        Cell? next;
        var best = double.negativeInfinity;
        for (final d in Direction.values) {
          final (ox, oy) = d.vector;
          final nx = tail.x + ox;
          final ny = tail.y + oy;
          if (!free(nx, ny)) continue;
          final k = idx(nx, ny);
          if (rayOwners[k].contains(i) || _reaches(<int>[i], rayOwners[k].toSet())) continue;
          // Prefer closing an open ray, then continuing straight, then the
          // snuggest cell.
          final score = 4.0 * openOn(k) +
              (d == straight ? 2.0 : 0.0) +
              _hugging(nx, ny) +
              random.nextDouble();
          if (score > best) {
            best = score;
            next = Cell(nx, ny);
          }
        }
        if (next == null) continue;
        placed[i] = ArrowPiece(
          id: piece.id,
          cells: <Cell>[next, ...piece.cells],
          heading: piece.heading,
        );
        _cover(idx(next.x, next.y), i);
        grew = true;
      }
    }
  }
}

/// The fixed puzzle for a level: deterministic in the level's seed, so a
/// retry (or a replay) is always the same board.
Puzzle puzzleForLevel(LevelSpec spec) =>
    PuzzleGenerator(random: Random(spec.seed)).generate(spec);
