/// User-configurable settings, persisted via shared_preferences. Immutable
/// with [copyWith]. Pure Dart (no Flutter).
library;

/// The theme preference. [system] (default) follows the OS light/dark setting;
/// [light]/[dark] force one. A plain Dart enum (no Flutter import) so the model
/// stays pure; mapped to Flutter's ThemeMode in main.dart.
enum ThemeChoice { system, light, dark }

class Settings {
  const Settings({required this.hapticsOn, required this.themeChoice});

  /// Vibration/haptics on/off (on by default).
  final bool hapticsOn;

  /// Theme preference (system/light/dark). System by default.
  final ThemeChoice themeChoice;

  static const Settings defaults =
      Settings(hapticsOn: true, themeChoice: ThemeChoice.system);

  Settings copyWith({bool? hapticsOn, ThemeChoice? themeChoice}) => Settings(
        hapticsOn: hapticsOn ?? this.hapticsOn,
        themeChoice: themeChoice ?? this.themeChoice,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.hapticsOn == hapticsOn &&
      other.themeChoice == themeChoice;

  @override
  int get hashCode => Object.hash(hapticsOn, themeChoice);
}
