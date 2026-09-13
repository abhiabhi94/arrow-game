import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/level_spec.dart';
import '../ui/colors.dart';
import '../utils/labels.dart';
import 'result_card.dart';

/// The pre-start card: level name, the rules in play, the target/clock/lives
/// chips and a big "Go!".
class LevelIntro extends StatelessWidget {
  const LevelIntro({super.key, required this.spec, required this.onStart});

  final LevelSpec spec;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    return ResultCard(
      emoji: '🎯',
      title: levelName(l10n, spec.level),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.flag_rounded, text: l10n.introTarget(spec.targetHits)),
              _Chip(
                icon: Icons.timer_outlined,
                text: l10n.introTime(spec.timeLimitMs ~/ 1000),
              ),
              _Chip(icon: Icons.favorite_rounded, text: l10n.introLives),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.introRules,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: p.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          for (final kind in spec.kinds)
            _RuleLine(emoji: emojiForKind(kind), text: ruleForKind(l10n, kind)),
          if (spec.hasFuse) _RuleLine(emoji: '⏳', text: l10n.ruleFuse),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: onStart,
          child: Text(l10n.introGo),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: p.backgroundSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: p.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: p.textInk)),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: context.palette.textInk, height: 1.3),
              ),
            ),
          ],
        ),
      );
}

