/// Flutter's own accessibility guidelines, run over every screen: tap targets
/// at least 48x48 (Android) and 44x44 (iOS), every tappable node labelled,
/// and rendered text at WCAG contrast. This is the part of the audit CI can
/// repeat on every change; the behaviours (what a reader hears, the keyboard,
/// a large font) live in `test/widgets/accessibility_test.dart`.
library;

import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/credits_screen.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/home_screen.dart';
import 'package:arrow_game/screens/onboarding_screen.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// Every guideline a screen has to meet, in both themes.
Future<void> _meetsAll(WidgetTester tester, String screen) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: screen);
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline), reason: screen);
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: screen);
  await expectLater(tester, meetsGuideline(textContrastGuideline), reason: screen);
}

List<Override> _game({bool blocked = false}) => [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          blocked ? blockedSpecFor(level) : sampleSpecFor(level),
          puzzle: blocked ? blockedPuzzle() : samplePuzzle(),
          savedGame: ref.read(savedGameProvider.notifier).forLevel(level),
          onCleared: ref.read(progressProvider.notifier).recordCompletion,
          onSnapshot: ref.read(savedGameProvider.notifier).record,
          autoTick: false,
        ),
      ),
      progressProvider.overrideWith(
        (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: true),
      ),
      ...silentFeedback(),
    ];

/// Mounts, lets flutter_animate's entrances start, and runs them out.
Future<void> _settle(WidgetTester tester, [int ms = 1500]) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> _tapCell(WidgetTester tester, Cell cell, {int width = 4}) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint)).first;
  final rect = tester.getRect(board);
  final cs = rect.width / width;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await _settle(tester, 1200);
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme = mode.name;

    testWidgets('home meets the guidelines ($theme)', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(
        tester,
        const HomeScreen(),
        themeMode: mode,
        seed: <String, Object>{
          'arrow_level_1_done': true,
          'arrow_level_1_stars': 2,
          'arrow_level_1_best': 21000,
          'arrow_level_1_count': 1,
        },
        extraOverrides: [
          progressProvider.overrideWith(
            (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: false),
          ),
        ],
      );
      await _settle(tester);
      await _meetsAll(tester, 'home');
      handle.dispose();
    });

    testWidgets('the game screen meets the guidelines in every phase ($theme)', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      final container = await pumpApp(
        tester,
        const GameScreen(level: 1),
        themeMode: mode,
        extraOverrides: _game(blocked: true),
      );
      await _settle(tester);
      await _meetsAll(tester, 'game, playing');

      final notifier = container.read(gameProvider(1).notifier);
      notifier.useHint();
      await _settle(tester);
      await _meetsAll(tester, 'game, hint showing');

      notifier.pause();
      await _settle(tester);
      await _meetsAll(tester, 'game, paused');
      notifier.resume();
      await _settle(tester);

      // Three dead ends: the ending card, then the riddle over it.
      await _tapCell(tester, const Cell(1, 0), width: 5);
      await _tapCell(tester, const Cell(1, 1), width: 5);
      await _tapCell(tester, const Cell(1, 2), width: 5);
      await _settle(tester);
      expect(find.text('Out of lives'), findsOneWidget);
      await _meetsAll(tester, 'game, out of lives');

      await tester.tap(find.text('Solve a riddle'));
      await _settle(tester);
      await _meetsAll(tester, 'game, riddle');
      await tester.tap(find.text('Give me a hint'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text("That's my answer"));
      await _settle(tester);
      await _meetsAll(tester, 'game, riddle with a hint and a wrong answer');
      handle.dispose();
    });

    testWidgets('a cleared level meets the guidelines ($theme)', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(tester, const GameScreen(level: 1), themeMode: mode, extraOverrides: _game());
      await _settle(tester);
      await _tapCell(tester, const Cell(2, 1));
      await _tapCell(tester, const Cell(3, 3));
      await _tapCell(tester, const Cell(0, 3));
      await _settle(tester, 3000);
      expect(find.text('Level cleared!'), findsOneWidget);
      await _meetsAll(tester, 'game, cleared');
      handle.dispose();
    });

    testWidgets('settings and credits meet the guidelines ($theme)', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(tester, const SettingsScreen(), themeMode: mode);
      await _settle(tester);
      await _meetsAll(tester, 'settings');
      await tester.scrollUntilVisible(find.text('Reset progress'), 200);
      await _settle(tester);
      await _meetsAll(tester, 'settings, scrolled');
      await pumpApp(tester, const CreditsScreen(), themeMode: mode);
      await _settle(tester);
      await _meetsAll(tester, 'credits');
      handle.dispose();
    });

    testWidgets('the walkthrough meets the guidelines ($theme)', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(tester, const OnboardingScreen(), themeMode: mode);
      await _settle(tester);
      await _meetsAll(tester, 'walkthrough, step 1');
      // The summary step: five rules and the start button.
      await tester.tap(find.text('Skip'));
      await _settle(tester);
      handle.dispose();
    });
  }
}
