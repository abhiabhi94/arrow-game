/// Short sound effects: the whoosh of an arrow leaving the board and the
/// knock of one that can't. Respects the user's sound-effects setting and
/// wraps audioplayers behind an injectable [SfxBackend] so the logic is
/// unit-testable without the plugin.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// The exit whoosh and the blocked knock, relative to `assets/` (see
/// `tool/make_sfx.py`).
const String kWhooshSound = 'audio/whoosh.wav';
const String kBumpSound = 'audio/bump.wav';

/// Consecutive exits within this window pitch the swoosh up a notch each,
/// so a quick run of taps climbs in pitch.
const Duration kWhooshStreakWindow = Duration(milliseconds: 1500);

/// How much each streak step raises the playback rate, and the cap.
const double kWhooshStreakStep = 0.06;
const int kWhooshStreakMax = 6;

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

  /// The streak the next [whoosh] will play at (0 = base pitch).
  int get streak => _streak;

  /// The whoosh of an arrow sliding out. Pitch climbs with quick successive
  /// exits and resets after a pause.
  void whoosh() {
    final now = _now();
    final last = _lastZip;
    if (last != null && now.difference(last) <= kWhooshStreakWindow) {
      _streak = (_streak + 1).clamp(0, kWhooshStreakMax);
    } else {
      _streak = 0;
    }
    _lastZip = now;
    if (!_enabled()) return;
    backend.play(kWhooshSound, rate: 1.0 + _streak * kWhooshStreakStep);
  }

  /// The knock of an arrow that ran into another. Ends any streak: the next
  /// whoosh starts again from the base pitch.
  void bump() {
    _streak = 0;
    _lastZip = null;
    if (!_enabled()) return;
    backend.play(kBumpSound, rate: 1.0);
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
