import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../models/level_progress.dart';
import '../ui/colors.dart';

/// Hearts for the lives left; a lost heart shrinks and greys out.
///
/// A live region: the label changes when a life goes, and a screen reader
/// says so ("2 lives left") the moment the bump lands. With [reduceMotion]
/// the lost heart simply greys out.
class LivesIndicator extends StatelessWidget {
  const LivesIndicator({super.key, required this.livesLeft, this.reduceMotion = false});

  final int livesLeft;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.hudLives(livesLeft),
      liveRegion: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(maxLives, (i) {
          final alive = i < livesLeft;
          final heart = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 26,
              color: alive ? p.heartFull : p.heartEmpty,
            ),
          );
          if (alive || reduceMotion) return heart;
          // Keyed so the pop plays once, when this heart is lost.
          return heart
              .animate(key: ValueKey<String>('lost-$i'))
              .scale(
                begin: const Offset(1.4, 1.4),
                end: const Offset(1, 1),
                duration: 260.ms,
                curve: Curves.easeOutBack,
              )
              .shake(hz: 6, duration: 260.ms);
        }),
      ),
    );
  }
}
