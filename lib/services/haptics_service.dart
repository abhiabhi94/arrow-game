/// Haptic feedback that respects the user's setting. Wraps the platform
/// behind an injectable [HapticEngine] so the gate logic is unit-testable
/// without a platform channel.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Low-level haptic impulses. The real implementation is [SystemHapticEngine].
abstract class HapticEngine {
  void selection();
  void light();
  void medium();
  void heavy();
  void vibrate();

  /// The crash of a bump: a hard hit with a rumble behind it, so a lost
  /// life is felt even when the eye missed the arrow.
  void crash();
}

/// The channel `MainActivity.kt` answers on Android.
const kHapticsChannel = MethodChannel('app.curious.arrow/haptics');

/// On Android, Flutter's [HapticFeedback] goes through
/// `View.performHapticFeedback`, which the OS silences whenever the user has
/// "touch feedback" turned off — common enough that the game felt mute. So
/// Android drives the Vibrator service through [kHapticsChannel] instead;
/// iOS keeps the Taptic engine via [HapticFeedback].
class SystemHapticEngine implements HapticEngine {
  const SystemHapticEngine();

  bool get _useVibrator =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _buzz(String effect) =>
      kHapticsChannel.invokeMethod<void>('vibrate', effect);

  @override
  void selection() =>
      _useVibrator ? _buzz('tick') : HapticFeedback.selectionClick();
  @override
  void light() => _useVibrator ? _buzz('click') : HapticFeedback.lightImpact();
  @override
  void medium() =>
      _useVibrator ? _buzz('click') : HapticFeedback.mediumImpact();
  @override
  void heavy() => _useVibrator ? _buzz('heavy') : HapticFeedback.heavyImpact();
  @override
  void vibrate() => _useVibrator ? _buzz('long') : HapticFeedback.vibrate();
  @override
  void crash() {
    if (_useVibrator) {
      _buzz('crash');
      return;
    }
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }
}

class HapticsService {
  HapticsService(
    this._enabled, {
    this._engine = const SystemHapticEngine(),
  });

  final bool Function() _enabled;
  final HapticEngine _engine;

  /// A light tick for taps and level start.
  void tap() => _run(_engine.selection);

  /// A soft confirmation for an arrow that slid out.
  void hit() => _run(_engine.light);

  /// The crash of a bump (a life lost): a hard hit and a rumble.
  void miss() => _run(_engine.crash);

  /// A celebratory nudge on clearing a level.
  void victory() => _run(_engine.medium);

  /// A long buzz when the level is lost (no lives / time up).
  void fail() => _run(_engine.vibrate);

  void _run(void Function() impulse) {
    if (_enabled()) impulse();
  }
}

final hapticsProvider = Provider<HapticsService>(
  (ref) => HapticsService(() => ref.read(settingsProvider).hapticsOn),
);
