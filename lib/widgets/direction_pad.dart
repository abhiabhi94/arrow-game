import 'package:flutter/material.dart';

import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import '../utils/labels.dart';

/// Four big round direction keys in a plus layout — the tap alternative to
/// swiping the arena. Each key is a labelled button so screen readers and the
/// screenshot driver can find it.
class DirectionPad extends StatelessWidget {
  const DirectionPad({
    super.key,
    required this.onDirection,
    this.enabled = true,
    this.keySize = 68,
  });

  final ValueChanged<Direction> onDirection;
  final bool enabled;
  final double keySize;

  @override
  Widget build(BuildContext context) {
    final gap = keySize * 0.18;
    final total = keySize * 3 + gap * 2;
    Widget key(Direction d) => _PadKey(
          direction: d,
          size: keySize,
          enabled: enabled,
          onTap: () => onDirection(d),
        );
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: key(Direction.up)),
          Align(alignment: Alignment.centerLeft, child: key(Direction.left)),
          Align(alignment: Alignment.centerRight, child: key(Direction.right)),
          Align(alignment: Alignment.bottomCenter, child: key(Direction.down)),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.direction,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final Direction direction;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: directionLabel(l10n, direction),
      button: true,
      enabled: enabled,
      child: Material(
        color: p.surface,
        shape: CircleBorder(side: BorderSide(color: p.outlineSoft)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: RotatedBox(
              quarterTurns: direction.quarterTurns,
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: size * 0.6,
                color: enabled ? p.textInk : p.textFaint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
