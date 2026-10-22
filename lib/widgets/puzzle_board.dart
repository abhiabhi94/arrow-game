import 'dart:math';

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

/// How long the pointer from a tapped lock to its key stays up.
const int kKeyPingMs = 1800;

/// How long a padlock takes to swing open, with its ring.
const int kUnlockMs = 700;

/// How long a hidden head takes to spring into view, with its ring.
const int kRevealMs = 650;

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
class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.state,
    required this.showGrid,
    required this.onTapArrow,
    this.zoom = 1,
    this.focusedArrowId,
    this.reduceMotion = false,
  });

  final GameState state;
  final bool showGrid;
  final ValueChanged<int> onTapArrow;

  /// The scale the board is being viewed at, so touch slop stays the same
  /// size on screen however far in the player has pinched.
  final double zoom;

  /// The arrow the keyboard cursor is on, ringed on the board; null for none.
  final int? focusedArrowId;

  /// Keep the board's motion to what carries information (see `ui/motion.dart`).
  final bool reduceMotion;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> with TickerProviderStateMixin {
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

  /// Runs after a tap on a locked arrow: a dashed line from the lock to its
  /// key and a ring pulsing on the key, so the player sees what has to go
  /// first without reading a number.
  AnimationController? _keyPing;

  /// Padlocks popping open, by the locked arrow's id: the key has just
  /// left, and the lock swings open with a ring.
  final Map<int, AnimationController> _unlocks = <int, AnimationController>{};

  /// Heads appearing, by the hidden arrow's id: a neighbour has just left
  /// (or a hint lit it), and the head springs into view with a ring.
  final Map<int, AnimationController> _reveals = <int, AnimationController>{};

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
  void didUpdateWidget(PuzzleBoard old) {
    super.didUpdateWidget(old);
    if (old.reduceMotion != widget.reduceMotion) {
      _hintPing?.dispose();
      _hintPing = null;
      _slump?.dispose();
      _slump = null;
    }
    _syncHintPing();
    final s = widget.state;
    if (s.puzzle != old.state.puzzle || s.moveToken < old.state.moveToken) {
      // A restart: forget every animation.
      _disposeAll();
      _syncSlump();
      return;
    }
    final moved = s.moveToken != old.state.moveToken && s.lastMoveId != null;
    if (moved) {
      final id = s.lastMoveId!;
      switch (s.lastOutcome) {
        case MoveOutcome.exited:
          _startExit(id);
          _startUnlocks(id);
        case MoveOutcome.blocked:
          _startBump(id);
        case MoveOutcome.locked:
          _startBump(id);
          _startKeyPing();
        case MoveOutcome.none:
          break;
      }
    }
    for (final id in s.revealed.difference(old.state.revealed)) {
      _startReveal(id);
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
        }
        setState(() {});
      });
      controller.forward().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _exits.remove(member)?.dispose();
        });
      });
    }
  }

  /// The padlocks [id] was the key of swing open as it leaves.
  void _startUnlocks(int id) {
    final puzzle = widget.state.puzzle!;
    for (final member in puzzle.exitGroup(id)) {
      for (final lock in puzzle.locksOpenedBy(member)) {
        if (widget.state.removed.contains(lock)) continue;
        _startOneShot(_unlocks, lock, kUnlockMs);
      }
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

  /// Points at the key of the arrow just tapped.
  void _startKeyPing() {
    _keyPing?.dispose();
    final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: kKeyPingMs));
    _keyPing = controller;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        if (_keyPing == controller) _keyPing = null;
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
    _keyPing?.dispose();
    _keyPing = null;
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
  int? _arrowFor(Offset p, double cellSize) {
    final puzzle = widget.state.puzzle!;
    final cell = Cell((p.dx / cellSize).floor(), (p.dy / cellSize).floor());
    if (cell.isInside(puzzle.width, puzzle.height)) {
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
        if (!c.isInside(puzzle.width, puzzle.height)) continue;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          constraints.maxWidth / puzzle.width,
          constraints.maxHeight / puzzle.height,
        );
        final size = Size(cellSize * puzzle.width, cellSize * puzzle.height);
        return Center(
          // The board is a labelled container and the painter supplies one
          // node per arrow; the gesture detector adds nothing of its own,
          // since a semantic tap on the whole board would land at its centre.
          child: Semantics(
            container: true,
            label: l10n == null ? null : boardLabel(l10n, widget.state),
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
                    keyPing: _keyPing?.value,
                    unlocks: <int, double>{for (final e in _unlocks.entries) e.key: e.value.value},
                    reveals: <int, double>{for (final e in _reveals.entries) e.key: e.value.value},
                    bounces: <int, double>{for (final e in _bounces.entries) e.key: e.value.value},
                    travel: widget.reduceMotion ? 0 : 1,
                    focusedId: widget.focusedArrowId,
                    l10n: l10n,
                    textDirection: Directionality.of(context),
                    onTapArrow: widget.onTapArrow,
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
    required this.keyPing,
    required this.unlocks,
    required this.reveals,
    required this.bounces,
    required this.travel,
    required this.focusedId,
    required this.l10n,
    required this.textDirection,
    required this.onTapArrow,
  });

  final GameState state;
  final ArrowPalette palette;
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

  /// The bumping arrow, its progress (0..1) and its motion.
  final int? bumpId;
  final double? bump;
  final BumpMotion? bumpMotion;

  /// The pointer to the key after a locked tap, 0..1, or null.
  final double? keyPing;

  /// Padlocks popping open (locked id → progress) and heads appearing
  /// (hidden id → progress).
  final Map<int, double> unlocks;
  final Map<int, double> reveals;

  /// Mirrors mid-flash, by packed cell: an arrow has just turned there.
  final Map<int, double> bounces;

  Puzzle get puzzle => state.puzzle!;

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / puzzle.width;
    final rect = Offset.zero & size;

    // No frame: the arrows sit straight on the page. Grid lines, when on,
    // run through the cell centres — the lattice the arrows are drawn on —
    // so every body lies exactly on a line and every head points along one.
    if (showGrid) {
      final grid = Paint()
        ..color = palette.gridLine
        ..strokeWidth = 1;
      final first = cs / 2;
      final lastX = size.width - cs / 2;
      final lastY = size.height - cs / 2;
      for (var x = 0; x < puzzle.width; x++) {
        final px = first + x * cs;
        canvas.drawLine(Offset(px, first), Offset(px, lastY), grid);
      }
      for (var y = 0; y < puzzle.height; y++) {
        final py = first + y * cs;
        canvas.drawLine(Offset(first, py), Offset(lastX, py), grid);
      }
    }

    final glyphs = BoardGlyphs(
      ink: palette.arrowInk,
      paper: palette.backgroundSoft,
      badge: palette.accentSun,
      onBadge: palette.onAccent,
      mirrorWash: palette.mirror,
      textDirection: textDirection,
    );
    // Mirrors: drawn under everything, so an arrow slides over the glass as
    // it turns.
    for (final e in puzzle.mirrors.entries) {
      glyphs.mirror(canvas, Rect.fromLTWH(e.key.x * cs, e.key.y * cs, cs, cs), e.value);
    }

    // The bump: the tapped arrow runs into the arrow in its way, which takes
    // the hit — its cell flashes and it is shoved a touch — then springs
    // back. Held by a lock instead, it only rattles (the same motion, a
    // fraction of a cell), and the key is pointed at below.
    final blocked = state.blockedCell;
    final bumpT = bump;
    final motion = bumpMotion;
    final bumping =
        (blocked != null || state.blockedKey != null) && bumpT != null && motion != null && bumpId == state.lastMoveId;
    final flash = bumping && blocked != null ? motion.flashAt(bumpT) : 0.0;
    final shove = bumping && blocked != null ? motion.shoveAt(bumpT) * travel : 0.0;
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
    // Tethers first, under the arrows they join. A pair in flight has
    // left together; the line is not drawn after them.
    for (final e in puzzle.pairs.entries) {
      final a = e.key;
      final b = e.value;
      if (a > b || state.removed.contains(a) || state.removed.contains(b)) continue;
      final (ca, cb) = _nearestCells(puzzle.arrows[a], puzzle.arrows[b]);
      glyphs.tether(canvas, _center(ca, cs), _center(cb, cs), cs);
    }
    for (final arrow in puzzle.arrows) {
      final exiting = exits[arrow.id];
      if (state.removed.contains(arrow.id) && exiting == null) continue;
      final travel = arrow.length + puzzle.rayOf(arrow.id).length;
      var offset = 0.0;
      if (exiting != null) {
        offset = Curves.easeIn.transform(exiting) * travel;
      } else if (bumping && bumpId == arrow.id) {
        offset = motion.offsetAt(bumpT) * travel;
      }
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
    _paintKeyPointer(canvas, cs, glyphs);
    _paintHint(canvas, size, cs);
    canvas.restore();
    // Outside the clip: the ring sits a little proud of the cells, and an
    // arrow on the board's edge would otherwise lose that side of it.
    _paintCursor(canvas, cs);
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

  /// After a tap on a locked arrow: a dashed line from the lock to its key
  /// and a ring swelling out of the key, twice, so "that one first" needs
  /// no number read.
  void _paintKeyPointer(Canvas canvas, double cs, BoardGlyphs glyphs) {
    final t = keyPing;
    final lock = state.lastMoveId;
    final key = state.blockedKey;
    if (t == null || lock == null || key == null || state.removed.contains(key)) return;
    final from = _center(puzzle.arrows[lock].cells[puzzle.arrows[lock].length ~/ 2], cs);
    final to = _center(puzzle.arrows[key].cells[puzzle.arrows[key].length ~/ 2], cs);
    final fade = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
    final stroke = max(2.0, min(cs * 0.16, 4.0));
    final line = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(
      BoardGlyphs.dashed(line, stroke * 1.5, stroke * 1.5),
      Paint()
        ..color = palette.accentSun.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    // Two pings over the run.
    final phase = (t * 2) % 1;
    final ease = Curves.easeOutCubic.transform(phase);
    final from0 = max(cs * 0.8, 14.0);
    final to0 = max(from0 + 8, min(cs * 2.4, 50.0));
    canvas.drawCircle(
      to,
      from0 + (to0 - from0) * ease,
      Paint()
        ..color = palette.accentSun.withValues(alpha: (0.95 - 0.8 * ease) * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.5, min(cs * 0.26, 5.0)),
    );
    // The key itself, brought forward.
    _paintArrow(canvas, puzzle.arrows[key], cs, 0, false, glyphs);
  }

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
      final cs = size.width / puzzle.width;
      final nodes = <CustomPainterSemantics>[];
      // Reading order: by the head's row, then its column.
      final order = <ArrowPiece>[
        for (final a in puzzle.arrows)
          if (!state.removed.contains(a.id)) a,
      ]..sort((a, b) => a.head.y != b.head.y ? a.head.y - b.head.y : a.head.x - b.head.x);
      for (var i = 0; i < order.length; i++) {
        final arrow = order[i];
        nodes.add(
          CustomPainterSemantics(
            key: ValueKey<int>(arrow.id),
            rect: _bounds(arrow, cs),
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
      old.l10n != l10n;

  /// The hint, drawn over the finished board: everything else dims behind a
  /// veil, the hinted arrow is redrawn at full strength on top of it, and a
  /// ring swells out of its head and fades, over and over. A late board is a
  /// hundred arrows in one ink — the eye does not find a static smudge among
  /// them, it finds the one thing still bright, and it finds movement.
  void _paintHint(Canvas canvas, Size size, double cs) {
    final id = state.hintArrowId;
    if (id == null || state.removed.contains(id)) return;
    final arrow = puzzle.arrows[id];
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.hintVeil);
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

  /// Draws [arrow] shifted [offset] cells forward along its own track (its
  /// cells, then its exit ray — which turns at a mirror, so the arrow bends
  /// through the glass as it goes — then straight on past the edge, where
  /// the clip swallows it). With [glyphs] the arrow's twist is drawn on it
  /// too: its padlock or key, its question mark while its head is hidden;
  /// the hint's redraw passes none.
  void _paintArrow(
    Canvas canvas,
    ArrowPiece arrow,
    double cs,
    double offset,
    bool hinted,
    BoardGlyphs? glyphs,
  ) {
    final ray = puzzle.rayOf(arrow.id);
    final track = <Cell>[...arrow.cells, ...ray];
    // Extend past the edge so sampling never runs out.
    var beyond = track.last;
    final exitHeading = puzzle.exitHeadingOf(arrow.id);
    for (var i = 0; i < arrow.length + 2; i++) {
      beyond = beyond.step(exitHeading);
      track.add(beyond);
    }
    Offset at(double u) {
      final i = u.floor().clamp(0, track.length - 2);
      final f = (u - i).clamp(0.0, 1.0);
      return Offset.lerp(_center(track[i], cs), _center(track[i + 1], cs), f)!;
    }

    final ink = palette.arrowInk;
    // Scales with the cell but stays a pen line on small boards, where a
    // cell is huge and a proportional stroke would turn into a slab.
    final stroke = min(cs * 0.12, 3.0);
    final headAt = offset + arrow.length - 1;
    final points = <Offset>[for (var i = 0; i < arrow.length; i++) at(offset + i)];
    final head = at(headAt);
    // The head's travel direction: where the track goes next.
    final ahead = at(headAt + 0.5);
    var dir = ahead - head;
    if (dir.distance < 0.001) dir = _unit(arrow.heading);
    dir = dir / dir.distance;
    final headShown = state.headShown(arrow.id);
    // A head that has just been uncovered springs in from nothing.
    final reveal = reveals[arrow.id];
    final headScale = reveal == null ? 1.0 : Curves.elasticOut.transform(reveal);

    // Body ends a bit short of the head so the triangle caps it cleanly;
    // a hidden head is no head, so the body runs to the cell's centre.
    final headLen = min(cs * 0.3, 8.0) * headScale;
    final bodyEnd = headShown ? head - dir * (headLen * 0.55) : head;
    var path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length > 1) {
      path.lineTo(bodyEnd.dx, bodyEnd.dy);
    }
    // A hidden head is drawn as a dashed body with no head at either end:
    // the player can see where it lies, not which way it goes.
    if (!headShown) path = BoardGlyphs.dashed(path, stroke * 1.6, stroke * 1.4);

    if (hinted) {
      // The ink is capped at 3 px, so a halo proportional to it is a hair on
      // a dense board: it gets its own floor in pixels.
      final glow = Paint()
        ..color = palette.hintGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(stroke * 2.4, min(cs * 0.6, 6.0))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, glow);
      canvas.drawCircle(
        head,
        max(headLen * 1.1, min(cs * 0.55, 10.0)),
        Paint()..color = palette.hintGlow,
      );
    }

    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (points.length > 1) {
      canvas.drawPath(path, paint);
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
    final key = puzzle.keyOf(arrow.id);
    if (key != null) {
      final opened = state.removed.contains(key);
      final pop = unlocks[arrow.id];
      // Shut, swinging open, or open: the swing is the pop's first half.
      final openness = !opened ? 0.0 : (pop == null ? 1.0 : Curves.easeOutBack.transform(min(1, pop * 2)));
      if (pop != null) {
        final t = Curves.easeOutCubic.transform(pop);
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
      old.keyPing != keyPing ||
      !_sameMap(old.unlocks, unlocks) ||
      !_sameMap(old.reveals, reveals) ||
      !_sameMap(old.bounces, bounces) ||
      old.travel != travel ||
      old.focusedId != focusedId;

  static bool _sameMap(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
