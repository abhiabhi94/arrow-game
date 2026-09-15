import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../models/level_progress.dart';
import '../ui/colors.dart';

/// Hearts for the lives left; a lost heart shrinks and greys out. [lives] is
/// how many the level grants — the later, denser boards grant more, and the
/// hearts shrink so the row still fits beside the clock on a narrow phone.
class LivesIndicator extends StatelessWidget {
  const LivesIndicator({
    super.key,
    required this.livesLeft,
    this.lives = maxLives,
  });

  final int livesLeft;
  final int lives;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.hudLives(livesLeft),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(lives, (i) {
          final alive = i < livesLeft;
          final heart = Padding(
            padding: EdgeInsets.symmetric(horizontal: lives > 3 ? 1 : 2),
            child: Icon(
              alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: switch (lives) { <= 3 => 26.0, 4 => 23.0, _ => 20.0 },
              color: alive ? p.heartFull : p.heartEmpty,
            ),
          );
          if (alive) return heart;
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
