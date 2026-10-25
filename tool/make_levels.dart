// Prints the `LevelSpec` rows for levels 11–100 — the four flat chapters
// past the plain rectangle and the fifty levels on the block — so the table
// in lib/data/level_specs.dart is drawn from one set of rules rather than
// tuned a row at a time:
//
//   dart run tool/make_levels.dart > /tmp/rows.dart
//
// **Levels 11–50** are four chapters of ten, each on one new twist (Mirrors,
// Locks, Fog, Pairs) stacked on the ones before it, and every chapter has
// the same shape:
//
//   level  1     a small, roomy teaching board with the new twist alone
//   levels 2–10  the climb: [climbStart] arrows at the second level,
//                [climbEnd] at the tenth, a steady step between, and the
//                chapter's own twist thickening along the way
//
// A board is sized so the cells an arrow may use (the rectangle less its
// mirrors) come to ~11.3 per arrow, which the generator fills to ~0.88.
//
// **Levels 51–100** are the block: six square faces, each a board of its
// own, played one at a time. The first is a teaching cube (three arrows a
// face); then the count climbs steadily from [cubeStart] to [cubeEnd] over
// the forty-nine levels after it, and the twists come back onto the faces
// ten levels at a time — plain faces to 60, mirrors from 61, locks from
// 71, hidden heads from 81, pairs from 91 — each thickening through its
// own ten and staying after. So every level on the block is a little more
// than the one before: a few more arrows, and every tenth level one more
// thing to read.
//
// The clock is a pace per arrow that *grows* chapter by chapter — a mirror,
// a lock, a hidden head or a tether is one more thing to read on every
// arrow — plus a few seconds for every one of them on the board, plus
// slack (and on the block, two seconds a face for turning it), and never
// over ten minutes. Teaching boards run at 3 s an arrow.

import 'dart:math';

/// Arrows on a flat chapter's second level and on its tenth.
const int climbStart = 30;
const int climbEnd = 120;

/// Seconds an arrow, by flat chapter (index 1 = Mirrors … 4 = Pairs).
const List<double> pace = <double>[0, 3.0, 3.2, 3.3, 3.4];

/// Arrows on the block's second level and on its last.
const int cubeStart = 30;
const int cubeEnd = 144;

/// Faces on the block.
const int faces = 6;

/// Free cells the board is sized to offer per arrow.
const double cellsPerArrow = 11.3;

/// The same on a face of the block, a little tighter: a face is a small
/// board with few arrows on it, and at the flat boards' room the first
/// faces came out a third empty.
const double cubeCellsPerArrow = 9.5;

/// Height over width of a board.
const double aspect = 1.52;

void main() {
  for (var level = 11; level <= 50; level++) {
    _flat(level);
  }
  for (var level = 51; level <= 100; level++) {
    _cube(level);
  }
}

void _flat(int level) {
  final chapter = (level - 1) ~/ 10; // 1 = Mirrors, 2 = Locks, 3 = Fog, 4 = Pairs
  final i = level - (chapter * 10); // 1..10 within the chapter
  final teach = i == 1;

  // Arrow count: the teaching board, then a straight climb.
  final arrows = teach ? 12 : (climbStart + (climbEnd - climbStart) * (i - 2) / 8).round();

  // Twists: the chapter's own climbs through it; earlier chapters' stay
  // at a steady few. Teaching boards carry a few of the new one, nothing
  // else.
  final climb = 2 + (i - 2) ~/ 2; // 2..6 over the chapter
  var locks = 0, hidden = 0, pairs = 0;
  if (teach) {
    if (chapter == 2) locks = 2;
    if (chapter == 3) hidden = 2;
    if (chapter == 4) pairs = 2;
  } else {
    if (chapter == 2) locks = climb;
    if (chapter >= 3) locks = 3;
    if (chapter == 3) hidden = climb;
    if (chapter >= 4) hidden = 3;
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
  final maxLength = teach ? 5 : 10 + chapter + (i >= 7 ? 1 : 0);

  // Board size: enough free cells for the arrows beside the mirrors.
  final (width, height) = teach ? (10, 13) : _sizeFor(arrows, mirrors);

  // Clock.
  final slack = teach ? 25.0 : 15.0;
  final think = mirrors * 1.0 + locks * 4.0 + hidden * 3.0 + pairs * 3.0;
  final seconds = arrows * (teach ? 3.0 : pace[chapter]) + slack + think;
  final timeLimitMs = min((seconds * 1000).round(), 599000);

  // A teaching board is roomy on purpose — three moves open at a time —
  // so there is always a plain tap to make while the new piece is studied.
  final openMoves = teach ? 3 : 2;
  _print(level, width, height, arrows, minLength, maxLength, timeLimitMs, openMoves, mirrors, locks, hidden, pairs, 0);
}

void _cube(int level) {
  final k = level - 50; // 1..50 on the block
  final teach = k == 1;
  // Which twists are back on the faces: 0 plain, 1 mirrors, 2 locks,
  // 3 hidden heads, 4 pairs — ten levels each, the teaching cube plain.
  final stage = teach ? 0 : (k - 1) ~/ 10;
  // How far into its own ten the newest twist is: 0..9.
  final into = teach ? 0 : (k - 1) % 10;

  final arrows = teach ? 3 * faces : (cubeStart + (cubeEnd - cubeStart) * (k - 2) / 48).round();
  final perFace = (arrows / faces).ceil();

  final own = faces + into ~/ 3; // one a face, thickening to 9 over the ten
  final mirrors = stage >= 1 ? max(faces, (arrows / (stage == 1 ? 8 : 12)).round()) : 0;
  final locks = stage == 2 ? own : (stage > 2 ? faces : 0);
  final hidden = stage == 3 ? own : (stage > 3 ? faces : 0);
  final pairs = stage == 4 ? own : 0;

  // A face is square, sized like the flat boards but a little tighter:
  // ~9.5 free cells an arrow beside its share of the mirrors.
  final side = teach ? 6 : sqrt(perFace * cubeCellsPerArrow + (mirrors / faces).ceil()).round();
  final minLength = side < 10 ? 2 : 3;
  final maxLength = teach ? 4 : min(12, max(5, side - 1));

  // The clock: the flat chapters' last pace and a little more for every
  // twist that has come back, the twists' seconds, and two seconds a face
  // for turning the block.
  final slack = (teach ? 25.0 : 15.0) + 2.0 * faces;
  final think = mirrors * 1.0 + locks * 4.0 + hidden * 3.0 + pairs * 3.0;
  final seconds = arrows * (teach ? 3.0 : 3.3 + 0.05 * stage) + slack + think;
  final timeLimitMs = min((seconds * 1000).round(), 599000);
  final openMoves = teach ? 3 : 2;
  _print(level, side, side, arrows, minLength, maxLength, timeLimitMs, openMoves, mirrors, locks, hidden, pairs, faces);
}

void _print(int level, int width, int height, int arrows, int minLength, int maxLength, int timeLimitMs,
    int openMoves, int mirrors, int locks, int hidden, int pairs, int faces) {
  final features = <String>[
    if (mirrors > 0) 'mirrors: $mirrors',
    if (locks > 0) 'locks: $locks',
    if (hidden > 0) 'hidden: $hidden',
    if (pairs > 0) 'pairs: $pairs',
  ];
  final featureText = features.isEmpty ? '' : ', features: LevelFeatures(${features.join(', ')})';
  final faceText = faces > 0 ? ', faces: $faces' : '';
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
