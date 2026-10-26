import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapters.dart';
import '../data/level_specs.dart';
import '../engine/cube.dart';
import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../models/board_cursor.dart';
import '../models/bump_motion.dart';
import '../models/game_state.dart';
import '../models/level_spec.dart';
import '../models/reaction_motion.dart';
import '../models/riddle.dart';
import '../providers/daily_provider.dart';
import '../providers/game_provider.dart';
import '../providers/intro_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/riddle_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import '../widgets/board_toolbar.dart';
import '../widgets/chapter_demo.dart';
import '../widgets/cube_map.dart';
import '../widgets/cube_stage.dart';
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
/// the toolbar (hint / grid / zoom), and the pause/result overlays. A
/// chapter's first level opens on an illustrated card of the twist it
/// brings, the first time it is played.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.level});

  /// Today's daily board rather than a level of the trail.
  const GameScreen.daily({super.key}) : level = LevelSpec.dailyLevel;

  /// A level of the trail, or [LevelSpec.dailyLevel] for the daily board.
  final int level;

  bool get isDaily => level == LevelSpec.dailyLevel;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

/// How long a cleared face stays in front before the block turns on to the
/// next by itself: long enough for the last arrow's slide to be seen.
const Duration kCubeAutoTurnDelay = Duration(milliseconds: 750);

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
  /// between a spent hint allowance and one more hint — null while no card
  /// is up. Held here rather than in the game state: the board is none the
  /// wiser, and a rebuild must not deal a different riddle mid-thought.
  int? _riddleId;

  /// The bank [_riddleId] was dealt from — see [OpenRiddle.language].
  String? _riddleLanguage;

  /// What the riddle on the table is for. A life is asked for over the
  /// "Out of lives" card; a hint pauses the level and asks over the board,
  /// so the clock is not running while the player thinks.
  RiddlePrize _riddlePrize = RiddlePrize.life;

  /// The keyboard cursor: the arrow the arrow keys have walked to, ringed on
  /// the board and played by Enter (see `models/board_cursor.dart`). Null
  /// until a key is pressed; an arrow that has left keeps the cursor where
  /// it was until the next step. Dropped on a restart.
  int? _cursor;

  /// Whether the screen keeps still — read in build, used by the listener.
  bool _calm = false;

  /// On a cube level, the face of the block being played — the one the
  /// block stands square on (`CubeStage` turns it round to this one).
  int _face = 0;

  /// The pause before the block turns on by itself from a cleared face.
  Timer? _turnTimer;

  /// Turns the block a quarter [turn]: the face that way comes to the front.
  void _turnCube(CubeTurn turn) => _turnTo(cubeNeighbour(_face, turn));

  /// Turns the block round to [face].
  void _turnTo(int face) {
    _turnTimer?.cancel();
    if (face != _face) setState(() => _face = face);
  }

  /// Arrows still on each face of the block.
  static List<int> _faceLeft(GameState state) {
    final puzzle = state.puzzle!;
    final left = List<int>.filled(puzzle.faceCount, 0);
    for (final a in puzzle.arrows) {
      if (!state.removed.contains(a.id)) left[puzzle.faceOf(a.id)]++;
    }
    return left;
  }

  /// The face of the block to play next once the front one is clear: one
  /// beside it if any still has arrows (right first, the way a page turns),
  /// else whichever does. Null once the block is clear.
  int? _nextFace(GameState state) {
    final left = _faceLeft(state);
    for (final turn in const <CubeTurn>[CubeTurn.right, CubeTurn.down, CubeTurn.left, CubeTurn.up]) {
      final next = cubeNeighbour(_face, turn);
      if (left[next] > 0) return next;
    }
    final rest = <int>[for (var f = 0; f < left.length; f++) if (left[f] > 0) f];
    return rest.isEmpty ? null : rest.first;
  }

  /// Puts the block down with the first face that still has arrows in
  /// front, without a turn: a fresh board, a restart or a level picked up.
  void _settleCube(GameState state) {
    final puzzle = state.puzzle;
    if (puzzle == null || !puzzle.isCube) return;
    _turnTimer?.cancel();
    final first = _faceLeft(state).indexWhere((n) => n > 0);
    _face = first < 0 ? 0 : first;
  }

  /// The chapter cards still to show over the paused board, in trail
  /// order: every twist this level is at or past whose card the player has
  /// not yet dismissed (`introProvider`). Usually one, on a chapter's first
  /// level; several for a player who was already past a chapter when it
  /// arrived. The first is the one up.
  List<ChapterRule> _intros = const <ChapterRule>[];
  bool _introsChecked = false;

  ChapterRule? get _introRule => _intros.isEmpty ? null : _intros.first;

  /// The twist [level] teaches, if it is a chapter's first level.
  ChapterRule? get _taught => widget.isDaily ? null : ruleTaughtAt(widget.level);

  /// Puts the chapter cards up over a freshly dealt board. A board coming
  /// back from a saved game (paused, with the resume offer) has been seen:
  /// no card.
  void _maybeIntro(GameState state) {
    if (_introsChecked || state.phase != GamePhase.playing) return;
    final intro = ref.read(introProvider.notifier);
    final due = widget.isDaily
        ? intro.due(chapter: ref.read(dailyProvider).chapter)
        : intro.due(level: widget.level);
    _introsChecked = true;
    if (due.isEmpty) return;
    _intros = due;
    // The card is up from this build; the clock stops after it, since a
    // provider may not change while the tree is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _intros.isEmpty) return;
      ref.read(gameProvider(widget.level).notifier).pause();
    });
  }

  /// "Got it": the card is marked seen for good, and the next one owed
  /// takes its place, or the level resumes.
  void _introDone() {
    final rule = _intros.first;
    ref.read(introProvider.notifier).markSeen(rule);
    setState(() => _intros = _intros.sublist(1));
    if (_intros.isEmpty) ref.read(gameProvider(widget.level).notifier).resume();
  }

  /// The phase a riddle for [prize] is asked in; leaving it takes the card
  /// away.
  static GamePhase _phaseOf(RiddlePrize prize) => switch (prize) {
        RiddlePrize.life => GamePhase.outOfLives,
        RiddlePrize.hint => GamePhase.paused,
      };

  /// Deals a riddle (a fresh one on every ask, including a swap), and notes
  /// it as the one on the table, so leaving the level brings it back.
  void _dealRiddle() {
    final deck = ref.read(riddleDeckProvider.notifier);
    final id = deck.draw();
    final language = Localizations.localeOf(context).languageCode;
    deck.hold(OpenRiddle(level: widget.level, prize: _riddlePrize, id: id, language: language));
    setState(() {
      _riddleId = id;
      _riddleLanguage = language;
    });
  }

  /// Takes the card off the table, here and in storage.
  void _putRiddleAway() {
    ref.read(riddleDeckProvider.notifier).hold(null);
    setState(() => _riddleId = null);
  }

  /// A level reopened on the moment it was left: if a riddle was up then,
  /// put the same one back, rather than the card it was asked from (or the
  /// "Welcome back" card) — the player left mid-riddle, and that is where
  /// they expect to be. One that no longer fits the level (it was cleared,
  /// restarted, or replayed since) is dropped.
  void _reclaimRiddle(GameState state) {
    final deck = ref.read(riddleDeckProvider.notifier);
    final open = deck.open;
    if (open == null || open.level != widget.level) return;
    final fits =
        state.phase == _phaseOf(open.prize) &&
        (open.prize == RiddlePrize.life || state.hintsLeft == 0);
    if (!fits) {
      deck.hold(null);
      return;
    }
    _riddlePrize = open.prize;
    _riddleId = open.id;
    _riddleLanguage = open.language;
  }

  /// Asks a riddle for [prize].
  void _askRiddle(RiddlePrize prize) {
    _riddlePrize = prize;
    _dealRiddle();
  }

  /// The hint button: a hint while there are free ones, a riddle for one
  /// after that. The level pauses under the riddle so the clock waits.
  void _onHint() {
    final notifier = ref.read(gameProvider(widget.level).notifier);
    final state = ref.read(gameProvider(widget.level));
    if (!state.isPlaying || state.hintArrowId != null) return;
    if (state.hintsLeft > 0) {
      notifier.useHint(face: _cubeFace(state));
      return;
    }
    notifier.pause();
    _askRiddle(RiddlePrize.hint);
  }

  /// Answered: bank the badge, hand over the prize, put the card away.
  void _riddleSolved() {
    ref.read(riddleDeckProvider.notifier).recordSolved();
    final notifier = ref.read(gameProvider(widget.level).notifier);
    switch (_riddlePrize) {
      case RiddlePrize.life:
        notifier.keepGoing();
      case RiddlePrize.hint:
        notifier.resume();
        notifier.earnHint(face: _cubeFace(ref.read(gameProvider(widget.level))));
    }
    _putRiddleAway();
  }

  /// Backed out without an answer: back to the ending card, or back to the
  /// board with the clock running again.
  void _riddleDismissed() {
    if (_riddlePrize == RiddlePrize.hint) {
      ref.read(gameProvider(widget.level).notifier).resume();
    }
    _putRiddleAway();
  }

  /// Keeps the block where the play is: a hint lit on another face turns
  /// the block round to it, and a face just cleared turns on by itself to
  /// the next face with arrows, once the last one has slid away.
  void _followCube(GameState? prev, GameState next) {
    final puzzle = next.puzzle!;
    final hint = next.hintArrowId;
    if (hint != null && hint != prev?.hintArrowId && puzzle.faceOf(hint) != _face) {
      _turnTo(puzzle.faceOf(hint));
      return;
    }
    final exited = next.lastOutcome == MoveOutcome.exited && next.moveToken != prev?.moveToken;
    if (!exited || next.phase != GamePhase.playing || _faceLeft(next)[_face] > 0) return;
    _turnTimer?.cancel();
    _turnTimer = Timer(kCubeAutoTurnDelay, () {
      if (!mounted) return;
      final now = ref.read(gameProvider(widget.level));
      if (!now.isPlaying || _faceLeft(now)[_face] > 0) return;
      final face = _nextFace(now);
      if (face != null) _turnTo(face);
    });
  }

  /// The face in front on a cube level, or null on a flat board.
  int? _cubeFace(GameState state) => state.puzzle?.isCube ?? false ? _face : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = ref.read(gameProvider(widget.level));
    if (state.phase != GamePhase.loading) {
      _reclaimRiddle(state);
      _maybeIntro(state);
      _settleCube(state);
    }
    _crash.addStatusListener((status) {
      if (status == AnimationStatus.completed && _endingHeld && mounted) {
        setState(() => _endingHeld = false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _turnTimer?.cancel();
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
    final spec = ref.read(gameProvider(widget.level)).spec;
    // The block zooms until the face in front fills the stage.
    if (spec.isCube) return kCubeMaxZoom;
    if (_viewport.isEmpty) return kMaxZoom;
    return maxZoomFor(min(_viewport.width / spec.width, _viewport.height / spec.height));
  }

  /// Zooms about the centre of the board viewport.
  void _setZoom(double scale) {
    final s = scale.clamp(kMinZoom, _maxZoom);
    if (ref.read(gameProvider(widget.level)).spec.isCube) {
      setState(() => _scale = s);
      return;
    }
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
  /// earned) and Space or P pauses and resumes. The arrow keys walk a cursor
  /// from arrow to arrow and Enter plays the one it is on, so the game can be
  /// played without a pointer at all. Anything with a modifier held is left
  /// alone so the browser keeps its own shortcuts.
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
    final shortcut = shortcutFor(event);
    // On the block, Shift with an arrow key turns it that way.
    if (keyboard.isShiftPressed && (state.puzzle?.isCube ?? false)) {
      final turn = cubeTurnFor(shortcut);
      if (turn == null) return KeyEventResult.ignored;
      if (state.isPlaying) _turnCube(turn);
      return KeyEventResult.handled;
    }
    switch (shortcut) {
      case null:
        return KeyEventResult.ignored;
      case GameShortcut.hint:
        _onHint(); // no-op unless playing with no hint showing
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
      case GameShortcut.cursorUp:
        _moveCursor(state, Direction.up);
      case GameShortcut.cursorRight:
        _moveCursor(state, Direction.right);
      case GameShortcut.cursorDown:
        _moveCursor(state, Direction.down);
      case GameShortcut.cursorLeft:
        _moveCursor(state, Direction.left);
      case GameShortcut.activate:
        final cursor = _cursor;
        if (cursor == null || !state.isPlaying) return KeyEventResult.ignored;
        notifier.tapArrow(cursor);
    }
    return KeyEventResult.handled;
  }

  /// Restarts the level; the keyboard cursor goes with the attempt, and on
  /// the block the turns.
  void _restart() {
    if (_cursor != null) setState(() => _cursor = null);
    ref.read(gameProvider(widget.level).notifier).restart();
    // The block goes back down with its first face in front.
    setState(() => _settleCube(ref.read(gameProvider(widget.level))));
  }

  /// Steps the keyboard cursor [direction] to the nearest arrow that way (or
  /// onto the first arrow when there is no cursor yet). Nothing that way
  /// leaves it where it is.
  void _moveCursor(GameState state, Direction direction) {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    final next = cursorStep(puzzle, state.removed, _cursor, direction, face: _cubeFace(state));
    if (next != null && next != _cursor) setState(() => _cursor = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = gameProvider(widget.level);
    final progress = ref.read(progressProvider.notifier);
    _calm = reduceMotionOf(context);
    ref.listen(provider, (prev, next) {
      // A locked tap is not a crash: the board rattles the arrow and points
      // at the key, and the screen keeps still.
      if (next.lastOutcome == MoveOutcome.blocked && next.moveToken != prev?.moveToken) {
        final motion = BumpMotion.forTap(next.puzzle!, next.lastMoveId!, next.blockedCell);
        _crashMotion = motion;
        _crash
          ..duration = Duration(milliseconds: motion.totalMs)
          ..forward(from: 0);
        // The bump that ends the attempt gets to play out first.
        _endingHeld = next.phase == GamePhase.outOfLives;
      }
      // A restart (or a new board) forgets the keyboard cursor, and puts
      // the block down again.
      final fresh = next.puzzle != prev?.puzzle || next.moveToken < (prev?.moveToken ?? 0);
      if (_cursor != null && fresh) {
        setState(() => _cursor = null);
      }
      if (fresh && (next.puzzle?.isCube ?? false)) setState(() => _settleCube(next));
      if (next.puzzle?.isCube ?? false) _followCube(prev, next);
      // Restarting (or any other way out of the phase the riddle was asked
      // in) takes the riddle with it, so backing out never leaves a card
      // floating over the board.
      if (prev?.phase == GamePhase.loading && next.phase != GamePhase.loading) {
        setState(() {
          _reclaimRiddle(next);
          _maybeIntro(next);
        });
      }
      if (_riddleId != null && next.phase != _phaseOf(_riddlePrize)) {
        _putRiddleAway();
      }
      if (next.phase == GamePhase.cleared && prev?.phase != GamePhase.cleared) {
        if (!next.spec.timed) {
          _newBest = false;
        } else if (widget.isDaily) {
          final best = ref.read(dailyProvider).bestTodayMs;
          _newBest = best == null || next.elapsedMs < best;
        } else {
          _newBest = progress.progressFor(widget.level).isNewBest(next.elapsedMs);
        }
        _gridJustUnlocked =
            widget.level == kGridLinesUnlockAfterLevel &&
            !progress.progressFor(widget.level).completed;
        // The hop and the confetti are the celebration; with motion reduced
        // the card and its sound are the celebration.
        if (!_calm) {
          _hop.forward(from: 0);
          _confetti.play();
        }
      }
    });
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final settings = ref.watch(settingsProvider);
    // Watch progress so the grid toggle unlocks live.
    ref.watch(progressProvider);
    final gridUnlocked = progress.gridLinesUnlocked;
    final p = context.palette;
    // The two-line title grows with the system font size; so does the bar.
    final textScaler = MediaQuery.textScalerOf(context);
    final toolbarHeight = max(kToolbarHeight, textScaler.scale(44) + 12);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      // A focusable node would swallow every descendant label (clock, lives,
      // tutorial line) into one; the screen's widgets keep their own.
      includeSemantics: false,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: toolbarHeight,
          // Two lines so long level names never truncate on narrow phones.
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.isDaily ? l10n.dailyLevelTitle : l10n.levelNumber(widget.level)),
              Text(
                widget.isDaily
                    ? chapterName(l10n, ref.watch(dailyProvider).chapter.index)
                    : levelName(l10n, widget.level),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textMuted),
              ),
            ],
          ),
          actions: [
            if (state.isPlaying) ...[
              IconButton(
                tooltip: l10n.gameRestart,
                onPressed: _restart,
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
                // With motion reduced the screen never leaves its place: the
                // red flash below still marks the hit.
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    _calm ? 0 : (_crashMotion?.joltAt(_crash.value) ?? 0) * kCrashJoltPx,
                    0,
                  ),
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
                              // With time limits removed there is no clock at all.
                              if (state.spec.timed)
                                Expanded(
                                  child: TimerBar(
                                    remainingMs: state.remainingMs,
                                    fraction: state.timeFraction,
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 12),
                              _ArrowsOut(out: state.arrowsOut, total: state.arrowsTotal),
                              const SizedBox(width: 12),
                              LivesIndicator(livesLeft: state.livesLeft, reduceMotion: _calm),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (state.puzzle?.isCube ?? false) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: CubeControls(
                              face: _face,
                              faceLeft: _faceLeft(state),
                              onTurn: _turnCube,
                              enabled: state.isPlaying,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              _viewport = constraints.biggest;
                              // The block is its own 3D stage: a finger turns
                              // it and two zoom it, so it takes no viewer.
                              if (state.puzzle?.isCube ?? false) {
                                return CubeStage(
                                  face: _face,
                                  zoom: _scale,
                                  reduceMotion: _calm,
                                  onFaceChanged: (face) => _turnTo(face),
                                  onZoom: _setZoom,
                                  interactive: state.isPlaying,
                                  faceBuilder: (context, face, boardKey, front) => PuzzleBoard(
                                    key: boardKey,
                                    state: state,
                                    face: face,
                                    showGrid: gridUnlocked && settings.gridLinesOn,
                                    onTapArrow: notifier.tapArrow,
                                    onBounce: front ? notifier.bounce : null,
                                    zoom: _scale,
                                    focusedArrowId: front ? _cursor : null,
                                    reduceMotion: _calm,
                                  ),
                                );
                              }
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
                                              onBounce: notifier.bounce,
                                              zoom: _scale,
                                              focusedArrowId: _cursor,
                                              reduceMotion: _calm,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_tutorialLine(l10n) case final line?)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Text(
                              line,
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
                            onHint: state.isPlaying ? _onHint : null,
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
              // A chapter's first level (or the first level opened past
              // one): the twist it brings, drawn on a card over the paused
              // board.
              if (_introRule != null)
                _IntroCard(key: ValueKey<ChapterRule>(_introRule!), rule: _introRule!, onDone: _introDone)
              else
              switch (state.phase) {
                // The free hints are spent and the player wants another: the
                // level waits, paused, while the riddle is cracked.
                GamePhase.paused when _riddleId != null => RiddleChallenge(
                  key: ValueKey<int>(_riddleId!),
                  riddleId: _riddleId!,
                  languageCode: _riddleLanguage,
                  prize: RiddlePrize.hint,
                  solvedCount: ref.watch(riddleDeckProvider).solved,
                  onSolved: _riddleSolved,
                  onSwap: _dealRiddle,
                  onDismiss: _riddleDismissed,
                ),
                GamePhase.paused when state.resumeOffered => ResultCard(
                  emoji: '👋',
                  title: l10n.resumeTitle,
                  body: state.spec.timed
                      ? l10n.resumeBody(
                          state.arrowsOut,
                          state.arrowsTotal,
                          formatDurationMs(state.elapsedMs),
                        )
                      : l10n.resumeBodyUntimed(state.arrowsOut, state.arrowsTotal),
                  actions: [
                    FilledButton(onPressed: notifier.resume, child: Text(l10n.resumeContinue)),
                    OutlinedButton(onPressed: _restart, child: Text(l10n.resumeStartOver)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.clearedHome),
                    ),
                  ],
                ),
                GamePhase.paused => ResultCard(
                  emoji: '⏸️',
                  title: l10n.gamePaused,
                  body: state.spec.timed ? l10n.gamePausedBody : l10n.gamePausedBodyUntimed,
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
                  body: widget.isDaily
                      ? l10n.dailyClearedBody
                      : switch (state.stars) {
                          3 => l10n.clearedFlawless,
                          2 => l10n.clearedGood,
                          _ => l10n.clearedOkay,
                        },
                  content: Column(
                    children: [
                      StarsRow(stars: state.stars, size: 44, animated: true),
                      const SizedBox(height: 10),
                      // An untimed level counted no time, so says none.
                      if (state.spec.timed)
                        Text(
                          l10n.clearedTime(formatDurationMs(state.elapsedMs)),
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.textInk),
                        ),
                      if (_newBest)
                        Text(
                          l10n.clearedNewBest,
                          style: TextStyle(fontWeight: FontWeight.w800, color: p.successInk),
                        ),
                      if (_gridJustUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            l10n.gridUnlockedToast,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: p.primaryInk),
                          ),
                        ),
                      if (!widget.isDaily && widget.level == totalLevels)
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
                    if (!widget.isDaily && widget.level < totalLevels)
                      FilledButton(
                        onPressed: () => _openLevel(widget.level + 1),
                        child: Text(l10n.clearedNext),
                      ),
                    OutlinedButton(onPressed: _restart, child: Text(l10n.clearedReplay)),
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
                  languageCode: _riddleLanguage,
                  prize: RiddlePrize.life,
                  solvedCount: ref.watch(riddleDeckProvider).solved,
                  onSolved: _riddleSolved,
                  onSwap: _dealRiddle,
                  onDismiss: _riddleDismissed,
                ),
                GamePhase.outOfLives => ResultCard(
                  mood: EmojiMood.sulk,
                  emoji: '💔',
                  title: l10n.outOfLivesTitle,
                  body: l10n.outOfLivesBody,
                  actions: [
                    FilledButton(
                      onPressed: () => _askRiddle(RiddlePrize.life),
                      child: Text(l10n.outOfLivesSolveRiddle),
                    ),
                    OutlinedButton(onPressed: _restart, child: Text(l10n.outOfLivesRetry)),
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
                    FilledButton(onPressed: _restart, child: Text(l10n.timeUpRetry)),
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

extension on _GameScreenState {
  /// The line under the board on the levels that teach something: the
  /// first two, and each chapter's first.
  String? _tutorialLine(AppLocalizations l10n) {
    if (widget.isDaily) return null;
    if (widget.level == 1) return l10n.tutorialTap;
    if (widget.level == 2) return l10n.tutorialBlocked;
    return switch (_taught) {
      null || ChapterRule.lines => null,
      ChapterRule.mirrors => l10n.tutorialMirrors,
      ChapterRule.locks => l10n.tutorialLocks,
      ChapterRule.fog => l10n.tutorialFog,
      ChapterRule.pairs => l10n.tutorialPairs,
      ChapterRule.cube => l10n.tutorialCube,
      ChapterRule.squeeze => l10n.tutorialSqueeze,
    };
  }
}

/// The chapter card: the twist's name, one line on how it plays, and a
/// small board that plays it over and over (`ChapterDemoBoard`). Watching
/// beats reading: the line is as short as it can be.
class _IntroCard extends StatelessWidget {
  const _IntroCard({super.key, required this.rule, required this.onDone});

  final ChapterRule rule;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (emoji, title, body) = switch (rule) {
      ChapterRule.lines => ('➡️', l10n.chapterName1, l10n.chapterBlurb1),
      ChapterRule.mirrors => ('🪞', l10n.introTitleMirrors, l10n.introBodyMirrors),
      ChapterRule.locks => ('🔒', l10n.introTitleLocks, l10n.introBodyLocks),
      ChapterRule.fog => ('🌫️', l10n.introTitleFog, l10n.introBodyFog),
      ChapterRule.pairs => ('🔗', l10n.introTitlePairs, l10n.introBodyPairs),
      ChapterRule.cube => ('🧊', l10n.introTitleCube, l10n.introBodyCube),
      ChapterRule.squeeze => ('🗜️', l10n.introTitleSqueeze, l10n.introBodySqueeze),
    };
    return ResultCard(
      emoji: emoji,
      title: title,
      body: body,
      content: ChapterDemoBoard(rule: rule),
      actions: [FilledButton(onPressed: onDone, child: Text(l10n.introGotIt))],
    );
  }
}

/// What a key press on the game screen does.
enum GameShortcut {
  hint,
  zoomIn,
  zoomOut,
  grid,
  pause,
  cursorUp,
  cursorRight,
  cursorDown,
  cursorLeft,
  activate,
}

/// The shortcut a key press means, or null when it isn't one. Zoom answers
/// both the main row and the numeric keypad, and `=` stands in for `+` so it
/// works without Shift on a US layout. The arrow keys move the board cursor
/// and Enter plays the arrow under it.
@visibleForTesting
GameShortcut? shortcutFor(KeyEvent event) => switch (event.logicalKey) {
  LogicalKeyboardKey.keyH => GameShortcut.hint,
  LogicalKeyboardKey.equal ||
  LogicalKeyboardKey.add ||
  LogicalKeyboardKey.numpadAdd => GameShortcut.zoomIn,
  LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract => GameShortcut.zoomOut,
  LogicalKeyboardKey.keyG => GameShortcut.grid,
  LogicalKeyboardKey.space || LogicalKeyboardKey.keyP => GameShortcut.pause,
  LogicalKeyboardKey.arrowUp => GameShortcut.cursorUp,
  LogicalKeyboardKey.arrowRight => GameShortcut.cursorRight,
  LogicalKeyboardKey.arrowDown => GameShortcut.cursorDown,
  LogicalKeyboardKey.arrowLeft => GameShortcut.cursorLeft,
  LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter => GameShortcut.activate,
  _ => null,
};

/// The way Shift with an arrow key turns the block, or null for any other
/// key.
@visibleForTesting
CubeTurn? cubeTurnFor(GameShortcut? shortcut) => switch (shortcut) {
  GameShortcut.cursorLeft => CubeTurn.left,
  GameShortcut.cursorRight => CubeTurn.right,
  GameShortcut.cursorUp => CubeTurn.up,
  GameShortcut.cursorDown => CubeTurn.down,
  _ => null,
};

/// Arrows out so far, as "3/12". A live region, so a screen reader hears each
/// exit land ("4 of 12 arrows out") without being told to look.
class _ArrowsOut extends StatelessWidget {
  const _ArrowsOut({required this.out, required this.total});

  final int out;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.hudArrowsLeft(out, total),
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_outward_rounded, size: 18, color: p.textMuted),
          const SizedBox(width: 4),
          Text(
            l10n.hudArrows(out, total),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: p.textInk,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

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
