/// The 100 levels. Difficulty climbs on four axes: board size, arrow count,
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
/// The count alone did not make those twenty levels harder, though: the
/// generator's tightness plateaus from about level 20, so level 60 was
/// level 41 with more arrows and more time. Three more things climb now:
///
/// * the shortest arrow is 4 cells from level 41 (5 is too many — the
///   generator stops placing the full count), so there are fewer of the
///   short pieces that are quick to read;
/// * the clock tightens from ~2.54 s an arrow at level 41 to 2.30 s at 60,
///   so the limits keep growing but slower than the arrow count;
/// * each level is dealt from the [LevelSpec.variant] whose board came out
///   tightest, picked so the moves open at a typical moment fall level by
///   level (`Puzzle.meanOpenMoves` ~2.5 at 41 to ~2.1 at 60) and no level
///   opens with more than three arrows to tap. `tool/level_report.dart`
///   prints a level's variants; `test/engine/puzzle_generator_test.dart`
///   pins the descent.
///
/// Levels 61–80 are the last act, and the clock is the thing that makes it
/// one. The count keeps climbing four a level to 384 on the 52×84 level 80,
/// the board keeps pace with it (~11.2–11.4 cells an arrow throughout, so
/// the fill stays at 0.9), the longest runs stretch to 16 cells, and
/// every level is dealt from its tightest variant as before. But the pace
/// per arrow, which the endgame had eased from 2.54 s to 2.30 s, falls on
/// from 2.29 s at level 61 to 2.00 s at 80: level 80 gives 12 minutes
/// 48 seconds for 384 arrows where level 60 gave 11 minutes 40 seconds for
/// 304 — eighty more arrows, barely a minute more. The clock no longer
/// keeps up with the board; it is the fifth axis.
///
/// Levels 81–100 are the encore, and they squeeze the clock harder still
/// rather than lengthen it: four more arrows a level to 464 on the 57×92
/// finale (the board keeping pace at ~11.3 cells an arrow), the longest runs
/// stretching to 17 and then 18 cells, every level dealt from a variant
/// whose hunt clears a floor that rises one arrow a level (130 at 81, 149 at
/// 100 — tighter than anything before level 61, and the finale tighter than
/// level 80; a strict neighbour-by-neighbour climb from level 80's lucky
/// deal would take thousands of deals a level) — and the limit grows by only
/// 1.6 seconds a level, from 12:49.6 at level 81 to 13:20 at 100. That is
/// eighty more arrows for half a minute more, so the pace per arrow falls
/// from 1.98 s to 1.72 s.
///
/// The clock scales with the arrow count: about 1.7 s an arrow on the
/// learning levels, 2.1 s in the middle and 2.5 s from level 10 (plus ~17 s
/// of slack) — brisk on purpose, so a level is a sprint of quick reads
/// rather than a long sit. Every level's clock was cut by 5% after the
/// curve was first drawn, so the numbers here are 95% of the ones the
/// shape was worked out with. The last levels are long in absolute terms
/// (11 minutes 40 seconds on level 60, 12 minutes 48 on level 80, 13
/// minutes 20 on the finale) simply because there are 300–460 arrows to
/// read; the pace per arrow never slackens, and the saved-game slot means a
/// long board can be put down and picked up.
library;

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
  LevelSpec(level: 41, width: 42, height: 64, arrows: 228, minLength: 4, maxLength: 12, timeLimitMs: 580000, openMoves: 2, variant: 47),
  LevelSpec(level: 42, width: 42, height: 64, arrows: 232, minLength: 4, maxLength: 12, timeLimitMs: 587000, openMoves: 2, variant: 24),
  LevelSpec(level: 43, width: 42, height: 64, arrows: 236, minLength: 4, maxLength: 12, timeLimitMs: 594000, openMoves: 2, variant: 15),
  LevelSpec(level: 44, width: 42, height: 64, arrows: 240, minLength: 4, maxLength: 12, timeLimitMs: 601000, openMoves: 2, variant: 18),
  LevelSpec(level: 45, width: 42, height: 65, arrows: 244, minLength: 4, maxLength: 12, timeLimitMs: 608000, openMoves: 2, variant: 18),
  LevelSpec(level: 46, width: 42, height: 65, arrows: 248, minLength: 4, maxLength: 13, timeLimitMs: 615000, openMoves: 2, variant: 5),
  LevelSpec(level: 47, width: 43, height: 65, arrows: 252, minLength: 4, maxLength: 13, timeLimitMs: 622000, openMoves: 2, variant: 7),
  LevelSpec(level: 48, width: 43, height: 66, arrows: 256, minLength: 4, maxLength: 13, timeLimitMs: 628000, openMoves: 2, variant: 8),
  LevelSpec(level: 49, width: 44, height: 66, arrows: 260, minLength: 4, maxLength: 13, timeLimitMs: 635000, openMoves: 2, variant: 5),
  LevelSpec(level: 50, width: 45, height: 66, arrows: 264, minLength: 4, maxLength: 13, timeLimitMs: 641000, openMoves: 2, variant: 16),
  LevelSpec(level: 51, width: 45, height: 66, arrows: 268, minLength: 4, maxLength: 13, timeLimitMs: 647000, openMoves: 2, variant: 1),
  LevelSpec(level: 52, width: 45, height: 67, arrows: 272, minLength: 4, maxLength: 13, timeLimitMs: 654000, openMoves: 2, variant: 7),
  LevelSpec(level: 53, width: 45, height: 68, arrows: 276, minLength: 4, maxLength: 14, timeLimitMs: 660000, openMoves: 2, variant: 31),
  LevelSpec(level: 54, width: 46, height: 68, arrows: 280, minLength: 4, maxLength: 14, timeLimitMs: 666000, openMoves: 2, variant: 57),
  LevelSpec(level: 55, width: 46, height: 68, arrows: 284, minLength: 4, maxLength: 14, timeLimitMs: 671000, openMoves: 2, variant: 24),
  LevelSpec(level: 56, width: 46, height: 69, arrows: 288, minLength: 4, maxLength: 14, timeLimitMs: 677000, openMoves: 2, variant: 3),
  LevelSpec(level: 57, width: 46, height: 70, arrows: 292, minLength: 4, maxLength: 14, timeLimitMs: 683000, openMoves: 2, variant: 0),
  LevelSpec(level: 58, width: 46, height: 71, arrows: 296, minLength: 4, maxLength: 14, timeLimitMs: 688000, openMoves: 2, variant: 3),
  LevelSpec(level: 59, width: 47, height: 72, arrows: 300, minLength: 4, maxLength: 14, timeLimitMs: 694000, openMoves: 2, variant: 5),
  LevelSpec(level: 60, width: 47, height: 73, arrows: 304, minLength: 4, maxLength: 14, timeLimitMs: 700000, openMoves: 2, variant: 55),
  LevelSpec(level: 61, width: 47, height: 74, arrows: 308, minLength: 4, maxLength: 14, timeLimitMs: 704000, openMoves: 2, variant: 10),
  LevelSpec(level: 62, width: 48, height: 74, arrows: 312, minLength: 4, maxLength: 14, timeLimitMs: 708000, openMoves: 2, variant: 374),
  LevelSpec(level: 63, width: 48, height: 74, arrows: 316, minLength: 4, maxLength: 14, timeLimitMs: 713000, openMoves: 2, variant: 72),
  LevelSpec(level: 64, width: 48, height: 75, arrows: 320, minLength: 4, maxLength: 14, timeLimitMs: 717000, openMoves: 2, variant: 171),
  LevelSpec(level: 65, width: 49, height: 75, arrows: 324, minLength: 4, maxLength: 15, timeLimitMs: 721000, openMoves: 2, variant: 54),
  LevelSpec(level: 66, width: 49, height: 75, arrows: 328, minLength: 4, maxLength: 15, timeLimitMs: 725000, openMoves: 2, variant: 25),
  LevelSpec(level: 67, width: 49, height: 76, arrows: 332, minLength: 4, maxLength: 15, timeLimitMs: 729000, openMoves: 2, variant: 106),
  LevelSpec(level: 68, width: 50, height: 76, arrows: 336, minLength: 4, maxLength: 15, timeLimitMs: 732000, openMoves: 2, variant: 268),
  LevelSpec(level: 69, width: 50, height: 76, arrows: 340, minLength: 4, maxLength: 15, timeLimitMs: 736000, openMoves: 2, variant: 156),
  LevelSpec(level: 70, width: 50, height: 77, arrows: 344, minLength: 4, maxLength: 15, timeLimitMs: 740000, openMoves: 2, variant: 324),
  LevelSpec(level: 71, width: 51, height: 77, arrows: 348, minLength: 4, maxLength: 15, timeLimitMs: 743000, openMoves: 2, variant: 7),
  LevelSpec(level: 72, width: 51, height: 77, arrows: 352, minLength: 4, maxLength: 15, timeLimitMs: 746000, openMoves: 2, variant: 110),
  LevelSpec(level: 73, width: 51, height: 78, arrows: 356, minLength: 4, maxLength: 16, timeLimitMs: 749000, openMoves: 2, variant: 10),
  LevelSpec(level: 74, width: 52, height: 78, arrows: 360, minLength: 4, maxLength: 16, timeLimitMs: 752000, openMoves: 2, variant: 103),
  LevelSpec(level: 75, width: 52, height: 79, arrows: 364, minLength: 4, maxLength: 16, timeLimitMs: 755000, openMoves: 2, variant: 93),
  LevelSpec(level: 76, width: 52, height: 80, arrows: 368, minLength: 4, maxLength: 16, timeLimitMs: 758000, openMoves: 2, variant: 247),
  LevelSpec(level: 77, width: 52, height: 81, arrows: 372, minLength: 4, maxLength: 16, timeLimitMs: 761000, openMoves: 2, variant: 607),
  LevelSpec(level: 78, width: 52, height: 82, arrows: 376, minLength: 4, maxLength: 16, timeLimitMs: 763000, openMoves: 2, variant: 143),
  LevelSpec(level: 79, width: 52, height: 83, arrows: 380, minLength: 4, maxLength: 16, timeLimitMs: 766000, openMoves: 2, variant: 123),
  LevelSpec(level: 80, width: 52, height: 84, arrows: 384, minLength: 4, maxLength: 16, timeLimitMs: 768000, openMoves: 2, variant: 377),
  LevelSpec(level: 81, width: 52, height: 84, arrows: 388, minLength: 4, maxLength: 16, timeLimitMs: 769600, openMoves: 2, variant: 118),
  LevelSpec(level: 82, width: 52, height: 85, arrows: 392, minLength: 4, maxLength: 16, timeLimitMs: 771200, openMoves: 2, variant: 102),
  LevelSpec(level: 83, width: 53, height: 85, arrows: 396, minLength: 4, maxLength: 16, timeLimitMs: 772800, openMoves: 2, variant: 35),
  LevelSpec(level: 84, width: 53, height: 86, arrows: 400, minLength: 4, maxLength: 16, timeLimitMs: 774400, openMoves: 2, variant: 381),
  LevelSpec(level: 85, width: 53, height: 86, arrows: 404, minLength: 4, maxLength: 17, timeLimitMs: 776000, openMoves: 2, variant: 252),
  LevelSpec(level: 86, width: 54, height: 86, arrows: 408, minLength: 4, maxLength: 17, timeLimitMs: 777600, openMoves: 2, variant: 69),
  LevelSpec(level: 87, width: 54, height: 87, arrows: 412, minLength: 4, maxLength: 17, timeLimitMs: 779200, openMoves: 2, variant: 229),
  LevelSpec(level: 88, width: 54, height: 87, arrows: 416, minLength: 4, maxLength: 17, timeLimitMs: 780800, openMoves: 2, variant: 61),
  LevelSpec(level: 89, width: 54, height: 88, arrows: 420, minLength: 4, maxLength: 17, timeLimitMs: 782400, openMoves: 2, variant: 327),
  LevelSpec(level: 90, width: 55, height: 88, arrows: 424, minLength: 4, maxLength: 17, timeLimitMs: 784000, openMoves: 2, variant: 127),
  LevelSpec(level: 91, width: 55, height: 89, arrows: 428, minLength: 4, maxLength: 17, timeLimitMs: 785600, openMoves: 2, variant: 377),
  LevelSpec(level: 92, width: 55, height: 89, arrows: 432, minLength: 4, maxLength: 17, timeLimitMs: 787200, openMoves: 2, variant: 163),
  LevelSpec(level: 93, width: 56, height: 89, arrows: 436, minLength: 4, maxLength: 18, timeLimitMs: 788800, openMoves: 2, variant: 441),
  LevelSpec(level: 94, width: 56, height: 90, arrows: 440, minLength: 4, maxLength: 18, timeLimitMs: 790400, openMoves: 2, variant: 237),
  LevelSpec(level: 95, width: 56, height: 90, arrows: 444, minLength: 4, maxLength: 18, timeLimitMs: 792000, openMoves: 2, variant: 1037),
  LevelSpec(level: 96, width: 56, height: 91, arrows: 448, minLength: 4, maxLength: 18, timeLimitMs: 793600, openMoves: 2, variant: 15),
  LevelSpec(level: 97, width: 56, height: 91, arrows: 452, minLength: 4, maxLength: 18, timeLimitMs: 795200, openMoves: 2, variant: 917),
  LevelSpec(level: 98, width: 57, height: 91, arrows: 456, minLength: 4, maxLength: 18, timeLimitMs: 796800, openMoves: 2, variant: 16),
  LevelSpec(level: 99, width: 57, height: 92, arrows: 460, minLength: 4, maxLength: 18, timeLimitMs: 798400, openMoves: 2, variant: 899),
  LevelSpec(level: 100, width: 57, height: 92, arrows: 464, minLength: 4, maxLength: 18, timeLimitMs: 800000, openMoves: 2, variant: 112),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
