/// Procedural puzzles that are solvable by construction. Pure Dart.
///
/// Arrows are placed in *reverse* solving order onto an empty board: each new
/// arrow gets a head whose exit ray is clear right now (so it can always go
/// after everything placed before it), then grows a mostly-straight body
/// behind the head that hugs whatever is already there. Arrows placed later
/// may sit across earlier rays — those are exactly the dependencies that make
/// the puzzle a puzzle. A final pass grows tails into leftover gaps. Several
/// candidate boards are generated; the fullest, then most tangled, wins.
///
/// Hot loops run on a flat byte grid rather than hashed cell sets: the big
/// late boards enumerate every cell for every placement.
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
const int kMinCandidates = 3;

/// Valid head placements grown per arrow; the best-scoring body wins.
const int kPlacementChoices = 8;

/// Score bonus for a body step that keeps going straight. Real boards are
/// mostly long runs with the occasional bend, which also packs more in.
const double kStraightBias = 4.0;

/// How far past the level's nominal maximum a tail may grow while soaking
/// up gaps in the final pass.
const int kGapTailSlack = 8;

class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds a puzzle for [spec]. Always solvable. Tries several boards and
  /// keeps the one with the most arrows (the spec's count when the board has
  /// room — the level table is tested for that), breaking ties by tangle.
  Puzzle generate(LevelSpec spec) {
    Puzzle? best;
    final candidates = candidatesFor(spec.arrows);
    for (var i = 0; i < candidates; i++) {
      final p = _Builder(spec, _random).build();
      if (best == null ||
          p.arrowCount > best.arrowCount ||
          (p.arrowCount == best.arrowCount && p.difficultyScore > best.difficultyScore)) {
        best = p;
      }
    }
    return best!;
  }
}

/// One candidate board under construction.
class _Builder {
  _Builder(this.spec, this.random)
      : w = spec.width,
        h = spec.height,
        occ = Uint8List(spec.width * spec.height),
        rays = Uint8List(spec.width * spec.height),
        scratch = Uint8List(spec.width * spec.height);

  final LevelSpec spec;
  final Random random;
  final int w;
  final int h;

  /// 1 where an arrow sits.
  final Uint8List occ;

  /// How many placed arrows' exit rays pass through each cell.
  final Uint8List rays;

  /// Per-growth "used by the arrow being grown" marks (cleared after use).
  final Uint8List scratch;

  final List<ArrowPiece> placed = <ArrowPiece>[];

  bool inside(int x, int y) => x >= 0 && y >= 0 && x < w && y < h;
  int idx(int x, int y) => y * w + x;
  bool free(int x, int y) => inside(x, y) && occ[idx(x, y)] == 0;

  Puzzle build() {
    while (placed.length < spec.arrows) {
      final piece = _placeOne(placed.length);
      if (piece == null) break;
      _commit(piece);
    }
    _fillGaps();
    // Reverse: the first arrow placed is the last one out.
    final ordered = placed.reversed.toList();
    return Puzzle(
      width: w,
      height: h,
      arrows: <ArrowPiece>[
        for (var i = 0; i < ordered.length; i++)
          ArrowPiece(id: i, cells: ordered[i].cells, heading: ordered[i].heading),
      ],
    );
  }

  void _commit(ArrowPiece piece) {
    placed.add(piece);
    for (final c in piece.cells) {
      occ[idx(c.x, c.y)] = 1;
    }
    for (final c in piece.exitRay(w, h)) {
      rays[idx(c.x, c.y)]++;
    }
  }

  /// Length of the clear exit ray from ([x],[y]) in [d], or -1 if blocked.
  int _clearRay(int x, int y, Direction d) {
    final (dx, dy) = d.vector;
    var n = 0;
    var cx = x + dx;
    var cy = y + dy;
    while (inside(cx, cy)) {
      if (occ[idx(cx, cy)] != 0) return -1;
      n++;
      cx += dx;
      cy += dy;
    }
    return n;
  }

