/// The 60 levels. Every board fits the screen: the cap is 12x18, the biggest
/// grid that still draws a finger-sized cell (~29 pt) on a 360x800 phone, so
/// the whole puzzle is visible at once and there is no zooming or panning to
/// do. That cap is the design: an arrow that blocks your move is always on
/// screen, and a cell is always big enough to hit.
///
/// Difficulty therefore comes from the puzzle, not the acreage. The board
/// grows from 5x6 to the cap by level 45 and the arrow count from 5 to 28,
/// but the axis that matters is `openMoves` — how many arrows the generator
/// leaves playable at once. Levels 1-40 sit at 2, so there is usually a
/// choice and a beginner is never stuck hunting. From level 41 it drops to
/// 1: the board stops offering options, the dependency chain runs nearly the
/// whole length of the board (depth ~22 of 28 arrows), and every move is the
/// only move there is. That step is the endgame.
///
/// Arrows also lengthen (2-5 cells to 4-12), so late boards are long snakes
/// crossing many exit paths rather than stubs. Fill stays at 0.86-0.98 — a
/// packed page, like a printed puzzle.
///
/// The clock scales with the arrow count and loosens as the choice narrows:
/// ~4 s an arrow at the start, ~8 s by the finale, since finding the single
/// legal move takes longer than picking one of three. A level is 30 s to
/// under four minutes — a bite, not a sitting.
library;

import '../models/level_spec.dart';

