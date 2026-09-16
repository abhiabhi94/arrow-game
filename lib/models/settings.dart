/// User-configurable settings, persisted via shared_preferences. Immutable
/// with [copyWith]. Pure Dart (no Flutter).
library;

/// The theme preference. [system] (default) follows the OS light/dark setting;
/// [light]/[dark] force one. A plain Dart enum (no Flutter import) so the model
/// stays pure; mapped to Flutter's ThemeMode in main.dart.
enum ThemeChoice { system, light, dark }

/// The language the app speaks. [system] (default) follows the device
/// locale — a phone set to Hindi opens in Hindi — and the other values pin
/// one language regardless. A plain Dart enum, mapped to a Flutter Locale in
/// main.dart.
enum LanguageChoice { system, english, hindi }

class Settings {
  const Settings({
    required this.musicOn,
    required this.musicVolume,
    required this.hapticsOn,
    required this.sfxOn,
    required this.themeChoice,
    required this.gridLinesOn,
    required this.onboardingDone,
    required this.languageChoice,
  });

  /// Background music on/off (on by default).
  final bool musicOn;

  /// Music volume, 0.0 .. 1.0.
  final double musicVolume;

  /// Haptic feedback on/off (on by default).
  final bool hapticsOn;

  /// Sound effects (every in-game sound, e.g. the exit whoosh) on/off (on by default).
  final bool sfxOn;

  /// Theme preference (system/light/dark). System by default.
  final ThemeChoice themeChoice;

  /// Whether the board draws its grid lines. On by default — the toggle is
  /// locked until it is earned by clearing a few levels (see
  /// progress_provider), so "on" only ever takes effect from that point, and
  /// the lattice is a reading aid the dense boards need.
  final bool gridLinesOn;

  /// Whether the one-time "how to play" walkthrough has been seen.
  final bool onboardingDone;

  /// Which language the app speaks; [LanguageChoice.system] follows the
  /// device.
  final LanguageChoice languageChoice;

  static const Settings defaults = Settings(
    musicOn: true,
    musicVolume: 0.6,
    hapticsOn: true,
    sfxOn: true,
    themeChoice: ThemeChoice.system,
    gridLinesOn: true,
    onboardingDone: false,
    languageChoice: LanguageChoice.system,
  );

  Settings copyWith({
    bool? musicOn,
    double? musicVolume,
    bool? hapticsOn,
    bool? sfxOn,
    ThemeChoice? themeChoice,
    bool? gridLinesOn,
    bool? onboardingDone,
    LanguageChoice? languageChoice,
  }) =>
      Settings(
        musicOn: musicOn ?? this.musicOn,
        musicVolume: musicVolume ?? this.musicVolume,
        hapticsOn: hapticsOn ?? this.hapticsOn,
        sfxOn: sfxOn ?? this.sfxOn,
        themeChoice: themeChoice ?? this.themeChoice,
        gridLinesOn: gridLinesOn ?? this.gridLinesOn,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        languageChoice: languageChoice ?? this.languageChoice,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.musicOn == musicOn &&
      other.musicVolume == musicVolume &&
      other.hapticsOn == hapticsOn &&
      other.sfxOn == sfxOn &&
      other.themeChoice == themeChoice &&
      other.gridLinesOn == gridLinesOn &&
      other.onboardingDone == onboardingDone &&
      other.languageChoice == languageChoice;

  @override
  int get hashCode => Object.hash(
        musicOn,
        musicVolume,
        hapticsOn,
        sfxOn,
        themeChoice,
        gridLinesOn,
        onboardingDone,
        languageChoice,
      );
}
