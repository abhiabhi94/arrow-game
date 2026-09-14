import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('routes each cue to its impulse when enabled', () {
    final engine = RecordingHapticEngine();
    final s = HapticsService(() => true, engine: engine);
    s.tap();
    s.hit();
    s.miss();
    s.victory();
    s.fail();
    expect(engine.calls, ['selection', 'light', 'crash', 'medium', 'vibrate']);
  });

  test('stays silent when disabled', () {
    final engine = RecordingHapticEngine();
    final s = HapticsService(() => false, engine: engine);
    s.tap();
    s.hit();
    s.miss();
    s.victory();
    s.fail();
    expect(engine.calls, isEmpty);
  });

  test('the provider gates on the haptic feedback setting', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues(<String, Object>{'arrow_haptics_on': false});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kHapticsChannel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kHapticsChannel, null));

    final service = container.read(hapticsProvider);
    service.hit();
    expect(calls, isEmpty);
    container.read(settingsProvider.notifier).setHaptics(true);
    service.hit();
    expect(calls.map((c) => c.arguments), ['click']);
  });

  test('SystemHapticEngine drives the Vibrator channel on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kHapticsChannel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kHapticsChannel, null));
    const SystemHapticEngine()
      ..selection()
      ..light()
      ..medium()
      ..heavy()
      ..vibrate()
      ..crash();
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((c) => c.method).toSet(), {'vibrate'});
    expect(calls.map((c) => c.arguments).toList(), [
      'tick',
      'click',
      'click',
      'heavy',
      'long',
      'crash',
    ]);
  });

  test('SystemHapticEngine uses HapticFeedback elsewhere', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    const SystemHapticEngine()
      ..selection()
      ..light()
      ..medium()
      ..heavy()
      ..vibrate()
      ..crash();
    await Future<void>.delayed(Duration.zero);
    // The crash is a heavy hit with the long buzz behind it.
    expect(calls, hasLength(7));
    expect(calls.map((c) => c.arguments).toList(), [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      null,
      'HapticFeedbackType.heavyImpact',
      null,
    ]);
  });
}
