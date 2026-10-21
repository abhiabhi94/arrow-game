import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/game_provider.dart';
import '../ui/colors.dart';
import '../utils/format.dart';

/// The level clock: a draining bar (green, turning red in the last quarter)
/// with the time left beside it as m:ss.
///
/// The last quarter is not colour alone: the icon changes to an alarm. To a
/// screen reader the whole row is one node, "0:30 left on the clock" — not a
/// live region, since it changes ten times a second.
class TimerBar extends StatelessWidget {
  const TimerBar({
    super.key,
    required this.remainingMs,
    required this.fraction,
  });

  final int remainingMs;
  final double fraction;

  static const double _warnBelow = 0.25;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final warn = fraction < _warnBelow;
    final time = formatTimeLeft(remainingMs);
    return Semantics(
      label: l10n.hudTimeLeft(time),
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            warn ? Icons.alarm_rounded : Icons.timer_outlined,
            size: 18,
            color: warn ? p.timerWarn : p.textMuted,
          ),
          const SizedBox(width: 6),
          SizedBox(
            // Room for "11:33" without reflowing as digits change, grown with
            // the system font size; the figures are tabular for the same reason.
            width: MediaQuery.textScalerOf(context).scale(50),
            child: Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: warn ? p.timerWarn : p.textInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 10,
                color: p.timerTrack,
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: kTickMs),
                  curve: Curves.linear,
                  widthFactor: fraction.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: ColoredBox(color: warn ? p.timerWarn : p.timerFill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
