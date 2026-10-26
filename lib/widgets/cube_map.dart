import 'package:flutter/material.dart';

import '../engine/cube.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import 'keycap.dart';

/// The block's controls on a cube level, over the block itself: how many
/// faces are clear and how many arrows are left on the one being played,
/// between a pair of keys either side for each way the block turns. A
/// finger on the block turns it too; the keys are the way to the next face
/// for a screen reader, a keyboard or a hand that would rather press.
class CubeControls extends StatelessWidget {
  const CubeControls({
    super.key,
    required this.face,
    required this.faceLeft,
    required this.onTurn,
    this.enabled = true,
  });

  /// The face being played.
  final int face;

  /// Arrows still on each face, by face number.
  final List<int> faceLeft;

  final ValueChanged<CubeTurn> onTurn;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final cleared = faceLeft.where((n) => n == 0).length;
    Widget key(CubeTurn turn, IconData icon, String tooltip) => Semantics(
          label: tooltip,
          button: true,
          enabled: enabled,
          excludeSemantics: true,
          child: Tooltip(
            message: tooltip,
            child: Keycap(
              width: 48,
              height: 44,
              radius: 14,
              color: p.surface,
              borderColor: p.outlineSoft,
              onPressed: enabled ? () => onTurn(turn) : null,
              child: Icon(icon, color: enabled ? p.textInk : p.textFaint),
            ),
          ),
        );
    return Row(
      children: [
        key(CubeTurn.left, Icons.chevron_left_rounded, l10n.cubeTurnLeft),
        const SizedBox(width: 6),
        key(CubeTurn.up, Icons.expand_less_rounded, l10n.cubeTurnUp),
        Expanded(
          child: Semantics(
            label: l10n.cubeMapLabel(face + 1, cleared, faceLeft.length),
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cubeFacesClear(cleared, faceLeft.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.textInk),
                ),
                Text(
                  l10n.cubeFaceArrows(faceLeft[face]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
        key(CubeTurn.down, Icons.expand_more_rounded, l10n.cubeTurnDown),
        const SizedBox(width: 6),
        key(CubeTurn.right, Icons.chevron_right_rounded, l10n.cubeTurnRight),
      ],
    );
  }
}
