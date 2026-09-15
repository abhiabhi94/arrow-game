import 'dart:async';

import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/services/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackend implements AudioBackend {
  final List<String> calls = <String>[];

  /// When true, the next [loop] throws the way a browser's autoplay refusal
  /// can reach us through audioplayers.
  bool blockStart = false;

  /// When true, [loop] resolves normally but nothing actually plays — the
  /// other way a browser refuses, and the quieter one.
  bool silentlyRefuse = false;

  /// When true, [loop] never completes at all, as the web plugin's does
  /// while it waits for a source it is not allowed to start.
  bool hangOnStart = false;

  @override
  Future<bool> get isPlaying async => _playing;
  bool _playing = false;
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
  Future<void> loop(String asset, double volume) async {
    calls.add('loop $asset $volume');
    if (blockStart) throw Exception('NotAllowedError: needs a user gesture');
    if (hangOnStart) return Completer<void>().future;
    _playing = !silentlyRefuse;
  }
  @override
  Future<void> setVolume(double volume) async => calls.add('volume $volume');
  @override
  Future<void> resume() async {
    calls.add('resume');
    _playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing = false;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _playing = false;
  }
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

  test('a refused start is retried on the next user gesture', () async {
    final b = _FakeBackend()..blockStart = true;
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);

    // Launch: the browser refuses, and the refusal must not become an
    // unhandled error or a silent session.
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);

    // The page has now been touched, so it works.
    b.blockStart = false;
    await s.nudge();
    expect(b.calls, ['loop $kBackgroundTrack 0.6', 'loop $kBackgroundTrack 0.6']);

    // And once it is playing, further gestures cost nothing.
    await s.nudge();
    await s.nudge();
    expect(b.calls, hasLength(2));
  });

  test('a start that resolves but plays nothing is retried on a gesture', () async {
    final b = _FakeBackend()..silentlyRefuse = true;
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);

    // This is the web case: the call succeeds, so the service would happily
    // believe it is playing, and the visit would be silent from here on.
    await s.apply(_on);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);
    expect(await b.isPlaying, isFalse);

    // The page has been touched, so the player is asked again.
    b.silentlyRefuse = false;
    await s.nudge();
    expect(await b.isPlaying, isTrue);
    expect(b.calls.where((c) => c.startsWith('loop')), hasLength(2));

    // Now that it really is playing, further gestures leave it alone.
    await s.nudge();
    expect(b.calls.where((c) => c.startsWith('loop')), hasLength(2));
  });

  test('a start that never finishes does not block the next gesture', () async {
    // The web case that cost me an afternoon: the platform call to start the
    // loop simply never completes. Anything that latches for the duration of
    // that call blocks every retry for the rest of the visit.
    final b = _FakeBackend()..hangOnStart = true;
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    final launch = s.apply(_on); // deliberately not awaited: it never returns
    await Future<void>.delayed(Duration.zero);
    expect(b.calls, ['loop $kBackgroundTrack 0.6']);

    b.hangOnStart = false;
    await s.nudge();
    expect(await b.isPlaying, isTrue);
    expect(b.calls.where((c) => c.startsWith('loop')), hasLength(2));
    // ignore: unawaited_futures
    launch; // still pending, and that is fine
  });

  test('a nudge starts nothing when music is off or the app is away', () async {
    final b = _FakeBackend();
    final s = AudioService(b, trackAsset: kBackgroundTrack);
    addTearDown(s.dispose);
    await s.apply(_off);
    await s.nudge();
    expect(b.calls, isEmpty);

    await s.apply(_on);
    await s.handleLifecycle(AppLifecycleState.paused);
    b.calls.clear();
    await s.nudge();
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
