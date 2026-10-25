import 'package:flutter/material.dart';

import '../engine/cube.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';

/// The block's controls on a cube level: a small picture of the block as it
/// stands — the face towards the player, the one on top and the one on the
/// right, each filled in the mint once it is clear — with how many faces
/// are clear and how many arrows are left on the one in front, and a button
/// either side for each way the block turns. A swipe across the picture
/// turns it too, the way the finger goes.
class CubeControls extends StatelessWidget {
  const CubeControls({
    super.key,
    required this.view,
    required this.faceLeft,
    required this.onTurn,
    this.enabled = true,
  });

  final CubeView view;

  /// Arrows still on each face, by face number.
  final List<int> faceLeft;

  final ValueChanged<CubeTurn> onTurn;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final cleared = faceLeft.where((n) => n == 0).length;
    Widget button(CubeTurn turn, IconData icon, String tooltip) => IconButton(
          tooltip: tooltip,
          onPressed: enabled ? () => onTurn(turn) : null,
          icon: Icon(icon),
        );
    return Row(
      children: [
        button(CubeTurn.left, Icons.chevron_left_rounded, l10n.cubeTurnLeft),
        button(CubeTurn.up, Icons.expand_less_rounded, l10n.cubeTurnUp),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A swipe pulls the block round the way the finger goes: a
            // swipe to the left brings the face on the right to the front.
            onPanEnd: !enabled
                ? null
                : (d) {
                    final v = d.velocity.pixelsPerSecond;
                    if (v.distance < 120) return;
                    if (v.dx.abs() > v.dy.abs()) {
                      onTurn(v.dx < 0 ? CubeTurn.right : CubeTurn.left);
                    } else {
                      onTurn(v.dy < 0 ? CubeTurn.down : CubeTurn.up);
                    }
                  },
            child: Semantics(
              label: l10n.cubeMapLabel(view.front + 1, cleared, faceLeft.length),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 40,
                    child: CustomPaint(
                      painter: _BlockPainter(
                        front: faceLeft[view.front] == 0,
                        top: faceLeft[view.up] == 0,
                        right: faceLeft[view.right] == 0,
                        palette: p,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.cubeFacesClear(cleared, faceLeft.length),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textInk),
                        ),
                        Text(
                          l10n.cubeFaceArrows(faceLeft[view.front]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        button(CubeTurn.down, Icons.expand_more_rounded, l10n.cubeTurnDown),
        button(CubeTurn.right, Icons.chevron_right_rounded, l10n.cubeTurnRight),
      ],
    );
  }
}

/// The block in a corner view: the front face lower left, the right face
/// lower right and the top above them, each a rhombus of the hexagon.
/// A clear face is filled in the mint; the front is rimmed in the primary.
class _BlockPainter extends CustomPainter {
  _BlockPainter({required this.front, required this.top, required this.right, required this.palette});

  final bool front;
  final bool top;
  final bool right;
  final ArrowPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final topV = Offset(w / 2, 0);
    final upL = Offset(0, h * 0.25);
    final upR = Offset(w, h * 0.25);
    final lowL = Offset(0, h * 0.75);
    final lowR = Offset(w, h * 0.75);
    final bottom = Offset(w / 2, h);
    Path quad(Offset a, Offset b, Offset c2, Offset d) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
    final faces = <(Path, bool, double)>[
      (quad(topV, upR, c, upL), top, 0.0),
      (quad(upL, c, bottom, lowL), front, 0.12),
      (quad(c, upR, lowR, bottom), right, 0.3),
    ];
    final edge = Paint()
      ..color = palette.cubeEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    for (final (path, clear, dark) in faces) {
      final fill = clear ? palette.accentMint : palette.cubeFace;
      canvas.drawPath(path, Paint()..color = Color.lerp(fill, palette.cubeEdge, dark)!);
      canvas.drawPath(path, edge);
    }
    canvas.drawPath(
      faces[1].$1,
      Paint()
        ..color = palette.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BlockPainter old) =>
      old.front != front || old.top != top || old.right != right || old.palette != palette;
}
