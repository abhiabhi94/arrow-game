// Prints the `LevelSpec` rows for levels 21–250 — the four chapters past the
// plain rectangle, the Rush after them, and the two chapters of fifty on the
// block after that — so the
// table in lib/data/level_specs.dart is drawn from one set of rules rather
// than tuned a row at a time:
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

// **Levels 101–150** are the Rush: the plain rectangle of levels 1–100,
// but the board does not only empty — new arrows land on it while it is
// played, a few at a time packed into a small shape (`LevelDrops`), and
// from level 126 blocks land with them and stay. Each half opens on a
// small teaching board and climbs for twenty-four levels: more arrows at
// the start ([rushStart] → +2 a level), more drops (one more every two
// levels) and bigger ones. The board starts about half full (the gaps are
// where the drops land), sized like a flat board at [cellsPerArrow] free
// cells an arrow, plus room for the blocks. The clock is [rushPace] a
// arrow, every arrow the drops bring counted, and the drops are spread
// over a little more than half of it, never more than twelve seconds
// apart — and a drop lands at once when the board is nearly empty, so a
// quick player never waits for the next.

import 'dart:math';

import 'package:arrow_game/data/level_specs.dart' show kClockTrim;

const int firstLevel = 21;
const int lastLevel = 100;

/// Arrows on the board at the start of the Rush's second level.
const int rushStart = 24;

/// Seconds an arrow in the Rush, the drops' arrows counted.
const double rushPace = 3.0;

/// Seconds an arrow on the block, before the twists' own seconds.
const double cubePace = 2.4;

/// Faces on the block.
const int faces = 6;

/// Free cells a face of the block is sized to offer per arrow: a little
/// tighter than a flat board, since a face is a small board with few arrows
/// on it, and at the flat boards' room the first faces came out a third
/// empty.
const double cubeCellsPerArrow = 9.5;


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
    // Never a clock over ten minutes, and every clock trimmed to kClockTrim.
    final timeLimitMs = (min((seconds * 1000).round(), 599000) * kClockTrim).round();

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
  for (var level = 101; level <= 150; level++) {
    _rush(level);
  }
  for (var level = 151; level <= 200; level++) {
    _squeeze(level);
  }
  for (var level = 201; level <= 250; level++) {
    _box(level);
  }
}

void _rush(int level) {
  final k = level - 100; // 1..50
  final withBlocks = k > 25;
  final i = withBlocks ? k - 25 : k; // 1..25 within the half
  final teach = i == 1;
  final arrows = teach ? 8 : rushStart + (i - 2) * 2;
  final count = teach ? 4 : 5 + (i - 2) ~/ 2;
  final perDrop = teach ? 2 : 3 + (i >= 14 ? 1 : 0);
  final blocks = !withBlocks ? 0 : (teach ? 1 : 1 + (i >= 13 ? 1 : 0));
  final dropLength = teach ? 3 : 4 + (i >= 10 ? 1 : 0);
  final minLength = teach ? 2 : 3;
  final maxLength = teach ? 4 : 7 + i ~/ 8;
  final (width, height) = teach ? (withBlocks ? (9, 12) : (8, 11)) : _sizeFor(arrows, blocks * count);
  final total = arrows + count * perDrop;
  final seconds = total * (teach ? 3.5 : rushPace) + (teach ? 30.0 : 20.0);
  final timeLimitMs = (min((seconds * 1000).round(), 599000) * kClockTrim).round();
  final everyMs = ((timeLimitMs * 0.55 / count / 500).round() * 500).clamp(4000, 12000);
  final openMoves = teach ? 3 : 2;
  final blockText = blocks > 0 ? ', blocks: $blocks' : '';
  // ignore: avoid_print
  print(
    '  LevelSpec(level: $level, width: $width, height: $height, arrows: $arrows, '
    'minLength: $minLength, maxLength: $maxLength, timeLimitMs: $timeLimitMs, openMoves: $openMoves, '
    'drops: LevelDrops(count: $count, everyMs: $everyMs, arrows: $perDrop$blockText, maxLength: $dropLength)),',
  );
}

/// Arrows on the block at the end of the squeeze, from level 150's 177.
const int squeezeTop = 200;

/// Levels 151–200, the squeeze: the block again, with one way out of each
/// face at a time (`openMoves` 1) where the block let two. A short warm-up
/// — a small teaching cube with no twists, then three levels on faces of
/// twenty, twenty-five and twenty-eight arrows with all four twists — and
/// from level 155 a little more than level 150's block (177 arrows and its
/// twists), taking turns: one level gains an arrow, the next a twist
/// (mirrors, locks, hidden heads, pairs in turn), to [squeezeTop] arrows,
/// so every level holds a little more than the one before. A face never
/// holds more than thirty-four arrows. The clock is the block's rule; past
/// the warm-up it runs at the ten-minute cap, so the extra work is what
/// gets harder, not the room to do it.
void _squeeze(int level) {
  final k = level - 150; // 1..50 in the chapter
  final teach = k == 1;
  final on = max(0, k - 5); // 0..45 past the warm-up
  final arrows = switch (k) {
    1 => 6 * faces,
    2 => 20 * faces,
    3 => 25 * faces,
    4 => 28 * faces,
    _ => 178 + on ~/ 2,
  };
  assert(arrows <= squeezeTop);
  final perFace = (arrows / faces).ceil();

  // Level 150 holds 30 mirrors, 12 locks, 11 hidden heads and 11 pairs;
  // the warm-up holds one of each (two mirrors) a face, and from level 155
  // every other level steps one twist up, round the four in turn.
  final int mirrors, locks, hidden, pairs;
  if (teach) {
    (mirrors, locks, hidden, pairs) = (0, 0, 0, 0);
  } else if (k < 5) {
    (mirrors, locks, hidden, pairs) = (2 * faces + (k - 2) * 3, faces, faces, faces);
  } else {
    // Twist steps taken so far: one on every odd level past 155.
    final steps = (on + 1) ~/ 2;
    int taken(int twist) => steps <= twist ? 0 : (steps - twist + 3) ~/ 4;
    mirrors = 30 + 2 * taken(0);
    locks = 12 + taken(1);
    hidden = 11 + taken(2);
    pairs = 11 + taken(3);
  }
  final mirrorsPerFace = (mirrors / faces).ceil();
  final side = teach ? 8 : sqrt(perFace * cubeCellsPerArrow + mirrorsPerFace).round();
  final minLength = side < 10 ? 2 : 3;
  final maxLength = teach ? 5 : min(15, max(5, side - 1));
  final slack = (teach ? 25.0 : 15.0) + 2.0 * faces;
  final think = mirrors * 1.0 + locks * 4.0 + hidden * 3.0 + pairs * 3.0;
  final seconds = arrows * (teach ? 3.0 : cubePace) + slack + think;
  final timeLimitMs = (min((seconds * 1000).round(), 599000) * kClockTrim).round();
  _print(level, side, side, arrows, minLength, maxLength, timeLimitMs, 1, mirrors, locks, hidden, pairs, faces);
}

