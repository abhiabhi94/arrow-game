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
    this.reduceMotion = false,
    this.extraTime = false,
    this.noTimeLimit = false,
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

  /// Calms the screen down for players who find motion hard to take: no
  /// screen jolt on a bump, no hop or confetti on a clear, no slump, no
  /// entrance animations, a still hint glow. Off by default; the OS "reduce
  /// motion" setting switches the same behaviour on without this flag (see
  /// `reduceMotionOf` in `ui/motion.dart`).
  final bool reduceMotion;

  /// Doubles every level's clock. The game is a sprint by design — 26 s on
  /// level 1 — and that is a wall for a player whose hands or eyes need
  /// longer; stars and progress are earned the same way.
  final bool extraTime;

  /// "Remove time limits": no level has a clock. No time is counted, none is
  /// shown while playing or on the win card, no best time is recorded, and
  /// "Time's up" never comes — the player sets the pace, not a wall clock.
  /// Off by default, so every level keeps the clock that counts down to zero
  /// (and [extraTime] applies).
  final bool noTimeLimit;

  static const Settings defaults = Settings(
    musicOn: true,
    musicVolume: 0.6,
    hapticsOn: true,
    sfxOn: true,
    themeChoice: ThemeChoice.system,
    gridLinesOn: true,
    onboardingDone: false,
    languageChoice: LanguageChoice.system,
    reduceMotion: false,
    extraTime: false,
    noTimeLimit: false,
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
    bool? reduceMotion,
    bool? extraTime,
    bool? noTimeLimit,
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
        reduceMotion: reduceMotion ?? this.reduceMotion,
        extraTime: extraTime ?? this.extraTime,
        noTimeLimit: noTimeLimit ?? this.noTimeLimit,
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
      other.languageChoice == languageChoice &&
      other.reduceMotion == reduceMotion &&
      other.extraTime == extraTime &&
      other.noTimeLimit == noTimeLimit;

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
        reduceMotion,
        extraTime,
        noTimeLimit,
      );
}
