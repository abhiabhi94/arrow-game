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
      const custom = Settings(hapticsOn: false, themeChoice: ThemeChoice.dark);
      await SettingsRepository(prefs).save(custom);
      expect(SettingsRepository(prefs).load(), custom);
    });

    test('unknown stored theme values fall back to system', () async {
      final repo = SettingsRepository(await _prefs(<String, Object>{'arrow_theme': 'chartreuse'}));
      expect(repo.load().themeChoice, ThemeChoice.system);
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
      notifier.setThemeChoice(ThemeChoice.light);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(settingsProvider), const Settings(hapticsOn: false, themeChoice: ThemeChoice.light));
      expect(prefs.getBool('arrow_haptics_on'), isFalse);
      expect(prefs.getString('arrow_theme'), 'light');
    });
  });

  test('sharedPreferencesProvider throws until overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(sharedPreferencesProvider), throwsUnimplementedError);
  });
}
