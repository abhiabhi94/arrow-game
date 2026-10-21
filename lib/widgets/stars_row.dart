import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../ui/colors.dart';
import '../ui/motion.dart';

/// Three stars, [stars] of them lit. Big and animated on the result card,
/// small and static on a level tile. One node to a screen reader: "2 of 3
/// stars".
class StarsRow extends StatelessWidget {
  const StarsRow({
    super.key,
    required this.stars,
    this.size = 20,
    this.animated = false,
  });

  final int stars;
  final double size;

  /// Pop the lit stars in one by one. Ignored with motion reduced.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final animate = animated && !reduceMotionOf(context);
    return Semantics(
      label: AppLocalizations.of(context)!.starsOfThree(stars),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(3, (i) {
          final lit = i < stars;
          Widget star = Icon(
            lit ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: lit ? p.star : p.starEmpty,
          );
          if (animate && lit) {
            star = star
                .animate(delay: (200 + i * 220).ms)
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 320.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 120.ms);
          }
          return star;
        }),
      ),
    );
  }
}