  ArrowPiece? _placeOne(int id) {
    // Every (head, heading) whose head and the cell behind it are free and
    // whose exit ray is clear, weighted so deep heads come first: filling
    // from the inside out keeps the free area an outer ring every later ray
    // can reach.
    final heads = <int>[]; // packed: idx * 4 + heading
    final weights = <int>[];
    var totalWeight = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (occ[idx(x, y)] != 0) continue;
        for (final d in Direction.values) {
          final (dx, dy) = d.vector;
          if (!free(x - dx, y - dy)) continue;
          if (_clearRay(x, y, d) < 0) continue;
          final depth = min(min(x, w - 1 - x), min(y, h - 1 - y));
          heads.add(idx(x, y) * 4 + d.index);
          weights.add((depth + 1) * (depth + 1));
          totalWeight += (depth + 1) * (depth + 1);
        }
      }
    }
    if (heads.isEmpty) return null;

    // Inner pieces (placed first, out last) are short; outer ones wrap
    // around them and run long — the nested look of a good board.
    final ramp = spec.arrows <= 1 ? 1.0 : id / (spec.arrows - 1);
    final span = spec.maxLength - spec.minLength;
    final centre = spec.minLength + span * ramp;

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
      final rayLength = _clearRay(hx, hy, heading);
      final target = (centre + (random.nextDouble() - 0.5) * span * 0.6)
          .round()
          .clamp(spec.minLength, spec.maxLength);
      final body = _growBody(hx, hy, heading, rayLength, target);
      if (body.length < spec.minLength) continue;
      // Crossing existing rays makes this arrow a blocker now and a longer
      // body packs the board. A long ray of its own is good early (later
      // arrows will cross it) and bad late (those cells would stay empty),
      // so its weight flips sign along the ramp.
      var score = body.length + (rayLength * (1 - 2 * ramp)).round();
      for (final c in body) {
        score += 3 * rays[idx(c.x, c.y)];
      }
      if (score > bestScore) {
        bestScore = score;
        best = ArrowPiece(id: id, cells: body, heading: heading);
      }
    }
    return best;
  }

  /// How many of a cell's four neighbours are off the board, occupied, or
  /// part of the arrow being grown (marked in [scratch]).
  int _hugging(int x, int y) {
    var n = 0;
    for (final d in Direction.values) {
      final (dx, dy) = d.vector;
      final nx = x + dx;
      final ny = y + dy;
      if (!inside(nx, ny) || occ[idx(nx, ny)] != 0 || scratch[idx(nx, ny)] != 0) n++;
    }
    return n;
  }

  /// Grows a self-avoiding walk backwards from the head until it reaches
  /// [target] cells or runs out of room. Each step scores: keep going
  /// straight, hug arrows/the border (that is what nests pieces tightly, ring
  /// inside ring, with no gaps), and sit on existing exit rays (a
  /// dependency). A little noise keeps boards from looking machine-made.
  /// The arrow's own ray is off limits. Returns tail → head.
  List<Cell> _growBody(int hx, int hy, Direction heading, int rayLength, int target) {
    final (dx, dy) = heading.vector;
    final body = <Cell>[Cell(hx - dx, hy - dy), Cell(hx, hy)];
    // Mark the head, the cell behind it and the ray as taken for this walk.
    final marked = <int>[idx(hx, hy), idx(hx - dx, hy - dy)];
    for (var i = 1, cx = hx + dx, cy = hy + dy; i <= rayLength; i++, cx += dx, cy += dy) {
      marked.add(idx(cx, cy));
    }
    for (final m in marked) {
      scratch[m] = 1;
    }
    while (body.length < target) {
      final tail = body.first;
      final straightDir = body[1].directionTo(tail)!;
      final (sx, sy) = straightDir.vector;
      Cell? next;
      var bestStep = double.negativeInfinity;
      for (final d in Direction.values) {
        final (ox, oy) = d.vector;
        final nx = tail.x + ox;
        final ny = tail.y + oy;
        if (!free(nx, ny) || scratch[idx(nx, ny)] != 0) continue;
        final score = (ox == sx && oy == sy ? kStraightBias : 0) +
            3.0 * _hugging(nx, ny) +
            2.0 * rays[idx(nx, ny)] +
            random.nextDouble() * 1.5;
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
  /// do is block *other* arrows' rays. That is safe exactly when the blocked
  /// arrow was placed earlier (it leaves later anyway) — a tail may not sit on
  /// the ray of any arrow placed after its own, which would make a cycle.
  /// Filling pockets this way is what packs the board and tangles it.
  void _fillGaps() {
    final maxLength = spec.maxLength + kGapTailSlack;
    // Cell → highest placement index whose exit ray covers it (-1: none).
    final latestRayOver = Int32List(w * h)..fillRange(0, w * h, -1);
    for (var i = 0; i < placed.length; i++) {
      for (final c in placed[i].exitRay(w, h)) {
        final k = idx(c.x, c.y);
        if (i > latestRayOver[k]) latestRayOver[k] = i;
      }
    }
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
          if (!free(nx, ny) || latestRayOver[idx(nx, ny)] >= i) continue;
          // Prefer continuing the tail straight, then the snuggest cell.
          final score = (d == straight ? 2.0 : 0.0) + _hugging(nx, ny) + random.nextDouble();
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
        occ[idx(next.x, next.y)] = 1;
        grew = true;
      }
    }
  }
}

/// The fixed puzzle for a level: deterministic in the level's seed, so a
/// retry (or a replay) is always the same board.
Puzzle puzzleForLevel(LevelSpec spec) =>
    PuzzleGenerator(random: Random(spec.seed)).generate(spec);
