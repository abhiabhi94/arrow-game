import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import '../widgets/board_toolbar.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/result_card.dart';
import '../widgets/stars_row.dart';
import '../widgets/timer_bar.dart';

/// Zoom steps for the board (pinch works too, within the same bounds).
const double kMinZoom = 1.0;
const double kMaxZoom = 3.0;
const double kZoomStep = 1.35;

/// The gameplay screen: HUD (clock, arrows out, lives), the zoomable board,
/// the toolbar (hint / grid / zoom), and the pause/result overlays.
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
  final TransformationController _zoom = TransformationController();
  double _scale = 1;
  Size _viewport = Size.zero;

  /// Whether the clear being shown beat the previous best (read once, before
  /// the progress notifier records the new time).
  bool _newBest = false;

  /// Whether this clear just earned the grid-lines toggle.
  bool _gridJustUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confetti.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never let the clock run while the player can't see the board.
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

  /// Zooms about the centre of the board viewport.
  void _setZoom(double scale) {
    final s = scale.clamp(kMinZoom, kMaxZoom);
    final dx = _viewport.width * (1 - s) / 2;
    final dy = _viewport.height * (1 - s) / 2;
    setState(() {
      _scale = s;
      _zoom.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = gameProvider(widget.level);
    final progress = ref.read(progressProvider.notifier);
    ref.listen(provider, (prev, next) {
      if (next.phase == GamePhase.cleared && prev?.phase != GamePhase.cleared) {
        _newBest = progress.progressFor(widget.level).isNewBest(next.elapsedMs);
        _gridJustUnlocked = widget.level == kGridLinesUnlockAfterLevel &&
            !progress.progressFor(widget.level).completed;
        _confetti.play();
      }
    });
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final settings = ref.watch(settingsProvider);
    // Watch progress so the grid toggle unlocks live.
    ref.watch(progressProvider);
    final gridUnlocked = progress.gridLinesUnlocked;
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
          if (state.isPlaying) ...[
            IconButton(
              tooltip: l10n.gameRestart,
              onPressed: notifier.restart,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: l10n.gamePause,
              onPressed: notifier.pause,
              icon: const Icon(Icons.pause_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  TimerBar(remainingMs: state.remainingMs, fraction: state.timeFraction),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ProgressPill(
                        text: l10n.hudArrows(state.arrowsOut, state.arrowsTotal),
                        fraction: state.progress,
                      ),
                      LivesIndicator(livesLeft: state.livesLeft),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _viewport = constraints.biggest;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: InteractiveViewer(
                            transformationController: _zoom,
                            minScale: kMinZoom,
                            maxScale: kMaxZoom,
                            onInteractionEnd: (_) {
                              final s = _zoom.value.getMaxScaleOnAxis();
                              if (s != _scale) setState(() => _scale = s);
                            },
                            child: SizedBox.expand(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: PuzzleBoard(
                                  state: state,
                                  showGrid: gridUnlocked && settings.gridLinesOn,
                                  onTapArrow: notifier.tapArrow,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.level <= 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.level == 1 ? l10n.tutorialTap : l10n.tutorialBlocked,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.textMuted, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 12),
                  BoardToolbar(
                    hintsLeft: state.hintsLeft,
                    hintActive: state.hintArrowId != null,
                    onHint: state.isPlaying ? notifier.useHint : null,
                    gridUnlocked: gridUnlocked,
                    gridUnlockLevel: kGridLinesUnlockAfterLevel,
                    gridOn: settings.gridLinesOn,
                    onToggleGrid: () => ref
                        .read(settingsProvider.notifier)
                        .setGridLines(!settings.gridLinesOn),
                    onZoomIn: () => _setZoom(_scale * kZoomStep),
                    onZoomOut: () => _setZoom(_scale / kZoomStep),
                    canZoomIn: _scale < kMaxZoom - 0.001,
                    canZoomOut: _scale > kMinZoom + 0.001,
                  ),
                ],
              ),
            ),
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
                      if (_gridJustUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.gridUnlockedToast,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.primary,
                            ),
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
                  body: l10n.timeUpBody(state.arrowsOut, state.arrowsTotal),
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
          Icon(Icons.north_east_rounded, size: 18, color: p.primary),
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
