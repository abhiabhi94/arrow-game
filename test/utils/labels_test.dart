import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/l10n/app_localizations_en.dart';
import 'package:arrow_game/utils/labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('every level has a distinct name', () {
    final names = <String>{for (var l = 1; l <= totalLevels; l++) levelName(l10n, l)};
    expect(names, hasLength(totalLevels));
    expect(levelName(l10n, 1), 'Warm-up');
    expect(levelName(l10n, 20), 'Grand Finale');
    expect(levelName(l10n, 99), 'Grand Finale');
  });

  test('directions and kinds are labelled', () {
    expect(Direction.values.map((d) => directionLabel(l10n, d)), ['Up', 'Right', 'Down', 'Left']);
    for (final k in ArrowKind.values) {
      expect(ruleForKind(l10n, k), isNotEmpty);
      expect(emojiForKind(k), isNotEmpty);
    }
  });

  test('rules for a spec: one per kind plus the fuse', () {
    expect(rulesForSpec(l10n, specForLevel(1)), [l10n.ruleNormal]);
    expect(rulesForSpec(l10n, specForLevel(20)), [
      l10n.ruleNormal,
      l10n.ruleReverse,
      l10n.ruleGhost,
      l10n.ruleDecoy,
      l10n.ruleFuse,
    ]);
  });
}
