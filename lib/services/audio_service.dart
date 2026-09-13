/// Looping background music that respects the user's music on/off + volume,
/// and gets out of the way while the app is in the background. Wraps
/// audioplayers behind an injectable [AudioBackend] so the control logic is
/// unit-testable without the audio plugin.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings.dart';

/// The bundled looping track, relative to `assets/` (audioplayers' AssetSource
/// prefixes that itself). "Permafrost" by Scott Buckley, CC-BY 4.0 — see
/// `lib/data/audio_credits.dart`.
const String kBackgroundTrack = 'audio/permafrost.mp3';

/// Minimal audio operations the service needs.
abstract class AudioBackend {
  Future<void> loop(String asset, double volume);
  Future<void> setVolume(double volume);
  Future<void> resume();
  Future<void> pause();
  Future<void> stop();
}

/// Real backend backed by an [AudioPlayer] set to loop. The player is created
/// on first use, so a session with music off never touches the plugin (the
/// headless web harness has no audio plumbing at all). Thin platform glue —
/// excluded from coverage (exercised only on a real device).
// coverage:ignore-start
class AudioPlayersBackend implements AudioBackend {
  AudioPlayersBackend([AudioPlayer? player]) : _player = player;

  AudioPlayer? _player;

  @override
  Future<void> loop(String asset, double volume) async {
    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume);
    await player.play(AssetSource(asset));
  }

  @override
  Future<void> setVolume(double volume) async => _player?.setVolume(volume);
  @override
  Future<void> resume() async => _player?.resume();
  @override
  Future<void> pause() async => _player?.pause();
  @override
  Future<void> stop() async => _player?.stop();
}
// coverage:ignore-end

class AudioService {
  AudioService(this._backend, {this.trackAsset});

  final AudioBackend _backend;

  /// Asset path (under `assets/audio/`) of the looping track, or null until a
  /// licensed track is bundled — while null the service does nothing.
  final String? trackAsset;

  /// Whether the looping player has been created yet.
  bool _started = false;

  /// Whether it is currently audible — keeps pause/resume from being issued
  /// twice, so a volume change doesn't re-resume an already-playing loop.
  bool _playing = false;

  /// True while the app is away from the foreground.
  bool _backgrounded = false;

  /// The most recent settings, replayed by [_sync] whenever the foreground
  /// state changes. Null until the app has applied its settings once.
  Settings? _settings;

  /// Applies the current [settings] to playback. Safe to call while
  /// backgrounded — the settings are recorded but nothing starts playing.
  Future<void> apply(Settings settings) async {
    _settings = settings;
    await _sync();
  }

  /// Pauses the loop whenever the app leaves the foreground (a call, the app
  /// switcher, the screen locking) and brings it back on return.
  Future<void> handleLifecycle(AppLifecycleState lifecycle) async {
    _backgrounded = lifecycle != AppLifecycleState.resumed;
    await _sync();
  }

  /// Drives the backend to match [_settings] and the foreground state. Both
  /// entry points funnel through here so returning to the foreground *starts*
  /// the loop when it never got going — not just resumes an existing one.
  Future<void> _sync() async {
    final track = trackAsset;
    final settings = _settings;
    if (track == null || settings == null) return;

    if (settings.musicOn && !_backgrounded) {
      if (!_started) {
        await _backend.loop(track, settings.musicVolume);
        _started = true;
        _playing = true;
        return;
      }
      await _backend.setVolume(settings.musicVolume);
      if (!_playing) {
        await _backend.resume();
        _playing = true;
      }
    } else if (_playing) {
      await _backend.pause();
      _playing = false;
    }
  }

  Future<void> stop() async {
    if (_started) {
      await _backend.stop();
      _started = false;
      _playing = false;
    }
  }
}

// coverage:ignore-start
final audioServiceProvider = Provider<AudioService>(
  (ref) => AudioService(AudioPlayersBackend(), trackAsset: kBackgroundTrack),
);
// coverage:ignore-end
