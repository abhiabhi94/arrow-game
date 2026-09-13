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
  });

  /// A snapshot of [state], which must have its board and be mid-level.
  factory SavedGame.fromState(GameState state) => SavedGame(
        level: state.level,
        removed: List<int>.unmodifiable(state.removed.toList()..sort()),
        mistakes: state.mistakes,
        hintsLeft: state.hintsLeft,
        elapsedMs: state.elapsedMs,
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
    return SavedGame(
      level: level,
      removed: List<int>.unmodifiable(removed.cast<int>()),
      mistakes: mistakes,
      hintsLeft: hintsLeft,
      elapsedMs: elapsedMs,
    );
  }

  final int level;

  /// Ids of the arrows already out, ascending.
  final List<int> removed;
  final int mistakes;
  final int hintsLeft;
  final int elapsedMs;

  int get arrowsOut => removed.length;

  /// Whether there is anything worth coming back to.
  bool get hasProgress => removed.isNotEmpty || mistakes > 0 || hintsLeft < maxHints;

  Map<String, Object?> toJson() => <String, Object?>{
        'level': level,
        'removed': removed,
        'mistakes': mistakes,
        'hintsLeft': hintsLeft,
        'elapsedMs': elapsedMs,
      };

  @override
  bool operator ==(Object other) =>
      other is SavedGame &&
      other.level == level &&
      other.mistakes == mistakes &&
      other.hintsLeft == hintsLeft &&
      other.elapsedMs == elapsedMs &&
      other.removed.length == removed.length &&
      other.removed.every(removed.contains);

  @override
  int get hashCode => Object.hash(level, mistakes, hintsLeft, elapsedMs, removed.length);

  @override
  String toString() => 'SavedGame(level $level, $arrowsOut out, $mistakes slips, ${elapsedMs}ms)';
}
