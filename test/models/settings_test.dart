import 'package:arrow_game/models/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults: music, sfx and haptics on, system theme, grid off, onboarding pending', () {
    expect(Settings.defaults.musicOn, isTrue);
    expect(Settings.defaults.musicVolume, 0.6);
    expect(Settings.defaults.hapticsOn, isTrue);
    expect(Settings.defaults.sfxOn, isTrue);
    expect(Settings.defaults.themeChoice, ThemeChoice.system);
    expect(Settings.defaults.gridLinesOn, isFalse);
    expect(Settings.defaults.onboardingDone, isFalse);
  });

  test('copyWith and equality', () {
    final dark = Settings.defaults.copyWith(themeChoice: ThemeChoice.dark);
    expect(dark.themeChoice, ThemeChoice.dark);
    expect(dark.hapticsOn, isTrue);
    final grid = dark.copyWith(hapticsOn: false, sfxOn: false, gridLinesOn: true, musicOn: false, musicVolume: 0.2, onboardingDone: true);
    const expected = Settings(
      musicOn: false,
      musicVolume: 0.2,
      hapticsOn: false,
      sfxOn: false,
      themeChoice: ThemeChoice.dark,
      gridLinesOn: true,
      onboardingDone: true,
    );
    expect(grid, expected);
    expect(grid.hashCode, expected.hashCode);
    expect(grid, isNot(dark));
  });
}
