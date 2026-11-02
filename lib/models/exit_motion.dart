/// How long an arrow takes to slide off the board. Pure Dart, so the
/// provider can hold the win sound and the screen the "Level cleared" card
/// until the last arrow has visibly left, and the board can run the slide.
library;

import 'dart:math';

import '../engine/puzzle.dart';

/// How much longer a slide takes for every turn at a mirror on its way, so
/// the bounce is watched rather than inferred.
const int kBounceDwellMs = 140;

/// The slide of arrow [id] (and of its partner, which leaves on the same
/// clock — the longer half's), in milliseconds. Quick but still readable as
/// a slide: a short arrow at the edge is gone in about a quarter second; a
/// long crossing of a big board never drags.
int exitSlideMs(Puzzle puzzle, int id) {
  var travel = 0;
  var turns = 0;
  for (final member in puzzle.exitGroup(id)) {
    travel = max(travel, puzzle.arrows[member].length + puzzle.rayOf(member).length);
    turns = max(turns, puzzle.rayOf(member).where(puzzle.isMirror).length);
  }
  final dwell = turns * kBounceDwellMs;
  return (140 + travel * 30 + dwell).clamp(240, 600 + dwell);
}
