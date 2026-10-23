// Prints the `LevelSpec` rows for levels 21–100 — the four chapters past the
// plain rectangle — so the table in lib/data/level_specs.dart is drawn from
// one set of rules rather than tuned a row at a time:
//
//   dart run tool/make_levels.dart > /tmp/rows.dart
//
// Each chapter is twenty levels on one new twist (Mirrors, Locks, Fog, Pairs)
// stacked on the ones before it, and every chapter has the same shape:
//
//   level  1   a small, roomy teaching board with the new twist alone
//   levels 2–20  the climb: [climbStart] arrows at the second level,
//                [climbEnd] at the twentieth, a steady step between, and
//                the chapter's own twist thickening along the way
//
// So a chapter opens easy and ends big, and the next one opens easy again
// with one more thing to read: the twists are what make the later chapters
// harder, not a bigger count. The first cut went from the twelve-arrow
// teaching board straight to 150 arrows and climbed to 265 by level 100,
// which played as a cliff after every card and a slog by the end. A board
// is sized so the cells an arrow may use (the rectangle less its mirrors)
// come to ~11.3 per arrow, which the generator fills to ~0.88.
//
// The clock is a pace per arrow that *grows* chapter by chapter — a mirror,
// a lock, a hidden head or a tether is one more thing to read on every
// arrow, so the twists buy time rather than cost it — plus a few seconds
// for every one of them on the board, plus slack, and never over ten
// minutes. Teaching boards run at 3 s an arrow.

import 'dart:math';

const int firstLevel = 21;
const int lastLevel = 100;

/// Arrows on a chapter's second level and on its twentieth.
const int climbStart = 30;
const int climbEnd = 150;

/// Seconds an arrow, by chapter (index 1 = Mirrors … 4 = Pairs).
const List<double> pace = <double>[0, 3.0, 3.2, 3.3, 3.4];

/// Free cells the board is sized to offer per arrow.
const double cellsPerArrow = 11.3;

/// Height over width of a board.
const double aspect = 1.52;

void main() {
  for (var level = firstLevel; level <= lastLevel; level++) {
    final chapter = (level - 1) ~/ 20; // 1 = Mirrors, 2 = Locks, 3 = Fog, 4 = Pairs
    final i = level - (chapter * 20); // 1..20 within the chapter
    final teach = i == 1;

    // Arrow count: the teaching board, then a straight climb.
    final arrows = teach ? 12 : (climbStart + (climbEnd - climbStart) * (i - 2) / 18).round();

    // Twists: the chapter's own climbs through it; earlier chapters' stay
    // at a steady few. Teaching boards carry a few of the new one, nothing
    // else.
    final climb = 2 + (i - 2) ~/ 3; // 2..8 over the chapter
    var locks = 0, hidden = 0, pairs = 0;
    if (teach) {
      if (chapter == 2) locks = 2;
      if (chapter == 3) hidden = 2;
      if (chapter == 4) pairs = 2;
    } else {
      if (chapter == 2) locks = climb;
      if (chapter >= 3) locks = 3;
      if (chapter == 3) hidden = climb;
      if (chapter >= 4) hidden = 4;
      if (chapter == 4) pairs = climb;
    }

    // Mirrors: a good handful on every board from the Mirrors chapter on —
    // one for every eight arrows through its own chapter, one for every
    // fourteen after, when the newer twist takes the stage.
    final int mirrors;
    if (teach) {
      mirrors = chapter == 1 ? 3 : 0;
    } else {
      mirrors = max(2, (arrows / (chapter == 1 ? 8 : 14)).round());
    }

    // Lengths.
    final minLength = teach ? 2 : (chapter == 1 ? 3 : 4);
    final maxLength = teach ? 5 : 10 + chapter + (i >= 12 ? 1 : 0);

    // Board size: enough free cells for the arrows beside the mirrors.
    final (width, height) = teach ? (10, 13) : _sizeFor(arrows, mirrors);

    // Clock.
    final slack = teach ? 25.0 : 15.0;
    final think = mirrors * 1.0 + locks * 4.0 + hidden * 3.0 + pairs * 3.0;
    final seconds = arrows * (teach ? 3.0 : pace[chapter]) + slack + think;
    // Never a clock over ten minutes.
    final timeLimitMs = min((seconds * 1000).round(), 599000);

    final features = <String>[
      if (mirrors > 0) 'mirrors: $mirrors',
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
/// [arrows] at [cellsPerArrow] once [mirrors] have taken theirs.
(int, int) _sizeFor(int arrows, int mirrors) {
  final want = arrows * cellsPerArrow + mirrors;
  for (var width = 10; width < 80; width++) {
    final height = (width * aspect).round();
    if (width * height >= want) return (width, height);
    // Try one row taller before the next width, for a finer step.
    if (width * (height + 1) >= want) return (width, height + 1);
  }
  return (80, (80 * aspect).round());
}
