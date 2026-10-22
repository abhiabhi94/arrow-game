/// The knobs that define one level's board. Pure Dart (no Flutter).
library;

import '../engine/board_shape.dart';

/// The chapter twists a board is dealt with: its shape and how many of its
/// arrows are locked, hidden or tethered. The plain rectangle with none of
/// them is every level before the Shapes chapter.
class LevelFeatures {
  const LevelFeatures({
    this.shape = BoardShape.plain,
    this.locks = 0,
    this.hidden = 0,
    this.pairs = 0,
  })  : assert(locks >= 0),
        assert(hidden >= 0),
        assert(pairs >= 0);

  static const LevelFeatures none = LevelFeatures();

  final BoardShape shape;

  /// Locked arrows, each with its own key arrow elsewhere on the board.
  final int locks;

  /// Arrows dealt with their head hidden.
  final int hidden;

  /// Tethered pairs that leave on one tap.
  final int pairs;

  bool get isPlain => shape == BoardShape.plain && locks == 0 && hidden == 0 && pairs == 0;

  @override
  bool operator ==(Object other) =>
      other is LevelFeatures &&
      other.shape == shape &&
      other.locks == locks &&
      other.hidden == hidden &&
      other.pairs == pairs;

  @override
  int get hashCode => Object.hash(shape, locks, hidden, pairs);

  @override
  String toString() => 'LevelFeatures(${shape.name}, locks $locks, hidden $hidden, pairs $pairs)';
}

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
    this.features = LevelFeatures.none,
    this._seed,
  })  : assert(level >= 0),
        assert(openMoves >= 1),
        assert(variant >= 0),
        assert(width >= 3 && height >= 3),
        assert(arrows >= 1),
        assert(minLength >= 2 && maxLength >= minLength),
        assert(timeLimitMs > 0);

  /// 1-based level number on the trail, or [dailyLevel] for a daily board.
  final int level;

  /// The level number a daily board carries: it is on no trail.
  static const int dailyLevel = 0;

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

  /// The shape and the chapter twists the board is dealt with.
  final LevelFeatures features;

  final int? _seed;

  /// Seed for the level's fixed puzzle. Variant 0 is the seed the levels were
  /// first cut with, so a level keeps its board unless it is re-dealt. A
  /// daily board carries its own seed instead.
  int get seed => _seed ?? level * 7919 + 17 + variant * 1_000_003;

  bool get isDaily => level == dailyLevel;

  int get cellCount => width * height;

  /// Cells an arrow may use: the board less the shape's walls.
  int get freeCellCount => cellCount - wallsFor(features.shape, width, height).length;

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
      features: features,
      seed: _seed,
    );
  }

  /// The same level dealt from another [variant].
  LevelSpec withVariant(int variant) => LevelSpec(
        level: level,
        width: width,
        height: height,
        arrows: arrows,
        minLength: minLength,
        maxLength: maxLength,
        timeLimitMs: timeLimitMs,
        openMoves: openMoves,
        variant: variant,
        features: features,
        seed: _seed,
      );

  @override
  String toString() =>
      'LevelSpec($level: ${width}x$height, $arrows arrows, ${timeLimitMs}ms)';
}
