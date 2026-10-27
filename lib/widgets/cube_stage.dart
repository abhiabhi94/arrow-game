import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/cube.dart';
import '../ui/colors.dart';
import 'puzzle_board.dart';

/// How long the block takes to come round to a face.
const Duration kCubeTurn = Duration(milliseconds: 520);

/// How much of the stage the block's outline takes at zoom 1, leaning the
/// way a level opens — whichever face is in front, so the block keeps one
/// size as it turns. The first cut sized a cube's edge at 0.6 of the
/// stage's shorter side, which left the block small in the middle of a
/// tall phone screen; now the block is fitted to the stage both ways, so a
/// tall box stands as tall as the stage allows.
const double kCubeFill = 0.94;

/// How far the block can be zoomed: about until the face in front fills
/// the stage's width.
const double kCubeMaxZoom = 1.5;

/// The gap between a face's edge and its board, in logical pixels.
const double kFacePadding = 6;

/// How fast a drag turns the block, in radians a logical pixel.
const double kDragTurn = 0.011;

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
/// cube, lit from above left so every face has its own shade, over a soft
/// pool of light with its shadow on the floor. A level opens with the block
/// leaning a little so the top and a side show beside [face]
/// ([openingPose]).
///
/// A finger turns it freely, and **it stays where the finger leaves it**:
/// no settling back to a pose the player did not choose. The face then
/// most towards the player is the one being played, and [onFaceChanged]
/// says so. A tap on the face being played plays the arrow under it (the
/// stage works out which cell from the block's geometry and hands the tap
/// to that face's board); a tap on another face that shows turns the block
/// round to it. Two fingers zoom ([onZoom]). When [face] changes from
/// outside — a button, a key, a hint, a cleared face — the block turns to
/// show that face the way the player left the last one: the same lean,
/// whether the opening one or their own ([leanOf]). With
/// [reduceMotion] such a turn is a jump; with [interactive] off (the
/// chapter card) the block only turns when told.
class CubeStage extends StatefulWidget {
  const CubeStage({
    super.key,
    required this.face,
    required this.faceBuilder,
    this.box = const (1, 1, 1),
    this.onFaceChanged,
    this.onZoom,
    this.zoom = 1,
    this.reduceMotion = false,
    this.interactive = true,
  });

  final int face;
  final CubeFaceBuilder faceBuilder;

  /// The block's width, height and depth in cells: all one on a cube, a
  /// box otherwise. A cell is the same size on every face.
  final (int, int, int) box;
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
  late Quat _orientation = openingPose(widget.face);

  /// How the block leans away from the face being played squared up — the
  /// opening lean until a finger turns it, then whatever the finger left.
  /// A turn to another face from outside keeps it ([leanOf]), so the block
  /// never swings back to a pose the player did not choose.
  Quat _lean = kOpeningLean;
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
  CubeCamera get camera {
    final u = _unit();
    final (x, y, z) = widget.box;
    return CubeCamera(
      orientation: _orientation,
      box: (x * u, y * u, z * u),
      zoom: widget.zoom,
    );
  }

  (Size, (int, int, int))? _unitFor;
  double _unitCache = 0;

  /// The length of a cell on screen at zoom 1: as big as lets the block,
  /// leaning the way a level opens with any face in front, fill
  /// [kCubeFill] of the stage both ways.
  double _unit() {
    if (_unitFor == (_size, widget.box)) return _unitCache;
    final (x, y, z) = widget.box;
    var w = 0.0, h = 0.0;
    for (var f = 0; f < 6; f++) {
      final b = CubeCamera(
        orientation: openingPose(f),
        box: (x.toDouble(), y.toDouble(), z.toDouble()),
      ).bounds;
      w = max(w, 2 * max(-b.left, b.right));
      h = max(h, 2 * max(-b.top, b.bottom));
    }
    _unitFor = (_size, widget.box);
    _unitCache = w <= 0 || h <= 0 ? 0 : min(_size.width / w, _size.height / h) * kCubeFill;
    return _unitCache;
  }

  /// Whether the block is still or moving (a finger on it, or a turn).
  bool get settled => !_dragging && !_turn.isAnimating;

  @override
  void didUpdateWidget(CubeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A face the block already shows in front (the one a drag left there)
    // needs no turn.
    if (widget.face != oldWidget.face &&
        (camera.nearestFace != widget.face || _turn.isAnimating)) {
      _turnTo(widget.face);
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _turnTo(int face) {
    final target = (_lean * faceOn(face)).normalized;
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

  /// Let go: the block stays exactly where the finger left it — no
  /// settling back to a pose the player did not choose — and the face now
  /// most towards the player is the one being played.
  void _onScaleEnd(ScaleEndDetails d) {
    setState(() => _dragging = false);
    final face = camera.nearestFace;
    _lean = leanOf(_orientation, face);
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
        final side = cam.longest;
        if (side <= 0) return const SizedBox.shrink();
        const light = _light;
        final faces = <Widget>[
          for (final f in cam.visibleFaces)
            Positioned(
              left: _size.width / 2 - cam.faceSize(f).$1 / 2,
              top: _size.height / 2 - cam.faceSize(f).$2 / 2,
              width: cam.faceSize(f).$1,
              height: cam.faceSize(f).$2,
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
                painter: _StagePainter(
                  width: max(cam.size.$1, cam.size.$3) * widget.zoom,
                  height: cam.size.$2 * widget.zoom,
                  palette: p,
                ),
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
  _StagePainter({required this.width, required this.height, required this.palette});

  /// The block's breadth (its wider of width and depth) and its height.
  final double width;
  final double height;
  final ArrowPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final pool = Rect.fromCircle(center: c, radius: max(width, height) * 1.25);
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
      center: c + Offset(0, height / 2 + width * 0.3),
      width: width * 1.9,
      height: width * 0.42,
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
      old.width != width || old.height != height || old.palette != palette;
}
