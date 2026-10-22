/// The 100 levels, in five chapters of twenty (`data/chapters.dart`).
///
/// **Levels 1–20** are the plain rectangle: one rule, the board growing
/// every level from 5 arrows on 5×6 to 144 on 32×50, with the clock brisk
/// (~1.7 s an arrow early, 2.5 s from level 10) so a level is a sprint of
/// quick reads. Untouched since the first release.
///
/// **Levels 21–100** are drawn by `tool/make_levels.dart` from one set of
/// rules, after the first hundred turned out to be the same level played
/// eighty times: from level 20 nothing changed but the count, which
/// climbed to 464 arrows and a fifteen-minute read. Now each chapter brings
/// one twist and keeps the ones before it — shaped boards (walls are holes
/// an arrow falls into), locks (an arrow waits for its numbered key),
/// hidden heads (shown once a neighbour leaves), tethered pairs (one tap,
/// two arrows) — and every chapter has the same rhythm: a small, roomy
/// teaching board first (12 arrows, the new twist alone, three moves open
/// at a time, and an illustrated card over it on the first visit), a sprint
/// on a 12×16 board at levels 5 and 15 of the chapter, a boss at 10 and a
/// finale at 20 with more of everything, and a climb between them that
/// grows by one arrow a level, ~150 at level 22 to ~230 at level 99. The
/// finales run to ~265 and the longest clock is a shade under ten minutes:
/// the late levels are long because there is a lot to read, not because the
/// read never changes.
///
/// The board is sized so the cells an arrow may use — the rectangle less
/// the shape's walls — come to ~11.3 an arrow, which the generator fills to
/// ~0.88. The clock is a pace per arrow (2.4 s in Shapes, easing to 2.0 s in
/// Pairs) plus a few seconds for every lock, hidden head and tether on the
/// board, since each is a thing to look for, plus slack; sprints run at
/// 1.6 s an arrow, teaching boards at 3 s. Settings → Extra time doubles
/// all of it.
///
/// Every level is dealt from the first [LevelSpec.variant] whose board keeps
/// every rule the tests pin — the full count, every twist placed, the
/// player's choice held within the generator's slack at the start and at
/// its widest — found by `tool/pick_variants.dart`; re-run it after
/// touching the table or the generator, and write its picks in here.
library;

import '../engine/board_shape.dart';
import '../models/level_spec.dart';

