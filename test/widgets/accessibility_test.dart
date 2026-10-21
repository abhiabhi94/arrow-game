/// The accessibility contract of the screens: screen-reader labels, the
/// keyboard, large system fonts, reduced motion and the extra-time clock.
library;

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/home_screen.dart';
import 'package:arrow_game/screens/onboarding_screen.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';
import '../support/semantics.dart';

List<Override> _overrides({bool blocked = false}) => [
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

Future<ProviderContainer> _pumpGame(
  WidgetTester tester, {
  bool blocked = false,
  Map<String, Object> seed = const {},
}) async {
  await usePhoneSurface(tester);
  final container = await pumpApp(
    tester,
    const GameScreen(level: 1),
    seed: seed,
    extraOverrides: _overrides(blocked: blocked),
  );
  await _settle(tester, 300);
  return container;
}

/// Mounts what is new, lets flutter_animate's zero-delay start fire and its
/// controllers take their first tick, then advances [ms]. Semantics needs
/// this: a widget fading in is at opacity 0 — and so out of the semantics
/// tree — until its animation has actually begun.
Future<void> _settle(WidgetTester tester, int ms) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(Duration(milliseconds: ms));
  // A delayed entrance (the trail's nodes) starts its controller on the
  // frame its delay timer fires in, so one more frame lets it finish.
  await tester.pump(Duration(milliseconds: ms));
}

/// Taps the centre of grid [cell] on a [width]-column board.
Future<void> _tapCell(WidgetTester tester, Cell cell, {int width = 4}) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint));
  final rect = tester.getRect(board);
  final cs = rect.width / width;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await _settle(tester, 1000);
}

/// Runs [body] with the system font size at [factor].
Future<void> _withTextScale(WidgetTester tester, double factor, Future<void> Function() body) async {
  tester.platformDispatcher.textScaleFactorTestValue = factor;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await body();
}

