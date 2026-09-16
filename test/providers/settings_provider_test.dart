import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository', () {
    test('loads defaults when nothing is stored', () async {
      expect(SettingsRepository(await _prefs()).load(), Settings.defaults);
    });

    test('round-trips saved settings', () async {
      final prefs = await _prefs();
      const custom = Settings(
        musicOn: false,
        musicVolume: 0.25,
        hapticsOn: false,
        sfxOn: false,
        themeChoice: ThemeChoice.dark,
        gridLinesOn: true,
        onboardingDone: true,
        languageChoice: LanguageChoice.hindi,
      );
      await SettingsRepository(prefs).save(custom);
      expect(SettingsRepository(prefs).load(), custom);
    });

    test('unknown stored theme values fall back to system', () async {
      final repo = SettingsRepository(await _prefs(<String, Object>{'arrow_theme': 'chartreuse'}));
      expect(repo.load().themeChoice, ThemeChoice.system);
    });

    test('unknown stored language values fall back to the device', () async {
      final repo = SettingsRepository(
        await _prefs(<String, Object>{'arrow_language': 'klingon'}),
      );
      expect(repo.load().languageChoice, LanguageChoice.system);
    });
  });

  group('SettingsNotifier', () {
    test('setters update state and persist', () async {
      final prefs = await _prefs();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(settingsProvider.notifier);

      notifier.setHaptics(false);
      notifier.setSfx(false);
      notifier.setThemeChoice(ThemeChoice.light);
      notifier.setGridLines(true);
      notifier.setMusic(false);
      notifier.setMusicVolume(1.7); // clamped
      notifier.completeOnboarding();
      notifier.setLanguageChoice(LanguageChoice.hindi);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(settingsProvider),
        const Settings(
          musicOn: false,
          musicVolume: 1.0,
          hapticsOn: false,
          sfxOn: false,
          themeChoice: ThemeChoice.light,
          gridLinesOn: true,
          onboardingDone: true,
          languageChoice: LanguageChoice.hindi,
        ),
      );
      expect(prefs.getBool('arrow_haptics_on'), isFalse);
      expect(prefs.getBool('arrow_sfx_on'), isFalse);
      expect(prefs.getString('arrow_theme'), 'light');
      expect(prefs.getBool('arrow_grid_lines'), isTrue);
      expect(prefs.getBool('arrow_music_on'), isFalse);
      expect(prefs.getDouble('arrow_music_volume'), 1.0);
      expect(prefs.getBool('arrow_onboarding_done'), isTrue);
    });
  });

  test('sharedPreferencesProvider throws until overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(sharedPreferencesProvider), throwsUnimplementedError);
  });
}
