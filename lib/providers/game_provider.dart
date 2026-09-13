/// Per-attempt gameplay state: sliding arrows out, lives, hints, the level
/// clock, pause/resume and the three endings.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../engine/puzzle.dart';
import '../engine/puzzle_generator.dart';
import '../models/game_state.dart';
import '../models/level_progress.dart';
import '../models/level_spec.dart';
import '../services/haptics_service.dart';
import 'progress_provider.dart';

/// Called once when a level is cleared, with the clear time and star rating.
typedef ClearedCallback = void Function(int level, int elapsedMs, int stars);

/// The clock's resolution.
const int kTickMs = 100;

/// Builds a level's board; the default runs on a background isolate so the
/// big late boards never freeze the UI (on web it runs inline).
typedef PuzzleBuilder = Future<Puzzle> Function(LevelSpec spec);

// coverage:ignore-start
Future<Puzzle> defaultPuzzleBuilder(LevelSpec spec) => compute(puzzleForLevel, spec);
// coverage:ignore-end

class GameNotifier extends StateNotifier<GameState> {
  /// Starts playing at once when [puzzle] is given (tests); otherwise shows
  /// [GamePhase.loading] until [builder] delivers the board.
  GameNotifier(
    this.spec, {
    Puzzle? puzzle,
    PuzzleBuilder builder = defaultPuzzleBuilder,
    this.haptics,
    this.onCleared,
    this.autoTick = true,
  }) : super(puzzle == null ? GameState.loading(spec) : GameState.fresh(spec, puzzle)) {
    if (puzzle == null) {
      _load(builder);
    } else {
      _ready.complete();
      _startTimer();
    }
  }

  final LevelSpec spec;
  final HapticsService? haptics;
  final ClearedCallback? onCleared;

  /// When false (tests), the clock only advances through [tick].
  final bool autoTick;

  Timer? _timer;
  final Completer<void> _ready = Completer<void>();

  /// Completes once the board is on screen (useful in tests).
  Future<void> get ready => _ready.future;

  Future<void> _load(PuzzleBuilder builder) async {
    final puzzle = await builder(spec);
    if (!mounted) return;
    state = GameState.fresh(spec, puzzle);
    _startTimer();
    _ready.complete();
  }

  /// Taps arrow [id]: it slides out if its exit path is clear, otherwise it
  /// bumps and costs a life.
  void tapArrow(int id) {
    if (!state.isPlaying || state.removed.contains(id)) return;
    final puzzle = state.puzzle!;
    final token = state.moveToken + 1;
    if (puzzle.canExit(id, state.removed)) {
      final removed = <int>{...state.removed, id};
      final cleared = removed.length == puzzle.arrowCount;
      if (cleared) _stopTimer();
      state = state.copyWith(
        removed: removed,
        phase: cleared ? GamePhase.cleared : GamePhase.playing,
        clearHint: true,
        lastMoveId: id,
        lastOutcome: MoveOutcome.exited,
        clearBlocked: true,
        moveToken: token,
      );
      if (cleared) {
        haptics?.victory();
        onCleared?.call(spec.level, state.elapsedMs, state.stars);
      } else {
        haptics?.hit();
      }
      return;
    }
    final mistakes = state.mistakes + 1;
    final lost = mistakes >= maxLives;
    if (lost) _stopTimer();
    state = state.copyWith(
      mistakes: mistakes,
      phase: lost ? GamePhase.outOfLives : GamePhase.playing,
      clearHint: true,
      lastMoveId: id,
      lastOutcome: MoveOutcome.blocked,
      blockedCell: puzzle.firstBlockedCell(id, state.removed),
      moveToken: token,
    );
    if (lost) {
      haptics?.fail();
    } else {
      haptics?.miss();
    }
  }

  /// Spends a hint to point at an arrow that can go now. No-op while a hint
  /// is already showing, when none are left, or outside play.
  void useHint() {
    if (!state.isPlaying || state.hintsLeft <= 0 || state.hintArrowId != null) {
      return;
    }
    final id = state.puzzle!.hintFor(state.removed);
    if (id == null) return;
    state = state.copyWith(hintArrowId: id, hintsLeft: state.hintsLeft - 1);
    haptics?.tap();
  }

  /// Throws the attempt away and starts the same puzzle again.
  void restart() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    state = GameState.fresh(spec, puzzle);
    _startTimer();
  }

  void pause() {
    if (state.phase == GamePhase.playing) {
      state = state.copyWith(phase: GamePhase.paused);
    }
  }

  void resume() {
    if (state.phase == GamePhase.paused) {
      state = state.copyWith(phase: GamePhase.playing);
    }
  }

  /// Advances the clock by [ms]. Public so the timer callback and tests can
  /// drive it. Only the playing phase consumes time.
  void tick(int ms) {
    if (!state.isPlaying) return;
    final elapsed = state.elapsedMs + ms;
    if (elapsed >= spec.timeLimitMs) {
      _stopTimer();
      state = state.copyWith(elapsedMs: spec.timeLimitMs, phase: GamePhase.timeUp);
      haptics?.fail();
      return;
    }
    state = state.copyWith(elapsedMs: elapsed);
  }

  void _startTimer() {
    _stopTimer();
    // coverage:ignore-start
    if (autoTick) {
      _timer = Timer.periodic(
        const Duration(milliseconds: kTickMs),
        (_) => tick(kTickMs),
      );
    }
    // coverage:ignore-end
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// One notifier per level, thrown away when the game screen closes.
final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, int>((ref, level) {
  return GameNotifier(
    specForLevel(level),
    haptics: ref.watch(hapticsProvider),
    onCleared: ref.read(progressProvider.notifier).recordCompletion,
  );
});
