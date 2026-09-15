/// Looping background music that respects the user's music on/off + volume,
/// and gets out of the way while the app is in the background. Wraps
/// audioplayers behind an injectable [AudioBackend] so the control logic is
/// unit-testable without the audio plugin.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings.dart';

/// The bundled looping track, relative to `assets/` (audioplayers' AssetSource
/// prefixes that itself). "Game" by The_Mountain, Pixabay Content License —
/// see `lib/data/audio_credits.dart`.
const String kBackgroundTrack = 'audio/game.mp3';

/// How many times the service will restart a loop that something else
/// silenced, before leaving it alone until the settings or the foreground
/// state change. A cap, because a platform that is refusing to play — during
/// a phone call, say — would otherwise be asked forever.
const int kMaxMusicRecoveries = 3;

/// Minimal audio operations the service needs.
abstract class AudioBackend {
  Future<void> loop(String asset, double volume);
  Future<void> setVolume(double volume);
  Future<void> resume();
  Future<void> pause();
  Future<void> stop();

  /// Fires whenever playback stops without the service asking — audio focus
  /// lost to a call or another app, or the platform reclaiming the player.
  /// Without it the service's idea of what is playing silently drifts from
  /// the truth, and it never restarts the loop.
  Stream<void> get interruptions;
}

/// Real backend backed by an [AudioPlayer] set to loop. The player is created
/// on first use, so a session with music off never touches the plugin (the
/// headless web harness has no audio plumbing at all). Thin platform glue —
/// excluded from coverage (exercised only on a real device).
// coverage:ignore-start
class AudioPlayersBackend implements AudioBackend {
  AudioPlayersBackend([AudioPlayer? player]) : _player = player;

  AudioPlayer? _player;
  final StreamController<void> _interruptions = StreamController<void>.broadcast();

  /// True while a call from the service is in flight, so the state change it
  /// causes is not reported back as an interruption.
  bool _expected = false;

  @override
  Stream<void> get interruptions => _interruptions.stream;

  /// Starts watching a freshly created player for stops it was not asked for.
  void _watch(AudioPlayer player) {
    player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing || _expected) return;
      _interruptions.add(null);
    });
  }

  /// Runs [body], swallowing the state change it is expected to produce.
  Future<void> _own(Future<void> Function() body) async {
    _expected = true;
    try {
      await body();
    } finally {
      _expected = false;
    }
  }

  @override
  Future<void> loop(String asset, double volume) async {
    final created = _player == null;
    final player = _player ??= AudioPlayer();
    if (created) _watch(player);
    await _own(() async {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      await player.play(AssetSource(asset));
    });
  }

  @override
  Future<void> setVolume(double volume) async => _player?.setVolume(volume);
  @override
  Future<void> resume() async => _own(() async => _player?.resume());
  @override
  Future<void> pause() async => _own(() async => _player?.pause());
  @override
  Future<void> stop() async => _own(() async => _player?.stop());
}
// coverage:ignore-end

class AudioService {
  AudioService(this._backend, {this.trackAsset}) {
    _watch = _backend.interruptions.listen((_) => _recover());
  }

  final AudioBackend _backend;
  late final StreamSubscription<void> _watch;

  /// Restarts spent since the loop was last known to be playing.
  int _recoveries = 0;

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
    _recoveries = 0;
    await _sync();
  }

  /// Pauses the loop whenever the app leaves the foreground (a call, the app
  /// switcher, the screen locking) and brings it back on return.
  Future<void> handleLifecycle(AppLifecycleState lifecycle) async {
    _backgrounded = lifecycle != AppLifecycleState.resumed;
    _recoveries = 0;
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

  /// Something else silenced the loop. The service has to admit it is no
  /// longer playing — otherwise [_sync] sees `_playing` still true and never
  /// starts it again, which is how one lost audio focus used to mean no music
  /// for the rest of the session — and then bring it back.
  ///
  /// Recovery goes through [_backend.loop] rather than `resume`, because a
  /// player that was *stopped* cannot be resumed; the track restarts from the
  /// top, which for a loop nobody is listening to closely is a fair price.
  Future<void> _recover() async {
    _playing = false;
    _started = false;
    if (_recoveries >= kMaxMusicRecoveries) return;
    _recoveries++;
    await _sync();
  }

  Future<void> stop() async {
    if (_started) {
      await _backend.stop();
      _started = false;
      _playing = false;
    }
  }

  /// Drops the interruption watch. The provider disposes the service with the
  /// app, so this only matters to tests and to a torn-down ProviderScope.
  Future<void> dispose() => _watch.cancel();
}

// coverage:ignore-start
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(AudioPlayersBackend(), trackAsset: kBackgroundTrack);
  ref.onDispose(service.dispose);
  return service;
});
// coverage:ignore-end
