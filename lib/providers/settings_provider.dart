/// Settings state: loads from and persists to shared_preferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import 'app_providers.dart';

/// Wraps shared_preferences with typed load/save for [Settings].
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kMusicOn = 'arrow_music_on';
  static const _kMusicVolume = 'arrow_music_volume';
  static const _kHaptics = 'arrow_haptics_on';
  static const _kSfx = 'arrow_sfx_on';
  static const _kTheme = 'arrow_theme';
  static const _kGridLines = 'arrow_grid_lines';
  static const _kOnboarding = 'arrow_onboarding_done';
  static const _kLanguage = 'arrow_language';

  Settings load() {
    const d = Settings.defaults;
    return Settings(
      musicOn: _prefs.getBool(_kMusicOn) ?? d.musicOn,
      musicVolume: _prefs.getDouble(_kMusicVolume) ?? d.musicVolume,
      hapticsOn: _prefs.getBool(_kHaptics) ?? d.hapticsOn,
      sfxOn: _prefs.getBool(_kSfx) ?? d.sfxOn,
      themeChoice: _parseTheme(_prefs.getString(_kTheme), d.themeChoice),
      gridLinesOn: _prefs.getBool(_kGridLines) ?? d.gridLinesOn,
      onboardingDone: _prefs.getBool(_kOnboarding) ?? d.onboardingDone,
      languageChoice: _parseLanguage(_prefs.getString(_kLanguage), d.languageChoice),
    );
  }

  Future<void> save(Settings s) async {
    await _prefs.setBool(_kMusicOn, s.musicOn);
    await _prefs.setDouble(_kMusicVolume, s.musicVolume);
    await _prefs.setBool(_kHaptics, s.hapticsOn);
    await _prefs.setBool(_kSfx, s.sfxOn);
    await _prefs.setString(_kTheme, s.themeChoice.name);
    await _prefs.setBool(_kGridLines, s.gridLinesOn);
    await _prefs.setBool(_kOnboarding, s.onboardingDone);
    await _prefs.setString(_kLanguage, s.languageChoice.name);
  }

  /// Maps a stored language name back to [LanguageChoice], falling back to
  /// [fallback] for missing or unrecognised values.
  static LanguageChoice _parseLanguage(String? name, LanguageChoice fallback) {
    for (final choice in LanguageChoice.values) {
      if (choice.name == name) return choice;
    }
    return fallback;
  }

  /// Maps a stored theme name back to [ThemeChoice], falling back to
  /// [fallback] for missing or unrecognised values.
  static ThemeChoice _parseTheme(String? name, ThemeChoice fallback) {
    for (final choice in ThemeChoice.values) {
      if (choice.name == name) return choice;
    }
    return fallback;
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this._repo) : super(_repo.load());

  final SettingsRepository _repo;

  void setMusic(bool on) => _update(state.copyWith(musicOn: on));
  void setMusicVolume(double volume) =>
      _update(state.copyWith(musicVolume: volume.clamp(0.0, 1.0)));
  void setHaptics(bool on) => _update(state.copyWith(hapticsOn: on));
  void setSfx(bool on) => _update(state.copyWith(sfxOn: on));

  void setThemeChoice(ThemeChoice choice) =>
      _update(state.copyWith(themeChoice: choice));

  void setLanguageChoice(LanguageChoice choice) =>
      _update(state.copyWith(languageChoice: choice));

  void setGridLines(bool on) => _update(state.copyWith(gridLinesOn: on));

  void completeOnboarding() => _update(state.copyWith(onboardingDone: true));

  void _update(Settings next) {
    state = next;
    _repo.save(next);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);
