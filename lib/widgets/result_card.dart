import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../ui/colors.dart';

/// A scrim over the arena with a centred card: emoji, title, body, optional
/// extra content, then the action buttons. Shared by the intro, pause and the
/// three endings so they all feel like one family.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.content,
    required this.actions,
    this.scrollable = false,
  });

  final String emoji;
  final String title;
  final String? body;
  final Widget? content;
  final List<Widget> actions;

  /// True for the intro, whose rule list can outgrow short phones.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: p.textInk,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textMuted, height: 1.4),
          ),
        ],
        if (content != null) ...[const SizedBox(height: 16), content!],
        const SizedBox(height: 22),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: actions[i]),
        ],
      ],
    );
    return Positioned.fill(
      child: ColoredBox(
        color: p.scrim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: scrollable ? SingleChildScrollView(child: column) : column,
          )
              .animate()
              .fadeIn(duration: 180.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 220.ms,
                curve: Curves.easeOutBack,
              ),
        ),
      ),
    );
  }
}
