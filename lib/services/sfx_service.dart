/// Short sound effects (the "zup" of an arrow leaving the board). Respects the
/// user's sound-effects setting and wraps audioplayers behind an injectable
/// [SfxBackend] so the logic is unit-testable without the plugin.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// The exit swoosh, relative to `assets/` (see `tool/make_sfx.py`).
const String kZipSound = 'audio/zip.wav';

/// Consecutive exits within this window pitch the swoosh up a notch each,
/// so a quick run of taps goes "zup, zup, zup" climbing.
const Duration kZipStreakWindow = Duration(milliseconds: 1500);

/// How much each streak step raises the playback rate, and the cap.
const double kZipStreakStep = 0.06;
const int kZipStreakMax = 6;

/// Minimal playback the service needs.
abstract class SfxBackend {
  Future<void> play(String asset, {required double rate});
}

/// Real backend: a small pool of low-latency players used round-robin so a
/// fast run of exits overlaps instead of cutting the previous swoosh off.
/// Players are created on first use, so a session with effects off never
/// touches the plugin. Thin platform glue — excluded from coverage.
// coverage:ignore-start
class AudioPlayersSfxBackend implements SfxBackend {
  AudioPlayersSfxBackend({this.poolSize = 3});

  final int poolSize;
  final List<AudioPlayer> _pool = <AudioPlayer>[];
  int _next = 0;

  @override
  Future<void> play(String asset, {required double rate}) async {
    if (_pool.isEmpty) {
      for (var i = 0; i < poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
    }
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    await player.stop();
    await player.setPlaybackRate(rate);
    await player.play(AssetSource(asset));
  }
}
// coverage:ignore-end

class SfxService {
  SfxService(
    this._enabled, {
    required this.backend,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final bool Function() _enabled;
  final SfxBackend backend;
  final DateTime Function() _now;

  DateTime? _lastZip;
  int _streak = 0;

  /// The streak the next [zip] will play at (0 = base pitch).
  int get streak => _streak;

  /// The "zup" of an arrow sliding out. Pitch climbs with quick successive
  /// exits and resets after a pause.
  void zip() {
    final now = _now();
    final last = _lastZip;
    if (last != null && now.difference(last) <= kZipStreakWindow) {
      _streak = (_streak + 1).clamp(0, kZipStreakMax);
    } else {
      _streak = 0;
    }
    _lastZip = now;
    if (!_enabled()) return;
    backend.play(kZipSound, rate: 1.0 + _streak * kZipStreakStep);
  }
}

// coverage:ignore-start
final sfxProvider = Provider<SfxService>(
  (ref) => SfxService(
    () => ref.read(settingsProvider).sfxOn,
    backend: AudioPlayersSfxBackend(),
  ),
);
// coverage:ignore-end
