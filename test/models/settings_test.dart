import 'package:arrow_game/models/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: haptics on, system theme, grid off', () {
    expect(Settings.defaults.hapticsOn, isTrue);
    expect(Settings.defaults.themeChoice, ThemeChoice.system);
    expect(Settings.defaults.gridLinesOn, isFalse);
  });

  test('copyWith and equality', () {
    final dark = Settings.defaults.copyWith(themeChoice: ThemeChoice.dark);
    expect(dark.themeChoice, ThemeChoice.dark);
    expect(dark.hapticsOn, isTrue);
    final grid = dark.copyWith(hapticsOn: false, gridLinesOn: true);
    const expected = Settings(hapticsOn: false, themeChoice: ThemeChoice.dark, gridLinesOn: true);
    expect(grid, expected);
    expect(grid.hashCode, expected.hashCode);
    expect(grid, isNot(dark));
  });
}
