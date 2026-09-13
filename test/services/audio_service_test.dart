import 'package:arrow_game/models/settings.dart';
import 'package:arrow_game/services/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackend implements AudioBackend {
  final List<String> calls = <String>[];

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

  test('without a track it does nothing', () async {
    final b = _FakeBackend();
    final s = AudioService(b);
    await s.apply(_on);
    await s.handleLifecycle(AppLifecycleState.resumed);
    expect(b.calls, isEmpty);
  });
}
