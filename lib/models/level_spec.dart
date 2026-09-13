/// The knobs that define one level's board. Pure Dart (no Flutter).
library;

class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.width,
    required this.height,
    required this.arrows,
    required this.minLength,
    required this.maxLength,
    required this.timeLimitMs,
  })  : assert(level >= 1),
        assert(width >= 3 && height >= 3),
        assert(arrows >= 1),
        assert(minLength >= 2 && maxLength >= minLength),
        assert(timeLimitMs > 0);

  /// 1-based level number.
  final int level;

  /// Board size in cells.
  final int width;
  final int height;

  /// Arrows on the board (all must exit to clear the level).
  final int arrows;

  /// Arrow length range in cells.
  final int minLength;
  final int maxLength;

  /// The level clock: run out and the level is failed.
  final int timeLimitMs;

  /// Seed for the level's fixed puzzle.
  int get seed => level * 7919 + 17;

  int get cellCount => width * height;

  @override
  String toString() =>
      'LevelSpec($level: ${width}x$height, $arrows arrows, ${timeLimitMs}ms)';
}