const int totalLevels = 60;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 28000, openMoves: 2),
  LevelSpec(level: 2, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 29000, openMoves: 2),
  LevelSpec(level: 3, width: 5, height: 7, arrows: 6, minLength: 2, maxLength: 5, timeLimitMs: 33000, openMoves: 2),
  LevelSpec(level: 4, width: 5, height: 7, arrows: 6, minLength: 2, maxLength: 5, timeLimitMs: 34000, openMoves: 2),
  LevelSpec(level: 5, width: 6, height: 7, arrows: 7, minLength: 2, maxLength: 5, timeLimitMs: 39000, openMoves: 2),
  LevelSpec(level: 6, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 6, timeLimitMs: 44000, openMoves: 2),
  LevelSpec(level: 7, width: 6, height: 8, arrows: 8, minLength: 2, maxLength: 6, timeLimitMs: 45000, openMoves: 2),
  LevelSpec(level: 8, width: 6, height: 8, arrows: 8, minLength: 2, maxLength: 6, timeLimitMs: 46000, openMoves: 2),
  LevelSpec(level: 9, width: 6, height: 8, arrows: 8, minLength: 2, maxLength: 6, timeLimitMs: 47000, openMoves: 2),
  LevelSpec(level: 10, width: 6, height: 8, arrows: 9, minLength: 2, maxLength: 6, timeLimitMs: 51000, openMoves: 2),
  LevelSpec(level: 11, width: 7, height: 9, arrows: 9, minLength: 2, maxLength: 6, timeLimitMs: 52000, openMoves: 2),
  LevelSpec(level: 12, width: 7, height: 9, arrows: 9, minLength: 2, maxLength: 6, timeLimitMs: 53000, openMoves: 2),
  LevelSpec(level: 13, width: 7, height: 9, arrows: 10, minLength: 2, maxLength: 6, timeLimitMs: 59000, openMoves: 2),
  LevelSpec(level: 14, width: 7, height: 10, arrows: 11, minLength: 2, maxLength: 7, timeLimitMs: 64000, openMoves: 2),
  LevelSpec(level: 15, width: 7, height: 10, arrows: 11, minLength: 2, maxLength: 7, timeLimitMs: 65000, openMoves: 2),
  LevelSpec(level: 16, width: 7, height: 10, arrows: 11, minLength: 2, maxLength: 7, timeLimitMs: 66000, openMoves: 2),
  LevelSpec(level: 17, width: 8, height: 10, arrows: 11, minLength: 2, maxLength: 7, timeLimitMs: 67000, openMoves: 2),
  LevelSpec(level: 18, width: 8, height: 11, arrows: 12, minLength: 2, maxLength: 7, timeLimitMs: 73000, openMoves: 2),
  LevelSpec(level: 19, width: 8, height: 11, arrows: 12, minLength: 2, maxLength: 7, timeLimitMs: 74000, openMoves: 2),
  LevelSpec(level: 20, width: 8, height: 11, arrows: 12, minLength: 2, maxLength: 7, timeLimitMs: 75000, openMoves: 2),
  LevelSpec(level: 21, width: 8, height: 11, arrows: 13, minLength: 3, maxLength: 7, timeLimitMs: 82000, openMoves: 2),
  LevelSpec(level: 22, width: 8, height: 12, arrows: 13, minLength: 3, maxLength: 7, timeLimitMs: 83000, openMoves: 2),
  LevelSpec(level: 23, width: 9, height: 12, arrows: 14, minLength: 3, maxLength: 8, timeLimitMs: 89000, openMoves: 2),
  LevelSpec(level: 24, width: 9, height: 12, arrows: 14, minLength: 3, maxLength: 8, timeLimitMs: 91000, openMoves: 2),
  LevelSpec(level: 25, width: 9, height: 13, arrows: 14, minLength: 3, maxLength: 8, timeLimitMs: 92000, openMoves: 2),
  LevelSpec(level: 26, width: 9, height: 13, arrows: 15, minLength: 3, maxLength: 8, timeLimitMs: 99000, openMoves: 2),
  LevelSpec(level: 27, width: 9, height: 13, arrows: 16, minLength: 3, maxLength: 8, timeLimitMs: 106000, openMoves: 2),
  LevelSpec(level: 28, width: 9, height: 13, arrows: 16, minLength: 3, maxLength: 8, timeLimitMs: 107000, openMoves: 2),
  LevelSpec(level: 29, width: 9, height: 14, arrows: 16, minLength: 3, maxLength: 8, timeLimitMs: 108000, openMoves: 2),
  LevelSpec(level: 30, width: 10, height: 14, arrows: 16, minLength: 3, maxLength: 8, timeLimitMs: 109000, openMoves: 2),
  LevelSpec(level: 31, width: 10, height: 14, arrows: 17, minLength: 3, maxLength: 9, timeLimitMs: 117000, openMoves: 2),
  LevelSpec(level: 32, width: 10, height: 14, arrows: 17, minLength: 3, maxLength: 9, timeLimitMs: 118000, openMoves: 2),
  LevelSpec(level: 33, width: 10, height: 15, arrows: 17, minLength: 3, maxLength: 9, timeLimitMs: 119000, openMoves: 2),
  LevelSpec(level: 34, width: 10, height: 15, arrows: 18, minLength: 3, maxLength: 9, timeLimitMs: 127000, openMoves: 2),
  LevelSpec(level: 35, width: 10, height: 15, arrows: 18, minLength: 3, maxLength: 9, timeLimitMs: 128000, openMoves: 2),
  LevelSpec(level: 36, width: 11, height: 16, arrows: 19, minLength: 3, maxLength: 9, timeLimitMs: 136000, openMoves: 2),
  LevelSpec(level: 37, width: 11, height: 16, arrows: 19, minLength: 3, maxLength: 9, timeLimitMs: 138000, openMoves: 2),
  LevelSpec(level: 38, width: 11, height: 16, arrows: 19, minLength: 3, maxLength: 9, timeLimitMs: 139000, openMoves: 2),
  LevelSpec(level: 39, width: 11, height: 16, arrows: 20, minLength: 3, maxLength: 10, timeLimitMs: 147000, openMoves: 2),
  LevelSpec(level: 40, width: 11, height: 17, arrows: 20, minLength: 3, maxLength: 10, timeLimitMs: 149000, openMoves: 2),
  LevelSpec(level: 41, width: 11, height: 17, arrows: 21, minLength: 4, maxLength: 10, timeLimitMs: 157000, openMoves: 1),
  LevelSpec(level: 42, width: 12, height: 17, arrows: 21, minLength: 4, maxLength: 10, timeLimitMs: 159000, openMoves: 1),
  LevelSpec(level: 43, width: 12, height: 17, arrows: 21, minLength: 4, maxLength: 10, timeLimitMs: 160000, openMoves: 1),
  LevelSpec(level: 44, width: 12, height: 18, arrows: 22, minLength: 4, maxLength: 10, timeLimitMs: 169000, openMoves: 1),
  LevelSpec(level: 45, width: 12, height: 18, arrows: 22, minLength: 4, maxLength: 10, timeLimitMs: 171000, openMoves: 1),
  LevelSpec(level: 46, width: 12, height: 18, arrows: 23, minLength: 4, maxLength: 10, timeLimitMs: 179000, openMoves: 1),
  LevelSpec(level: 47, width: 12, height: 18, arrows: 23, minLength: 4, maxLength: 10, timeLimitMs: 181000, openMoves: 1),
  LevelSpec(level: 48, width: 12, height: 18, arrows: 23, minLength: 4, maxLength: 11, timeLimitMs: 183000, openMoves: 1),
  LevelSpec(level: 49, width: 12, height: 18, arrows: 24, minLength: 4, maxLength: 11, timeLimitMs: 192000, openMoves: 1),
  LevelSpec(level: 50, width: 12, height: 18, arrows: 24, minLength: 4, maxLength: 11, timeLimitMs: 194000, openMoves: 1),
  LevelSpec(level: 51, width: 12, height: 18, arrows: 24, minLength: 4, maxLength: 11, timeLimitMs: 196000, openMoves: 1),
  LevelSpec(level: 52, width: 12, height: 18, arrows: 25, minLength: 4, maxLength: 11, timeLimitMs: 205000, openMoves: 1),
  LevelSpec(level: 53, width: 12, height: 18, arrows: 25, minLength: 4, maxLength: 11, timeLimitMs: 207000, openMoves: 1),
  LevelSpec(level: 54, width: 12, height: 18, arrows: 26, minLength: 4, maxLength: 11, timeLimitMs: 216000, openMoves: 1),
  LevelSpec(level: 55, width: 12, height: 18, arrows: 26, minLength: 4, maxLength: 11, timeLimitMs: 218000, openMoves: 1),
  LevelSpec(level: 56, width: 12, height: 18, arrows: 26, minLength: 4, maxLength: 12, timeLimitMs: 220000, openMoves: 1),
  LevelSpec(level: 57, width: 12, height: 18, arrows: 27, minLength: 4, maxLength: 12, timeLimitMs: 230000, openMoves: 1),
  LevelSpec(level: 58, width: 12, height: 18, arrows: 27, minLength: 4, maxLength: 12, timeLimitMs: 232000, openMoves: 1),
  LevelSpec(level: 59, width: 12, height: 18, arrows: 28, minLength: 4, maxLength: 12, timeLimitMs: 242000, openMoves: 1),
  LevelSpec(level: 60, width: 12, height: 18, arrows: 28, minLength: 4, maxLength: 12, timeLimitMs: 244000, openMoves: 1),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
