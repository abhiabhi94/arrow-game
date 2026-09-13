/// The 20 levels. Difficulty climbs on three axes: board size, arrow count
/// and arrow length (longer, bendier arrows cross more exit paths). The
/// clock grows with the board so the pressure stays "reasonable, not frantic".
library;

import '../models/level_spec.dart';

const int totalLevels = 20;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 4, height: 4, arrows: 3, minLength: 2, maxLength: 3, timeLimitMs: 60000),
  LevelSpec(level: 2, width: 4, height: 5, arrows: 4, minLength: 2, maxLength: 3, timeLimitMs: 75000),
  LevelSpec(level: 3, width: 5, height: 5, arrows: 5, minLength: 2, maxLength: 4, timeLimitMs: 90000),
  LevelSpec(level: 4, width: 5, height: 5, arrows: 6, minLength: 2, maxLength: 4, timeLimitMs: 90000),
  LevelSpec(level: 5, width: 5, height: 6, arrows: 6, minLength: 3, maxLength: 5, timeLimitMs: 100000),
  LevelSpec(level: 6, width: 6, height: 6, arrows: 7, minLength: 3, maxLength: 5, timeLimitMs: 110000),
  LevelSpec(level: 7, width: 6, height: 6, arrows: 8, minLength: 3, maxLength: 5, timeLimitMs: 120000),
  LevelSpec(level: 8, width: 6, height: 7, arrows: 8, minLength: 3, maxLength: 6, timeLimitMs: 130000),
  LevelSpec(level: 9, width: 7, height: 7, arrows: 9, minLength: 3, maxLength: 6, timeLimitMs: 140000),
  LevelSpec(level: 10, width: 7, height: 7, arrows: 10, minLength: 3, maxLength: 6, timeLimitMs: 150000),
  LevelSpec(level: 11, width: 7, height: 8, arrows: 10, minLength: 3, maxLength: 6, timeLimitMs: 160000),
  LevelSpec(level: 12, width: 8, height: 8, arrows: 11, minLength: 3, maxLength: 7, timeLimitMs: 170000),
  LevelSpec(level: 13, width: 8, height: 8, arrows: 12, minLength: 3, maxLength: 7, timeLimitMs: 180000),
  LevelSpec(level: 14, width: 8, height: 9, arrows: 12, minLength: 4, maxLength: 7, timeLimitMs: 195000),
  LevelSpec(level: 15, width: 9, height: 9, arrows: 13, minLength: 4, maxLength: 7, timeLimitMs: 210000),
  LevelSpec(level: 16, width: 9, height: 9, arrows: 14, minLength: 4, maxLength: 8, timeLimitMs: 225000),
  LevelSpec(level: 17, width: 9, height: 10, arrows: 14, minLength: 4, maxLength: 8, timeLimitMs: 240000),
  LevelSpec(level: 18, width: 10, height: 10, arrows: 15, minLength: 4, maxLength: 8, timeLimitMs: 255000),
  LevelSpec(level: 19, width: 10, height: 10, arrows: 15, minLength: 4, maxLength: 9, timeLimitMs: 270000),
  LevelSpec(level: 20, width: 10, height: 11, arrows: 16, minLength: 4, maxLength: 9, timeLimitMs: 300000),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
