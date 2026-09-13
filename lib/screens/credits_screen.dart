import 'package:flutter/material.dart';

import '../data/audio_credits.dart';
import '../l10n/app_localizations.dart';
import '../ui/colors.dart';

/// Lists music attributions.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key, this.credits = audioCredits});

  /// The tracks to credit (defaults to the bundled set; injectable for tests).
  final List<TrackCredit> credits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.creditsIntro,
            style: TextStyle(color: context.palette.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          for (final credit in credits)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credit.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16, color: context.palette.textInk),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.creditsBy(credit.artist),
                      style: TextStyle(color: context.palette.textMuted)),
                  const SizedBox(height: 8),
                  Text('${credit.license} · ${credit.sourceUrl}',
                      style: TextStyle(color: context.palette.textFaint, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