/// The proportions of the box, width : height : depth, level by level
/// round the list: mostly taller than wide, since a phone screen is, and a
/// different shape every level so no two in a row fold up the same.
const List<(int, int, int)> boxShapes = <(int, int, int)>[
  (3, 4, 2),
  (3, 5, 2),
  (2, 4, 3),
  (4, 5, 2),
  (3, 4, 3),
];

/// Levels 201–250, the box: the block is no longer a cube but a box — six
/// faces of three sizes, front and back, two sides, top and bottom — each
/// face a board as big as its share of the box, so the faces are bigger
/// than the cube's and differ in shape, and the block is drawn to fill the
/// stage. A small teaching box with no twists, three warm-up levels on
/// 100, 140 and 170 arrows with every twist, then from level 205 a little
/// under level 200's count (190) with two ways out of a face again
/// (`openMoves` 2, where the squeeze had one) — the bigger, uneven faces
/// are the new work, so the hunt itself is let off a little — gaining an
/// arrow every third level to 205 and a twist on the levels between
/// (mirrors by two, locks, hidden heads, pairs in turn), so every level
/// holds a little more than the one before. The clock is the block's rule,
/// at the cap past the warm-up.
void _box(int level) {
  final k = level - 200; // 1..50 in the chapter
  final teach = k == 1;
  final on = max(0, k - 5); // 0..45 past the warm-up
  final arrows = switch (k) {
    1 => 24,
    2 => 100,
    3 => 140,
    4 => 170,
    _ => 190 + (on + 2) ~/ 3,
  };
  final int mirrors, locks, hidden, pairs;
  if (teach) {
    (mirrors, locks, hidden, pairs) = (0, 0, 0, 0);
  } else if (k < 5) {
    (mirrors, locks, hidden, pairs) = (2 * faces + (k - 2) * 6, faces + k - 2, faces + k - 2, faces + k - 2);
  } else {
    // Twist steps so far: one on every level that did not gain an arrow.
    final steps = on - (arrows - 190);
    int taken(int twist) => steps <= twist ? 0 : (steps - twist + 3) ~/ 4;
    mirrors = 40 + 2 * taken(0);
    locks = 16 + taken(1);
    hidden = 15 + taken(2);
    pairs = 15 + taken(3);
  }
  // The box's shape, scaled so its six faces hold ~9.5 free cells an arrow
  // beside the mirrors.
  final (rx, ry, rz) = teach ? boxShapes.first : boxShapes[k % boxShapes.length];
  final area = arrows * cubeCellsPerArrow + mirrors;
  final unit = sqrt(area / (2 * (rx * ry + ry * rz + rx * rz)));
  final (w, h, d) = ((rx * unit).round(), (ry * unit).round(), (rz * unit).round());
  final shortest = min(w, min(h, d));
  final minLength = shortest < 8 ? 2 : 3;
  final maxLength = min(shortest - 1, teach ? 4 : min(14, max(5, shortest - 1)));
  final slack = (teach ? 25.0 : 15.0) + 2.0 * faces;
  final think = mirrors * 1.0 + locks * 4.0 + hidden * 3.0 + pairs * 3.0;
  final seconds = arrows * (teach ? 3.0 : cubePace) + slack + think;
  final timeLimitMs = (min((seconds * 1000).round(), 599000) * kClockTrim).round();
  _print(level, w, h, arrows, minLength, maxLength, timeLimitMs, teach ? 3 : 2, mirrors, locks, hidden, pairs, faces,
      depth: d);
}

void _print(int level, int width, int height, int arrows, int minLength, int maxLength, int timeLimitMs,
    int openMoves, int mirrors, int locks, int hidden, int pairs, int faces, {int depth = 0}) {
  final features = <String>[
    if (mirrors > 0) 'mirrors: $mirrors',
    if (locks > 0) 'locks: $locks',
    if (hidden > 0) 'hidden: $hidden',
    if (pairs > 0) 'pairs: $pairs',
  ];
  final featureText = features.isEmpty ? '' : ', features: LevelFeatures(${features.join(', ')})';
  final faceText = (faces > 0 ? ', faces: $faces' : '') + (depth > 0 ? ', depth: $depth' : '');
  // ignore: avoid_print
  print(
    '  LevelSpec(level: $level, width: $width, height: $height, arrows: $arrows, '
    'minLength: $minLength, maxLength: $maxLength, timeLimitMs: $timeLimitMs, openMoves: $openMoves$featureText$faceText),',
  );
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
