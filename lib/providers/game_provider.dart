/// Per-attempt gameplay state: dealing arrows, scoring swipes, lives, the
/// level clock and the per-arrow fuse, pause/resume and the three endings.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../engine/arrow_factory.dart';
import '../engine/direction.dart';
import '../models/game_state.dart';
import '../models/level_progress.dart';
import '../models/level_spec.dart';
import '../services/haptics_service.dart';
import 'progress_provider.dart';

/// Called once when a level is cleared, with the clear time and star rating.
typedef ClearedCallback = void Function(int level, int elapsedMs, int stars);

/// The clock's resolution. Fine enough for a smooth fuse ring; coarse enough
/// to stay cheap.
const int kTickMs = 100;

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier(
    this.spec, {
    this.haptics,
    this.onCleared,
    Random? random,
    this.autoTick = true,
  })  : _factory = ArrowFactory(spec, random: random),
        super(GameState.ready(spec));

  final LevelSpec spec;
  final HapticsService? haptics;
  final ClearedCallback? onCleared;

  /// When false (tests), the clock only advances through [tick].
  final bool autoTick;

  final ArrowFactory _factory;
  Timer? _timer;

  /// Leaves the intro and deals the first arrow. No-op unless [GamePhase.ready].
  void start() {
    if (state.phase != GamePhase.ready) return;
    state = state.copyWith(
      phase: GamePhase.playing,
      arrow: _factory.next(),
      arrowAgeMs: 0,
    );
    haptics?.tap();
    _startTimer();
  }

  /// Throws away the attempt and immediately starts a fresh one (the "Retry" /
  /// "Play again" buttons).
  void restart() {
    _stopTimer();
    _factory.reset();
    state = GameState.ready(spec);
    start();
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

  /// Scores a swipe/tap in [direction] against the current arrow.
  void answer(Direction direction) {
    final arrow = state.arrow;
    if (!state.isPlaying || arrow == null) return;
    if (arrow.accepts(direction)) {
      _hit();
    } else {
      _miss();
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
    final age = state.arrowAgeMs + ms;
    if (spec.hasFuse && age >= spec.arrowTimeoutMs) {
      state = state.copyWith(elapsedMs: elapsed, arrowAgeMs: age);
      _miss();
      return;
    }
    state = state.copyWith(elapsedMs: elapsed, arrowAgeMs: age);
  }

  void _hit() {
    final hits = state.hits + 1;
    final streak = state.streak + 1;
    final bestStreak = max(streak, state.bestStreak);
    if (hits >= spec.targetHits) {
      _stopTimer();
      state = state.copyWith(
        hits: hits,
        streak: streak,
        bestStreak: bestStreak,
        phase: GamePhase.cleared,
        lastOutcome: Outcome.hit,
        outcomeToken: state.outcomeToken + 1,
      );
      haptics?.victory();
      onCleared?.call(spec.level, state.elapsedMs, state.stars);
      return;
    }
    state = state.copyWith(
      hits: hits,
      streak: streak,
      bestStreak: bestStreak,
      arrow: _factory.next(),
      arrowAgeMs: 0,
      lastOutcome: Outcome.hit,
      outcomeToken: state.outcomeToken + 1,
    );
    haptics?.hit();
  }

  void _miss() {
    final mistakes = state.mistakes + 1;
    if (mistakes >= maxLives) {
      _stopTimer();
      state = state.copyWith(
        mistakes: mistakes,
        streak: 0,
        phase: GamePhase.outOfLives,
        lastOutcome: Outcome.miss,
        outcomeToken: state.outcomeToken + 1,
      );
      haptics?.fail();
      return;
    }
    state = state.copyWith(
      mistakes: mistakes,
      streak: 0,
      arrow: _factory.next(),
      arrowAgeMs: 0,
      lastOutcome: Outcome.miss,
      outcomeToken: state.outcomeToken + 1,
    );
    haptics?.miss();
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
