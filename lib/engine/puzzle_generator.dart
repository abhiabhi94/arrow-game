/// Procedural puzzles that are solvable by construction. Pure Dart.
///
/// Arrows are placed in *reverse* solving order onto an empty board: each new
/// arrow gets a head whose exit ray is currently clear (so it can always go
/// after everything placed before it), then grows a random self-avoiding body
/// behind the head. Arrows placed later may sit across earlier rays — those
/// are exactly the dependencies that make the puzzle a puzzle. Several
/// candidates are generated and the most tangled one wins.
library;

import 'dart:math';

import '../models/level_spec.dart';
import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';
import 'puzzle.dart';

/// Candidates generated per puzzle; the highest [Puzzle.difficultyScore] wins.
const int kGeneratorCandidates = 40;

/// Head placements tried per arrow before a candidate is abandoned.
const int _kPlacementTries = 200;

/// Valid placements collected per arrow; the one crossing the most existing
/// exit rays wins, which is what turns a scattering of arrows into a puzzle.
const int _kPlacementChoices = 6;

/// Candidate boards tried before the arrow count is relaxed by one.
const int _kCandidateTries = 60;

class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Builds a puzzle for [spec]. Always returns a solvable board; if the spec
  /// asks for more arrows than the board can take, the count is relaxed one
  /// at a time (the level table is tested to never need that).
  Puzzle generate(LevelSpec spec) {
    var arrows = spec.arrows;
    while (true) {
      Puzzle? best;
      var tries = 0;
      while (best == null || tries < kGeneratorCandidates) {
        final candidate = _tryGenerate(spec.width, spec.height, arrows, spec);
        if (candidate != null) {
          if (best == null || candidate.difficultyScore > best.difficultyScore) {
            best = candidate;
          }
          tries++;
        } else if (++tries >= _kCandidateTries && best == null) {
          break;
        }
      }
      if (best != null) return best;
      arrows--;
    }
  }

  Puzzle? _tryGenerate(int width, int height, int count, LevelSpec spec) {
    final occupied = <Cell>{};
    // How many already-placed arrows' exit rays pass through each cell. A new
    // body that sits on such a cell must leave before that arrow can — a
    // dependency, and the more of them the better the puzzle.
    final rayCells = <Cell, int>{};
    final placed = <ArrowPiece>[];
    for (var i = 0; i < count; i++) {
      final piece = _placeOne(width, height, occupied, rayCells, spec, placed.length);
      if (piece == null) return null;
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

  ArrowPiece? _placeOne(
    int width,
    int height,
    Set<Cell> occupied,
    Map<Cell, int> rayCells,
    LevelSpec spec,
    int id,
  ) {
    ArrowPiece? best;
    var bestCrossings = -1; // best placement score so far
    var found = 0;
    for (var attempt = 0; attempt < _kPlacementTries && found < _kPlacementChoices; attempt++) {
      final head = Cell(_random.nextInt(width), _random.nextInt(height));
      if (occupied.contains(head)) continue;
      final heading = Direction.values[_random.nextInt(4)];
      // The head must have somewhere to grow a body from.
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
      if (!clear) continue;

      final target = spec.minLength + _random.nextInt(spec.maxLength - spec.minLength + 1);
      final body = _growBody(head, behind, target, width, height, occupied, ray.toSet(), rayCells);
      if (body.length < spec.minLength) continue;
      found++;
      // Crossing existing rays makes this arrow a blocker now; a long ray of
      // its own leaves room for later arrows to block it in turn.
      var score = ray.length;
      for (final cell in body) {
        score += 3 * (rayCells[cell] ?? 0);
      }
      if (score > bestCrossings) {
        bestCrossings = score;
        best = ArrowPiece(id: id, cells: body, heading: heading);
      }
    }
    return best;
  }

  /// Grows a self-avoiding walk backwards from [head] through [behind] until
  /// it reaches [target] cells or runs out of room, preferring cells that sit
  /// on existing exit rays. Returns tail → head.
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
      // Weighted pick: a cell on k exit rays counts (1 + 2k) times.
      var total = 0;
      for (final o in options) {
        total += 1 + 2 * (rayCells[o] ?? 0);
      }
      var roll = _random.nextInt(total);
      var next = options.last;
      for (final o in options) {
        roll -= 1 + 2 * (rayCells[o] ?? 0);
        if (roll < 0) {
          next = o;
          break;
        }
      }
      body.insert(0, next);
      used.add(next);
    }
    return body;
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

/// The fixed puzzle for a level: deterministic in the level's seed, so a
/// retry (or a replay) is always the same board.
Puzzle puzzleForLevel(LevelSpec spec) =>
    PuzzleGenerator(random: Random(spec.seed)).generate(spec);
