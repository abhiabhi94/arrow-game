/// User-configurable settings, persisted via shared_preferences. Immutable
/// with [copyWith]. Pure Dart (no Flutter).
library;

/// The theme preference. [system] (default) follows the OS light/dark setting;
/// [light]/[dark] force one. A plain Dart enum (no Flutter import) so the model
/// stays pure; mapped to Flutter's ThemeMode in main.dart.
enum ThemeChoice { system, light, dark }

class Settings {
  const Settings({
    required this.musicOn,
    required this.musicVolume,
    required this.hapticsOn,
    required this.themeChoice,
    required this.gridLinesOn,
    required this.onboardingDone,
  });

  /// Background music on/off (on by default).
  final bool musicOn;

  /// Music volume, 0.0 .. 1.0.
  final double musicVolume;

  /// Vibration/haptics on/off (on by default).
  final bool hapticsOn;

  /// Theme preference (system/light/dark). System by default.
  final ThemeChoice themeChoice;

  /// Whether the board draws its grid lines. Off by default; the toggle
  /// itself is earned by clearing a few levels (see progress_provider).
  final bool gridLinesOn;

  /// Whether the one-time "how to play" walkthrough has been seen.
  final bool onboardingDone;

  static const Settings defaults = Settings(
    musicOn: true,
    musicVolume: 0.6,
    hapticsOn: true,
    themeChoice: ThemeChoice.system,
    gridLinesOn: false,
    onboardingDone: false,
  );

  Settings copyWith({
    bool? musicOn,
    double? musicVolume,
    bool? hapticsOn,
    ThemeChoice? themeChoice,
    bool? gridLinesOn,
    bool? onboardingDone,
  }) =>
      Settings(
        musicOn: musicOn ?? this.musicOn,
        musicVolume: musicVolume ?? this.musicVolume,
        hapticsOn: hapticsOn ?? this.hapticsOn,
        themeChoice: themeChoice ?? this.themeChoice,
        gridLinesOn: gridLinesOn ?? this.gridLinesOn,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.musicOn == musicOn &&
      other.musicVolume == musicVolume &&
      other.hapticsOn == hapticsOn &&
      other.themeChoice == themeChoice &&
      other.gridLinesOn == gridLinesOn &&
      other.onboardingDone == onboardingDone;

  @override
  int get hashCode => Object.hash(
        musicOn,
        musicVolume,
        hapticsOn,
        themeChoice,
        gridLinesOn,
        onboardingDone,
      );
}
