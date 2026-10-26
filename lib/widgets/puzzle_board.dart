import 'dart:math';

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../l10n/app_localizations.dart';
import '../models/bump_motion.dart';
import '../models/game_state.dart';
import '../models/reaction_motion.dart';
import '../ui/colors.dart';
import 'board_glyphs.dart';
import 'board_semantics.dart';

/// How far the arrow that was hit is shoved along, in cells, at full jolt.
const double kShoveDistance = 0.12;

/// How far from a tap the board looks for an arrow when the finger lands on
/// an empty cell, in logical pixels on screen. A late board draws a cell at
/// about a dozen pixels — a quarter of a fingertip — so a tap that misses
/// into a gap still gets the arrow it was plainly aimed at. A cell that *is*
/// occupied always wins: slop never overrides a deliberate hit.
const double kTouchSlopPx = 22;

/// How far into a slide the board starts accepting taps again. The slide runs
/// 240-600 ms, so this is the first 70-180 ms of it.
const double kSettleFraction = 0.3;

/// How long one ping of the hint ring takes.
const Duration kHintPingPeriod = Duration(milliseconds: 1100);

/// How long the pointer from a tapped lock to its key (or from a tapped
/// hidden arrow to the arrows that would uncover it) stays up.
const int kKeyPingMs = 1800;

/// How long a lock takes to open once its key has left: a spark flies from
/// where the key was to the lock, then the padlock swings open with a ring
/// and the arrow glows. Starts when the key's slide is over, not when it
/// starts, so the key is seen to go and *then* the lock to open.
const int kUnlockMs = 1200;

/// The share of [kUnlockMs] the spark takes to reach the lock.
const double kSparkShare = 0.35;

/// How long a hidden head takes to come out of the fog once the neighbour
/// that uncovers it has gone: the dashes firm into a line, the head springs
/// in with a ring, and the arrow glows. Starts when that slide is over.
const int kRevealMs = 1000;

/// How long the flash on a mirror lasts as an arrow bounces through it.
const int kBounceMs = 600;

/// How much longer a slide takes for every mirror it turns at, so a bounce
/// is a moment and not a blink.
const int kBounceDwellMs = 140;

/// The board: draws every arrow still on the board (plus any arrow mid-slide
/// on its way out) in a single ink — thin lines with a small head, like a
/// printed puzzle, straight on the page with no frame — plus optional grid
/// lines, the hint glow and the blocked-cell flash, and turns taps into
/// [onTapArrow] calls. Requires a loaded [GameState.puzzle].
///
/// Game state changes instantly on a tap; the slide-out and bump animations
/// are purely visual and live here, keyed on [GameState.moveToken].
///
/// **Accessibility.** The canvas is one picture, so the painter hands the
/// semantics tree one node per arrow still on the board, placed over its
/// cells and labelled the way `board_semantics.dart` describes it, with a
/// tap action that plays it — a screen reader can walk the arrows and slide
/// one out. The board itself is a container labelled with its size and how
/// many arrows are left. With [focusedArrowId] set (the keyboard cursor on
/// the game screen) a ring is drawn around that arrow. With [reduceMotion]
/// the bump no longer travels (the hit cell still flashes), the hint glow
/// holds still instead of pulsing and a lost level does not slump.
///
/// **The block.** On a cube level ([Puzzle.isCube]) the board shows one
/// [face]: it is sized, drawn, tapped and read out as that face alone, and
/// an arrow sliding out leaves by the face's own edge.
class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.state,
    required this.showGrid,
    required this.onTapArrow,
    this.onBounce,
    this.zoom = 1,
    this.focusedArrowId,
    this.reduceMotion = false,
    this.face,
  });

  final GameState state;

  /// On a cube level, the face to show; null shows the whole board.
  final int? face;
  final bool showGrid;
  final ValueChanged<int> onTapArrow;

  /// Called as the head of an arrow sliding out reaches a mirror — the
  /// moment the glass flashes — so a sound can land on the turn.
  final VoidCallback? onBounce;

  /// The scale the board is being viewed at, so touch slop stays the same
  /// size on screen however far in the player has pinched.
  final double zoom;

  /// The arrow the keyboard cursor is on, ringed on the board; null for none.
  final int? focusedArrowId;

  /// Keep the board's motion to what carries information (see `ui/motion.dart`).
  final bool reduceMotion;

  @override
  State<PuzzleBoard> createState() => PuzzleBoardState();
}

class PuzzleBoardState extends State<PuzzleBoard> with TickerProviderStateMixin {
  /// The cell size and where the drawing sits in the board's box, from the
  /// last layout, for [tapAtBox].
  double _cellSize = 0;
  Offset _paintOffset = Offset.zero;
  /// Arrows sliding out: id → progress controller.
  final Map<int, AnimationController> _exits = <int, AnimationController>{};

  /// Runs the slump when a level ends badly: every arrow still on the board
  /// droops and tilts, like the puzzle giving up.
  AnimationController? _slump;

  /// Pointers on the board now, and the most this gesture has seen. A pinch
  /// that never travels far enough to be read as a pan can end as a tap,
  /// which would play an arrow the player was only zooming in on.
  int _pointersDown = 0;
  int _pointersInGesture = 0;

  /// Drives the hint ring while a hint is showing. A late board is a hundred
  /// arrows in one ink, and the eye does not find a static smudge among them
  /// — it finds movement.
  AnimationController? _hintPing;

  /// The arrow currently bumping (or rattling at its lock), if any, and
  /// how it moves.
  int? _bumpId;
  BumpMotion? _bumpMotion;
  AnimationController? _bump;

  /// Runs after a tap on a locked arrow, or on one whose head is hidden: a
  /// dashed line from the tapped arrow to each of [_pointerTargets] (the
  /// key; the arrows that would uncover the head) and a ring pulsing on
  /// each, so the player sees what has to go first without reading a
  /// number or guessing.
  AnimationController? _pointer;
  List<int> _pointerTargets = const <int>[];

  /// Padlocks popping open, by the locked arrow's id: the key has gone,
  /// and a spark flies from where it was to the lock, which swings open
  /// with a ring. [_pendingUnlocks] are the locks whose key is still
  /// sliding out: drawn shut until it has gone.
  final Map<int, AnimationController> _unlocks = <int, AnimationController>{};
  final Set<int> _pendingUnlocks = <int>{};

  /// Heads appearing, by the hidden arrow's id: a neighbour has gone (or a
  /// hint lit it), and the fog lifts off the arrow. [_pendingReveals] are
  /// the heads owed to an arrow still sliding out, by that arrow's id:
  /// drawn hidden until it has gone.
  final Map<int, AnimationController> _reveals = <int, AnimationController>{};
  final Map<int, Set<int>> _pendingReveals = <int, Set<int>>{};

