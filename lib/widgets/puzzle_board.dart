import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../models/bump_motion.dart';
import '../models/game_state.dart';
import '../models/reaction_motion.dart';
import '../ui/colors.dart';

/// How far the arrow that was hit is shoved along, in cells, at full jolt.
const double kShoveDistance = 0.12;

/// How far from a tap the board looks for an arrow when the finger lands on
/// an empty cell, in logical pixels. Boards are capped so a cell is about
/// two thirds of a fingertip, so a tap that misses into a gap still gets the
/// arrow it was plainly aimed at. A cell that *is* occupied always wins:
/// slop never overrides a deliberate hit.
const double kTouchSlopPx = 22;

/// How far into a slide the board starts accepting taps again. The slide runs
/// 240-600 ms, so this is the first 70-180 ms of it.
const double kSettleFraction = 0.3;

/// How long one ping of the hint ring takes.
const Duration kHintPingPeriod = Duration(milliseconds: 1100);

/// The board: draws every arrow still on the board (plus any arrow mid-slide
/// on its way out) in a single ink — thin lines with a small head, like a
/// printed puzzle, straight on the page with no frame — plus optional grid
/// lines, the hint glow and the blocked-cell flash, and turns taps into
/// [onTapArrow] calls. Requires a loaded [GameState.puzzle].
///
/// Game state changes instantly on a tap; the slide-out and bump animations
/// are purely visual and live here, keyed on [GameState.moveToken].
class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({
    super.key,
    required this.state,
    required this.showGrid,
    required this.onTapArrow,
  });

  final GameState state;
  final bool showGrid;
  final ValueChanged<int> onTapArrow;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> with TickerProviderStateMixin {
  /// Arrows sliding out: id → progress controller.
  final Map<int, AnimationController> _exits = <int, AnimationController>{};

  /// Runs the slump when a level ends badly: every arrow still on the board
  /// droops and tilts, like the puzzle giving up.
  AnimationController? _slump;

  /// Pointers on the board now, and the most this gesture has seen. A second
  /// finger resting on the board should never turn a stray touch into a move.
  int _pointersDown = 0;
  int _pointersInGesture = 0;

  /// Drives the hint ring while a hint is showing. A late board is a hundred
  /// arrows in one ink, and the eye does not find a static smudge among them
  /// — it finds movement.
  AnimationController? _hintPing;

  /// The arrow currently bumping, if any, and how it moves.
  int? _bumpId;
  BumpMotion? _bumpMotion;
  AnimationController? _bump;

  @override
  void initState() {
    super.initState();
    _syncHintPing();
    _syncSlump();
  }

  @override
  void didUpdateWidget(PuzzleBoard old) {
    super.didUpdateWidget(old);
    _syncHintPing();
    _syncSlump();
    final s = widget.state;
    if (s.puzzle != old.state.puzzle || s.moveToken < old.state.moveToken) {
      // A restart: forget every animation.
      _disposeAll();
      return;
    }
    if (s.moveToken == old.state.moveToken || s.lastMoveId == null) return;
    final id = s.lastMoveId!;
    switch (s.lastOutcome) {
      case MoveOutcome.exited:
        _startExit(id);
      case MoveOutcome.blocked:
        _startBump(id);
      case MoveOutcome.none:
        break;
    }
  }

  void _startExit(int id) {
    final puzzle = widget.state.puzzle!;
    final arrow = puzzle.arrows[id];
    final travel = arrow.length + arrow.exitRay(puzzle.width, puzzle.height).length;
    // Quick but still readable as a slide: a short arrow at the edge is gone
    // in about a quarter second; a long crossing of a big board never drags.
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (140 + travel * 30).clamp(240, 600)),
    );
    _exits[id]?.dispose();
    _exits[id] = controller;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        _exits.remove(id)?.dispose();
      });
    });
  }

  void _startBump(int id) {
    _bump?.dispose();
    final puzzle = widget.state.puzzle!;
    final motion = BumpMotion.forTap(puzzle, id, widget.state.blockedCell!);
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
    });
  }

  /// Starts the slump on a losing ending, and clears it on the way out of
  /// one (a restart, or carrying on past a spent allowance).
  void _syncSlump() {
    final losing =
        widget.state.phase == GamePhase.outOfLives || widget.state.phase == GamePhase.timeUp;
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

  /// Runs the ping while a hint points somewhere, and stops it otherwise.
  void _syncHintPing() {
    final showing = widget.state.hintArrowId != null;
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
  /// whole screen sideways for two thirds of a second, and a slide is in
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
    final slop = min(kTouchSlopPx, cellSize * 1.5);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          constraints.maxWidth / puzzle.width,
          constraints.maxHeight / puzzle.height,
        );
        final size = Size(cellSize * puzzle.width, cellSize * puzzle.height);
        return Center(
          child: Semantics(
            label: 'Puzzle board ${puzzle.width} by ${puzzle.height}',
            child: Listener(
              onPointerDown: (_) => _onPointerDown(),
              onPointerUp: (_) => _onPointerUp(),
              onPointerCancel: (_) => _onPointerUp(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
  });

  final GameState state;
  final ArrowPalette palette;
  final bool showGrid;

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

    // The bump: the tapped arrow runs into the arrow in its way, which takes
    // the hit — its cell flashes and it is shoved a touch — then springs back.
    final blocked = state.blockedCell;
    final bumpT = bump;
    final motion = bumpMotion;
    final bumping =
        blocked != null && bumpT != null && motion != null && bumpId == state.lastMoveId;
    final flash = bumping ? motion.flashAt(bumpT) : 0.0;
    final shove = bumping ? motion.shoveAt(bumpT) : 0.0;
    final hitId = bumping ? puzzle.arrowAt(blocked) : null;
    if (bumping && flash > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(blocked.x * cs, blocked.y * cs, cs, cs).deflate(cs * 0.08),
          Radius.circular(cs * 0.2),
        ),
        Paint()..color = palette.blockedFlash.withValues(alpha: palette.blockedFlash.a * flash),
      );
    }

    canvas.save();
    canvas.clipRect(rect);
    for (final arrow in puzzle.arrows) {
      final exiting = exits[arrow.id];
      if (state.removed.contains(arrow.id) && exiting == null) continue;
      final travel = arrow.length + arrow.exitRay(puzzle.width, puzzle.height).length;
      var offset = 0.0;
      if (exiting != null) {
        offset = Curves.easeIn.transform(exiting) * travel;
      } else if (bumping && bumpId == arrow.id) {
        offset = motion.offsetAt(bumpT);
      }
      final shoved = bumping && arrow.id == hitId && shove > 0;
      if (shoved) {
        final push = _unit(puzzle.arrows[bumpId!].heading) * (shove * kShoveDistance * cs);
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
      _paintArrow(canvas, arrow, cs, offset, false);
      if (slumping) canvas.restore();
      if (shoved) canvas.restore();
    }
    _paintHint(canvas, size, cs);
    canvas.restore();
  }

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
    _paintArrow(canvas, arrow, cs, 0, true);

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

  /// Draws [arrow] shifted [offset] cells forward along its own track (its
  /// cells, then its exit ray, then straight on past the edge).
  void _paintArrow(Canvas canvas, ArrowPiece arrow, double cs, double offset, bool hinted) {
    final track = <Cell>[...arrow.cells, ...arrow.exitRay(puzzle.width, puzzle.height)];
    // Extend past the edge so sampling never runs out.
    var beyond = track.last;
    for (var i = 0; i < arrow.length + 2; i++) {
      beyond = beyond.step(arrow.heading);
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
    final points = <Offset>[for (var i = 0; i < arrow.length; i++) at(offset + i)];
    final headAt = offset + arrow.length - 1;
    final head = at(headAt);
    // The head's travel direction: where the track goes next.
    final ahead = at(headAt + 0.5);
    var dir = ahead - head;
    if (dir.distance < 0.001) dir = _unit(arrow.heading);
    dir = dir / dir.distance;

    // Body ends a bit short of the head so the triangle caps it cleanly.
    final headLen = min(cs * 0.3, 8.0);
    final bodyEnd = head - dir * (headLen * 0.55);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length > 1) {
      path.lineTo(bodyEnd.dx, bodyEnd.dy);
    }

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
      old.hintPing != hintPing ||
      old.slump != slump ||
      old.state.blockedCell != state.blockedCell ||
      old.state.moveToken != state.moveToken ||
      old.showGrid != showGrid ||
      old.palette != palette ||
      !_sameMap(old.exits, exits) ||
      old.bumpId != bumpId ||
      old.bump != bump;

  static bool _sameMap(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
