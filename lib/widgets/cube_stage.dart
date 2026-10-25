import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/cube.dart';
import '../ui/colors.dart';
import 'puzzle_board.dart';

/// How long the block takes to come round to a face.
const Duration kCubeTurn = Duration(milliseconds: 520);

/// How much of the stage's shorter side the block's edge takes at zoom 1:
/// room for the block leaning, and turning through a corner, without
/// leaving the stage.
const double kCubeFill = 0.6;

/// How far the block can be zoomed: until the face in front fills the
/// stage's width.
const double kCubeMaxZoom = 1 / kCubeFill;

/// The gap between a face's edge and its board, in logical pixels.
const double kFacePadding = 6;

/// How fast a drag turns the block, in radians a logical pixel.
const double kDragTurn = 0.011;

/// A flick faster than this, in logical pixels a second, turns the block on
/// to the next face that way rather than settling on the nearest.
const double kFlickSpeed = 500;

/// Builds the board on [face]. [boardKey] goes on its [PuzzleBoard] so the
/// stage can hand it the taps that land on it; [front] says whether it is
/// the face being played.
typedef CubeFaceBuilder =
    Widget Function(
      BuildContext context,
      int face,
      GlobalKey<PuzzleBoardState> boardKey,
      bool front,
    );

/// The block on a cube level, whole and in 3D: six faces of arrows on a
/// cube that leans a little so the top and a side show beside the face
/// being played ([face]), lit from above left so every face has its own
/// shade, over a soft pool of light with its shadow on the floor.
///
/// A finger turns it freely; let go and it settles, square, on the face
/// most towards the player — or, flicked, on the next face that way — and
/// [onFaceChanged] says so. A tap on the face being played plays the arrow
/// under it (the stage works out which cell from the block's geometry and
/// hands the tap to that face's board); a tap on another face that shows
/// turns the block round to it. Two fingers zoom ([onZoom]). When [face]
/// changes from outside — a button, a key, a hint, a cleared face — the
/// block turns round to it on its own. With [reduceMotion] it is simply
/// there; with [interactive] off (the chapter card) it only turns when told.
class CubeStage extends StatefulWidget {
  const CubeStage({
    super.key,
    required this.face,
    required this.faceBuilder,
    this.onFaceChanged,
    this.onZoom,
    this.zoom = 1,
    this.reduceMotion = false,
    this.interactive = true,
  });

  final int face;
  final CubeFaceBuilder faceBuilder;
  final ValueChanged<int>? onFaceChanged;
  final ValueChanged<double>? onZoom;
  final double zoom;
  final bool reduceMotion;
  final bool interactive;

  @override
  State<CubeStage> createState() => CubeStageState();
}

