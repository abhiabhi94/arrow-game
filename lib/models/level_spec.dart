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
    this.openMoves = 2,
    this.variant = 0,
  })  : assert(level >= 1),
        assert(openMoves >= 1),
        assert(variant >= 0),
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

  /// How many arrows the generator tries to keep playable at any moment.
  /// Small numbers mean the player has to hunt for the next move; big ones
  /// leave plenty of obvious taps. A soft target, not a guarantee.
  final int openMoves;

  /// Which of the level's boards is dealt. The generator is seeded from the
  /// level and this, so a level can be re-dealt — when its first board came
  /// out looser than the curve wants — without moving any other level's.
  /// `tool/level_report.dart <level> <extra>` shows how the variants compare.
  final int variant;

  /// Seed for the level's fixed puzzle. Variant 0 is the seed the levels were
  /// first cut with, so a level keeps its board unless it is re-dealt.
  int get seed => level * 7919 + 17 + variant * 1_000_003;

  int get cellCount => width * height;

  /// The same level with its clock multiplied by [factor] — the "extra time"
  /// accessibility setting. The board (and so [seed]) is untouched, so a
  /// saved game still fits and a cleared level is still that level. A factor
  /// of 1 is this very spec.
  LevelSpec withClockFactor(int factor) {
    assert(factor >= 1);
    if (factor == 1) return this;
    return LevelSpec(
      level: level,
      width: width,
      height: height,
      arrows: arrows,
      minLength: minLength,
      maxLength: maxLength,
      timeLimitMs: timeLimitMs * factor,
      openMoves: openMoves,
      variant: variant,
    );
  }

  @override
  String toString() =>
      'LevelSpec($level: ${width}x$height, $arrows arrows, ${timeLimitMs}ms)';
}
