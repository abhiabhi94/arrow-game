/// The knobs that define one level's difficulty. Pure Dart (no Flutter).
library;

import '../engine/arrow.dart';

/// How long a ghost arrow stays visible before it fades (memory pressure).
const int kGhostVisibleMs = 600;

class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.targetHits,
    required this.timeLimitMs,
    this.reverseChance = 0,
    this.ghostChance = 0,
    this.decoyChance = 0,
    this.arrowTimeoutMs = 0,
  })  : assert(level >= 1),
        assert(targetHits > 0),
        assert(timeLimitMs > 0),
        assert(reverseChance >= 0 && ghostChance >= 0 && decoyChance >= 0),
        assert(
          reverseChance + ghostChance + decoyChance <= 1,
          'kind chances must leave room for plain arrows',
        ),
        assert(arrowTimeoutMs >= 0);

  /// 1-based level number.
  final int level;

  /// Correct swipes needed to clear the level.
  final int targetHits;

  /// The level clock: run out and the level is failed.
  final int timeLimitMs;

  /// Fraction of arrows that are [ArrowKind.reverse].
  final double reverseChance;

  /// Fraction of arrows that are [ArrowKind.ghost].
  final double ghostChance;

  /// Fraction of arrows that are [ArrowKind.decoy].
  final double decoyChance;

  /// Per-arrow fuse in milliseconds; an arrow left unanswered this long counts
  /// as a mistake. 0 disables the fuse.
  final int arrowTimeoutMs;

  bool get hasFuse => arrowTimeoutMs > 0;

  /// The arrow kinds that can appear, in rule-explanation order.
  List<ArrowKind> get kinds => <ArrowKind>[
        ArrowKind.normal,
        if (reverseChance > 0) ArrowKind.reverse,
        if (ghostChance > 0) ArrowKind.ghost,
        if (decoyChance > 0) ArrowKind.decoy,
      ];

  /// Average seconds the player has per arrow if they use the whole clock.
  double get secondsPerArrow => timeLimitMs / 1000 / targetHits;

  @override
  String toString() => 'LevelSpec($level: $targetHits in ${timeLimitMs}ms)';
}
