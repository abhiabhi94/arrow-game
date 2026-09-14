/// Localised names for engine values. Keeps the `switch`es in one place so
/// screens stay declarative.
library;

import '../l10n/app_localizations.dart';

/// The playful title of 1-based [level] (1..40).
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
      20 => l10n.levelName20,
      21 => l10n.levelName21,
      22 => l10n.levelName22,
      23 => l10n.levelName23,
      24 => l10n.levelName24,
      25 => l10n.levelName25,
      26 => l10n.levelName26,
      27 => l10n.levelName27,
      28 => l10n.levelName28,
      29 => l10n.levelName29,
      30 => l10n.levelName30,
      31 => l10n.levelName31,
      32 => l10n.levelName32,
      33 => l10n.levelName33,
      34 => l10n.levelName34,
      35 => l10n.levelName35,
      36 => l10n.levelName36,
      37 => l10n.levelName37,
      38 => l10n.levelName38,
      39 => l10n.levelName39,
      _ => l10n.levelName40,
    };
