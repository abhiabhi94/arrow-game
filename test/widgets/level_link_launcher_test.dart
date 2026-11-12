import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/level_link_launcher.dart';
import 'package:arrow_game/utils/level_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// The sample board on every level, with progress as a new player's: no
/// level past the first unlocked.
List<Override> _overrides() => [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          sampleSpecFor(level),
          puzzle: samplePuzzle(),
          savedGame: ref.read(savedGameProvider.notifier).forLevel(level),
          onCleared: ref.read(progressProvider.notifier).recordCompletion,
          onSnapshot: ref.read(savedGameProvider.notifier).record,
          autoTick: false,
        ),
      ),
      progressProvider.overrideWith(
        (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: false),
      ),
      ...silentFeedback(),
    ];

final Map<String, Object> _introsSeen = <String, Object>{
  IntroRepository.key: [for (final r in ChapterRule.values) r.name],
};

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('a link opens its level over home, even one not reached yet', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const LevelLinkLauncher(level: 42, child: Text('home')),
      seed: _introsSeen,
      extraOverrides: _overrides(),
    );
    await _settle(tester);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 42'), findsOneWidget);

    // Back leads into the game, not out of it.
    await tester.tap(find.byTooltip('Back'));
    await _settle(tester);
    await _settle(tester);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the link button copies the level\'s link and says so', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    // A test is not a browser; a PR preview is.
    debugLevelLinksAnywhere = true;
    addTearDown(() => debugLevelLinksAnywhere = false);
    await usePhoneSurface(tester);
    await pumpApp(tester, const GameScreen(level: 7), seed: _introsSeen, extraOverrides: _overrides());
    await _settle(tester);

    await tester.tap(find.byTooltip('Copy a link to this level'));
    await _settle(tester);
    expect(copied, ['https://abhiabhi94.github.io/arrow-game/?level=7']);
    expect(find.text('Link to level 7 copied. Send it to a friend!'), findsOneWidget);
  });

  testWidgets('outside a preview build there is no link button', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const GameScreen(level: 7), seed: _introsSeen, extraOverrides: _overrides());
    await _settle(tester);
    expect(levelLinksOn, isFalse);
    expect(find.byTooltip('Copy a link to this level'), findsNothing);
  });

  testWidgets('the daily board has no link: it is dealt per install', (tester) async {
    debugLevelLinksAnywhere = true;
    addTearDown(() => debugLevelLinksAnywhere = false);
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const GameScreen(level: LevelSpec.dailyLevel),
      seed: _introsSeen,
      extraOverrides: _overrides(),
    );
    await _settle(tester);
    expect(find.byTooltip('Copy a link to this level'), findsNothing);
  });
}
