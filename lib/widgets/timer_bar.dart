import 'package:flutter/material.dart';

import '../providers/game_provider.dart';
import '../ui/colors.dart';
import '../utils/format.dart';

/// The level clock: a draining bar (mint, turning coral in the last quarter)
/// with the seconds left beside it.
class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.remainingMs, required this.fraction});

  final int remainingMs;
  final double fraction;

  static const double _warnBelow = 0.25;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final warn = fraction < _warnBelow;
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: warn ? p.timerWarn : p.textMuted),
        const SizedBox(width: 6),
        SizedBox(
          width: 30,
          child: Text(
            formatSecondsLeft(remainingMs),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: warn ? p.timerWarn : p.textInk,
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
    );
  }
}
