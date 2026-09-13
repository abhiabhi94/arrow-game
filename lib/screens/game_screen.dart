import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../ui/colors.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import '../widgets/arrow_view.dart';
import '../widgets/direction_pad.dart';
import '../widgets/level_intro.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/result_card.dart';
import '../widgets/stars_row.dart';
import '../widgets/streak_badge.dart';
import '../widgets/timer_bar.dart';

/// The gameplay screen: HUD (clock, progress, lives), the swipe arena with the
/// current arrow, the direction pad, and the intro/pause/result overlays.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  /// Whether the clear being shown beat the previous best (read once, before
  /// the progress notifier records the new time).
  bool _newBest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confetti.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never let the clock run while the player can't see the arrow.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(gameProvider(widget.level).notifier).pause();
    }
  }

  void _openLevel(int level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = gameProvider(widget.level);
    ref.listen(provider, (prev, next) {
      if (next.phase == GamePhase.cleared && prev?.phase != GamePhase.cleared) {
        _newBest = ref
            .read(progressProvider.notifier)
            .progressFor(widget.level)
            .isNewBest(next.elapsedMs);
        _confetti.play();
      }
    });
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        // Two lines so long level names never truncate on narrow phones.
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.levelNumber(widget.level)),
            Text(
              levelName(l10n, widget.level),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          if (state.isPlaying)
            IconButton(
              tooltip: l10n.gamePause,
              onPressed: notifier.pause,
              icon: const Icon(Icons.pause_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _PlayView(state: state, onDirection: notifier.answer),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                gravity: 0.25,
                colors: [p.primary, p.accentCoral, p.accentSun, p.accentMint],
              ),
            ),
            switch (state.phase) {
              GamePhase.ready => LevelIntro(spec: state.spec, onStart: notifier.start),
              GamePhase.paused => ResultCard(
                  emoji: '⏸️',
                  title: l10n.gamePaused,
                  body: l10n.gamePausedBody,
                  actions: [
                    FilledButton(
                      onPressed: notifier.resume,
                      child: Text(l10n.gameResume),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.gameQuit),
                    ),
                  ],
                ),
              GamePhase.cleared => ResultCard(
                  emoji: state.stars == 3 ? '🏆' : '🎉',
                  title: l10n.clearedTitle,
                  body: switch (state.stars) {
                    3 => l10n.clearedFlawless,
                    2 => l10n.clearedGood,
                    _ => l10n.clearedOkay,
                  },
                  content: Column(
                    children: [
                      StarsRow(stars: state.stars, size: 44, animated: true),
                      const SizedBox(height: 10),
                      Text(
                        l10n.clearedTime(formatDurationMs(state.elapsedMs)),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: p.textInk,
                        ),
                      ),
                      if (_newBest)
                        Text(
                          l10n.clearedNewBest,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: p.accentMint,
                          ),
                        ),
                      if (widget.level == totalLevels)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.clearedAllDone,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.textMuted),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    if (widget.level < totalLevels)
                      FilledButton(
                        onPressed: () => _openLevel(widget.level + 1),
                        child: Text(l10n.clearedNext),
                      ),
                    OutlinedButton(
                      onPressed: notifier.restart,
                      child: Text(l10n.clearedReplay),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
              GamePhase.outOfLives => ResultCard(
                  emoji: '💔',
                  title: l10n.outOfLivesTitle,
                  body: l10n.outOfLivesBody,
                  actions: [
                    FilledButton(
                      onPressed: notifier.restart,
                      child: Text(l10n.outOfLivesRetry),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
              GamePhase.timeUp => ResultCard(
                  emoji: '⏰',
                  title: l10n.timeUpTitle,
                  body: l10n.timeUpBody(state.hits, state.spec.targetHits),
                  actions: [
                    FilledButton(
                      onPressed: notifier.restart,
                      child: Text(l10n.timeUpRetry),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
              GamePhase.playing => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView({required this.state, required this.onDirection});

  final GameState state;
  final ValueChanged<Direction> onDirection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final arrow = state.arrow;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          TimerBar(remainingMs: state.remainingMs, fraction: state.timeFraction),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressPill(
                text: l10n.hudHits(state.hits, state.spec.targetHits),
                fraction: state.progress,
              ),
              LivesIndicator(livesLeft: state.livesLeft),
            ],
          ),
          const SizedBox(height: 8),
          StreakBadge(streak: state.streak),
          Expanded(
            child: _SwipeArena(
              outcome: state.lastOutcome,
              outcomeToken: state.outcomeToken,
              onDirection: onDirection,
              child: arrow == null
                  ? const SizedBox.shrink()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final size = min(
                          220.0,
                          min(constraints.maxWidth, constraints.maxHeight) - 40,
                        );
                        return Center(
                          child: ArrowView(
                            arrow: arrow,
                            visible: state.arrowVisible,
                            fuseFraction: state.fuseFraction,
                            size: max(size, 100),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          DirectionPad(onDirection: onDirection, enabled: state.isPlaying),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.text, required this.fraction});
  final String text;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 18, color: p.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: p.textInk)),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: p.timerTrack,
                color: p.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The swipeable area around the arrow. Fires [onDirection] once per gesture
/// as soon as the drag is decisively in one direction, flashes green/red and
/// shakes on a miss.
class _SwipeArena extends StatefulWidget {
  const _SwipeArena({
    required this.outcome,
    required this.outcomeToken,
    required this.onDirection,
    required this.child,
  });

  final Outcome outcome;
  final int outcomeToken;
  final ValueChanged<Direction> onDirection;
  final Widget child;

  @override
  State<_SwipeArena> createState() => _SwipeArenaState();
}

class _SwipeArenaState extends State<_SwipeArena> {
  static const double _swipeDistance = 32;

  Offset _start = Offset.zero;
  bool _fired = false;

  void _onStart(DragStartDetails d) {
    _start = d.localPosition;
    _fired = false;
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_fired) return;
    final delta = d.localPosition - _start;
    final dir = directionFromSwipe(delta.dx, delta.dy, minDistance: _swipeDistance);
    if (dir == null) return;
    _fired = true;
    widget.onDirection(dir);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final flash = switch (widget.outcome) {
      Outcome.hit => p.arenaHit,
      Outcome.miss => p.arenaMiss,
      Outcome.none => p.surface,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onStart,
      onPanUpdate: _onUpdate,
      child: _ShakeOnChange(
        trigger: widget.outcome == Outcome.miss ? widget.outcomeToken : 0,
        child: TweenAnimationBuilder<Color?>(
          key: ValueKey<int>(widget.outcomeToken),
          tween: ColorTween(begin: flash, end: p.surface),
          duration: const Duration(milliseconds: 450),
          builder: (context, color, child) => Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: p.outlineSoft),
            ),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Plays a quick damped horizontal shake each time [trigger] changes to a
/// non-zero value. An implicit animation (no stray timers), so it's safe in
/// widget tests.
class _ShakeOnChange extends StatelessWidget {
  const _ShakeOnChange({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(trigger),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        final dx = trigger == 0 ? 0.0 : sin(t * pi * 5) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
