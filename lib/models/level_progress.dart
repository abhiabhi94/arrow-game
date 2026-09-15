/// Per-level progress: completion, stars, best time and play count. Pure Dart.
library;

/// Lives on the early levels; each mistake costs one.
const int maxLives = 3;

/// The last level played with three lives. Past [kFourthLifeAfterLevel] a
/// board is tapped at barely a dozen pixels a cell, so a slip is as often the
/// finger's fault as the player's; [kFifthLifeAfterLevel] adds one more for
/// the very biggest boards.
const int kFourthLifeAfterLevel = 15;
const int kFifthLifeAfterLevel = 25;

/// Lives for [level]: three, four from level 16, five from level 26.
int livesForLevel(int level) {
  if (level > kFifthLifeAfterLevel) return maxLives + 2;
  if (level > kFourthLifeAfterLevel) return maxLives + 1;
  return maxLives;
}

/// Stars for clearing [level] with [mistakes] slips. Flawless is always
/// three; the rest of the level's allowance splits in half, the better half
/// two stars and the rest one. On a three-life level that is the old rule
/// (one slip two stars, two slips one), and the extra lives later buy room
/// to slip without making three stars any cheaper.
int starsForMistakes(int mistakes, int level) {
  final lives = livesForLevel(level);
  if (mistakes <= 0) return 3;
  if (mistakes >= lives) return 0;
  return mistakes <= (lives - 1) ~/ 2 ? 2 : 1;
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.completed,
    required this.stars,
    required this.bestTimeMs,
    required this.timesCompleted,
  });

  /// Level number, 1..20.
  final int level;

  /// Whether the level has ever been cleared.
  final bool completed;

  /// Best star rating earned, 0..3.
  final int stars;

  /// Best clear time in milliseconds, or null if never cleared.
  final int? bestTimeMs;

  /// How many times the level has been cleared.
  final int timesCompleted;

  /// Empty progress for a level that has not been played.
  factory LevelProgress.empty(int level) => LevelProgress(
        level: level,
        completed: false,
        stars: 0,
        bestTimeMs: null,
        timesCompleted: 0,
      );

  /// Whether [timeMs] would be a new best time for this level.
  bool isNewBest(int timeMs) => bestTimeMs == null || timeMs < bestTimeMs!;

  /// Progress after clearing in [timeMs] with [stars], keeping the best of each.
  LevelProgress withCompletion(int timeMs, int stars) => LevelProgress(
        level: level,
        completed: true,
        stars: stars > this.stars ? stars : this.stars,
        bestTimeMs: isNewBest(timeMs) ? timeMs : bestTimeMs,
        timesCompleted: timesCompleted + 1,
      );

  @override
  bool operator ==(Object other) =>
      other is LevelProgress &&
      other.level == level &&
      other.completed == completed &&
      other.stars == stars &&
      other.bestTimeMs == bestTimeMs &&
      other.timesCompleted == timesCompleted;

  @override
  int get hashCode =>
      Object.hash(level, completed, stars, bestTimeMs, timesCompleted);
}
