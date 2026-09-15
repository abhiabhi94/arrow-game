import 'dart:async';

import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/services/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackend implements AudioBackend {
  final List<String> calls = <String>[];
  final StreamController<void> _interruptions = StreamController<void>.broadcast();

  @override
  Stream<void> get interruptions => _interruptions.stream;

  /// Pretends something else silenced the player — audio focus lost to a
  /// call, another app, or (before they stopped asking for it) our own sound
  /// effects — and waits for the service to react.
  Future<void> interrupt() async {
    _interruptions.add(null);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> loop(String asset, double volume) async => calls.add('loop $asset $volume');
  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');
  @override
  Future<void> resume() async => calls.add('resume');
  @override
  Future<void> pause() async => calls.add('pause');
  @override
  Future<void> stop() async => calls.add('stop');
}

const _on = Settings.defaults;
final _off = Settings.defaults.copyWith(musicOn: false);

void main() {
  test('starts the loop once and follows volume changes', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.apply(_on);
    await s.apply(_on.copyWith(musicVolume: 0.3));
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'volume 0.3']);
  });

  test('pauses when music is turned off and resumes when back on', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.apply(_on);
    await s.apply(_off);
    await s.apply(_off); // already paused: nothing more
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'pause', 'volume 0.6', 'resume']);
  });

  test('never starts while off, and starts on the first on', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.apply(_off);
    expect(b.calls, isEmpty);
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);
  });

  test('backgrounding pauses; returning to the foreground resumes', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.apply(_on);
    await s.handleLifecycle(AppLifecycleState.paused);
    await s.handleLifecycle(AppLifecycleState.resumed);
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'pause', 'volume 0.6', 'resume']);
  });

  test('a cold launch in the background starts the loop only on return', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.handleLifecycle(AppLifecycleState.inactive);
    await s.apply(_on);
    expect(b.calls, isEmpty);
    await s.handleLifecycle(AppLifecycleState.resumed);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);
  });

  test('stop tears the loop down; a later apply starts fresh', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    await s.stop(); // nothing started yet
    await s.apply(_on);
    await s.stop();
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'stop', 'loop $kBackgroundTrack 0.6']);
  });

  test('an interruption restarts the loop instead of silencing the session', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);

    // What used to end the music for good: the player is silenced by
    // something the service did not ask for, so its own `_playing` flag was
    // left true and no later call would ever resume it.
    await b.interrupt();
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'loop $kBackgroundTrack 0.6']);

    // And a settings change afterwards still works on the restarted loop
    // rather than starting a third one.
    await s.apply(_on.copyWith(musicVolume: 0.3));
    expect(b.calls.last, 'volume 0.3');
  });

  test('recovery goes through loop, not resume: a stopped player cannot resume', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    await s.apply(_on);
    await b.interrupt();
    expect(b.calls, isNot(contains('resume')));
  });

  test('a platform that keeps refusing is not asked forever', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    await s.apply(_on);
    for (var i = 0; i < kMaxMusicRecoveries + 4; i++) {
      await b.interrupt();
    }
    // The first loop, then one per allowed recovery, and no more.
    expect(
      b.calls.where((c) => c.startsWith('loop')),
      hasLength(kMaxMusicRecoveries + 1),
    );

    // A settings change or a return to the foreground gives it another go.
    await s.apply(_on);
    await b.interrupt();
    expect(
      b.calls.where((c) => c.startsWith('loop')),
      hasLength(kMaxMusicRecoveries + 3),
    );
  });

  test('an interruption while music is off or backgrounded starts nothing', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    await s.apply(_off);
    await b.interrupt();
    expect(b.calls, isEmpty);

    await s.apply(_on);
    await s.handleLifecycle(AppLifecycleState.paused);
    b.calls.clear();
    await b.interrupt();
    expect(b.calls, isEmpty);
  });

  test('without a track it does nothing', () async {
    final b = _FakeBackend();
    final s = AudioService(b);
    await s.apply(_on);
    await s.handleLifecycle(AppLifecycleState.resumed);
    expect(b.calls, isEmpty);
  });
}
