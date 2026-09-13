/// Immutable gameplay state for one attempt at a level. Pure Dart (no Flutter).
library;

import '../engine/cell.dart';
import '../engine/puzzle.dart';
import 'level_progress.dart';
import 'level_spec.dart';

/// Hints available per attempt.
const int maxHints = 3;

/// [loading] is the moment the board is being generated (off-thread on
/// mobile); [paused] freezes the clock; the last three are terminal and each
/// maps to its own result overlay.
enum GamePhase { loading, playing, paused, cleared, outOfLives, timeUp }

/// What the most recent tap did, for UI feedback.
enum MoveOutcome { none, exited, blocked }

class GameState {
  const GameState({
    required this.spec,
    required this.puzzle,
    required this.phase,
    required this.removed,
    required this.mistakes,
    required this.hintsLeft,
    required this.hintArrowId,
    required this.elapsedMs,
    required this.lastMoveId,
    required this.lastOutcome,
    required this.blockedCell,
    required this.moveToken,
    this.resumeOffered = false,
  });

  /// The board is still being generated.
  factory GameState.loading(LevelSpec spec) => GameState(
        spec: spec,
        puzzle: null,
        phase: GamePhase.loading,
        removed: const <int>{},
        mistakes: 0,
        hintsLeft: maxHints,
        hintArrowId: null,
        elapsedMs: 0,
        lastMoveId: null,
        lastOutcome: MoveOutcome.none,
        blockedCell: null,
        moveToken: 0,
      );

  /// A fresh attempt at [puzzle], clock at zero, already playing.
  factory GameState.fresh(LevelSpec spec, Puzzle puzzle) => GameState(
        spec: spec,
        puzzle: puzzle,
        phase: GamePhase.playing,
        removed: const <int>{},
        mistakes: 0,
        hintsLeft: maxHints,
        hintArrowId: null,
        elapsedMs: 0,
        lastMoveId: null,
        lastOutcome: MoveOutcome.none,
        blockedCell: null,
        moveToken: 0,
      );

  final LevelSpec spec;

  /// The board, or null while [GamePhase.loading].
  final Puzzle? puzzle;
  final GamePhase phase;

  /// Ids of arrows that have left the board.
  final Set<int> removed;

  /// Blocked taps so far (each costs a life).
  final int mistakes;

  final int hintsLeft;

  /// The arrow a hint is currently pointing at, if any.
  final int? hintArrowId;

  /// Time on the level clock in milliseconds (frozen while paused).
  final int elapsedMs;

  /// The arrow of the most recent tap, its outcome, and (when blocked) the
  /// cell it bumped into. [moveToken] bumps on every tap so the UI can replay
  /// feedback even when two consecutive taps look the same.
  final int? lastMoveId;
  final MoveOutcome lastOutcome;
  final Cell? blockedCell;
  final int moveToken;

  /// True while a level restored from a saved game waits, paused, for the
  /// player to choose between picking it up and starting over.
  final bool resumeOffered;

  int get level => spec.level;
  int get arrowsOut => removed.length;
  int get arrowsTotal => puzzle?.arrowCount ?? spec.arrows;
  int get livesLeft => maxLives - mistakes;
  int get remainingMs =>
      (spec.timeLimitMs - elapsedMs).clamp(0, spec.timeLimitMs);

  /// Fraction of the level clock still left, 0..1.
  double get timeFraction => remainingMs / spec.timeLimitMs;

  /// Fraction of arrows out, 0..1.
  double get progress => arrowsTotal == 0 ? 0 : arrowsOut / arrowsTotal;

  bool get isLoading => phase == GamePhase.loading;
  bool get isPlaying => phase == GamePhase.playing;
  bool get isOver =>
      phase == GamePhase.cleared ||
      phase == GamePhase.outOfLives ||
      phase == GamePhase.timeUp;

  /// Stars earned — meaningful once [phase] is [GamePhase.cleared].
  int get stars =>
      phase == GamePhase.cleared ? starsForMistakes(mistakes) : 0;

  GameState copyWith({
    GamePhase? phase,
    Set<int>? removed,
    int? mistakes,
    int? hintsLeft,
    int? hintArrowId,
    bool clearHint = false,
    int? elapsedMs,
    int? lastMoveId,
    MoveOutcome? lastOutcome,
    Cell? blockedCell,
    bool clearBlocked = false,
    int? moveToken,
    bool? resumeOffered,
  }) =>
      GameState(
        spec: spec,
        puzzle: puzzle,
        phase: phase ?? this.phase,
        removed: removed ?? this.removed,
        mistakes: mistakes ?? this.mistakes,
        hintsLeft: hintsLeft ?? this.hintsLeft,
        hintArrowId: clearHint ? null : (hintArrowId ?? this.hintArrowId),
        elapsedMs: elapsedMs ?? this.elapsedMs,
        lastMoveId: lastMoveId ?? this.lastMoveId,
        lastOutcome: lastOutcome ?? this.lastOutcome,
        blockedCell: clearBlocked ? null : (blockedCell ?? this.blockedCell),
        moveToken: moveToken ?? this.moveToken,
        resumeOffered: resumeOffered ?? this.resumeOffered,
      );
}
