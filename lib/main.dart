import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'models/settings.dart';
import 'providers/app_providers.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/audio_service.dart';
import 'services/sfx_service.dart';
import 'ui/layout.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ArrowApp(),
    ),
  );
}

class ArrowApp extends ConsumerStatefulWidget {
  const ArrowApp({super.key});

  @override
  ConsumerState<ArrowApp> createState() => _ArrowAppState();
}

class _ArrowAppState extends ConsumerState<ArrowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ref.listen below only fires on a *change*, so the persisted settings
    // have to be applied once explicitly or music never starts on a cold
    // launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(audioServiceProvider).apply(ref.read(settingsProvider));
      // Build the effect players now rather than on the first tap of a
      // level: creating them is the moment the plugin gets busy, and the
      // first arrow of a level is a bad time for that.
      ref.read(sfxProvider).warmUp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep playing over a phone call, another app, or a locked screen.
    ref.read(audioServiceProvider).handleLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    // Keep background music in sync with the music/volume settings.
    ref.listen(settingsProvider, (_, next) {
      ref.read(audioServiceProvider).apply(next);
    });
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Arrow',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeModeFor(settings.themeChoice),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: settings.onboardingDone ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

/// Maps the persisted [ThemeChoice] to Flutter's [ThemeMode].
ThemeMode themeModeFor(ThemeChoice choice) => switch (choice) {
      ThemeChoice.system => ThemeMode.system,
      ThemeChoice.light => ThemeMode.light,
      ThemeChoice.dark => ThemeMode.dark,
    };
