/// Procedural puzzles that are solvable by construction. Pure Dart.
///
/// Arrows are placed in *reverse* solving order onto an empty board: each new
/// arrow gets a head whose exit ray is clear right now (so it can always go
/// after everything placed before it), then grows a mostly-straight body
/// behind the head. Arrows placed later may sit across earlier rays — those
/// are exactly the dependencies that make the puzzle a puzzle. Several
/// candidate boards are generated; the fullest, then most tangled, wins.
library;

import 'dart:math';

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

/// How strongly a growing body keeps going straight. Real boards are mostly
/// long runs with the occasional bend, which also packs far more arrows in.
const double kStraightBias = 0.85;

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
      final p = _build(spec);
      if (best == null ||
          p.arrowCount > best.arrowCount ||
          (p.arrowCount == best.arrowCount && p.difficultyScore > best.difficultyScore)) {
        best = p;
      }
    }
    return best!;
  }

  Puzzle _build(LevelSpec spec) {
    final width = spec.width;
    final height = spec.height;
    final occupied = <Cell>{};
    // How many already-placed arrows' exit rays pass through each cell. A new
    // body that sits on such a cell must leave before that arrow can — a
    // dependency, and the more of them the better the puzzle.
    final rayCells = <Cell, int>{};
    final placed = <ArrowPiece>[];
    while (placed.length < spec.arrows) {
      final piece = _placeOne(width, height, occupied, rayCells, spec, placed.length);
      if (piece == null) break;
      placed.add(piece);
      occupied.addAll(piece.cells);
      for (final c in piece.exitRay(width, height)) {
        rayCells[c] = (rayCells[c] ?? 0) + 1;
      }
    }
    // Reverse: the first arrow placed is the last one out.
    final ordered = placed.reversed.toList();
    return Puzzle(
      width: width,
      height: height,
      arrows: <ArrowPiece>[
        for (var i = 0; i < ordered.length; i++)
          ArrowPiece(id: i, cells: ordered[i].cells, heading: ordered[i].heading),
      ],
    );
  }

  /// Every (head, heading) whose head and the cell behind it are free and
  /// whose exit ray is clear, with the ray attached.
  List<_HeadOption> _headOptions(int width, int height, Set<Cell> occupied) {
    final out = <_HeadOption>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final head = Cell(x, y);
        if (occupied.contains(head)) continue;
        for (final heading in Direction.values) {
          final behind = head.step(heading.opposite);
          if (!behind.isInside(width, height) || occupied.contains(behind)) continue;
          final ray = <Cell>[];
          var clear = true;
          var c = head.step(heading);
          while (c.isInside(width, height)) {
            if (occupied.contains(c)) {
              clear = false;
              break;
            }
            ray.add(c);
            c = c.step(heading);
          }
          if (clear) out.add(_HeadOption(head, heading, ray));
        }
      }
    }
    return out;
  }

  ArrowPiece? _placeOne(
    int width,
    int height,
    Set<Cell> occupied,
    Map<Cell, int> rayCells,
    LevelSpec spec,
    int id,
  ) {
    final options = _headOptions(width, height, occupied);
    if (options.isEmpty) return null;
    ArrowPiece? best;
    var bestScore = -1;
    final choices = min(kPlacementChoices, options.length);
    // Fill from the inside out: deep heads first, so the free area stays an
    // outer ring that every later ray can reach — no walled-off pockets.
    var totalWeight = 0;
    final weights = <int>[for (final o in options) _depthWeight(o.head, width, height)];
    for (final w in weights) {
      totalWeight += w;
    }
    for (var i = 0; i < choices; i++) {
      // Weighted sample without replacement by swapping the pick to the end.
      var roll = _random.nextInt(totalWeight);
      var pick = 0;
      for (; pick < options.length - 1 - i; pick++) {
        roll -= weights[pick];
        if (roll < 0) break;
      }
      final option = options[pick];
      final last = options.length - 1 - i;
      totalWeight -= weights[pick];
      options[pick] = options[last];
      weights[pick] = weights[last];
      options[last] = option;

      final target = spec.minLength + _random.nextInt(spec.maxLength - spec.minLength + 1);
      final body = _growBody(
        option.head,
        option.head.step(option.heading.opposite),
        target,
        width,
        height,
        occupied,
        option.ray.toSet(),
        rayCells,
      );
      if (body.length < spec.minLength) continue;
      // Crossing existing rays makes this arrow a blocker now; a longer body
      // packs the board; a ray of its own leaves room for later arrows to
      // block it in turn.
      var score = body.length + option.ray.length;
      for (final cell in body) {
        score += 3 * (rayCells[cell] ?? 0);
      }
      if (score > bestScore) {
        bestScore = score;
        best = ArrowPiece(id: id, cells: body, heading: option.heading);
      }
    }
    return best;
  }

  /// Grows a self-avoiding walk backwards from [head] through [behind] until
  /// it reaches [target] cells or runs out of room: mostly straight, and when
  /// it does turn, preferring cells that sit on existing exit rays. Returns
  /// tail → head.
  List<Cell> _growBody(
    Cell head,
    Cell behind,
    int target,
    int width,
    int height,
    Set<Cell> occupied,
    Set<Cell> forbidden,
    Map<Cell, int> rayCells,
  ) {
    final body = <Cell>[behind, head]; // tail → head, tail grows at the front
    final used = <Cell>{head, behind};
    while (body.length < target) {
      final tail = body.first;
      final options = <Cell>[
        for (final d in Direction.values)
          if (_free(tail.step(d), width, height, occupied, forbidden, used))
            tail.step(d),
      ];
      if (options.isEmpty) break;
      // Mostly keep going straight (the tail extends away from the head).
      final straight = tail.step(body[1].directionTo(tail)!);
      Cell next;
      if (options.contains(straight) && _random.nextDouble() < kStraightBias) {
        next = straight;
      } else {
        // Weighted pick: cells on exit rays (dependencies) and cells hugging
        // arrows or the border (dense packing, no stranded pockets) count more.
        int weight(Cell o) =>
            1 + 2 * (rayCells[o] ?? 0) + 2 * _hugging(o, width, height, occupied, used);
        var total = 0;
        for (final o in options) {
          total += weight(o);
        }
        var roll = _random.nextInt(total);
        next = options.last;
        for (final o in options) {
          roll -= weight(o);
          if (roll < 0) {
            next = o;
            break;
          }
        }
      }
      body.insert(0, next);
      used.add(next);
    }
    return body;
  }

  /// How many of [c]'s four neighbours are off the board, occupied, or part
  /// of the arrow being grown.
  static int _hugging(Cell c, int width, int height, Set<Cell> occupied, Set<Cell> used) {
    var n = 0;
    for (final d in Direction.values) {
      final s = c.step(d);
      if (!s.isInside(width, height) || occupied.contains(s) || used.contains(s)) n++;
    }
    return n;
  }

  /// Sampling weight for a head: strongly favours cells far from the edge.
  static int _depthWeight(Cell c, int width, int height) {
    final depth = min(min(c.x, width - 1 - c.x), min(c.y, height - 1 - c.y));
    return (depth + 1) * (depth + 1);
  }

  static bool _free(
    Cell c,
    int width,
    int height,
    Set<Cell> occupied,
    Set<Cell> forbidden,
    Set<Cell> used,
  ) =>
      c.isInside(width, height) &&
      !occupied.contains(c) &&
      !forbidden.contains(c) &&
      !used.contains(c);
}

class _HeadOption {
  const _HeadOption(this.head, this.heading, this.ray);
  final Cell head;
  final Direction heading;
  final List<Cell> ray;
}

/// The fixed puzzle for a level: deterministic in the level's seed, so a
/// retry (or a replay) is always the same board.
Puzzle puzzleForLevel(LevelSpec spec) =>
    PuzzleGenerator(random: Random(spec.seed)).generate(spec);
