/// A level in progress, kept so the player can pick it up after closing the
/// app, switching away or backing out. The board itself is not stored: a
/// level's puzzle is fixed by its seed, so the arrows out, the slips, the
/// hints spent and the clock are enough to rebuild the moment. Pure Dart.
library;

import 'game_state.dart';

class SavedGame {
  const SavedGame({
    required this.level,
    required this.removed,
    required this.mistakes,
    required this.hintsLeft,
    required this.elapsedMs,
    this.bumped = const <int>[],
    this.continues = 0,
  });

  /// A snapshot of [state], which must have its board and be mid-level.
  factory SavedGame.fromState(GameState state) => SavedGame(
        level: state.level,
        removed: List<int>.unmodifiable(state.removed.toList()..sort()),
        bumped: List<int>.unmodifiable(state.bumped.toList()..sort()),
        mistakes: state.mistakes,
        hintsLeft: state.hintsLeft,
        elapsedMs: state.elapsedMs,
        continues: state.continues,
      );

  /// Rebuilds a snapshot from [toJson]; null when the map is not one.
  static SavedGame? fromJson(Map<String, Object?> json) {
    final level = json['level'];
    final removed = json['removed'];
    final mistakes = json['mistakes'];
    final hintsLeft = json['hintsLeft'];
    final elapsedMs = json['elapsedMs'];
    if (level is! int ||
        removed is! List ||
        removed.any((e) => e is! int) ||
        mistakes is! int ||
        hintsLeft is! int ||
        elapsedMs is! int) {
      return null;
    }
    // Both were added after the first release, so a snapshot without them is
    // still good: it just forgets which dead ends were already paid for.
    final bumped = json['bumped'];
    return SavedGame(
      level: level,
      removed: List<int>.unmodifiable(removed.cast<int>()),
      bumped: bumped is List && bumped.every((e) => e is int)
          ? List<int>.unmodifiable(bumped.cast<int>())
          : const <int>[],
      mistakes: mistakes,
      hintsLeft: hintsLeft,
      elapsedMs: elapsedMs,
      continues: switch (json['continues']) {
        final int n when n >= 0 => n,
        // The flag this replaced, from a snapshot written before the count.
        true => 1,
        _ => 0,
      },
    );
  }

  final int level;

  /// Ids of the arrows already out, ascending.
  final List<int> removed;

  /// Ids of the arrows that have already bumped, ascending: those no longer
  /// cost a life.
  final List<int> bumped;

  /// How many times the player spent the allowance and chose to play on.
  final int continues;
  final int mistakes;
  final int hintsLeft;
  final int elapsedMs;

  int get arrowsOut => removed.length;

  /// Whether there is anything worth coming back to.
  bool get hasProgress => removed.isNotEmpty || mistakes > 0 || hintsLeft < maxHints;

  Map<String, Object?> toJson() => <String, Object?>{
        'level': level,
        'removed': removed,
        'bumped': bumped,
        'mistakes': mistakes,
        'hintsLeft': hintsLeft,
        'elapsedMs': elapsedMs,
        'continues': continues,
      };

  @override
  bool operator ==(Object other) =>
      other is SavedGame &&
      other.level == level &&
      other.mistakes == mistakes &&
      other.hintsLeft == hintsLeft &&
      other.elapsedMs == elapsedMs &&
      other.continues == continues &&
      other.removed.length == removed.length &&
      other.removed.every(removed.contains) &&
      other.bumped.length == bumped.length &&
      other.bumped.every(bumped.contains);

  @override
  int get hashCode => Object.hash(
        level,
        mistakes,
        hintsLeft,
        elapsedMs,
        removed.length,
        bumped.length,
        continues,
      );

  @override
  String toString() => 'SavedGame(level $level, $arrowsOut out, $mistakes slips, ${elapsedMs}ms)';
}