const int totalLevels = 100;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 26000, openMoves: 3),
  LevelSpec(level: 2, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 5, timeLimitMs: 30000, openMoves: 3),
  LevelSpec(level: 3, width: 7, height: 9, arrows: 12, minLength: 2, maxLength: 6, timeLimitMs: 38000, openMoves: 3),
  LevelSpec(level: 4, width: 8, height: 11, arrows: 17, minLength: 2, maxLength: 6, timeLimitMs: 46000, openMoves: 2),
  LevelSpec(level: 5, width: 10, height: 13, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 67000, openMoves: 2),
  LevelSpec(level: 6, width: 12, height: 16, arrows: 30, minLength: 2, maxLength: 8, timeLimitMs: 80000, openMoves: 2),
  LevelSpec(level: 7, width: 14, height: 20, arrows: 40, minLength: 3, maxLength: 8, timeLimitMs: 101000, openMoves: 2),
  LevelSpec(level: 8, width: 19, height: 26, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 141000, openMoves: 2),
  LevelSpec(level: 9, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 142000, openMoves: 2),
  LevelSpec(level: 10, width: 21, height: 30, arrows: 67, minLength: 3, maxLength: 10, timeLimitMs: 182000, openMoves: 2),
  LevelSpec(level: 11, width: 22, height: 32, arrows: 74, minLength: 3, maxLength: 10, timeLimitMs: 200000, openMoves: 2),
  LevelSpec(level: 12, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 219000, openMoves: 2),
  LevelSpec(level: 13, width: 24, height: 36, arrows: 88, minLength: 3, maxLength: 10, timeLimitMs: 235000, openMoves: 2),
  LevelSpec(level: 14, width: 25, height: 38, arrows: 96, minLength: 3, maxLength: 10, timeLimitMs: 255000, openMoves: 2),
  LevelSpec(level: 15, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 276000, openMoves: 2),
  LevelSpec(level: 16, width: 27, height: 42, arrows: 110, minLength: 3, maxLength: 10, timeLimitMs: 289000, openMoves: 2),
  LevelSpec(level: 17, width: 28, height: 44, arrows: 117, minLength: 3, maxLength: 10, timeLimitMs: 306000, openMoves: 2),
  LevelSpec(level: 18, width: 29, height: 46, arrows: 126, minLength: 3, maxLength: 10, timeLimitMs: 329000, openMoves: 2),
  LevelSpec(level: 19, width: 30, height: 48, arrows: 128, minLength: 3, maxLength: 10, timeLimitMs: 333000, openMoves: 2),
  LevelSpec(level: 20, width: 32, height: 50, arrows: 144, minLength: 3, maxLength: 10, timeLimitMs: 372000, openMoves: 2),
  LevelSpec(level: 21, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 61000, openMoves: 3, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 22, width: 34, height: 52, arrows: 150, minLength: 3, maxLength: 11, timeLimitMs: 375000, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars)),
  LevelSpec(level: 23, width: 36, height: 55, arrows: 151, minLength: 3, maxLength: 11, timeLimitMs: 377400, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 24, width: 36, height: 55, arrows: 152, minLength: 3, maxLength: 11, timeLimitMs: 379800, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole)),
  LevelSpec(level: 25, width: 12, height: 16, arrows: 20, minLength: 2, maxLength: 7, timeLimitMs: 40000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross)),
  LevelSpec(level: 26, width: 35, height: 53, arrows: 154, minLength: 3, maxLength: 11, timeLimitMs: 384600, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars)),
  LevelSpec(level: 27, width: 36, height: 55, arrows: 155, minLength: 3, maxLength: 11, timeLimitMs: 387000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 28, width: 36, height: 55, arrows: 156, minLength: 3, maxLength: 11, timeLimitMs: 389400, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole)),
  LevelSpec(level: 29, width: 39, height: 59, arrows: 157, minLength: 3, maxLength: 11, timeLimitMs: 391800, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross)),
  LevelSpec(level: 30, width: 37, height: 56, arrows: 174, minLength: 3, maxLength: 11, timeLimitMs: 432600, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars)),
  LevelSpec(level: 31, width: 37, height: 56, arrows: 159, minLength: 3, maxLength: 11, timeLimitMs: 396600, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 32, width: 37, height: 56, arrows: 160, minLength: 3, maxLength: 12, timeLimitMs: 399000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole)),
  LevelSpec(level: 33, width: 40, height: 61, arrows: 161, minLength: 3, maxLength: 12, timeLimitMs: 401400, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross), variant: 1),
  LevelSpec(level: 34, width: 36, height: 55, arrows: 162, minLength: 3, maxLength: 12, timeLimitMs: 403800, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars)),
  LevelSpec(level: 35, width: 12, height: 16, arrows: 20, minLength: 2, maxLength: 7, timeLimitMs: 40000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 36, width: 37, height: 56, arrows: 164, minLength: 3, maxLength: 12, timeLimitMs: 408600, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole)),
  LevelSpec(level: 37, width: 40, height: 62, arrows: 165, minLength: 3, maxLength: 12, timeLimitMs: 411000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross), variant: 2),
  LevelSpec(level: 38, width: 36, height: 55, arrows: 166, minLength: 3, maxLength: 12, timeLimitMs: 413400, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars), variant: 2),
  LevelSpec(level: 39, width: 38, height: 58, arrows: 167, minLength: 3, maxLength: 12, timeLimitMs: 415800, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners)),
  LevelSpec(level: 40, width: 40, height: 62, arrows: 194, minLength: 3, maxLength: 12, timeLimitMs: 480600, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole)),
  LevelSpec(level: 41, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 69000, openMoves: 3, features: LevelFeatures(locks: 2)),
  LevelSpec(level: 42, width: 38, height: 58, arrows: 171, minLength: 4, maxLength: 12, timeLimitMs: 407750, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 2)),
  LevelSpec(level: 43, width: 38, height: 58, arrows: 172, minLength: 4, maxLength: 12, timeLimitMs: 410000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 2)),
  LevelSpec(level: 44, width: 41, height: 63, arrows: 173, minLength: 4, maxLength: 12, timeLimitMs: 412250, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 2)),
  LevelSpec(level: 45, width: 12, height: 16, arrows: 22, minLength: 2, maxLength: 7, timeLimitMs: 51200, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 2)),
  LevelSpec(level: 46, width: 38, height: 59, arrows: 175, minLength: 4, maxLength: 12, timeLimitMs: 420750, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3), variant: 1),
  LevelSpec(level: 47, width: 38, height: 59, arrows: 176, minLength: 4, maxLength: 12, timeLimitMs: 423000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3)),
  LevelSpec(level: 48, width: 42, height: 64, arrows: 177, minLength: 4, maxLength: 12, timeLimitMs: 429250, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 4)),
  LevelSpec(level: 49, width: 37, height: 57, arrows: 178, minLength: 4, maxLength: 12, timeLimitMs: 431500, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 4)),
  LevelSpec(level: 50, width: 41, height: 62, arrows: 197, minLength: 4, maxLength: 12, timeLimitMs: 482250, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 6), variant: 1),
  LevelSpec(level: 51, width: 39, height: 59, arrows: 180, minLength: 4, maxLength: 12, timeLimitMs: 440000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 5)),
  LevelSpec(level: 52, width: 42, height: 64, arrows: 181, minLength: 4, maxLength: 13, timeLimitMs: 442250, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 5)),
  LevelSpec(level: 53, width: 38, height: 58, arrows: 182, minLength: 4, maxLength: 13, timeLimitMs: 444500, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 5)),
  LevelSpec(level: 54, width: 39, height: 60, arrows: 183, minLength: 4, maxLength: 13, timeLimitMs: 450750, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 6)),
  LevelSpec(level: 55, width: 12, height: 16, arrows: 22, minLength: 2, maxLength: 7, timeLimitMs: 51200, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 2)),
  LevelSpec(level: 56, width: 43, height: 65, arrows: 185, minLength: 4, maxLength: 13, timeLimitMs: 455250, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 6)),
  LevelSpec(level: 57, width: 38, height: 58, arrows: 186, minLength: 4, maxLength: 13, timeLimitMs: 461500, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 7)),
  LevelSpec(level: 58, width: 40, height: 61, arrows: 187, minLength: 4, maxLength: 13, timeLimitMs: 463750, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 7), variant: 1),
  LevelSpec(level: 59, width: 40, height: 61, arrows: 188, minLength: 4, maxLength: 13, timeLimitMs: 466000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 7)),
  LevelSpec(level: 60, width: 46, height: 70, arrows: 217, minLength: 4, maxLength: 13, timeLimitMs: 543250, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 10)),
  LevelSpec(level: 61, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(hidden: 2)),
  LevelSpec(level: 62, width: 40, height: 61, arrows: 191, minLength: 4, maxLength: 13, timeLimitMs: 434100, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 2), variant: 1),
  LevelSpec(level: 63, width: 43, height: 66, arrows: 192, minLength: 4, maxLength: 13, timeLimitMs: 436200, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 2)),
  LevelSpec(level: 64, width: 39, height: 59, arrows: 193, minLength: 4, maxLength: 13, timeLimitMs: 438300, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 2), variant: 1),
  LevelSpec(level: 65, width: 12, height: 16, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 56400, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 1, hidden: 2)),
  LevelSpec(level: 66, width: 40, height: 62, arrows: 195, minLength: 4, maxLength: 13, timeLimitMs: 445500, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 3), variant: 1),
  LevelSpec(level: 67, width: 44, height: 67, arrows: 196, minLength: 4, maxLength: 13, timeLimitMs: 447600, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 3)),
  LevelSpec(level: 68, width: 39, height: 60, arrows: 197, minLength: 4, maxLength: 13, timeLimitMs: 452700, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 4), variant: 2),
  LevelSpec(level: 69, width: 41, height: 63, arrows: 198, minLength: 4, maxLength: 13, timeLimitMs: 454800, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4), variant: 1),
  LevelSpec(level: 70, width: 43, height: 65, arrows: 219, minLength: 4, maxLength: 13, timeLimitMs: 504900, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 6)),
  LevelSpec(level: 71, width: 45, height: 68, arrows: 200, minLength: 4, maxLength: 13, timeLimitMs: 462000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 5)),
  LevelSpec(level: 72, width: 40, height: 61, arrows: 201, minLength: 4, maxLength: 14, timeLimitMs: 464100, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 5), variant: 1),
  LevelSpec(level: 73, width: 42, height: 64, arrows: 202, minLength: 4, maxLength: 14, timeLimitMs: 466200, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 5), variant: 1),
  LevelSpec(level: 74, width: 41, height: 63, arrows: 203, minLength: 4, maxLength: 14, timeLimitMs: 471300, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 6), variant: 1),
  LevelSpec(level: 75, width: 12, height: 16, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 56400, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 1, hidden: 2)),
  LevelSpec(level: 76, width: 40, height: 61, arrows: 205, minLength: 4, maxLength: 14, timeLimitMs: 475500, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 6)),
  LevelSpec(level: 77, width: 42, height: 64, arrows: 206, minLength: 4, maxLength: 14, timeLimitMs: 480600, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 7)),
  LevelSpec(level: 78, width: 42, height: 64, arrows: 207, minLength: 4, maxLength: 14, timeLimitMs: 482700, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 7), variant: 1),
  LevelSpec(level: 79, width: 45, height: 69, arrows: 208, minLength: 4, maxLength: 14, timeLimitMs: 484800, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 7)),
  LevelSpec(level: 80, width: 43, height: 66, arrows: 241, minLength: 4, maxLength: 14, timeLimitMs: 563100, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 10), variant: 7),
  LevelSpec(level: 81, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(pairs: 2), variant: 4),
  LevelSpec(level: 82, width: 46, height: 70, arrows: 212, minLength: 4, maxLength: 14, timeLimitMs: 469000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 4, pairs: 2), variant: 2),
  LevelSpec(level: 83, width: 41, height: 62, arrows: 213, minLength: 4, maxLength: 14, timeLimitMs: 471000, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 84, width: 43, height: 65, arrows: 214, minLength: 4, maxLength: 14, timeLimitMs: 473000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4, pairs: 2), variant: 2),
  LevelSpec(level: 85, width: 12, height: 16, arrows: 26, minLength: 2, maxLength: 7, timeLimitMs: 62600, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 1, hidden: 1, pairs: 2)),
  LevelSpec(level: 86, width: 46, height: 70, arrows: 216, minLength: 4, maxLength: 14, timeLimitMs: 480000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 4, pairs: 3), variant: 2),
  LevelSpec(level: 87, width: 41, height: 63, arrows: 217, minLength: 4, maxLength: 14, timeLimitMs: 482000, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 4, pairs: 3), variant: 12),
  LevelSpec(level: 88, width: 43, height: 65, arrows: 218, minLength: 4, maxLength: 14, timeLimitMs: 487000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4, pairs: 4), variant: 1),
  LevelSpec(level: 89, width: 43, height: 65, arrows: 219, minLength: 4, maxLength: 14, timeLimitMs: 489000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 90, width: 49, height: 74, arrows: 242, minLength: 4, maxLength: 14, timeLimitMs: 541000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 4, pairs: 6), variant: 1),
  LevelSpec(level: 91, width: 42, height: 64, arrows: 221, minLength: 4, maxLength: 14, timeLimitMs: 496000, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 4, pairs: 5), variant: 18),
  LevelSpec(level: 92, width: 43, height: 66, arrows: 222, minLength: 4, maxLength: 15, timeLimitMs: 498000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4, pairs: 5), variant: 6),
  LevelSpec(level: 93, width: 43, height: 66, arrows: 223, minLength: 4, maxLength: 15, timeLimitMs: 500000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 4, pairs: 5), variant: 1),
  LevelSpec(level: 94, width: 47, height: 71, arrows: 224, minLength: 4, maxLength: 15, timeLimitMs: 505000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 4, pairs: 6), variant: 3),
  LevelSpec(level: 95, width: 12, height: 16, arrows: 26, minLength: 2, maxLength: 7, timeLimitMs: 62600, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 1, hidden: 1, pairs: 2), variant: 1),
  LevelSpec(level: 96, width: 44, height: 67, arrows: 226, minLength: 4, maxLength: 15, timeLimitMs: 509000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4, pairs: 6), variant: 2),
  LevelSpec(level: 97, width: 44, height: 67, arrows: 227, minLength: 4, maxLength: 15, timeLimitMs: 514000, openMoves: 2, features: LevelFeatures(shape: BoardShape.hole, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 98, width: 47, height: 71, arrows: 228, minLength: 4, maxLength: 15, timeLimitMs: 516000, openMoves: 2, features: LevelFeatures(shape: BoardShape.cross, locks: 3, hidden: 4, pairs: 7), variant: 3),
  LevelSpec(level: 99, width: 42, height: 65, arrows: 229, minLength: 4, maxLength: 15, timeLimitMs: 518000, openMoves: 2, features: LevelFeatures(shape: BoardShape.pillars, locks: 3, hidden: 4, pairs: 7), variant: 3),
  LevelSpec(level: 100, width: 48, height: 73, arrows: 265, minLength: 4, maxLength: 15, timeLimitMs: 599000, openMoves: 2, features: LevelFeatures(shape: BoardShape.corners, locks: 3, hidden: 4, pairs: 10), variant: 12),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
