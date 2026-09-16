import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../l10n/app_localizations.dart';
import '../models/bump_motion.dart';
import '../models/game_state.dart';
import '../models/reaction_motion.dart';
import '../providers/game_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/riddle_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import '../widgets/board_toolbar.dart';
import '../widgets/lives_indicator.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/result_card.dart';
import '../widgets/riddle_card.dart';
import '../widgets/stars_row.dart';
import '../widgets/timer_bar.dart';

/// Zoom steps for the board (pinch works too, within the same bounds).
const double kMinZoom = 1.0;
const double kMaxZoom = 4.0;
const double kZoomStep = 1.35;

/// How big a cell should be able to get, in logical pixels — about a
/// fingertip. A 42x63 board draws a cell at 8 px, so a flat 4x ceiling left
/// the last levels with no zoom at which a cell was finger-sized at all.
const double kFingerCellPx = 46;

/// The zoom ceiling for a board whose cells are [cellPx] across at 1x:
/// [kMaxZoom], or enough to bring a cell up to [kFingerCellPx].
double maxZoomFor(double cellPx) =>
    cellPx <= 0 ? kMaxZoom : max(kMaxZoom, kFingerCellPx / cellPx).clamp(kMaxZoom, 8.0);

/// The gameplay screen: HUD (clock, arrows out, lives), the zoomable board,
/// the toolbar (hint / grid / zoom), and the pause/result overlays.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

/// How far the screen is thrown sideways at the peak of a crash, in
/// logical pixels.
const double kCrashJoltPx = 7;

