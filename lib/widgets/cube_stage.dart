import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/cube.dart';
import '../ui/colors.dart';

/// How long the block takes to turn a quarter.
const Duration kCubeTurn = Duration(milliseconds: 460);

/// How much of the block's sides shows beside and below the face at rest,
/// in logical pixels.
const double kCubeDepth = 10;

/// The block on a cube level: one face towards the player, drawn as a
/// square card a step off the page with the block's edge round it, and —
/// when [view] changes — a real quarter turn of a cube, the face going
/// away round the side as the next one comes round to the front, each
/// darkening as it turns from the light. The faces are built by
/// [faceBuilder]; nothing on either can be tapped while the block turns.
/// With [reduceMotion] the new face is simply there.
class CubeStage extends StatefulWidget {
  const CubeStage({
    super.key,
    required this.view,
    required this.faceBuilder,
    this.lastTurn,
    this.reduceMotion = false,
  });

  /// How the block stands: [CubeView.front] is the face shown.
  final CubeView view;

  /// The turn that brought [view] about, which sets the way the block
  /// spins; null (a jump, or the start) shows the face without a turn.
  final CubeTurn? lastTurn;

  final Widget Function(BuildContext context, int face) faceBuilder;
  final bool reduceMotion;

  @override
  State<CubeStage> createState() => _CubeStageState();
}

class _CubeStageState extends State<CubeStage> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: kCubeTurn)
    ..addListener(() => setState(() {}))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _from = null);
    });

  /// The face going away while the block turns, and which way it turns.
  int? _from;
  CubeTurn? _spin;

  @override
  void didUpdateWidget(CubeStage old) {
    super.didUpdateWidget(old);
    if (widget.view.front == old.view.front) return;
    final turn = widget.lastTurn;
    if (turn == null || widget.reduceMotion) {
      _turn.stop();
      _from = null;
      return;
    }
    _from = old.view.front;
    _spin = turn;
    _turn.forward(from: 0);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The block stands a little proud of the page: its right side and
        // its underside show below and beside the face, [kCubeDepth] deep.
        final side = min(constraints.maxWidth, constraints.maxHeight) - kCubeDepth;
        Widget face(int f, {double shade = 0}) => SizedBox.square(
              key: ValueKey<int>(f),
              dimension: side,
              child: _Face(shade: shade, child: widget.faceBuilder(context, f)),
            );
        final from = _from;
        if (from == null) {
          return Center(
            child: CustomPaint(
              painter: _BlockSides(palette: context.palette),
              child: Padding(
                padding: const EdgeInsets.only(right: kCubeDepth, bottom: kCubeDepth),
                child: face(widget.view.front),
              ),
            ),
          );
        }
        final t = Curves.easeInOut.transform(_turn.value);
        // A quarter turn about the cube's own centre, half a side behind
        // the face: the face going away turns through t·90°, the one coming
        // round from 90° to none.
        final out = _spin!;
        final angle = t * pi / 2;
        // Turned to the corner, the block is a diagonal wide: it draws back
        // a little as it turns so the corner never leaves the screen.
        final fit = 1 / (sin(angle) + cos(angle));
        return IgnorePointer(
          child: Center(
            child: Container(
              transform: Matrix4.diagonal3Values(fit, fit, 1),
              transformAlignment: Alignment.center,
              width: side,
              height: side,
              margin: const EdgeInsets.only(right: kCubeDepth, bottom: kCubeDepth),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Whichever is further turned goes underneath.
                  if (t < 0.5) ...[
                    _turned(face(widget.view.front, shade: cos(angle)), out, angle - pi / 2, side),
                    _turned(face(from, shade: sin(angle)), out, angle, side),
                  ] else ...[
                    _turned(face(from, shade: sin(angle)), out, angle, side),
                    _turned(face(widget.view.front, shade: cos(angle)), out, angle - pi / 2, side),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// [child] (a face the size of [side]) turned [angle] round the block's
  /// centre in the sense of [turn]: towards the face on the right sends
  /// the front face off to the left, and so on.
  static Widget _turned(Widget child, CubeTurn turn, double angle, double side) {
    final half = side / 2;
    final m = Matrix4.identity()..setEntry(3, 2, 1 / (side * 2.6));
    m.translateByDouble(0, 0, half, 1);
    switch (turn) {
      case CubeTurn.right:
        m.rotateY(angle);
      case CubeTurn.left:
        m.rotateY(-angle);
      case CubeTurn.up:
        m.rotateX(-angle);
      case CubeTurn.down:
        m.rotateX(angle);
    }
    m.translateByDouble(0, 0, -half, 1);
    return Transform(transform: m, alignment: Alignment.center, child: child);
  }
}

/// The block's right side and underside, drawn behind the face at rest as
/// two slanted bands [kCubeDepth] deep, the underside the darker — enough
/// to read the card as the near face of a solid.
class _BlockSides extends CustomPainter {
  _BlockSides({required this.palette});

  final ArrowPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const d = kCubeDepth;
    const r = 14.0;
    final w = size.width - d;
    final h = size.height - d;
    final right = Path()
      ..moveTo(w - r / 2, r / 2)
      ..lineTo(w + d, d + r / 2)
      ..lineTo(w + d, h + d - r / 2)
      ..lineTo(w - r / 2, h)
      ..close();
    final under = Path()
      ..moveTo(r / 2, h - r / 2)
      ..lineTo(w, h - r / 2)
      ..lineTo(w + d - r / 2, h + d)
      ..lineTo(d + r / 2, h + d)
      ..close();
    canvas.drawPath(right, Paint()..color = palette.cubeEdge);
    canvas.drawPath(under, Paint()..color = Color.lerp(palette.cubeEdge, palette.arrowInk, 0.18)!);
  }

  @override
  bool shouldRepaint(_BlockSides old) => old.palette != palette;
}

/// A face of the block: a square card in [ArrowPalette.cubeFace] with the
/// block's edge round it, darkened by [shade] (0..1) as it turns away.
class _Face extends StatelessWidget {
  const _Face({required this.child, this.shade = 0});

  final Widget child;
  final double shade;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(14);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: shade > 0 ? p.cubeEdge.withValues(alpha: 0.85 * shade.clamp(0.0, 1.0)) : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.cubeFace,
          borderRadius: radius,
          border: Border.all(color: p.cubeEdge, width: 2),
        ),
        child: Padding(padding: const EdgeInsets.all(6), child: child),
      ),
    );
  }
}
