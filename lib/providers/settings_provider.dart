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

  static const _kHaptics = 'arrow_haptics_on';
  static const _kTheme = 'arrow_theme';
  static const _kGridLines = 'arrow_grid_lines';

  Settings load() {
    const d = Settings.defaults;
    return Settings(
      hapticsOn: _prefs.getBool(_kHaptics) ?? d.hapticsOn,
      themeChoice: _parseTheme(_prefs.getString(_kTheme), d.themeChoice),
      gridLinesOn: _prefs.getBool(_kGridLines) ?? d.gridLinesOn,
    );
  }

  Future<void> save(Settings s) async {
    await _prefs.setBool(_kHaptics, s.hapticsOn);
    await _prefs.setString(_kTheme, s.themeChoice.name);
    await _prefs.setBool(_kGridLines, s.gridLinesOn);
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

  void setHaptics(bool on) => _update(state.copyWith(hapticsOn: on));

  void setThemeChoice(ThemeChoice choice) =>
      _update(state.copyWith(themeChoice: choice));

  void setGridLines(bool on) => _update(state.copyWith(gridLinesOn: on));

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
