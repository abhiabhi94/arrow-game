/// The 40 levels. Difficulty climbs on four axes: board size, arrow count,
/// arrow length (long runs cross many exit paths) and how few arrows are
/// playable at once (`openMoves` — the generator keeps the choice that
/// narrow, so from the middle of the game on the player has to hunt for the
/// next move). The curve is steep on purpose — a handful of arrows to learn
/// on, ~60 by level 8, ~145 by level 20 — then keeps climbing four arrows a
/// level to 224 on the 42×63 finale, with the longest runs stretching from
/// 10 to 12 cells along the way. The clock scales with the arrow count:
/// about 4.5 s an arrow on the learning levels, 5.5 s in the middle and
/// 6.5 s from level 10 (plus 45 s of slack), since those boards are meant
/// to be thought about, not raced.
library;

import '../models/level_spec.dart';

const int totalLevels = 40;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3),
  LevelSpec(level: 2, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 5, timeLimitMs: 81000, openMoves: 3),
  LevelSpec(level: 3, width: 7, height: 9, arrows: 12, minLength: 2, maxLength: 6, timeLimitMs: 99000, openMoves: 3),
  LevelSpec(level: 4, width: 8, height: 11, arrows: 17, minLength: 2, maxLength: 6, timeLimitMs: 121000, openMoves: 2),
  LevelSpec(level: 5, width: 10, height: 13, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 177000, openMoves: 2),
  LevelSpec(level: 6, width: 12, height: 16, arrows: 30, minLength: 2, maxLength: 8, timeLimitMs: 210000, openMoves: 2),
  LevelSpec(level: 7, width: 14, height: 20, arrows: 40, minLength: 3, maxLength: 8, timeLimitMs: 265000, openMoves: 2),
  LevelSpec(level: 8, width: 19, height: 26, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 370000, openMoves: 2),
  LevelSpec(level: 9, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 375000, openMoves: 2),
  LevelSpec(level: 10, width: 21, height: 30, arrows: 67, minLength: 3, maxLength: 10, timeLimitMs: 481000, openMoves: 2),
  LevelSpec(level: 11, width: 22, height: 32, arrows: 74, minLength: 3, maxLength: 10, timeLimitMs: 526000, openMoves: 2),
  LevelSpec(level: 12, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 578000, openMoves: 2),
  LevelSpec(level: 13, width: 24, height: 36, arrows: 88, minLength: 3, maxLength: 10, timeLimitMs: 617000, openMoves: 2),
  LevelSpec(level: 14, width: 25, height: 38, arrows: 96, minLength: 3, maxLength: 10, timeLimitMs: 669000, openMoves: 2),
  LevelSpec(level: 15, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 728000, openMoves: 2),
  LevelSpec(level: 16, width: 27, height: 42, arrows: 110, minLength: 3, maxLength: 10, timeLimitMs: 760000, openMoves: 2),
  LevelSpec(level: 17, width: 28, height: 44, arrows: 117, minLength: 3, maxLength: 10, timeLimitMs: 806000, openMoves: 2),
  LevelSpec(level: 18, width: 29, height: 46, arrows: 126, minLength: 3, maxLength: 10, timeLimitMs: 864000, openMoves: 2),
  LevelSpec(level: 19, width: 30, height: 48, arrows: 128, minLength: 3, maxLength: 10, timeLimitMs: 877000, openMoves: 2),
  LevelSpec(level: 20, width: 32, height: 50, arrows: 144, minLength: 3, maxLength: 10, timeLimitMs: 981000, openMoves: 2),
  LevelSpec(level: 21, width: 33, height: 52, arrows: 148, minLength: 3, maxLength: 10, timeLimitMs: 1007000, openMoves: 2),
  LevelSpec(level: 22, width: 33, height: 54, arrows: 152, minLength: 3, maxLength: 10, timeLimitMs: 1033000, openMoves: 2),
  LevelSpec(level: 23, width: 34, height: 54, arrows: 156, minLength: 3, maxLength: 10, timeLimitMs: 1059000, openMoves: 2),
  LevelSpec(level: 24, width: 34, height: 55, arrows: 160, minLength: 3, maxLength: 10, timeLimitMs: 1085000, openMoves: 2),
  LevelSpec(level: 25, width: 35, height: 55, arrows: 164, minLength: 3, maxLength: 11, timeLimitMs: 1111000, openMoves: 2),
  LevelSpec(level: 26, width: 35, height: 56, arrows: 168, minLength: 3, maxLength: 11, timeLimitMs: 1137000, openMoves: 2),
  LevelSpec(level: 27, width: 36, height: 56, arrows: 172, minLength: 3, maxLength: 11, timeLimitMs: 1163000, openMoves: 2),
  LevelSpec(level: 28, width: 36, height: 57, arrows: 176, minLength: 3, maxLength: 11, timeLimitMs: 1189000, openMoves: 2),
  LevelSpec(level: 29, width: 37, height: 57, arrows: 180, minLength: 3, maxLength: 11, timeLimitMs: 1215000, openMoves: 2),
  LevelSpec(level: 30, width: 37, height: 58, arrows: 184, minLength: 3, maxLength: 11, timeLimitMs: 1241000, openMoves: 2),
  LevelSpec(level: 31, width: 38, height: 58, arrows: 188, minLength: 3, maxLength: 11, timeLimitMs: 1267000, openMoves: 2),
  LevelSpec(level: 32, width: 38, height: 59, arrows: 192, minLength: 3, maxLength: 11, timeLimitMs: 1293000, openMoves: 2),
  LevelSpec(level: 33, width: 39, height: 59, arrows: 196, minLength: 3, maxLength: 12, timeLimitMs: 1319000, openMoves: 2),
  LevelSpec(level: 34, width: 39, height: 60, arrows: 200, minLength: 3, maxLength: 12, timeLimitMs: 1345000, openMoves: 2),
  LevelSpec(level: 35, width: 40, height: 60, arrows: 204, minLength: 3, maxLength: 12, timeLimitMs: 1371000, openMoves: 2),
  LevelSpec(level: 36, width: 40, height: 61, arrows: 208, minLength: 3, maxLength: 12, timeLimitMs: 1397000, openMoves: 2),
  LevelSpec(level: 37, width: 41, height: 61, arrows: 212, minLength: 3, maxLength: 12, timeLimitMs: 1423000, openMoves: 2),
  LevelSpec(level: 38, width: 41, height: 62, arrows: 216, minLength: 3, maxLength: 12, timeLimitMs: 1449000, openMoves: 2),
  LevelSpec(level: 39, width: 42, height: 62, arrows: 220, minLength: 3, maxLength: 12, timeLimitMs: 1475000, openMoves: 2),
  LevelSpec(level: 40, width: 42, height: 63, arrows: 224, minLength: 3, maxLength: 12, timeLimitMs: 1500000, openMoves: 2),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
