import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_localizations.dart';
import '../ui/colors.dart';

/// Streaks at or above this show the badge.
const int kStreakShowAt = 3;

/// Streak milestones and their cheer.
String? streakCheer(AppLocalizations l10n, int streak) {
  if (streak >= 20) return l10n.streakLegend;
  if (streak >= 10) return l10n.streakUnstoppable;
  if (streak >= 5) return l10n.streakOnFire;
  return null;
}

/// "🔥 ×7  On fire!" — pops on every streak change, hidden under [kStreakShowAt].
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    if (streak < kStreakShowAt) return const SizedBox(height: 34);
    final p = context.palette;
    final cheer = streakCheer(AppLocalizations.of(context)!, streak);
    return Container(
      key: ValueKey<int>(streak),
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: p.accentSun, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '×$streak',
            style: TextStyle(fontWeight: FontWeight.w900, color: p.textInk),
          ),
          if (cheer != null) ...[
            const SizedBox(width: 8),
            Text(
              cheer,
              style: TextStyle(fontWeight: FontWeight.w800, color: p.accentCoral),
            ),
          ],
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 180.ms,
          curve: Curves.easeOutBack,
        );
  }
}
