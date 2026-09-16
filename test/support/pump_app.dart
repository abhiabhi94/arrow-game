import 'package:arrow_game/l10n/app_localizations.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:arrow_game/services/sfx_service.dart';
import 'package:arrow_game/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_haptics.dart';
import 'fake_sfx.dart';

/// Pumps [home] inside a fully-localised MaterialApp with a mock
/// SharedPreferences, returning the ProviderContainer for state assertions.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Widget home, {
  Map<String, Object> seed = const {},
  List<Override> extraOverrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  Locale? locale,
}) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  return container;
}

/// Sound and haptics with the plugins taken out: widget tests that play a
/// sound must not reach audioplayers or the vibrator channel.
List<Override> silentFeedback() => <Override>[
      sfxProvider.overrideWithValue(SfxService(() => true, backend: RecordingSfxBackend())),
      hapticsProvider.overrideWithValue(
        HapticsService(() => true, engine: RecordingHapticEngine()),
      ),
    ];

/// A tall phone surface so the whole home grid / game screen fits.
Future<void> usePhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
