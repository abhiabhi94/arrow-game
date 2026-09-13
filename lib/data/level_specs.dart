/// The 20 hand-tuned levels. Difficulty climbs on two axes: pace (arrows per
/// second of clock) and twists (reverse, ghost and decoy arrows, then a
/// per-arrow fuse). Each new twist arrives with a slightly gentler pace so the
/// player can learn it, then the pace tightens again.
///
/// Chapters:
///   1–3   plain arrows — learn the swipe
///   4–6   reverse arrows join
///   7–9   the per-arrow fuse joins
///   10–12 ghost arrows join
///   13–15 decoy words join
///   16–20 everything, faster and faster
library;

import '../models/level_spec.dart';

const int totalLevels = 20;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  // Chapter 1: plain arrows.
  LevelSpec(level: 1, targetHits: 10, timeLimitMs: 30000),
  LevelSpec(level: 2, targetHits: 12, timeLimitMs: 30000),
  LevelSpec(level: 3, targetHits: 15, timeLimitMs: 30000),
  // Chapter 2: reverse arrows.
  LevelSpec(level: 4, targetHits: 14, timeLimitMs: 30000, reverseChance: 0.25),
  LevelSpec(level: 5, targetHits: 18, timeLimitMs: 32000, reverseChance: 0.35),
  LevelSpec(level: 6, targetHits: 22, timeLimitMs: 34000, reverseChance: 0.40),
  // Chapter 3: the fuse.
  LevelSpec(
    level: 7,
    targetHits: 18,
    timeLimitMs: 30000,
    reverseChance: 0.30,
    arrowTimeoutMs: 2500,
  ),
  LevelSpec(
    level: 8,
    targetHits: 22,
    timeLimitMs: 32000,
    reverseChance: 0.35,
    arrowTimeoutMs: 2300,
  ),
  LevelSpec(
    level: 9,
    targetHits: 26,
    timeLimitMs: 34000,
    reverseChance: 0.40,
    arrowTimeoutMs: 2100,
  ),
  // Chapter 4: ghost arrows.
  LevelSpec(
    level: 10,
    targetHits: 22,
    timeLimitMs: 32000,
    reverseChance: 0.30,
    ghostChance: 0.25,
    arrowTimeoutMs: 2300,
  ),
  LevelSpec(
    level: 11,
    targetHits: 26,
    timeLimitMs: 34000,
    reverseChance: 0.30,
    ghostChance: 0.30,
    arrowTimeoutMs: 2100,
  ),
  LevelSpec(
    level: 12,
    targetHits: 30,
    timeLimitMs: 36000,
    reverseChance: 0.35,
    ghostChance: 0.35,
    arrowTimeoutMs: 2000,
  ),
  // Chapter 5: decoy words.
  LevelSpec(
    level: 13,
    targetHits: 26,
    timeLimitMs: 34000,
    reverseChance: 0.25,
    ghostChance: 0.20,
    decoyChance: 0.25,
    arrowTimeoutMs: 2100,
  ),
  LevelSpec(
    level: 14,
    targetHits: 30,
    timeLimitMs: 36000,
    reverseChance: 0.25,
    ghostChance: 0.25,
    decoyChance: 0.25,
    arrowTimeoutMs: 2000,
  ),
  LevelSpec(
    level: 15,
    targetHits: 34,
    timeLimitMs: 38000,
    reverseChance: 0.30,
    ghostChance: 0.25,
    decoyChance: 0.25,
    arrowTimeoutMs: 1900,
  ),
  // Chapter 6: everything, faster.
  LevelSpec(
    level: 16,
    targetHits: 32,
    timeLimitMs: 36000,
    reverseChance: 0.30,
    ghostChance: 0.25,
    decoyChance: 0.30,
    arrowTimeoutMs: 1800,
  ),
  LevelSpec(
    level: 17,
    targetHits: 36,
    timeLimitMs: 38000,
    reverseChance: 0.30,
    ghostChance: 0.28,
    decoyChance: 0.27,
    arrowTimeoutMs: 1700,
  ),
  LevelSpec(
    level: 18,
    targetHits: 38,
    timeLimitMs: 40000,
    reverseChance: 0.30,
    ghostChance: 0.28,
    decoyChance: 0.27,
    arrowTimeoutMs: 1600,
  ),
  LevelSpec(
    level: 19,
    targetHits: 40,
    timeLimitMs: 40000,
    reverseChance: 0.30,
    ghostChance: 0.28,
    decoyChance: 0.27,
    arrowTimeoutMs: 1500,
  ),
  LevelSpec(
    level: 20,
    targetHits: 44,
    timeLimitMs: 42000,
    reverseChance: 0.30,
    ghostChance: 0.28,
    decoyChance: 0.27,
    arrowTimeoutMs: 1400,
  ),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