class CubeStageState extends State<CubeStage>
    with SingleTickerProviderStateMixin {
  late Quat _orientation = faceOn(widget.face);
  Quat _from = Quat.identity;
  Quat _to = Quat.identity;
  late final AnimationController _turn =
      AnimationController(vsync: this, duration: kCubeTurn)..addListener(
        () => setState(
          () => _orientation = _from.slerp(
            _to,
            Curves.easeOutCubic.transform(_turn.value),
          ),
        ),
      );

  final Map<int, GlobalKey<PuzzleBoardState>> _boards =
      <int, GlobalKey<PuzzleBoardState>>{};

  /// The stage's size at the last layout, for the camera.
  Size _size = Size.zero;

  bool _dragging = false;
  double _zoomAtStart = 1;

  /// The block as it stands now, as seen on this stage.
  CubeCamera get camera => CubeCamera(
    orientation: _orientation,
    side: min(_size.width, _size.height) * kCubeFill,
    zoom: widget.zoom,
  );

  /// Whether the block is still or moving (a finger on it, or a turn).
  bool get settled => !_dragging && !_turn.isAnimating;

  @override
  void didUpdateWidget(CubeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.face != oldWidget.face) _turnTo(widget.face);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _turnTo(int face) {
    final target = faceOn(face);
    if (widget.reduceMotion) {
      _turn.stop();
      setState(() => _orientation = target);
      return;
    }
    _from = _orientation;
    _to = target;
    _turn.forward(from: 0);
  }

  void _onScaleStart(ScaleStartDetails d) {
    _turn.stop();
    _zoomAtStart = widget.zoom;
    _dragging = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount > 1) {
      widget.onZoom?.call(_zoomAtStart * d.scale);
      return;
    }
    final delta = d.focalPointDelta;
    if (delta == Offset.zero) return;
    // Drag right and the front swings right; drag down and it tips down.
    setState(() {
      _orientation =
          (Quat.axisAngle((0, 1, 0), delta.dx * kDragTurn) *
                  Quat.axisAngle((1, 0, 0), delta.dy * kDragTurn) *
                  _orientation)
              .normalized;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond;
    var face = camera.nearestFace;
    if (d.pointerCount == 0 &&
        v.distance > kFlickSpeed &&
        face == widget.face) {
      // A flick: on to the next face the way the finger went — a flick to
      // the left brings the face on the right round.
      final turn = v.dx.abs() > v.dy.abs()
          ? (v.dx < 0 ? CubeTurn.right : CubeTurn.left)
          : (v.dy < 0 ? CubeTurn.down : CubeTurn.up);
      face = cubeNeighbour(widget.face, turn);
    }
    _turnTo(face);
    if (face != widget.face) widget.onFaceChanged?.call(face);
  }

  void _onTapUp(TapUpDetails d) {
    if (!settled) return;
    final c = Offset(_size.width / 2, _size.height / 2);
    final p = d.localPosition - c;
    final hit = camera.hit(p.dx, p.dy);
    if (hit == null) return;
    if (hit.face != widget.face) {
      // Another face that shows: bring it round.
      _turnTo(hit.face);
      widget.onFaceChanged?.call(hit.face);
      return;
    }
    _boards[hit.face]?.currentState?.tapAtBox(
      Offset(hit.u - kFacePadding, hit.v - kFacePadding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final cam = camera;
        final side = cam.side;
        if (side <= 0) return const SizedBox.shrink();
        const light = _light;
        final faces = <Widget>[
          for (final f in cam.visibleFaces)
            Positioned(
              left: _size.width / 2 - side / 2,
              top: _size.height / 2 - side / 2,
              width: side,
              height: side,
              // The faces draw nothing a finger can press: the stage works
              // out from the geometry what a tap meant.
              child: IgnorePointer(
                child: Transform(
                  key: ValueKey<int>(f),
                  alignment: Alignment.center,
                  transform: Matrix4.fromList(cam.faceMatrix(f)),
                  child: _Face(
                    // The face being played keeps its full light: its
                    // arrows are the ones being read.
                    shade: f == widget.face
                        ? 0
                        : (1 - max(0.0, dot(cam.toView(faceNormal(f)), light)))
                                .clamp(0.0, 1.0) *
                            0.55,
                    front: f == widget.face,
                    child: f == widget.face
                        ? widget.faceBuilder(
                            context,
                            f,
                            _boards.putIfAbsent(
                              f,
                              GlobalKey<PuzzleBoardState>.new,
                            ),
                            true,
                          )
                        : ExcludeSemantics(
                            child: widget.faceBuilder(
                              context,
                              f,
                              _boards.putIfAbsent(
                                f,
                                GlobalKey<PuzzleBoardState>.new,
                              ),
                              false,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ];
        final stage = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StagePainter(side: side * widget.zoom, palette: p),
              ),
            ),
            ...faces,
          ],
        );
        if (!widget.interactive) return stage;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          onTapUp: _onTapUp,
          child: stage,
        );
      },
    );
  }

  /// The light, from above, a little left and in front.
  static const Vec3 _light = (-0.35, 0.75, 0.56);
}

/// A face of the block: a square of [ArrowPalette.cubeFace] edged in the
/// block's own shade, darkened by [shade] (0..1) as it turns from the
/// light. The face being played wears a primary rim.
class _Face extends StatelessWidget {
  const _Face({required this.child, required this.shade, required this.front});

  final Widget child;
  final double shade;
  final bool front;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        color: shade > 0 ? p.cubeEdge.withValues(alpha: shade) : null,
        border: front
            ? Border.all(color: p.primary.withValues(alpha: 0.55), width: 2.5)
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.cubeFace,
          border: Border.all(color: p.cubeEdge, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kFacePadding),
          child: child,
        ),
      ),
    );
  }
}

/// The stage under the block: a soft pool of light behind it and its
/// shadow on the floor below.
class _StagePainter extends CustomPainter {
  _StagePainter({required this.side, required this.palette});

  final double side;
  final ArrowPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final pool = Rect.fromCircle(center: c, radius: side * 1.25);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.cubeFace.withValues(alpha: 0.9),
            palette.cubeFace.withValues(alpha: 0),
          ],
        ).createShader(pool),
    );
    final floor = Rect.fromCenter(
      center: c + Offset(0, side * 0.8),
      width: side * 1.9,
      height: side * 0.42,
    );
    canvas.drawOval(
      floor,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.arrowInk.withValues(alpha: 0.22),
            palette.arrowInk.withValues(alpha: 0),
          ],
        ).createShader(floor),
    );
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.side != side || old.palette != palette;
}
