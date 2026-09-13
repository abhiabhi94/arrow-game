/// Localised names for engine values. Keeps the `switch`es in one place so
/// screens stay declarative.
library;

import '../l10n/app_localizations.dart';

/// The playful title of 1-based [level] (1..20).
String levelName(AppLocalizations l10n, int level) => switch (level) {
      1 => l10n.levelName1,
      2 => l10n.levelName2,
      3 => l10n.levelName3,
      4 => l10n.levelName4,
      5 => l10n.levelName5,
      6 => l10n.levelName6,
      7 => l10n.levelName7,
      8 => l10n.levelName8,
      9 => l10n.levelName9,
      10 => l10n.levelName10,
      11 => l10n.levelName11,
      12 => l10n.levelName12,
      13 => l10n.levelName13,
      14 => l10n.levelName14,
      15 => l10n.levelName15,
      16 => l10n.levelName16,
      17 => l10n.levelName17,
      18 => l10n.levelName18,
      19 => l10n.levelName19,
      _ => l10n.levelName20,
    };
