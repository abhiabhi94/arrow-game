/// Per-attempt gameplay state: sliding arrows out, lives, hints, the level
/// clock, pause/resume, the three endings, and snapshots for picking a
/// level up later.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../engine/puzzle.dart';
import '../engine/puzzle_generator.dart';
import '../models/bump_motion.dart';
import '../models/game_state.dart';
import '../models/level_progress.dart';
import '../models/level_spec.dart';
import '../models/saved_game.dart';
import '../services/haptics_service.dart';
import '../services/sfx_service.dart';
import 'progress_provider.dart';
import 'saved_game_provider.dart';

/// Called once when a level is cleared, with the clear time and star rating.
typedef ClearedCallback = void Function(int level, int elapsedMs, int stars);

/// Called whenever the level's standing is worth remembering: after every
/// move, hint, pause, restart or ending, and when the screen goes away.
typedef SnapshotCallback = void Function(GameState state);

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
    this.savedGame,
    this.haptics,
    this.sfx,
    this.onCleared,
    this.onSnapshot,
    this.autoTick = true,
  }) : super(puzzle == null ? GameState.loading(spec) : GameState.fresh(spec, puzzle)) {
    if (puzzle == null) {
      _load(builder);
    } else {
      _begin(puzzle);
    }
  }

  final LevelSpec spec;
  final HapticsService? haptics;
  final SfxService? sfx;
  final ClearedCallback? onCleared;
  final SnapshotCallback? onSnapshot;

  /// When false (tests), the clock only advances through [tick].
  final bool autoTick;

  /// A saved game to restore once the board is ready, if it fits this level.
  final SavedGame? savedGame;
  Timer? _timer;
  Timer? _impact;
  final Completer<void> _ready = Completer<void>();

  /// Completes once the board is on screen (useful in tests).
  Future<void> get ready => _ready.future;

  Future<void> _load(PuzzleBuilder builder) async {
    final puzzle = await builder(spec);
    if (!mounted) return;
    _begin(puzzle);
  }

  /// Puts [puzzle] on the board: fresh and playing, or — when a saved game
  /// for this level fits it — restored and paused with the resume offer up.
  void _begin(Puzzle puzzle) {
    final saved = savedGame;
    if (saved != null && _fits(saved, puzzle)) {
      state = GameState.fresh(spec, puzzle).copyWith(
        phase: GamePhase.paused,
        removed: saved.removed.toSet(),
        bumped: saved.bumped.toSet(),
        mistakes: saved.mistakes,
        hintsLeft: saved.hintsLeft,
        elapsedMs: saved.elapsedMs,
        resumeOffered: true,
        continuedAfterLoss: saved.continuedAfterLoss,
      );
    } else {
      state = GameState.fresh(spec, puzzle);
    }
    _startTimer();
    _ready.complete();
  }

  /// Whether [saved] describes a moment this level can still be in.
  bool _fits(SavedGame saved, Puzzle puzzle) =>
      saved.level == spec.level &&
      saved.hasProgress &&
      saved.removed.length < puzzle.arrowCount &&
      saved.removed.every((id) => id >= 0 && id < puzzle.arrowCount) &&
      (saved.continuedAfterLoss || saved.mistakes < livesForLevel(spec.level)) &&
      saved.hintsLeft >= 0 &&
      saved.hintsLeft <= maxHints &&
      saved.elapsedMs >= 0 &&
      saved.elapsedMs < spec.timeLimitMs;

  void _snapshot() => onSnapshot?.call(state);

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
      sfx?.whoosh();
      if (cleared) {
        haptics?.victory();
        onCleared?.call(spec.level, state.elapsedMs, state.stars);
      } else {
        haptics?.hit();
      }
      _snapshot();
      return;
    }
    // Two bumps the board does not charge for: a second run at an arrow that
    // has already bumped (that lesson is paid for, and a 200-arrow board is
    // far too big to hold every dead end in your head), and any bump at all
    // once the player has spent the allowance and chosen to play on.
    final free = state.bumped.contains(id) || state.continuedAfterLoss;
    final mistakes = free ? state.mistakes : state.mistakes + 1;
    final lost = !state.continuedAfterLoss && mistakes >= state.lives;
    if (lost) _stopTimer();
    final blockedCell = puzzle.firstBlockedCell(id, state.removed)!;
    state = state.copyWith(
      mistakes: mistakes,
      bumped: <int>{...state.bumped, id},
      phase: lost ? GamePhase.outOfLives : GamePhase.playing,
      clearHint: true,
      lastMoveId: id,
      lastOutcome: MoveOutcome.blocked,
      blockedCell: blockedCell,
      moveToken: token,
    );
    haptics?.tap();
    // The knock and the buzz land when the arrow actually hits, not when
    // the finger does — the board plays the same motion.
    final motion = BumpMotion.forTap(puzzle, id, blockedCell);
    _impact?.cancel();
    _impact = Timer(Duration(milliseconds: motion.forwardMs), () {
      _impact = null;
      sfx?.bump();
      if (lost) {
        haptics?.fail();
      } else if (free) {
        // No life lost: answer the finger, but don't punch.
        haptics?.tap();
      } else {
        haptics?.miss();
      }
    });
    _snapshot();
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
    _snapshot();
  }

  /// Throws the attempt away and starts the same puzzle again.
  void restart() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    _impact?.cancel();
    _impact = null;
    state = GameState.fresh(spec, puzzle);
    _startTimer();
    _snapshot();
  }

  /// Carries on from [GamePhase.outOfLives] instead of replaying: the board
  /// and the clock are where they were, blocked taps stop costing anything,
  /// and the clear will be worth one star. Losing a level's worth of correct
  /// taps to a slipped finger is the worst thing the game does; running out
  /// of time is still a real ending.
  void keepGoing() {
    if (state.phase != GamePhase.outOfLives) return;
    state = state.copyWith(phase: GamePhase.playing, continuedAfterLoss: true);
    _startTimer();
    _snapshot();
  }

  void pause() {
    if (state.phase == GamePhase.playing) {
      state = state.copyWith(phase: GamePhase.paused);
      _snapshot();
    }
  }

  /// Continues a paused level — including one just restored, which drops
  /// the resume offer.
  void resume() {
    if (state.phase == GamePhase.paused) {
      state = state.copyWith(phase: GamePhase.playing, resumeOffered: false);
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
      _snapshot();
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
    _impact?.cancel();
    // Leaving the screen (back, quit, next level) is the moment to remember
    // where the level stood.
    _snapshot();
    super.dispose();
  }
}

/// One notifier per level, thrown away when the game screen closes. A level
/// with a saved game comes back where it was left, paused, with the choice
/// to continue or start over.
final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, int>((ref, level) {
  final saves = ref.read(savedGameProvider.notifier);
  return GameNotifier(
    specForLevel(level),
    savedGame: saves.forLevel(level),
    haptics: ref.watch(hapticsProvider),
    sfx: ref.watch(sfxProvider),
    onCleared: ref.read(progressProvider.notifier).recordCompletion,
    onSnapshot: saves.record,
  );
});
