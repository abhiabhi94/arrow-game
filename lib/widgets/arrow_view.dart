import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../engine/arrow.dart';
import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import '../utils/labels.dart';

/// The arrow prompt: a big round tile whose colour says what kind of arrow it
/// is, a glyph rotated to its direction, an optional fuse ring around it, an
/// optional decoy word under it, and a "gone" state for ghosts.
class ArrowView extends StatelessWidget {
  const ArrowView({
    super.key,
    required this.arrow,
    required this.visible,
    this.fuseFraction,
    this.size = 200,
  });

  final Arrow arrow;

  /// False once a ghost arrow has faded; the tile stays, the glyph goes.
  final bool visible;

  /// Fraction of the fuse left (1 = fresh), or null for no fuse ring.
  final double? fuseFraction;

  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final tileColor = switch (arrow.kind) {
      ArrowKind.reverse => p.arrowReverse,
      ArrowKind.ghost => p.arrowGhost,
      ArrowKind.normal || ArrowKind.decoy => p.arrowNormal,
    };
    final decoy = arrow.decoyLabel;
    final glyphSize = size * 0.56;

    // Keyed by id so every new arrow replays the pop-in.
    final tile = Container(
      key: ValueKey<int>(arrow.id),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visible ? tileColor : p.arrowHiddenTile,
        shape: BoxShape.circle,
        boxShadow: [
          if (visible)
            BoxShadow(
              color: tileColor.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: RotatedBox(
              quarterTurns: arrow.direction.quarterTurns,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: glyphSize,
                color: p.arrowGlyph,
              ),
            ),
          ),
          if (!visible)
            Text(
              '?',
              style: TextStyle(
                fontSize: glyphSize * 0.7,
                fontWeight: FontWeight.w900,
                color: p.textFaint,
              ),
            ),
          if (arrow.kind == ArrowKind.reverse && visible)
            Positioned(
              top: size * 0.09,
              right: size * 0.09,
              child: _Badge(
                icon: Icons.sync_rounded,
                color: p.arrowGlyph,
                onColor: p.arrowReverse,
              ),
            ),
          if (decoy != null && visible)
            Positioned(
              bottom: size * 0.12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: p.accentSun,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  directionLabel(l10n, decoy).toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.085,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: p.textInk,
                  ),
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.55, 0.55),
          end: const Offset(1, 1),
          duration: 200.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 120.ms);

    final fuse = fuseFraction;
    return Semantics(
      label: '${arrow.kind.name} arrow ${directionLabel(l10n, arrow.direction)}',
      child: SizedBox(
        width: size + 28,
        height: size + 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (fuse != null)
              SizedBox(
                width: size + 22,
                height: size + 22,
                child: CircularProgressIndicator(
                  value: fuse,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: p.fuseTrack,
                  color: fuse < 0.3 ? p.timerWarn : p.fuseRing,
                ),
              ),
            tile,
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color, required this.onColor});
  final IconData icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: onColor),
      );
}
