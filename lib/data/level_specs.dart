/// The 60 levels. Difficulty climbs on four axes: board size, arrow count,
/// arrow length (long runs cross many exit paths) and how few arrows are
/// playable at once (`openMoves` — the generator keeps the choice that
/// narrow, so from the middle of the game on the player has to hunt for the
/// next move). The curve is steep on purpose — a handful of arrows to learn
/// on, ~60 by level 8, ~145 by level 20 — then keeps climbing four arrows a
/// level to 224 on the 42×63 level 40, with the longest runs stretching
/// from 10 to 12 cells along the way.
///
/// Levels 41–60 keep that four-an-arrow climb to 304 on the 47×73 finale,
/// but the board barely grows with them: it goes from 42×63 to 47×73 while
/// the arrow count rises by a third, so the cells an arrow falls from ~11.8
/// to ~11.3 and the fill from ~0.87 to ~0.90. The endgame is a *tighter*
/// board, not just a bigger one — fewer empty cells to slide through, more
/// arrows across every exit path — and the longest runs stretch on to 14
/// cells, each one crossing that much more of the board.
///
/// The clock scales with the arrow count: about 1.7 s an arrow on the
/// learning levels, 2.1 s in the middle and 2.5 s from level 10 (plus ~17 s
/// of slack) — brisk on purpose, so a level is a sprint of quick reads
/// rather than a long sit. Every level's clock was cut by 5% after the
/// curve was first drawn, so the numbers here are 95% of the ones the
/// shape was worked out with. The last levels are long in absolute terms
/// (just under 13 minutes on the finale) simply because there are 300
/// arrows to read;
/// the pace per arrow never slackens, and the saved-game slot means a long
/// board can be put down and picked up.
library;

import '../models/level_spec.dart';

