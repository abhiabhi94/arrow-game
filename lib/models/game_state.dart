/// Immutable gameplay state for one attempt at a level. Pure Dart (no Flutter).
library;

import '../engine/arrow.dart';
import 'level_progress.dart';
import 'level_spec.dart';

/// [ready] is the pre-start intro; [paused] freezes the clock; the last three
/// are terminal and each maps to its own result overlay.
enum GamePhase { ready, playing, paused, cleared, outOfLives, timeUp }

/// The result of the most recent swipe (or fuse burn-out), for UI feedback.
enum Outcome { none, hit, miss }

class GameState {
  const GameState({
    required this.spec,
    required this.phase,
    required this.hits,
    required this.mistakes,
    required this.streak,
    required this.bestStreak,
    required this.elapsedMs,
    required this.arrow,
    required this.arrowAgeMs,
    required this.lastOutcome,
    required this.outcomeToken,
  });

  /// A fresh, not-yet-started attempt at [spec].
  factory GameState.ready(LevelSpec spec) => GameState(
        spec: spec,
        phase: GamePhase.ready,
        hits: 0,
        mistakes: 0,
        streak: 0,
        bestStreak: 0,
        elapsedMs: 0,
        arrow: null,
        arrowAgeMs: 0,
        lastOutcome: Outcome.none,
        outcomeToken: 0,
      );

  final LevelSpec spec;
  final GamePhase phase;

  /// Correct swipes so far.
  final int hits;

  /// Wrong swipes and burnt fuses so far (each costs a life).
  final int mistakes;

  /// Consecutive hits since the last mistake.
  final int streak;

  /// The longest streak this attempt.
  final int bestStreak;

  /// Time on the level clock in milliseconds (frozen while paused).
  final int elapsedMs;

  /// The arrow currently on screen, or null before the level starts.
  final Arrow? arrow;

  /// How long the current arrow has been showing (drives ghosts and the fuse).
  final int arrowAgeMs;

  final Outcome lastOutcome;

  /// Bumped on every hit/miss so the UI can replay feedback animations even
  /// when two consecutive outcomes are the same.
  final int outcomeToken;

  int get level => spec.level;
  int get livesLeft => maxLives - mistakes;
  int get remainingMs =>
      (spec.timeLimitMs - elapsedMs).clamp(0, spec.timeLimitMs);

  /// Fraction of the level clock still left, 0..1.
  double get timeFraction => remainingMs / spec.timeLimitMs;

  /// Fraction of the target reached, 0..1.
  double get progress => (hits / spec.targetHits).clamp(0.0, 1.0);

  bool get isPlaying => phase == GamePhase.playing;
  bool get isOver =>
      phase == GamePhase.cleared ||
      phase == GamePhase.outOfLives ||
      phase == GamePhase.timeUp;

  /// Whether the current arrow should be drawn. Ghosts hide once they have
  /// been up for [kGhostVisibleMs]; everything else stays visible.
  bool get arrowVisible {
    final a = arrow;
    if (a == null) return false;
    if (a.kind != ArrowKind.ghost) return true;
    return arrowAgeMs < kGhostVisibleMs;
  }

  /// Fraction of the current arrow's fuse still left (1 = fresh, 0 = burnt),
  /// or null when the level has no fuse.
  double? get fuseFraction {
    if (!spec.hasFuse) return null;
    return (1 - arrowAgeMs / spec.arrowTimeoutMs).clamp(0.0, 1.0);
  }

  /// Stars earned — meaningful once [phase] is [GamePhase.cleared].
  int get stars =>
      phase == GamePhase.cleared ? starsForMistakes(mistakes) : 0;

  GameState copyWith({
    GamePhase? phase,
    int? hits,
    int? mistakes,
    int? streak,
    int? bestStreak,
    int? elapsedMs,
    Arrow? arrow,
    int? arrowAgeMs,
    Outcome? lastOutcome,
    int? outcomeToken,
  }) =>
      GameState(
        spec: spec,
        phase: phase ?? this.phase,
        hits: hits ?? this.hits,
        mistakes: mistakes ?? this.mistakes,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        elapsedMs: elapsedMs ?? this.elapsedMs,
        arrow: arrow ?? this.arrow,
        arrowAgeMs: arrowAgeMs ?? this.arrowAgeMs,
        lastOutcome: lastOutcome ?? this.lastOutcome,
        outcomeToken: outcomeToken ?? this.outcomeToken,
      );
}