/// The side gutter the HUD and toolbar keep. The board itself goes edge to
/// edge, which is worth about 9% more cell on the dense late levels.
const EdgeInsets _gutter = EdgeInsets.symmetric(horizontal: 16);

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  /// The crash of a bump, felt by the whole screen: it runs the same
  /// [BumpMotion] as the board so the jolt and the red flash land on impact.
  late final AnimationController _crash = AnimationController(vsync: this);
  BumpMotion? _crashMotion;

  /// The hop a cleared level does: the whole play column squashes, springs and
  /// settles. By then the board is empty — every arrow has left — so the
  /// celebration has to be the screen rather than the arrows.
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: kHopMs),
  );
  final TransformationController _zoom = TransformationController();
  double _scale = 1;
  Size _viewport = Size.zero;

  /// Whether the clear being shown beat the previous best (read once, before
  /// the progress notifier records the new time).
  bool _newBest = false;

  /// Whether this clear just earned the grid-lines toggle.
  bool _gridJustUnlocked = false;

  /// True while the bump that spent the last life is still playing. The
  /// ending card would otherwise drop its scrim over the board in the same
  /// frame as the tap, and the player would never see the crash that cost
  /// them the level — only the card telling them about it.
  bool _endingHeld = false;

  /// The riddle standing between a spent allowance and one more life, or
  /// null while the ending card itself is up. Held here rather than in the
  /// game state: the board is none the wiser, and a rebuild must not deal a
  /// different riddle mid-thought.
  int? _riddleId;

  /// Deals a riddle (a fresh one on every ask, including a swap).
  void _dealRiddle() {
    setState(() => _riddleId = ref.read(riddleDeckProvider.notifier).draw());
  }

  /// Answered: bank the badge, hand back the life, put the card away.
  void _riddleSolved() {
    ref.read(riddleDeckProvider.notifier).recordSolved();
    ref.read(gameProvider(widget.level).notifier).keepGoing();
    setState(() => _riddleId = null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _crash.addStatusListener((status) {
      if (status == AnimationStatus.completed && _endingHeld && mounted) {
        setState(() => _endingHeld = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _crash.dispose();
    _hop.dispose();
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
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)));
  }

  /// The zoom ceiling for the level on screen, from how small a cell is
  /// drawn in the viewport the board actually has.
  double get _maxZoom {
    if (_viewport.isEmpty) return kMaxZoom;
    final spec = specForLevel(widget.level);
    return maxZoomFor(min(_viewport.width / spec.width, _viewport.height / spec.height));
  }

  /// Zooms about the centre of the board viewport.
  void _setZoom(double scale) {
    final s = scale.clamp(kMinZoom, _maxZoom);
    final dx = _viewport.width * (1 - s) / 2;
    final dy = _viewport.height * (1 - s) / 2;
    setState(() {
      _scale = s;
      _zoom.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    });
  }

  /// Keyboard shortcuts for the web build, played on a laptop via GitHub
  /// Pages: H asks for a hint, + / - zoom, G toggles the grid lines (once
  /// earned) and Space or P pauses and resumes. Taps stay on the mouse — the
  /// arrows are drawn on a canvas, not focusable widgets. Anything with a
  /// modifier held is left alone so the browser keeps its own shortcuts.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isMetaPressed || keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    // While a riddle is on the table the keyboard is for typing the answer:
    // "shadow" must not spend a hint on its h and pause on its space.
    if (_riddleId != null) return KeyEventResult.ignored;
    final provider = gameProvider(widget.level);
    final state = ref.read(provider);
    final notifier = ref.read(provider.notifier);
    switch (shortcutFor(event)) {
      case null:
        return KeyEventResult.ignored;
      case GameShortcut.hint:
        notifier.useHint(); // no-op unless playing with a hint to spare
      case GameShortcut.zoomIn:
        _setZoom(_scale * kZoomStep);
      case GameShortcut.zoomOut:
        _setZoom(_scale / kZoomStep);
      case GameShortcut.grid:
        if (ref.read(progressProvider.notifier).gridLinesUnlocked) {
          final settings = ref.read(settingsProvider.notifier);
          settings.setGridLines(!ref.read(settingsProvider).gridLinesOn);
        }
      case GameShortcut.pause:
        // Resume covers the "Welcome back" card too: Space is "Continue".
        state.isPlaying ? notifier.pause() : notifier.resume();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = gameProvider(widget.level);
    final progress = ref.read(progressProvider.notifier);
    ref.listen(provider, (prev, next) {
      if (next.lastOutcome == MoveOutcome.blocked && next.moveToken != prev?.moveToken) {
        final motion = BumpMotion.forTap(next.puzzle!, next.lastMoveId!, next.blockedCell!);
        _crashMotion = motion;
        _crash
          ..duration = Duration(milliseconds: motion.totalMs)
          ..forward(from: 0);
        // The bump that ends the attempt gets to play out first.
        _endingHeld = next.phase == GamePhase.outOfLives;
      }
      // Restarting (or any other way out of the ending) takes the riddle
      // with it, so backing out never leaves a card floating over the board.
      if (next.phase != GamePhase.outOfLives && _riddleId != null) {
        setState(() => _riddleId = null);
      }
      if (next.phase == GamePhase.cleared && prev?.phase != GamePhase.cleared) {
        _hop.forward(from: 0);
        _newBest = progress.progressFor(widget.level).isNewBest(next.elapsedMs);
        _gridJustUnlocked =
            widget.level == kGridLinesUnlockAfterLevel &&
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

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      // A focusable node would swallow every descendant label (clock, lives,
      // tutorial line) into one; the screen's widgets keep their own.
      includeSemantics: false,
      child: Scaffold(
        appBar: AppBar(
          // Two lines so long level names never truncate on narrow phones.
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.levelNumber(widget.level)),
              Text(
                levelName(l10n, widget.level),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textMuted),
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
              // Phone-first layout in a desktop browser: the clock, board and
              // toolbar keep to a centred phone-width column instead of
              // spreading across the window. The board loses nothing — the
              // levels are taller than wide, so the window's height is what
              // sizes them there.
              AnimatedBuilder(
                animation: Listenable.merge([_crash, _hop]),
                builder: (context, child) => Transform.translate(
                  offset: Offset((_crashMotion?.joltAt(_crash.value) ?? 0) * kCrashJoltPx, 0),
                  child: Transform.scale(
                    scaleX: _hop.isAnimating ? hopScaleX(_hop.value) : 1,
                    scaleY: _hop.isAnimating ? hopScaleY(_hop.value) : 1,
                    child: child,
                  ),
                ),
                child: ContentColumn(
                  child: Padding(
                    // No side padding here: the board runs edge to edge and the
                    // HUD and toolbar take the gutter themselves.
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: _gutter,
                          child: Row(
                            children: [
                              Expanded(
                                child: TimerBar(
                                  remainingMs: state.remainingMs,
                                  fraction: state.timeFraction,
                                ),
                              ),
                              const SizedBox(width: 14),
                              LivesIndicator(livesLeft: state.livesLeft),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              _viewport = constraints.biggest;
                              return ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _zoom,
                                  minScale: kMinZoom,
                                  maxScale: _maxZoom,
                                  onInteractionEnd: (_) {
                                    final s = _zoom.value.getMaxScaleOnAxis();
                                    if (s != _scale) setState(() => _scale = s);
                                  },
                                  child: SizedBox.expand(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: state.isLoading
                                          ? _LoadingView(message: l10n.gameLoading)
                                          : PuzzleBoard(
                                              state: state,
                                              showGrid: gridUnlocked && settings.gridLinesOn,
                                              onTapArrow: notifier.tapArrow,
                                              zoom: _scale,
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              widget.level == 1 ? l10n.tutorialTap : l10n.tutorialBlocked,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.textMuted, fontSize: 13),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: _gutter,
                          child: BoardToolbar(
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
                            canZoomIn: _scale < _maxZoom - 0.001,
                            canZoomOut: _scale > kMinZoom + 0.001,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // The crash flash: a red edge over the whole screen that
              // blooms at impact and fades with the spring back.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _crash,
                    builder: (context, child) => Opacity(
                      key: const ValueKey<String>('crash-flash'),
                      opacity: _crashMotion?.flashAt(_crash.value) ?? 0,
                      child: child,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.1,
                          colors: [Colors.transparent, p.blockedFlash],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                  ),
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
                GamePhase.paused when state.resumeOffered => ResultCard(
                  emoji: '👋',
                  title: l10n.resumeTitle,
                  body: l10n.resumeBody(
                    state.arrowsOut,
                    state.arrowsTotal,
                    formatDurationMs(state.elapsedMs),
                  ),
                  actions: [
                    FilledButton(onPressed: notifier.resume, child: Text(l10n.resumeContinue)),
                    OutlinedButton(onPressed: notifier.restart, child: Text(l10n.resumeStartOver)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
                GamePhase.paused => ResultCard(
                  emoji: '⏸️',
                  title: l10n.gamePaused,
                  body: l10n.gamePausedBody,
                  actions: [
                    FilledButton(onPressed: notifier.resume, child: Text(l10n.gameResume)),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.gameQuit),
                    ),
                  ],
                ),
                GamePhase.cleared => ResultCard(
                  mood: EmojiMood.cheer,
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
                        style: TextStyle(fontWeight: FontWeight.w800, color: p.textInk),
                      ),
                      if (_newBest)
                        Text(
                          l10n.clearedNewBest,
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.accentMint),
                        ),
                      if (_gridJustUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.gridUnlockedToast,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: p.primary),
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
                    OutlinedButton(onPressed: notifier.restart, child: Text(l10n.clearedReplay)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
                // Nothing over the board until the crash has been seen.
                GamePhase.outOfLives when _endingHeld => const SizedBox.shrink(),
                // A spent allowance is not the end of the level, but it is
                // no longer free either: carrying on is earned by cracking a
                // riddle, so a board is never lost to a slipped finger and
                // lives are never spent thoughtlessly.
                GamePhase.outOfLives when _riddleId != null => RiddleChallenge(
                  key: ValueKey<int>(_riddleId!),
                  riddleId: _riddleId!,
                  solvedCount: ref.watch(riddleDeckProvider).solved,
                  onSolved: _riddleSolved,
                  onSwap: _dealRiddle,
                  onDismiss: () => setState(() => _riddleId = null),
                ),
                GamePhase.outOfLives => ResultCard(
                  mood: EmojiMood.sulk,
                  emoji: '💔',
                  title: l10n.outOfLivesTitle,
                  body: l10n.outOfLivesBody,
                  actions: [
                    FilledButton(
                      onPressed: _dealRiddle,
                      child: Text(l10n.outOfLivesSolveRiddle),
                    ),
                    OutlinedButton(onPressed: notifier.restart, child: Text(l10n.outOfLivesRetry)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
                GamePhase.timeUp => ResultCard(
                  mood: EmojiMood.sulk,
                  emoji: '⏰',
                  title: l10n.timeUpTitle,
                  body: l10n.timeUpBody(state.arrowsOut, state.arrowsTotal),
                  actions: [
                    FilledButton(onPressed: notifier.restart, child: Text(l10n.timeUpRetry)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
                GamePhase.playing || GamePhase.loading => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// What a key press on the game screen does.
enum GameShortcut { hint, zoomIn, zoomOut, grid, pause }

/// The shortcut a key press means, or null when it isn't one. Zoom answers
/// both the main row and the numeric keypad, and `=` stands in for `+` so it
/// works without Shift on a US layout.
@visibleForTesting
GameShortcut? shortcutFor(KeyEvent event) => switch (event.logicalKey) {
  LogicalKeyboardKey.keyH => GameShortcut.hint,
  LogicalKeyboardKey.equal ||
  LogicalKeyboardKey.add ||
  LogicalKeyboardKey.numpadAdd => GameShortcut.zoomIn,
  LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract => GameShortcut.zoomOut,
  LogicalKeyboardKey.keyG => GameShortcut.grid,
  LogicalKeyboardKey.space || LogicalKeyboardKey.keyP => GameShortcut.pause,
  _ => null,
};

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: context.palette.textMuted)),
      ],
    ),
  );
}
