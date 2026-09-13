/// Localised names for engine values (levels, directions, arrow rules). Keeps
/// the `switch`es in one place so screens stay declarative.
library;

import '../engine/arrow.dart';
import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../models/level_spec.dart';

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

String directionLabel(AppLocalizations l10n, Direction d) => switch (d) {
      Direction.up => l10n.directionUp,
      Direction.right => l10n.directionRight,
      Direction.down => l10n.directionDown,
      Direction.left => l10n.directionLeft,
    };

/// The one-line rule for an arrow kind, as shown on the level intro.
String ruleForKind(AppLocalizations l10n, ArrowKind kind) => switch (kind) {
      ArrowKind.normal => l10n.ruleNormal,
      ArrowKind.reverse => l10n.ruleReverse,
      ArrowKind.ghost => l10n.ruleGhost,
      ArrowKind.decoy => l10n.ruleDecoy,
    };

/// Every rule that applies to [spec]: one per arrow kind, plus the fuse.
List<String> rulesForSpec(AppLocalizations l10n, LevelSpec spec) => <String>[
      for (final kind in spec.kinds) ruleForKind(l10n, kind),
      if (spec.hasFuse) l10n.ruleFuse,
    ];

/// The emoji that fronts each rule line on the intro card.
String emojiForKind(ArrowKind kind) => switch (kind) {
      ArrowKind.normal => '👆',
      ArrowKind.reverse => '🔄',
      ArrowKind.ghost => '👻',
      ArrowKind.decoy => '🙈',
    };