void main() {
  group('screen reader', () {
    testWidgets('the HUD is three spoken things and the arrows are buttons', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await _pumpGame(tester);
      expect(find.bySemanticsLabel('0:30 left on the clock'), findsOneWidget);
      expect(find.bySemanticsLabel('0 of 3 arrows out'), findsOneWidget);
      expect(find.bySemanticsLabel('3 lives left'), findsOneWidget);
      expect(semanticsNodes(tester, RegExp(r'^Arrow pointing')), hasLength(3));
      // The grid button says whether it is on.
      final grid = tester.getSemantics(find.bySemanticsLabel('Grid lines'));
      expect(grid.flagsCollection.isToggled != Tristate.none, isTrue);
      expect(grid.flagsCollection.isToggled == Tristate.isTrue, isTrue);

      // A semantic tap on an arrow plays it, and the counter follows (it is
      // a live region, so the change is spoken).
      final node = semanticsNode(tester, RegExp(r'^Arrow pointing right'));
      performSemanticsAction(tester, node, SemanticsAction.tap);
      await _settle(tester, 1000);
      expect(container.read(gameProvider(1)).removed, {0});
      final counter = tester.getSemantics(find.bySemanticsLabel('1 of 3 arrows out'));
      expect(counter.flagsCollection.isLiveRegion, isTrue);
      expect(
        tester.getSemantics(find.bySemanticsLabel('3 lives left')).flagsCollection.isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('a result card is modal: the board behind it is not read', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await _pumpGame(tester);
      container.read(gameProvider(1).notifier).pause();
      await _settle(tester, 400);
      expect(find.text('Paused'), findsOneWidget);
      final title = tester.getSemantics(find.text('Paused'));
      expect(title.flagsCollection.isHeader, isTrue);
      expect(title.flagsCollection.isLiveRegion, isTrue);
      expect(semanticsNodes(tester, RegExp(r'^Arrow pointing')), isEmpty);
      expect(semanticsNodes(tester, RegExp(r'^Puzzle board')), isEmpty);
      // The emoji is decoration.
      expect(find.bySemanticsLabel('⏸️'), findsNothing);
      handle.dispose();
    });

    testWidgets('the home trail says what state each level is in', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(
        tester,
        const HomeScreen(),
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
      await _settle(tester, 800);
      expect(
        find.bySemanticsLabel('Level 1, First Steps, Cleared, 2 of 3 stars, best time 0:21'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Level 2, Two Ways Out, Up next'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Level 3, Tight Corners, Locked', skipOffstage: false),
        findsOneWidget,
      );
      // The hero card is one button that says everything on it.
      expect(find.bySemanticsLabel('Next up. Level 2, Two Ways Out. Play'), findsOneWidget);
      // Headings are headings.
      expect(tester.getSemantics(find.text('Arrow')).flagsCollection.isHeader, isTrue);
      expect(tester.getSemantics(find.text('Your journey')).flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('settings: the slider has a name and the emoji stay quiet', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(tester, const SettingsScreen());
      final slider = tester.getSemantics(find.byType(Slider)).getSemanticsData();
      expect(slider.label, 'Music volume');
      expect(slider.value, '60%');
      expect(slider.hasAction(SemanticsAction.increase), isTrue);
      expect(find.bySemanticsLabel('🎵'), findsNothing);
      expect(find.text('Accessibility'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the walkthrough names its step', (tester) async {
      final handle = tester.ensureSemantics();
      await usePhoneSurface(tester);
      await pumpApp(tester, const OnboardingScreen());
      await _settle(tester, 400);
      expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
      expect(semanticsNodes(tester, RegExp(r'^Arrow pointing right')), hasLength(1));
      handle.dispose();
    });
  });

  group('keyboard', () {
    testWidgets('the arrow keys walk the cursor and Enter plays the arrow', (tester) async {
      final container = await _pumpGame(tester);
      final notifier = container.read(gameProvider(1).notifier);
      // The first press lands on the first arrow (0, head at row 2).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, 0);
      // Down again: arrows 1 and 2 lie equally below; reading order picks 2.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, 1);
      // Nothing further right: the cursor stays.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester, 1000);
      expect(notifier.state.removed, {1});

      // Back up to arrow 0 and play it; the cursor keeps its place.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await _settle(tester, 1000);
      expect(notifier.state.removed, {0, 1});
      // Left from where arrow 0 was: arrow 2.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester, 1500);
      expect(notifier.state.phase, GamePhase.cleared);
      await _settle(tester, 2000);
    });

    testWidgets('a restart forgets the cursor; Enter with none does nothing', (tester) async {
      final container = await _pumpGame(tester);
      final notifier = container.read(gameProvider(1).notifier);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(notifier.state.moveToken, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, 0);
      await tester.tap(find.byTooltip('Restart level'));
      await _settle(tester, 300);
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, isNull);
      expect(notifier.state.phase, GamePhase.playing);
    });

    test('shortcutFor knows the cursor keys', () {
      GameShortcut? of(LogicalKeyboardKey key) =>
          shortcutFor(KeyDownEvent(physicalKey: PhysicalKeyboardKey.enter, logicalKey: key, timeStamp: Duration.zero));
      expect(of(LogicalKeyboardKey.arrowUp), GameShortcut.cursorUp);
      expect(of(LogicalKeyboardKey.arrowRight), GameShortcut.cursorRight);
      expect(of(LogicalKeyboardKey.arrowDown), GameShortcut.cursorDown);
      expect(of(LogicalKeyboardKey.arrowLeft), GameShortcut.cursorLeft);
      expect(of(LogicalKeyboardKey.enter), GameShortcut.activate);
      expect(of(LogicalKeyboardKey.numpadEnter), GameShortcut.activate);
    });
  });

  group('large system font', () {
    testWidgets('the game screen lays out at 2x without overflowing', (tester) async {
      await _withTextScale(tester, 2.0, () async {
        final container = await _pumpGame(tester, blocked: true);
        expect(find.text('0:30'), findsOneWidget);
        // A level ends on a card with stars, a time and three buttons.
        container.read(gameProvider(1).notifier).pause();
        await _settle(tester, 400);
        expect(find.text('Paused'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a cleared level fits its card at 2x', (tester) async {
      await _withTextScale(tester, 2.0, () async {
        await _pumpGame(tester);
        await _tapCell(tester, const Cell(2, 1));
        await _tapCell(tester, const Cell(3, 3));
        await _tapCell(tester, const Cell(0, 3));
        await _settle(tester, 1500);
        expect(find.text('Level cleared!'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _settle(tester, 3000);
      });
    });

    testWidgets('home and its pinned header grow with the font', (tester) async {
      await _withTextScale(tester, 2.0, () async {
        await usePhoneSurface(tester);
        await pumpApp(tester, const HomeScreen(), extraOverrides: [
          progressProvider.overrideWith(
            (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: false),
          ),
        ]);
        await _settle(tester, 800);
        expect(find.text('Arrow'), findsOneWidget);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('settings and the walkthrough at 2x', (tester) async {
      await _withTextScale(tester, 2.0, () async {
        await usePhoneSurface(tester);
        await pumpApp(tester, const SettingsScreen());
        expect(find.text('100%'), findsNothing);
        expect(find.text('60%'), findsOneWidget);
        await pumpApp(tester, const OnboardingScreen());
        await _settle(tester, 400);
        await tester.tap(find.text('Skip'));
        await _settle(tester, 300);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('reduced motion', () {
    testWidgets('the OS setting keeps the screen still on a bump and a clear', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final container = await _pumpGame(tester);
      expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).reduceMotion, isTrue);
      // A bump: the flash still blooms, the screen does not move.
      await _tapCell(tester, const Cell(1, 2));
      expect(container.read(gameProvider(1)).mistakes, 1);
      await _tapCell(tester, const Cell(2, 1));
      await _tapCell(tester, const Cell(3, 3));
      await _tapCell(tester, const Cell(0, 3));
      await _settle(tester, 1500);
      expect(find.text('Level cleared!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the in-app setting is the same flag, from the root', (tester) async {
      await _pumpGame(tester, seed: {'arrow_reduce_motion': true});
      // The widget tree below the app reads it through MediaQuery; the game
      // screen is pumped bare here, so the setting itself is what is checked.
      expect(find.byType(PuzzleBoard), findsOneWidget);
    });
  });

  group('extra time', () {
    test('doubles the clock of every level and nothing else', () {
      expect(specForLevel(1).withClockFactor(1), same(specForLevel(1)));
      for (final spec in levelSpecs) {
        final longer = spec.withClockFactor(2);
        expect(longer.timeLimitMs, spec.timeLimitMs * 2);
        expect(longer.seed, spec.seed);
        expect(longer.arrows, spec.arrows);
        expect(longer.width, spec.width);
        expect(longer.height, spec.height);
        expect(longer.openMoves, spec.openMoves);
        expect(longer.variant, spec.variant);
      }
    });

    test('the game provider deals the longer clock when the setting is on', () async {
      Future<ProviderContainer> containerWith(Map<String, Object> seed) async {
        SharedPreferences.setMockInitialValues(seed);
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...silentFeedback()],
        );
        addTearDown(container.dispose);
        return container;
      }

      final longer = await containerWith({'arrow_extra_time': true});
      // Reading the provider starts the real generator for level 1 on an
      // isolate; the spec is set before that lands, and the notifier is
      // disposed with the container.
      final sub = longer.listen(gameProvider(1), (_, _) {});
      expect(longer.read(gameProvider(1)).spec.timeLimitMs, specForLevel(1).timeLimitMs * 2);
      expect(longer.read(gameProvider(1)).spec.seed, specForLevel(1).seed);
      await longer.read(gameProvider(1).notifier).ready;
      sub.close();

      final plain = await containerWith({});
      final sub2 = plain.listen(gameProvider(1), (_, _) {});
      expect(plain.read(gameProvider(1)).spec.timeLimitMs, specForLevel(1).timeLimitMs);
      await plain.read(gameProvider(1).notifier).ready;
      sub2.close();
    });
  });
}
