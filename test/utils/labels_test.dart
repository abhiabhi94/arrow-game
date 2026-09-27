import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/l10n/app_localizations_en.dart';
import 'package:arrow_game/utils/labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('every level has a distinct name', () {
    final names = <String>{for (var l = 1; l <= totalLevels; l++) levelName(l10n, l)};
    expect(names, hasLength(totalLevels));
    expect(levelName(l10n, 1), 'First Steps');
    expect(levelName(l10n, 40), 'Halfway Out');
    expect(levelName(l10n, 60), 'Turning Point');
    expect(levelName(l10n, 61), 'Second Wind');
    expect(levelName(l10n, 80), 'Beyond the Edge');
    expect(levelName(l10n, 81), 'Far Side');
    expect(levelName(l10n, 100), 'The Last Arrow');
    expect(levelName(l10n, 101), 'The Last Arrow');
  });
}