  /// Mirrors flashing, by packed cell (`y * width + x`): an arrow on its way
  /// out has just turned there, and the glass lights up with a ring so the
  /// bounce is seen as well as implied by the path.
  final Map<int, AnimationController> _bounces = <int, AnimationController>{};

  @override
  void initState() {
    super.initState();
    _syncHintPing();
    _syncSlump();
  }

  @override
  void didUpdateWidget(PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      _hintPing?.dispose();
      _hintPing = null;
      _slump?.dispose();
      _slump = null;
    }
    _syncHintPing();
    final s = widget.state;
    if (s.puzzle != oldWidget.state.puzzle || s.moveToken < oldWidget.state.moveToken) {
      // A restart: forget every animation.
      _disposeAll();
      _syncSlump();
      return;
    }
    final moved = s.moveToken != oldWidget.state.moveToken && s.lastMoveId != null;
    final uncovered = s.revealed.difference(oldWidget.state.revealed);
    if (moved) {
      final id = s.lastMoveId!;
      switch (s.lastOutcome) {
        case MoveOutcome.exited:
          // The heads this exit uncovers appear once it has gone, and so
          // do the locks it opens: cause, then effect.
          if (uncovered.isNotEmpty) _pendingReveals[id] = uncovered;
          _startExit(id);
        case MoveOutcome.blocked:
          _startBump(id);
        case MoveOutcome.locked:
          _startBump(id);
          _startPointer(<int>[s.blockedKey!]);
        case MoveOutcome.hidden:
          _startBump(id);
          _startPointer(s.puzzle!.revealersOf(id).toList()..sort());
        case MoveOutcome.none:
          break;
      }
    }
    if (!(moved && s.lastOutcome == MoveOutcome.exited)) {
      // Lit by a hint (or restored): the head is there at once.
      for (final id in uncovered) {
        _startReveal(id);
      }
    }
    // After the move, not before: the bump that spends the last life has to
    // have started before the slump can know to wait for it.
    _syncSlump();
  }

  void _startExit(int id) {
    final puzzle = widget.state.puzzle!;
    // A tethered pair leaves together, so both halves run on one clock —
    // the longer half's.
    final group = puzzle.exitGroup(id);
    var travel = 0;
    var turns = 0;
    for (final member in group) {
      travel = max(travel, puzzle.arrows[member].length + puzzle.rayOf(member).length);
      turns = max(turns, puzzle.rayOf(member).where(puzzle.isMirror).length);
    }
    // Quick but still readable as a slide: a short arrow at the edge is gone
    // in about a quarter second; a long crossing of a big board never drags.
    // A turn at a mirror buys a little more, so the bounce is watched.
    final dwell = turns * kBounceDwellMs;
    final duration = Duration(milliseconds: (140 + travel * 30 + dwell).clamp(240, 600 + dwell));
    // The locks this exit opens stay shut until it is over.
    for (final member in group) {
      for (final lock in puzzle.locksOpenedBy(member)) {
        if (!widget.state.removed.contains(lock)) _pendingUnlocks.add(lock);
      }
      // A lock leaving opens nothing of its own; it is simply gone.
      _pendingUnlocks.remove(member);
    }
    for (final member in group) {
      final controller = AnimationController(vsync: this, duration: duration);
      _exits[member]?.dispose();
      _exits[member] = controller;
      // The mirrors on the way, with how far the head has to travel to
      // reach each; the glass flashes as the head gets there. The offset is
      // the painter's own formula, so the flash lands as the arrow turns.
      final arrow = puzzle.arrows[member];
      final ray = puzzle.rayOf(member);
      final ahead = <(int, Cell)>[
        for (var i = 0; i < ray.length; i++)
          if (puzzle.isMirror(ray[i])) (i + 1, ray[i]),
      ];
      final run = arrow.length + ray.length;
      controller.addListener(() {
        final offset = Curves.easeIn.transform(controller.value) * run;
        while (ahead.isNotEmpty && offset >= ahead.first.$1) {
          final cell = ahead.removeAt(0).$2;
          _startOneShot(_bounces, cell.y * puzzle.width + cell.x, kBounceMs);
          widget.onBounce?.call();
        }
        setState(() {});
      });
      controller.forward().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _exits.remove(member)?.dispose();
          _afterExit(member);
        });
      });
    }
  }

  /// [id] has left the board: the padlocks it was the key of swing open,
  /// and the heads its going uncovered come out of the fog.
  void _afterExit(int id) {
    final puzzle = widget.state.puzzle!;
    for (final lock in puzzle.locksOpenedBy(id)) {
      if (!_pendingUnlocks.remove(lock)) continue;
      if (widget.state.removed.contains(lock)) continue;
      _startOneShot(_unlocks, lock, kUnlockMs);
    }
    for (final hidden in _pendingReveals.remove(id) ?? const <int>{}) {
      _startReveal(hidden);
    }
  }

  void _startReveal(int id) => _startOneShot(_reveals, id, kRevealMs);

  /// Starts (or restarts) a one-shot [ms] animation for [id] in [slot].
  void _startOneShot(Map<int, AnimationController> slot, int id, int ms) {
    slot[id]?.dispose();
    final controller = AnimationController(vsync: this, duration: Duration(milliseconds: ms));
    slot[id] = controller;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        if (slot[id] == controller) slot.remove(id);
        controller.dispose();
      });
    });
  }

  /// Points from the arrow just tapped at [targets]: its key, or the
  /// arrows that would uncover its head.
  void _startPointer(List<int> targets) {
    _pointer?.dispose();
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: kKeyPingMs));
    _pointer = controller;
    _pointerTargets = targets;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        if (_pointer == controller) {
          _pointer = null;
          _pointerTargets = const <int>[];
        }
        controller.dispose();
      });
    });
  }

  void _startBump(int id) {
    _bump?.dispose();
    final puzzle = widget.state.puzzle!;
    final motion = BumpMotion.forTap(puzzle, id, widget.state.blockedCell);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: motion.totalMs),
    );
    _bumpId = id;
    _bumpMotion = motion;
    _bump = controller;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        if (_bump == controller) {
          _bump = null;
          _bumpId = null;
          _bumpMotion = null;
        }
        controller.dispose();
      });
      // The last life is spent by a bump like any other, and the board only
      // gives up once the player has seen it happen.
      _syncSlump();
    });
  }

  /// Starts the slump on a losing ending, and clears it on the way out of
  /// one (a restart, or carrying on past a spent allowance). A bump still
  /// playing holds it off: the arrow that spent the last life must be seen
  /// to hit before the board droops around it.
  void _syncSlump() {
    final ending =
        widget.state.phase == GamePhase.outOfLives || widget.state.phase == GamePhase.timeUp;
    // A sagging board is motion for its own sake; the card says what happened.
    final losing = ending && _bump == null && !widget.reduceMotion;
    if (losing == (_slump != null)) return;
    if (losing) {
      _slump =
          AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: kSlumpMs),
            )
            ..addListener(() => setState(() {}))
            ..forward();
    } else {
      _slump?.dispose();
      _slump = null;
    }
  }

  /// Runs the ping while a hint points somewhere, and stops it otherwise. With
  /// motion reduced the glow is enough: the hinted arrow is the one thing
  /// still bright on a dimmed board.
  void _syncHintPing() {
    final showing = widget.state.hintArrowId != null && !widget.reduceMotion;
    if (showing == (_hintPing != null)) return;
    if (showing) {
      _hintPing = AnimationController(vsync: this, duration: kHintPingPeriod)
        ..addListener(() => setState(() {}))
        ..repeat();
    } else {
      _hintPing?.dispose();
      _hintPing = null;
    }
  }

  void _disposeAll() {
    for (final c in _exits.values) {
      c.dispose();
    }
    _exits.clear();
    for (final slot in <Map<int, AnimationController>>[_unlocks, _reveals, _bounces]) {
      for (final c in slot.values) {
        c.dispose();
      }
      slot.clear();
    }
    _pendingUnlocks.clear();
    _pendingReveals.clear();
    _pointer?.dispose();
    _pointer = null;
    _pointerTargets = const <int>[];
    _bump?.dispose();
    _bump = null;
    _bumpId = null;
    _bumpMotion = null;
  }

  @override
  void dispose() {
    _slump?.dispose();
    _slump = null;
    _hintPing?.dispose();
    _hintPing = null;
    _disposeAll();
    super.dispose();
  }

  /// Whether the board is still reacting to the last tap. A bump throws the
  /// whole screen sideways for about a second, and a slide is in
  /// flight for up to another half: a tap that lands in that window is a
  /// finger still finishing the last move, not a new decision.
  bool get _settling {
    if (_bump != null) return true;
    for (final c in _exits.values) {
      if (c.value < kSettleFraction) return true;
    }
    return false;
  }

  void _onPointerDown() {
    _pointersDown++;
    if (_pointersDown > _pointersInGesture) _pointersInGesture = _pointersDown;
  }

  void _onPointerUp() {
    _pointersDown--;
    if (_pointersDown <= 0) {
      _pointersDown = 0;
      _pointersInGesture = 0;
    }
  }

  /// The arrow a touch at [p] means: the one under the finger, or — when that
  /// cell is empty — the nearest arrow still on the board within
  /// [kTouchSlopPx] of it. Null when the finger is over open space.
  int? _arrowFor(Offset local, double cellSize) {
    final puzzle = widget.state.puzzle!;
    final (originX, windowWidth) = _window(puzzle, widget.face);
    // In the board's own cells: the face shown starts [originX] cells in.
    final p = local + Offset(originX * cellSize, 0);
    bool inside(Cell c) => c.x >= originX && c.x < originX + windowWidth && c.y >= 0 && c.y < puzzle.height;
    final cell = Cell((p.dx / cellSize).floor(), (p.dy / cellSize).floor());
    if (inside(cell)) {
      final under = puzzle.arrowAt(cell);
      if (under != null && !widget.state.removed.contains(under)) return under;
    }
    // Capped in cells as well, so on the small early boards — where a cell is
    // already far bigger than a finger — slop never reaches a neighbour.
    final slop = min(kTouchSlopPx / widget.zoom, cellSize * 1.5);
    final reach = (slop / cellSize).ceil();
    int? best;
    var nearest = slop;
    for (var dy = -reach; dy <= reach; dy++) {
      for (var dx = -reach; dx <= reach; dx++) {
        final c = Cell(cell.x + dx, cell.y + dy);
        if (!inside(c)) continue;
        final id = puzzle.arrowAt(c);
        if (id == null || widget.state.removed.contains(id)) continue;
        final d = (_BoardPainter._center(c, cellSize) - p).distance;
        if (d < nearest) {
          nearest = d;
          best = id;
        }
      }
    }
    return best;
  }

  /// A tap the block's stage worked out from its own geometry, at [p] in
  /// this board's box: the cube's faces are drawn turned in space, so the
  /// stage, not this board, catches the finger. Taken the same way as a tap
  /// on the board itself, nearest-arrow slop and all.
  void tapAtBox(Offset p) {
    if (_cellSize <= 0 || _settling) return;
    final id = _arrowFor(p - _paintOffset, _cellSize);
    if (id != null) widget.onTapArrow(id);
  }

  void _onTapUp(TapUpDetails d, double cellSize) {
    // Taps the player never meant: one finger of a pinch, or a stutter while
    // the board is still moving from the last one.
    if (_pointersInGesture > 1 || _settling) return;
    final id = _arrowFor(d.localPosition, cellSize);
    if (id != null) widget.onTapArrow(id);
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.state.puzzle!;
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final (_, windowWidth) = _window(puzzle, widget.face);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          constraints.maxWidth / windowWidth,
          constraints.maxHeight / puzzle.height,
        );
        final size = Size(cellSize * windowWidth, cellSize * puzzle.height);
        _cellSize = cellSize;
        _paintOffset = Offset(
          (constraints.maxWidth - size.width) / 2,
          (constraints.maxHeight - size.height) / 2,
        );
        return Center(
          // The board is a labelled container and the painter supplies one
          // node per arrow; the gesture detector adds nothing of its own,
          // since a semantic tap on the whole board would land at its centre.
          child: Semantics(
            container: true,
            label: l10n == null ? null : boardLabel(l10n, widget.state, face: widget.face),
            child: Listener(
              onPointerDown: (_) => _onPointerDown(),
              onPointerUp: (_) => _onPointerUp(),
              onPointerCancel: (_) => _onPointerUp(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapUp: (d) => _onTapUp(d, cellSize),
                child: CustomPaint(
                  size: size,
                  painter: _BoardPainter(
                    state: widget.state,
                    palette: p,
                    showGrid: widget.showGrid,
                    exits: <int, double>{for (final e in _exits.entries) e.key: e.value.value},
                    hintPing: _hintPing?.value,
                    slump: _slump?.value,
                    bumpId: _bumpId,
                    bump: _bump?.value,
                    bumpMotion: _bumpMotion,
                    pointer: _pointer?.value,
                    pointerTargets: _pointerTargets,
                    unlocks: <int, double>{for (final e in _unlocks.entries) e.key: e.value.value},
                    reveals: <int, double>{for (final e in _reveals.entries) e.key: e.value.value},
                    pendingUnlocks: Set<int>.of(_pendingUnlocks),
                    pendingReveals: <int>{for (final owed in _pendingReveals.values) ...owed},
                    bounces: <int, double>{for (final e in _bounces.entries) e.key: e.value.value},
                    travel: widget.reduceMotion ? 0 : 1,
                    focusedId: widget.focusedArrowId,
                    l10n: l10n,
                    textDirection: Directionality.of(context),
                    onTapArrow: widget.onTapArrow,
                    face: widget.face,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The columns a board shows: from where, and how many — one face of a
/// cube level, or the whole board.
(int, int) _window(Puzzle puzzle, int? face) =>
    face == null || !puzzle.isCube ? (0, puzzle.width) : (face * puzzle.faceWidth, puzzle.faceWidth);

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.state,
    required this.palette,
    required this.showGrid,
    required this.exits,
    required this.hintPing,
    required this.slump,
    required this.bumpId,
    required this.bump,
    required this.bumpMotion,
    required this.pointer,
    required this.pointerTargets,
    required this.unlocks,
    required this.reveals,
    required this.pendingUnlocks,
    required this.pendingReveals,
    required this.bounces,
    required this.travel,
    required this.focusedId,
    required this.l10n,
    required this.textDirection,
    required this.onTapArrow,
    required this.face,
  });

  final GameState state;
  final ArrowPalette palette;

  /// The face of a cube level being shown, or null for the whole board.
  final int? face;

  /// Whether [id] is on the face shown (always, on a flat board).
  bool _shown(int id) => face == null || !puzzle.isCube || puzzle.faceOf(id) == face;
  final bool showGrid;

  /// How far the bump actually moves the arrows, 0..1: 0 with motion reduced,
  /// when only the flash marks the hit.
  final double travel;

  /// The arrow the keyboard cursor rings, if any.
  final int? focusedId;

  /// For the labels of the semantics nodes, or null when no localizations
  /// are in scope (then the board stays one node).
  final AppLocalizations? l10n;

  /// For the labels: a semantics node with a label has to say which way it
  /// reads.
  final TextDirection textDirection;

  /// What a semantic tap on an arrow does.
  final ValueChanged<int> onTapArrow;

  /// Slide-out progress (0..1) per exiting arrow.
  final Map<int, double> exits;

  /// The hint ring's progress (0..1), or null when no hint is showing.
  final double? hintPing;

  /// The slump's progress (0..1) on a losing ending, else null.
  final double? slump;

  /// The bumping arrow, its progress (0..1) and its motion. Its tethered
  /// partner moves with it.
  final int? bumpId;
  final double? bump;
  final BumpMotion? bumpMotion;

  /// The pointer after a locked or a hidden tap, 0..1, or null, and the
  /// arrows it points at.
  final double? pointer;
  final List<int> pointerTargets;

  /// Padlocks popping open (locked id → progress) and heads coming out of
  /// the fog (hidden id → progress); and the ones owed to an arrow still
  /// sliding out, drawn shut and hidden until it has gone.
  final Map<int, double> unlocks;
  final Map<int, double> reveals;
  final Set<int> pendingUnlocks;
  final Set<int> pendingReveals;

  /// Mirrors mid-flash, by packed cell: an arrow has just turned there.
  final Map<int, double> bounces;

  Puzzle get puzzle => state.puzzle!;

  /// Whether a bump is being drawn now: the last tap ran into a cell, a
  /// lock or a hidden head, and the board is still moving from it.
  bool get _bumping =>
      bump != null &&
      bumpMotion != null &&
      bumpId == state.lastMoveId &&
      (state.blockedCell != null || state.blockedKey != null || state.lastOutcome == MoveOutcome.hidden);

  /// The arrows moving with the bump: the one that bumped and its partner.
  List<int> get _bumpGroup => _bumping ? puzzle.exitGroup(bumpId!) : const <int>[];

  /// How far along its track [arrow] is drawn right now, in cells: sliding
  /// out, bumping (with its partner), or at rest.
  double _offsetOf(ArrowPiece arrow) {
    final exiting = exits[arrow.id];
    if (exiting != null) {
      return Curves.easeIn.transform(exiting) * (arrow.length + puzzle.rayOf(arrow.id).length);
    }
    if (_bumpGroup.contains(arrow.id)) {
      // In cells already; [travel] only switches it off with motion
      // reduced. (The first cut multiplied by the arrow's whole run by
      // mistake, so every bump flew to the edge and back in a blink.)
      return bumpMotion!.offsetAt(bump!) * travel;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (originX, windowWidth) = _window(puzzle, face);
    final cs = size.width / windowWidth;
    // Drawn in the board's own cells: a face of the block is shifted so it
    // sits at the canvas's origin, and the rest of the strip is never drawn.
    canvas.save();
    canvas.translate(-originX * cs, 0);
    final rect = Rect.fromLTWH(originX * cs, 0, size.width, size.height);

    // No frame: the arrows sit straight on the page. Grid lines, when on,
    // run through the cell centres — the lattice the arrows are drawn on —
    // so every body lies exactly on a line and every head points along one.
    if (showGrid) {
      final grid = Paint()
        ..color = palette.gridLine
        ..strokeWidth = 1;
      final first = cs / 2;
      final firstX = rect.left + cs / 2;
      final lastX = rect.right - cs / 2;
      final lastY = size.height - cs / 2;
      for (var x = 0; x < windowWidth; x++) {
        final px = firstX + x * cs;
        canvas.drawLine(Offset(px, first), Offset(px, lastY), grid);
      }
      for (var y = 0; y < puzzle.height; y++) {
        final py = first + y * cs;
        canvas.drawLine(Offset(firstX, py), Offset(lastX, py), grid);
      }
    }

    final glyphs = BoardGlyphs(
      ink: palette.arrowInk,
      paper: palette.backgroundSoft,
      badge: palette.accentSun,
      onBadge: palette.onAccent,
      mirrorWash: palette.mirror,
      pairWash: palette.pairWash,
      textDirection: textDirection,
    );
    // The wash under every pair still on the board, so the two halves read
    // as one piece. It stays on the cells while the pair bumps (the home
    // it springs back to) and goes once the pair is on its way out.
    for (final e in puzzle.pairs.entries) {
      final a = e.key;
      final b = e.value;
      if (a > b || state.removed.contains(a) || state.removed.contains(b) || !_shown(a)) continue;
      glyphs.washPair(canvas, <Rect>[
        for (final id in <int>[a, b])
          for (final c in puzzle.arrows[id].cells) Rect.fromLTWH(c.x * cs, c.y * cs, cs, cs),
      ]);
    }
    // Mirrors: drawn under everything, so an arrow slides over the glass as
    // it turns.
    for (final e in puzzle.mirrors.entries) {
      if (puzzle.faceOfCell(e.key) * puzzle.faceWidth != originX) continue;
      glyphs.mirror(canvas, Rect.fromLTWH(e.key.x * cs, e.key.y * cs, cs, cs), e.value);
    }

    // The bump: the tapped arrow runs into the arrow in its way, which takes
    // the hit — its cell flashes and it is shoved a touch — then springs
    // back. Held by a lock instead, it only rattles (the same motion, a
    // fraction of a cell), and the key is pointed at below; the same for a
    // tap on a hidden head, which points at what would uncover it.
    final blocked = state.blockedCell;
    final bumping = _bumping;
    final bumpT = bump;
    final motion = bumpMotion;
    final flash = bumping && blocked != null ? motion!.flashAt(bumpT!) : 0.0;
    final shove = bumping && blocked != null ? motion!.shoveAt(bumpT!) * travel : 0.0;
    final hitId = bumping && blocked != null ? puzzle.arrowAt(blocked) : null;
    if (flash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(blocked!.x * cs, blocked.y * cs, cs, cs).deflate(cs * 0.08),
          Radius.circular(cs * 0.2),
        ),
        Paint()..color = palette.blockedFlash.withValues(alpha: palette.blockedFlash.a * flash),
      );
    }

    canvas.save();
    canvas.clipRect(rect);
    // Tethers first, under the arrows they join — and moving with them: a
    // pair on its way out, or bumping, is drawn joined the whole way, the
    // tether in the glow, so the second half is seen to be pulled along.
    for (final e in puzzle.pairs.entries) {
      final a = e.key;
      final b = e.value;
      if (a > b || !_shown(a)) continue;
      bool gone(int id) => state.removed.contains(id) && !exits.containsKey(id);
      if (gone(a) || gone(b)) continue;
      final arrowA = puzzle.arrows[a];
      final arrowB = puzzle.arrows[b];
      final (ca, cb) = _nearestCells(arrowA, arrowB);
      final offsetA = _offsetOf(arrowA);
      final offsetB = _offsetOf(arrowB);
      final moving = offsetA > 0 || offsetB > 0;
      glyphs.tether(
        canvas,
        _trackPoint(arrowA, arrowA.cells.indexOf(ca) + offsetA, cs),
        _trackPoint(arrowB, arrowB.cells.indexOf(cb) + offsetB, cs),
        cs,
        colour: moving ? palette.hintGlow : null,
      );
    }
    for (final arrow in puzzle.arrows) {
      final exiting = exits[arrow.id];
      if (state.removed.contains(arrow.id) && exiting == null) continue;
      if (!_shown(arrow.id)) continue;
      final offset = _offsetOf(arrow);
      final shoved = bumping && arrow.id == hitId && shove > 0;
      if (shoved) {
        // Shoved the way the bumping arrow was going when it hit — past a
        // mirror that is not the way its head points.
        final push = _unit(_travelInto(bumpId!, blocked!)) * (shove * kShoveDistance * cs);
        canvas.save();
        canvas.translate(push.dx, push.dy);
      }
      // The slump: each arrow droops and leans by its own amount, about its
      // own middle, so a lost level sags raggedly instead of sliding as one
      // block.
      final slumping = slump != null && !state.removed.contains(arrow.id);
      if (slumping) {
        final pivot = _center(arrow.cells[arrow.length ~/ 2], cs);
        canvas.save();
        canvas.translate(pivot.dx, pivot.dy + slumpDropFor(arrow.id, slump!) * cs);
        canvas.rotate(slumpTiltFor(arrow.id, slump!));
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      _paintArrow(canvas, arrow, cs, offset, false, glyphs);
      if (slumping) canvas.restore();
      if (shoved) canvas.restore();
    }
    _paintBounces(canvas, cs, glyphs);
    _paintSparks(canvas, cs);
    _paintPointer(canvas, cs, glyphs);
    _paintHint(canvas, rect, cs);
    canvas.restore();
    // Outside the clip: the ring sits a little proud of the cells, and an
    // arrow on the board's edge would otherwise lose that side of it.
    _paintCursor(canvas, cs);
    canvas.restore();
  }

  /// A mirror an arrow has just turned at: its diagonal lights up in the
  /// glow and a ring swells out of the cell and fades, the same ring the
  /// board uses for everything that just happened (a key leaving, a head
  /// appearing), so a bounce is a thing that is seen to happen and not only
  /// a path that happened to bend.
  void _paintBounces(Canvas canvas, double cs, BoardGlyphs glyphs) {
    for (final e in bounces.entries) {
      final cell = Cell(e.key % puzzle.width, e.key ~/ puzzle.width);
      final kind = puzzle.mirrorAt(cell);
      if (kind == null) continue;
      final t = e.value;
      final centre = _center(cell, cs);
      final rect = Rect.fromLTWH(cell.x * cs, cell.y * cs, cs, cs);
      glyphs.mirrorFlash(canvas, rect, kind, palette.hintGlow.withValues(alpha: 1 - t));
      final ease = Curves.easeOutCubic.transform(t);
      canvas.drawCircle(
        centre,
        max(cs * 0.5, 10.0) + max(cs * 1.4, 28.0) * ease,
        Paint()
          ..color = palette.hintGlow.withValues(alpha: 0.9 * (1 - ease))
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.0, min(cs * 0.2, 4.0)),
      );
    }
  }

  /// The first part of a lock opening: a spark in the sun colour flies
  /// from where the key was to the lock, a dashed trail fading behind it,
  /// so the two are seen to be the two ends of one thing before the
  /// padlock pops.
  void _paintSparks(Canvas canvas, double cs) {
    for (final e in unlocks.entries) {
      if (e.value >= kSparkShare) continue;
      final key = puzzle.keyOf(e.key);
      if (key == null) continue;
      final u = Curves.easeInOut.transform(e.value / kSparkShare);
      final from = _middle(puzzle.arrows[key], cs);
      final to = _middle(puzzle.arrows[e.key], cs);
      final at = Offset.lerp(from, to, u)!;
      final stroke = max(2.0, min(cs * 0.16, 4.0));
      final trail = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(at.dx, at.dy);
      canvas.drawPath(
        BoardGlyphs.dashed(trail, stroke * 1.5, stroke * 1.5),
        Paint()
          ..color = palette.accentSun.withValues(alpha: 0.9 * (1 - u * 0.6))
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      final r = max(cs * 0.3, 6.0);
      canvas.drawCircle(at, r * 1.8, Paint()..color = palette.hintGlow.withValues(alpha: 0.35));
      canvas.drawCircle(at, r, Paint()..color = palette.accentSun);
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..color = palette.arrowInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, r * 0.18),
      );
    }
  }

  /// After a tap on a locked arrow, or on a hidden one: a dashed line from
  /// it to each arrow it waits on — the key; the arrows beside it that
  /// would uncover its head — and a ring swelling out of each, twice, so
  /// "that one first" needs no number read and no guess made.
  void _paintPointer(Canvas canvas, double cs, BoardGlyphs glyphs) {
    final t = pointer;
    final from = state.lastMoveId;
    if (t == null || from == null) return;
    final targets = <int>[
      for (final id in pointerTargets)
        if (!state.removed.contains(id)) id,
    ];
    if (targets.isEmpty) return;
    final origin = _middle(puzzle.arrows[from], cs);
    final fade = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
    final stroke = max(2.0, min(cs * 0.16, 4.0));
    // Two pings over the run.
    final phase = (t * 2) % 1;
    final ease = Curves.easeOutCubic.transform(phase);
    final from0 = max(cs * 0.8, 14.0);
    final to0 = max(from0 + 8, min(cs * 2.4, 50.0));
    for (final id in targets) {
      final to = _middle(puzzle.arrows[id], cs);
      final line = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(to.dx, to.dy);
      canvas.drawPath(
        BoardGlyphs.dashed(line, stroke * 1.5, stroke * 1.5),
        Paint()
          ..color = palette.accentSun.withValues(alpha: fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        to,
        from0 + (to0 - from0) * ease,
        Paint()
          ..color = palette.accentSun.withValues(alpha: (0.95 - 0.8 * ease) * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.5, min(cs * 0.26, 5.0)),
      );
    }
    // The targets themselves, brought forward.
    for (final id in targets) {
      _paintArrow(canvas, puzzle.arrows[id], cs, _offsetOf(puzzle.arrows[id]), false, glyphs);
    }
  }

  /// The centre of [arrow]'s middle cell, where its glyph sits.
  static Offset _middle(ArrowPiece arrow, double cs) => _center(arrow.cells[arrow.length ~/ 2], cs);

  /// The direction arrow [id] is travelling as it enters [cell] on its ray.
  Direction _travelInto(int id, Cell cell) {
    final ray = puzzle.rayOf(id);
    final i = ray.indexOf(cell);
    final from = i <= 0 ? puzzle.arrows[id].head : ray[i - 1];
    return from.directionTo(cell) ?? puzzle.arrows[id].heading;
  }

  /// The keyboard cursor: a rounded ring around the cells of the focused
  /// arrow, in the primary, so a player on a laptop can see which arrow
  /// Enter will play.
  void _paintCursor(Canvas canvas, double cs) {
    final id = focusedId;
    if (id == null || id >= puzzle.arrowCount || state.removed.contains(id)) return;
    final rect = _bounds(puzzle.arrows[id], cs).inflate(cs * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cs * 0.35)),
      Paint()
        ..color = palette.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.0, min(cs * 0.14, 4.0)),
    );
  }

  /// The box around every cell of [arrow], in canvas pixels.
  static Rect _bounds(ArrowPiece arrow, double cs) {
    var minX = arrow.cells.first.x, maxX = minX, minY = arrow.cells.first.y, maxY = minY;
    for (final c in arrow.cells) {
      minX = min(minX, c.x);
      maxX = max(maxX, c.x);
      minY = min(minY, c.y);
      maxY = max(maxY, c.y);
    }
    return Rect.fromLTRB(minX * cs, minY * cs, (maxX + 1) * cs, (maxY + 1) * cs);
  }

  /// One semantics node per arrow still on the board, over the cells it
  /// covers, labelled as `board_semantics.dart` describes it and tappable.
  /// Only ever called with semantics on, so the big boards pay nothing for
  /// it otherwise.
  @override
  SemanticsBuilderCallback? get semanticsBuilder {
    final strings = l10n;
    if (strings == null) return null;
    return (Size size) {
      final (originX, windowWidth) = _window(puzzle, face);
      final cs = size.width / windowWidth;
      final nodes = <CustomPainterSemantics>[];
      // Reading order: by the head's row, then its column.
      final order = <ArrowPiece>[
        for (final a in puzzle.arrows)
          if (!state.removed.contains(a.id) && _shown(a.id)) a,
      ]..sort((a, b) => a.head.y != b.head.y ? a.head.y - b.head.y : a.head.x - b.head.x);
      for (var i = 0; i < order.length; i++) {
        final arrow = order[i];
        nodes.add(
          CustomPainterSemantics(
            key: ValueKey<int>(arrow.id),
            rect: _bounds(arrow, cs).shift(Offset(-originX * cs, 0)),
            properties: SemanticsProperties(
              label: arrowLabel(strings, state, arrow.id),
              textDirection: textDirection,
              hintOverrides: SemanticsHintOverrides(onTapHint: strings.arrowTapHint),
              button: true,
              enabled: state.isPlaying,
              focused: arrow.id == focusedId,
              sortKey: OrdinalSortKey(i.toDouble()),
              onTap: state.isPlaying ? () => onTapArrow(arrow.id) : null,
            ),
          ),
        );
      }
      return nodes;
    };
  }

  @override
  bool shouldRebuildSemantics(_BoardPainter old) =>
      old.state.puzzle != state.puzzle ||
      old.state.removed != state.removed ||
      old.state.bumped != state.bumped ||
      old.state.revealed != state.revealed ||
      old.state.hintArrowId != state.hintArrowId ||
      old.state.phase != state.phase ||
      old.focusedId != focusedId ||
      old.face != face ||
      old.l10n != l10n;

  /// The hint, drawn over the finished board: everything else dims behind a
  /// veil, the hinted arrow is redrawn at full strength on top of it, and a
  /// ring swells out of its head and fades, over and over. A late board is a
  /// hundred arrows in one ink — the eye does not find a static smudge among
  /// them, it finds the one thing still bright, and it finds movement.
  void _paintHint(Canvas canvas, Rect board, double cs) {
    final id = state.hintArrowId;
    if (id == null || state.removed.contains(id) || !_shown(id)) return;
    final arrow = puzzle.arrows[id];
    canvas.drawRect(board, Paint()..color = palette.hintVeil);
    _paintArrow(canvas, arrow, cs, 0, true, null);

    final ping = hintPing;
    if (ping == null) return;
    final t = Curves.easeOutCubic.transform(ping);
    final from = min(cs * 0.9, 20.0);
    final to = max(from + 6, min(cs * 2.6, 56.0));
    canvas.drawCircle(
      _center(arrow.head, cs),
      from + (to - from) * t,
      Paint()
        ..color = palette.hintGlow.withValues(alpha: 0.95 - 0.7 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.5, min(cs * 0.26, 5.0)),
    );
  }

  /// The closest two cells of [a] and [b], for the tether between them —
  /// off the heads where there is a choice, so the ring never sits on the
  /// one part of an arrow that says which way it goes.
  static (Cell, Cell) _nearestCells(ArrowPiece a, ArrowPiece b) {
    var best = (a.cells.first, b.cells.first);
    var bestD = 1 << 30;
    for (final ca in a.cells) {
      for (final cb in b.cells) {
        var d = 4 * ((ca.x - cb.x).abs() + (ca.y - cb.y).abs());
        if (ca == a.head) d += 3;
        if (cb == b.head) d += 3;
        if (d < bestD) {
          bestD = d;
          best = (ca, cb);
        }
      }
    }
    return best;
  }

  /// [arrow]'s track: its cells, then its exit ray — which turns at a
  /// mirror, so the arrow bends through the glass as it goes — then
  /// straight on past the edge (where the clip swallows it), far enough
  /// that sampling never runs out.
  List<Cell> _trackOf(ArrowPiece arrow) {
    final track = <Cell>[...arrow.cells, ...puzzle.rayOf(arrow.id)];
    var beyond = track.last;
    final exitHeading = puzzle.exitHeadingOf(arrow.id);
    for (var i = 0; i < arrow.length + 2; i++) {
      beyond = beyond.step(exitHeading);
      track.add(beyond);
    }
    return track;
  }

  /// The point [u] cells along [arrow]'s track (0 is its tail's cell).
  Offset _trackPoint(ArrowPiece arrow, double u, double cs) => _along(_trackOf(arrow), u, cs);

  /// How far either side of a bend in a track the line is rounded, in
  /// cells: a body turns its corner on a curve rather than at a point.
  static const double kBend = 0.35;

  /// Whether [track] changes direction at its [k]th cell.
  static bool _bendsAt(List<Cell> track, int k) {
    if (k < 1 || k > track.length - 2) return false;
    final before = track[k];
    final a = track[k - 1];
    final b = track[k + 1];
    return a.x - before.x != before.x - b.x || a.y - before.y != before.y - b.y;
  }

  /// The point [u] cells along [track]: straight between cell centres, and
  /// round each bend a curve through the corner (a quadratic from [kBend]
  /// before the corner to [kBend] after it), so an arrow sliding through
  /// its own turn or a mirror's swings round it like a train on rails.
  static Offset _along(List<Cell> track, double u, double cs) {
    final k = u.round();
    if ((u - k).abs() < kBend && _bendsAt(track, k)) {
      final corner = _center(track[k], cs);
      final a = Offset.lerp(_center(track[k - 1], cs), corner, 1 - kBend)!;
      final b = Offset.lerp(corner, _center(track[k + 1], cs), kBend)!;
      final t = (u - (k - kBend)) / (2 * kBend);
      final s = 1 - t;
      return a * (s * s) + corner * (2 * s * t) + b * (t * t);
    }
    final i = u.floor().clamp(0, track.length - 2);
    final f = (u - i).clamp(0.0, 1.0);
    return Offset.lerp(_center(track[i], cs), _center(track[i + 1], cs), f)!;
  }

  /// The stretch of [track] from [from] to [to] cells along it, as a path:
  /// straight runs between the corners and the corners rounded as
  /// [_along] rounds them. The first cut joined the body's cell points
  /// with straight lines, so as an arrow slid round a bend the line
  /// between the point before the corner and the point after it cut
  /// straight across — the body pinched at every turn as it went.
  static Path _pathAlong(List<Cell> track, double from, double to, double cs) {
    final start = _along(track, from, cs);
    final path = Path()..moveTo(start.dx, start.dy);
    const steps = 6;
    for (var k = max(1, from.floor()); k <= min(track.length - 2, to.ceil()); k++) {
      if (!_bendsAt(track, k) || k + kBend <= from || k - kBend >= to) continue;
      final a = max(from, k - kBend);
      final b = min(to, k + kBend);
      for (var s = 0; s <= steps; s++) {
        final p = _along(track, a + (b - a) * s / steps, cs);
        path.lineTo(p.dx, p.dy);
      }
    }
    final end = _along(track, to, cs);
    path.lineTo(end.dx, end.dy);
    return path;
  }

  /// Draws [arrow] shifted [offset] cells forward along its own track. With
  /// [glyphs] the arrow's twist is drawn on it too: its padlock or key, its
  /// question mark while its head is hidden; the hint's redraw passes none.
  /// A head coming out of the fog and a lock popping open are drawn here as
  /// well: the dashes firm into a line and the head springs in, or the
  /// padlock swings open, each with a ring and a glow over the whole arrow
  /// that fades as the moment passes.
  void _paintArrow(
    Canvas canvas,
    ArrowPiece arrow,
    double cs,
    double offset,
    bool hinted,
    BoardGlyphs? glyphs,
  ) {
    final track = _trackOf(arrow);
    Offset at(double u) => _along(track, u, cs);

    final ink = palette.arrowInk;
    // Scales with the cell but stays a pen line on small boards, where a
    // cell is huge and a proportional stroke would turn into a slab.
    final stroke = min(cs * 0.12, 3.0);
    final headAt = offset + arrow.length - 1;
    final head = at(headAt);
    // The head's travel direction: the track's tangent there, which turns
    // smoothly through a rounded corner.
    var dir = at(headAt + 0.15) - at(headAt - 0.15);
    if (dir.distance < 0.001) dir = _unit(arrow.heading);
    dir = dir / dir.distance;
    // Hidden until the arrow that uncovers it has gone.
    final headShown = state.headShown(arrow.id) && !pendingReveals.contains(arrow.id);
    // A head that has just been uncovered springs in from nothing over the
    // first part of the reveal; the dashes firm into a line meanwhile.
    final reveal = reveals[arrow.id];
    final headScale = reveal == null ? 1.0 : Curves.elasticOut.transform(min(1, reveal / 0.6));
    final solidity = reveal == null ? 1.0 : min(1.0, reveal / 0.4);
    // A lock whose key has gone: shut while the spark is on its way, then
    // swinging open.
    final key = puzzle.keyOf(arrow.id);
    final pop = unlocks[arrow.id];
    final popT = pop == null ? null : ((pop - kSparkShare) / (1 - kSparkShare)).clamp(0.0, 1.0);

    // Body ends a bit short of the head so the triangle caps it cleanly;
    // a hidden head is no head, so the body runs to the cell's centre.
    final headLen = min(cs * 0.3, 8.0) * headScale;
    final bodyEnd = headShown ? head - dir * (headLen * 0.55) : head;
    final longBody = arrow.length > 1;
    final path = longBody
        ? _pathAlong(track, offset, headAt - (headShown ? headLen * 0.55 / cs : 0), cs)
        : (Path()..moveTo(bodyEnd.dx, bodyEnd.dy));
    // A hidden head is drawn as a dashed body with no head at either end:
    // the player can see where it lies, not which way it goes.
    final dashedPath = !headShown || solidity < 1 ? BoardGlyphs.dashed(path, stroke * 1.6, stroke * 1.4) : null;

    // The glow: the hint's halo at full strength, or the moment's — a head
    // out of the fog, a lock open (lit as the spark lands, not before) —
    // fading as it passes.
    final moment = max(reveal == null ? 0.0 : 1 - reveal, popT == null || pop! < kSparkShare ? 0.0 : 1 - popT);
    if (hinted || moment > 0) {
      // The ink is capped at 3 px, so a halo proportional to it is a hair on
      // a dense board: it gets its own floor in pixels.
      final glowColor = hinted ? palette.hintGlow : palette.hintGlow.withValues(alpha: palette.hintGlow.a * moment);
      final glow = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(stroke * 2.4, min(cs * 0.6, 6.0))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, glow);
      if (headShown) {
        canvas.drawCircle(
          head,
          max(headLen * 1.1, min(cs * 0.55, 10.0)),
          Paint()..color = glowColor,
        );
      }
    }

    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (longBody) {
      if (!headShown) {
        canvas.drawPath(dashedPath!, paint);
      } else if (dashedPath != null) {
        // The fog lifting: the dashes fade as the line comes through.
        canvas.drawPath(dashedPath, Paint.from(paint)..color = ink.withValues(alpha: 1 - solidity));
        canvas.drawPath(path, Paint.from(paint)..color = ink.withValues(alpha: solidity));
      } else {
        canvas.drawPath(path, paint);
      }
    } else {
      // A one-cell arrow is just its head plus a stub.
      canvas.drawLine(head - dir * (cs * 0.25), bodyEnd, paint);
    }

    if (headShown) {
      final tip = head + dir * (headLen * 0.8);
      final base = head - dir * (headLen * 0.55);
      final side = Offset(-dir.dy, dir.dx) * (headLen * 0.75);
      final tri = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + side.dx, base.dy + side.dy)
        ..lineTo(base.dx - side.dx, base.dy - side.dy)
        ..close();
      canvas.drawPath(
        tri,
        Paint()
          ..color = ink
          ..style = PaintingStyle.fill
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        tri,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 0.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (reveal != null) {
      // A ring swells out of the new head.
      final t = Curves.easeOutCubic.transform(reveal);
      canvas.drawCircle(
        head,
        max(cs * 0.6, 10.0) + max(cs * 1.6, 30.0) * t,
        Paint()
          ..color = palette.hintGlow.withValues(alpha: 0.9 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.0, min(cs * 0.2, 4.0)),
      );
    }

    if (glyphs == null) return;
    // The twist, on the arrow's middle cell, travelling with it.
    final mid = at(offset + arrow.length ~/ 2);
    final g = BoardGlyphs.glyphSize(cs);
    if (!headShown) {
      glyphs.question(canvas, mid, g);
    }
    if (key != null) {
      final opened = state.removed.contains(key) && !pendingUnlocks.contains(arrow.id);
      // Shut, swinging open, or open: the swing is the first half of the
      // pop once the spark has arrived.
      final openness = !opened ? 0.0 : (popT == null ? 1.0 : Curves.easeOutBack.transform(min(1, popT * 2)));
      if (popT != null && popT > 0) {
        final t = Curves.easeOutCubic.transform(popT);
        canvas.drawCircle(
          mid,
          g * 0.5 + max(cs * 1.4, 26.0) * t,
          Paint()
            ..color = palette.hintGlow.withValues(alpha: 0.9 * (1 - t))
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2.0, min(cs * 0.2, 4.0)),
        );
      }
      glyphs.padlock(canvas, mid, g, openness: openness, number: puzzle.lockNumber(arrow.id));
    } else if (puzzle.locksOpenedBy(arrow.id).isNotEmpty) {
      glyphs.key(canvas, mid, g, puzzle.lockNumber(arrow.id)!);
    }
  }

  static Offset _center(Cell c, double cs) => Offset((c.x + 0.5) * cs, (c.y + 0.5) * cs);

  static Offset _unit(Direction d) {
    final (dx, dy) = d.vector;
    return Offset(dx.toDouble(), dy.toDouble());
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      // The clock ticks ten times a second; only board-relevant state counts.
      old.state.puzzle != state.puzzle ||
      old.state.removed != state.removed ||
      old.state.hintArrowId != state.hintArrowId ||
      old.state.revealed != state.revealed ||
      old.hintPing != hintPing ||
      old.slump != slump ||
      old.state.blockedCell != state.blockedCell ||
      old.state.blockedKey != state.blockedKey ||
      old.state.moveToken != state.moveToken ||
      old.showGrid != showGrid ||
      old.palette != palette ||
      !_sameMap(old.exits, exits) ||
      old.bumpId != bumpId ||
      old.bump != bump ||
      old.pointer != pointer ||
      !listEquals(old.pointerTargets, pointerTargets) ||
      !_sameMap(old.unlocks, unlocks) ||
      !_sameMap(old.reveals, reveals) ||
      !setEquals(old.pendingUnlocks, pendingUnlocks) ||
      !setEquals(old.pendingReveals, pendingReveals) ||
      !_sameMap(old.bounces, bounces) ||
      old.travel != travel ||
      old.face != face ||
      old.focusedId != focusedId;

  static bool _sameMap(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
