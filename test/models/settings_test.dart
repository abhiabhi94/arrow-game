import 'package:arrow_game/models/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: haptics on, system theme', () {
    expect(Settings.defaults.hapticsOn, isTrue);
    expect(Settings.defaults.themeChoice, ThemeChoice.system);
  });

  test('copyWith and equality', () {
    final dark = Settings.defaults.copyWith(themeChoice: ThemeChoice.dark);
    expect(dark.themeChoice, ThemeChoice.dark);
    expect(dark.hapticsOn, isTrue);
    final quiet = dark.copyWith(hapticsOn: false);
    expect(quiet, const Settings(hapticsOn: false, themeChoice: ThemeChoice.dark));
    expect(quiet.hashCode, const Settings(hapticsOn: false, themeChoice: ThemeChoice.dark).hashCode);
    expect(quiet, isNot(dark));
  });
}
