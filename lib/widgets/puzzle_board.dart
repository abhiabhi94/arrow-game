import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../models/game_state.dart';
import '../ui/colors.dart';

/// How far a blocked arrow nudges forward before bouncing back, in cells.
const double kBumpDistance = 0.3;

/// The board: draws every arrow still on the board (plus any arrow mid-slide
/// on its way out) in a single ink — thin lines with a small head, like a
/// printed puzzle — plus optional grid lines, the hint glow and the
/// blocked-cell flash, and turns taps into [onTapArrow] calls. Requires a
/// loaded [GameState.puzzle].
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

  /// The arrow currently bumping, if any.
  int? _bumpId;
  AnimationController? _bump;

  @override
  void didUpdateWidget(PuzzleBoard old) {
    super.didUpdateWidget(old);
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
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (140 + travel * 55).clamp(300, 900)),
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
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _bumpId = id;
    _bump = controller;
    controller.addListener(() => setState(() {}));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        if (_bump == controller) {
          _bump = null;
          _bumpId = null;
        }
        controller.dispose();
      });
    });
  }

  void _disposeAll() {
    for (final c in _exits.values) {
      c.dispose();
    }
    _exits.clear();
    _bump?.dispose();
    _bump = null;
    _bumpId = null;
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _onTapUp(TapUpDetails d, double cellSize) {
    final puzzle = widget.state.puzzle!;
    final x = (d.localPosition.dx / cellSize).floor();
    final y = (d.localPosition.dy / cellSize).floor();
    final cell = Cell(x, y);
    if (!cell.isInside(puzzle.width, puzzle.height)) return;
    final id = puzzle.arrowAt(cell);
    if (id == null || widget.state.removed.contains(id)) return;
    widget.onTapArrow(id);
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTapUp(d, cellSize),
              child: CustomPaint(
                size: size,
                painter: _BoardPainter(
                  state: widget.state,
                  palette: p,
                  showGrid: widget.showGrid,
                  exits: <int, double>{
                    for (final e in _exits.entries) e.key: e.value.value,
                  },
                  bumpId: _bumpId,
                  bump: _bump?.value,
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
    required this.bumpId,
    required this.bump,
  });

  final GameState state;
  final ArrowPalette palette;
  final bool showGrid;

  /// Slide-out progress (0..1) per exiting arrow.
  final Map<int, double> exits;
  final int? bumpId;
  final double? bump;

  Puzzle get puzzle => state.puzzle!;

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / puzzle.width;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cs * 0.35));
    canvas.drawRRect(rrect, Paint()..color = palette.boardSurface);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = palette.boardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (showGrid) {
      final grid = Paint()
        ..color = palette.gridLine
        ..strokeWidth = 1;
      for (var x = 1; x < puzzle.width; x++) {
        canvas.drawLine(Offset(x * cs, 0), Offset(x * cs, size.height), grid);
      }
      for (var y = 1; y < puzzle.height; y++) {
        canvas.drawLine(Offset(0, y * cs), Offset(size.width, y * cs), grid);
      }
    }

    // The blocked cell flashes while the bump plays.
    final blocked = state.blockedCell;
    final bumpT = bump;
    if (blocked != null && bumpT != null && bumpId == state.lastMoveId) {
      final alpha = sin(bumpT * pi).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(blocked.x * cs, blocked.y * cs, cs, cs).deflate(cs * 0.08),
          Radius.circular(cs * 0.2),
        ),
        Paint()..color = palette.blockedFlash.withValues(alpha: palette.blockedFlash.a * alpha),
      );
    }

    canvas.save();
    canvas.clipRRect(rrect);
    for (final arrow in puzzle.arrows) {
      final exiting = exits[arrow.id];
      if (state.removed.contains(arrow.id) && exiting == null) continue;
      final travel = arrow.length + arrow.exitRay(puzzle.width, puzzle.height).length;
      var offset = 0.0;
      if (exiting != null) {
        offset = Curves.easeIn.transform(exiting) * travel;
      } else if (bumpId == arrow.id && bumpT != null) {
        offset = sin(bumpT * pi) * kBumpDistance;
      }
      _paintArrow(canvas, arrow, cs, offset, arrow.id == state.hintArrowId && exiting == null);
    }
    canvas.restore();
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
    final stroke = min(cs * 0.2, 9.0);
    final points = <Offset>[for (var i = 0; i < arrow.length; i++) at(offset + i)];
    final headAt = offset + arrow.length - 1;
    final head = at(headAt);
    // The head's travel direction: where the track goes next.
    final ahead = at(headAt + 0.5);
    var dir = ahead - head;
    if (dir.distance < 0.001) dir = _unit(arrow.heading);
    dir = dir / dir.distance;

    // Body ends a bit short of the head so the triangle caps it cleanly.
    final headLen = min(cs * 0.36, 18.0);
    final bodyEnd = head - dir * (headLen * 0.55);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length > 1) {
      path.lineTo(bodyEnd.dx, bodyEnd.dy);
    }

    if (hinted) {
      final glow = Paint()
        ..color = palette.hintGlow
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, glow);
      canvas.drawCircle(head, headLen * 1.1, Paint()..color = palette.hintGlow);
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