const int totalLevels = 60;

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
  LevelSpec(level: 21, width: 33, height: 52, arrows: 148, minLength: 3, maxLength: 10, timeLimitMs: 383000, openMoves: 2),
  LevelSpec(level: 22, width: 33, height: 54, arrows: 152, minLength: 3, maxLength: 10, timeLimitMs: 392000, openMoves: 2),
  LevelSpec(level: 23, width: 34, height: 54, arrows: 156, minLength: 3, maxLength: 10, timeLimitMs: 403000, openMoves: 2),
  LevelSpec(level: 24, width: 34, height: 55, arrows: 160, minLength: 3, maxLength: 10, timeLimitMs: 412000, openMoves: 2),
  LevelSpec(level: 25, width: 35, height: 55, arrows: 164, minLength: 3, maxLength: 11, timeLimitMs: 422000, openMoves: 2),
  LevelSpec(level: 26, width: 35, height: 56, arrows: 168, minLength: 3, maxLength: 11, timeLimitMs: 432000, openMoves: 2),
  LevelSpec(level: 27, width: 36, height: 56, arrows: 172, minLength: 3, maxLength: 11, timeLimitMs: 442000, openMoves: 2),
  LevelSpec(level: 28, width: 36, height: 57, arrows: 176, minLength: 3, maxLength: 11, timeLimitMs: 452000, openMoves: 2),
  LevelSpec(level: 29, width: 37, height: 57, arrows: 180, minLength: 3, maxLength: 11, timeLimitMs: 462000, openMoves: 2),
  LevelSpec(level: 30, width: 37, height: 58, arrows: 184, minLength: 3, maxLength: 11, timeLimitMs: 471000, openMoves: 2),
  LevelSpec(level: 31, width: 38, height: 58, arrows: 188, minLength: 3, maxLength: 11, timeLimitMs: 482000, openMoves: 2),
  LevelSpec(level: 32, width: 38, height: 59, arrows: 192, minLength: 3, maxLength: 11, timeLimitMs: 491000, openMoves: 2),
  LevelSpec(level: 33, width: 39, height: 59, arrows: 196, minLength: 3, maxLength: 12, timeLimitMs: 502000, openMoves: 2),
  LevelSpec(level: 34, width: 39, height: 60, arrows: 200, minLength: 3, maxLength: 12, timeLimitMs: 511000, openMoves: 2),
  LevelSpec(level: 35, width: 40, height: 60, arrows: 204, minLength: 3, maxLength: 12, timeLimitMs: 521000, openMoves: 2),
  LevelSpec(level: 36, width: 40, height: 61, arrows: 208, minLength: 3, maxLength: 12, timeLimitMs: 531000, openMoves: 2),
  LevelSpec(level: 37, width: 41, height: 61, arrows: 212, minLength: 3, maxLength: 12, timeLimitMs: 541000, openMoves: 2),
  LevelSpec(level: 38, width: 41, height: 62, arrows: 216, minLength: 3, maxLength: 12, timeLimitMs: 551000, openMoves: 2),
  LevelSpec(level: 39, width: 42, height: 62, arrows: 220, minLength: 3, maxLength: 12, timeLimitMs: 560000, openMoves: 2),
  LevelSpec(level: 40, width: 42, height: 63, arrows: 224, minLength: 3, maxLength: 12, timeLimitMs: 570000, openMoves: 2),
  LevelSpec(level: 41, width: 42, height: 64, arrows: 228, minLength: 3, maxLength: 12, timeLimitMs: 580000, openMoves: 2),
  LevelSpec(level: 42, width: 42, height: 64, arrows: 232, minLength: 3, maxLength: 12, timeLimitMs: 590000, openMoves: 2),
  LevelSpec(level: 43, width: 42, height: 64, arrows: 236, minLength: 3, maxLength: 12, timeLimitMs: 600000, openMoves: 2),
  LevelSpec(level: 44, width: 42, height: 64, arrows: 240, minLength: 3, maxLength: 12, timeLimitMs: 610000, openMoves: 2),
  LevelSpec(level: 45, width: 42, height: 65, arrows: 244, minLength: 3, maxLength: 12, timeLimitMs: 619000, openMoves: 2),
  LevelSpec(level: 46, width: 42, height: 65, arrows: 248, minLength: 3, maxLength: 13, timeLimitMs: 630000, openMoves: 2),
  LevelSpec(level: 47, width: 43, height: 65, arrows: 252, minLength: 3, maxLength: 13, timeLimitMs: 639000, openMoves: 2),
  LevelSpec(level: 48, width: 43, height: 66, arrows: 256, minLength: 3, maxLength: 13, timeLimitMs: 650000, openMoves: 2),
  LevelSpec(level: 49, width: 44, height: 66, arrows: 260, minLength: 3, maxLength: 13, timeLimitMs: 659000, openMoves: 2),
  LevelSpec(level: 50, width: 45, height: 66, arrows: 264, minLength: 3, maxLength: 13, timeLimitMs: 669000, openMoves: 2),
  LevelSpec(level: 51, width: 45, height: 66, arrows: 268, minLength: 3, maxLength: 13, timeLimitMs: 679000, openMoves: 2),
  LevelSpec(level: 52, width: 45, height: 67, arrows: 272, minLength: 3, maxLength: 13, timeLimitMs: 689000, openMoves: 2),
  LevelSpec(level: 53, width: 45, height: 68, arrows: 276, minLength: 3, maxLength: 14, timeLimitMs: 699000, openMoves: 2),
  LevelSpec(level: 54, width: 46, height: 68, arrows: 280, minLength: 3, maxLength: 14, timeLimitMs: 709000, openMoves: 2),
  LevelSpec(level: 55, width: 46, height: 68, arrows: 284, minLength: 3, maxLength: 14, timeLimitMs: 718000, openMoves: 2),
  LevelSpec(level: 56, width: 46, height: 69, arrows: 288, minLength: 3, maxLength: 14, timeLimitMs: 729000, openMoves: 2),
  LevelSpec(level: 57, width: 46, height: 70, arrows: 292, minLength: 3, maxLength: 14, timeLimitMs: 738000, openMoves: 2),
  LevelSpec(level: 58, width: 46, height: 71, arrows: 296, minLength: 3, maxLength: 14, timeLimitMs: 749000, openMoves: 2),
  LevelSpec(level: 59, width: 47, height: 72, arrows: 300, minLength: 3, maxLength: 14, timeLimitMs: 758000, openMoves: 2),
  LevelSpec(level: 60, width: 47, height: 73, arrows: 304, minLength: 3, maxLength: 14, timeLimitMs: 770000, openMoves: 2),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
