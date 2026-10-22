// Prints the `LevelSpec` rows for levels 21–100 — the four chapters past the
// plain rectangle — so the table in lib/data/level_specs.dart is drawn from
// one set of rules rather than tuned a row at a time:
//
//   dart run tool/make_levels.dart > /tmp/rows.dart
//
// Each chapter is twenty levels on one new twist (Shapes, Locks, Fog, Pairs)
// stacked on the ones before it, and every chapter has the same rhythm:
//
//   level  1   a small, roomy teaching board with the new twist alone
//   level  5   a sprint: a small, brisk board
//   level 10   the chapter's boss: a bigger board, more of everything
//   level 15   another sprint
//   level 20   the chapter's finale: its biggest board
//   the rest   the climb, a little bigger each time
//
// The arrow count climbs from ~150 at level 22 to ~230 at level 99 and the
// finales run to ~265: the last levels are long because there is a lot to
// read, not because the read never changes. The board is sized so the cells
// an arrow may use (the rectangle less the shape's walls) come to ~11.3 per
// arrow, the fill the generator packs to ~0.88.
//
// The clock is a pace per arrow — 2.4 s in Shapes easing to 2.0 s in Pairs —
// plus a few seconds for every lock, hidden head and tether on the board,
// since each is a thing to look for, plus slack. Sprints run at 1.6 s an
// arrow; teaching boards at 3 s.

import 'package:arrow_game/engine/board_shape.dart';

const int firstLevel = 21;
const int lastLevel = 100;

/// Free cells the board is sized to offer per arrow.
const double cellsPerArrow = 11.3;

/// Height over width of a board.
const double aspect = 1.52;

void main() {
  for (var level = firstLevel; level <= lastLevel; level++) {
    final chapter = (level - 1) ~/ 20; // 1 = Shapes, 2 = Locks, 3 = Fog, 4 = Pairs
    final i = level - (chapter * 20); // 1..20 within the chapter
    final teach = i == 1;
    final sprint = i == 5 || i == 15;
    final boss = i == 10;
    final finale = i == 20;

    // The shape: teaching boards for Shapes use the simplest cut; later
    // chapters teach their twist on a plain board so it stands alone; the
    // climb cycles through every shape.
    final shapes = <BoardShape>[BoardShape.corners, BoardShape.hole, BoardShape.cross, BoardShape.pillars];
    final BoardShape shape;
    if (teach) {
      shape = chapter == 1 ? BoardShape.corners : BoardShape.plain;
    } else {
      shape = shapes[(level + chapter) % shapes.length];
    }

    // Twists: the chapter's own climbs through it; earlier chapters' stay
    // at a steady few. Teaching boards carry two of the new one, nothing else.
    final climb = 2 + (i - 2) ~/ 3; // 2..8 over the chapter
    final extra = (boss || finale) ? 2 : 0;
    var locks = 0, hidden = 0, pairs = 0;
    if (teach) {
      if (chapter == 2) locks = 2;
      if (chapter == 3) hidden = 2;
      if (chapter == 4) pairs = 2;
    } else if (sprint) {
      if (chapter >= 2) locks = chapter == 2 ? 2 : 1;
      if (chapter >= 3) hidden = chapter == 3 ? 2 : 1;
      if (chapter >= 4) pairs = 2;
    } else {
      if (chapter == 2) locks = climb + extra;
      if (chapter >= 3) locks = 3;
      if (chapter == 3) hidden = climb + extra;
      if (chapter >= 4) hidden = 4;
      if (chapter == 4) pairs = climb + extra;
    }

    // Arrow count.
    final int arrows;
    if (teach) {
      arrows = 12;
    } else if (sprint) {
      arrows = 18 + chapter * 2;
    } else {
      final base = 150 + (level - 22) * 80 / 78;
      arrows = (base * (boss ? 1.1 : finale ? 1.15 : 1.0)).round();
    }

    // Lengths.
    final minLength = teach || sprint ? 2 : (chapter == 1 ? 3 : 4);
    final int maxLength;
    if (teach) {
      maxLength = 5;
    } else if (sprint) {
      maxLength = 7;
    } else {
      maxLength = 10 + chapter + (i >= 12 ? 1 : 0);
    }

    // Board size: enough free cells for the arrows at the shape's wall cost.
    final (width, height) = teach
        ? (10, 13)
        : sprint
            ? (12, 16)
            : _sizeFor(arrows, shape);

    // Clock.
    final pace = teach
        ? 3.0
        : sprint
            ? 1.6
            : <double>[0, 2.4, 2.25, 2.1, 2.0][chapter];
    final slack = teach ? 25.0 : (sprint ? 8.0 : 15.0);
    final think = locks * 4.0 + hidden * 3.0 + pairs * 3.0;
    final timeLimitMs = ((arrows * pace + slack + think) * 1000).round();

    final features = <String>[
      if (shape != BoardShape.plain) 'shape: BoardShape.${shape.name}',
      if (locks > 0) 'locks: $locks',
      if (hidden > 0) 'hidden: $hidden',
      if (pairs > 0) 'pairs: $pairs',
    ];
    final featureText = features.isEmpty ? '' : ', features: LevelFeatures(${features.join(', ')})';
    // A teaching board is roomy on purpose — three moves open at a time —
    // so there is always a plain tap to make while the new piece is studied.
    final openMoves = teach ? 3 : 2;
    // ignore: avoid_print
    print(
      '  LevelSpec(level: $level, width: $width, height: $height, arrows: $arrows, '
      'minLength: $minLength, maxLength: $maxLength, timeLimitMs: $timeLimitMs, openMoves: $openMoves$featureText),',
    );
  }
}

/// The smallest board of the usual proportions whose free cells cover
/// [arrows] at [cellsPerArrow].
(int, int) _sizeFor(int arrows, BoardShape shape) {
  final want = arrows * cellsPerArrow;
  for (var width = 20; width < 80; width++) {
    final height = (width * aspect).round();
    final free = width * height - wallsFor(shape, width, height).length;
    if (free >= want) return (width, height);
    // Try one row taller before the next width, for a finer step.
    final free2 = width * (height + 1) - wallsFor(shape, width, height + 1).length;
    if (free2 >= want) return (width, height + 1);
  }
  return (80, (80 * aspect).round());
}

