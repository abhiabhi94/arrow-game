import 'dart:async';
import 'dart:convert';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/data/riddle_bank.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/riddle.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/riddle_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/ui/colors.dart';
import 'package:arrow_game/ui/layout.dart';
import 'package:arrow_game/widgets/board_toolbar.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// Every level gets the tiny sample puzzle with the real timer off (tests
/// drive the clock through [GameNotifier.tick]).
List<Override> _overrides({bool unlockAll = true, bool blocked = false}) => [
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
        (ref) => ProgressNotifier(
          ref.watch(progressRepositoryProvider),
          unlockAllLevels: unlockAll,
        ),
      ),
      // The riddle card plays a sound and buzzes on every answer.
      ...silentFeedback(),
    ];

Future<ProviderContainer> _pumpGame(
  WidgetTester tester, {
  int level = 1,
  bool unlockAll = true,
  bool blocked = false,
  Map<String, Object> seed = const {},
  Size? surface,
}) async {
  if (surface == null) {
    await usePhoneSurface(tester);
  } else {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  final container = await pumpApp(
    tester,
    GameScreen(level: level),
    seed: seed,
    extraOverrides: _overrides(unlockAll: unlockAll, blocked: blocked),
  );
  await _settle(tester, 300);
  return container;
}

/// Pumps a frame (mounting any new widgets) and then advances the clock by
/// [ms], so animations started on mount are flushed before the test ends.
Future<void> _settle(WidgetTester tester, int ms) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// The riddle the card is showing: the last one the deck dealt.
Riddle _riddleOnScreen(ProviderContainer container) {
  final deck = container.read(riddleDeckProvider);
  return riddleFor('en', deck.order[deck.cursor - 1]);
}

/// Answers the riddle standing between the player and one more life, from
/// the ending card all the way back to the board.
Future<void> _crackRiddle(WidgetTester tester, ProviderContainer container) async {
  await tester.tap(find.text('Solve a riddle'));
  await _settle(tester, 400);
  await tester.enterText(find.byType(TextField), _riddleOnScreen(container).answer);
  await tester.tap(find.text("That's my answer"));
  await _settle(tester, 600);
  await tester.tap(find.text('Back to the arrows'));
  await _settle(tester, 400);
}

/// Taps the centre of grid [cell] on a [width]-column board.
Future<void> _tapCell(WidgetTester tester, Cell cell, {int width = 4}) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint));
  final rect = tester.getRect(board);
  final cs = rect.width / width;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await _settle(tester, 1000); // let the slide / bump animation finish
}

void main() {
  testWidgets('renders the HUD, board, toolbar and tutorial line', (tester) async {
    final container = await _pumpGame(tester);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.byType(PuzzleBoard), findsOneWidget);
    expect(find.text('Tap an arrow to slide it out the way it points.'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.byTooltip('Restart level'), findsOneWidget);
    expect(find.byTooltip('Hint · 3 hints left'), findsOneWidget);
    expect(container.read(gameProvider(1)).phase, GamePhase.playing);
  });

  testWidgets('tapping a free arrow slides it out; the last clears the level', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);

    await _tapCell(tester, const Cell(2, 1)); // arrow 0
    expect(notifier.state.removed, {0});

    await _tapCell(tester, const Cell(2, 1)); // now empty: nothing happens
    expect(notifier.state.moveToken, 1);

    await _tapCell(tester, const Cell(3, 3)); // arrow 1
    await _tapCell(tester, const Cell(0, 3)); // arrow 2 (tail cell)
    expect(notifier.state.phase, GamePhase.cleared);
    await _settle(tester, 1500);
    expect(find.text('Level cleared!'), findsOneWidget);
    expect(find.text('Flawless run — three stars!'), findsOneWidget);
    expect(find.text('New best time!'), findsOneWidget);
    expect(find.text('Next level'), findsOneWidget);
    expect(container.read(progressProvider.notifier).progressFor(1).stars, 3);

    await tester.tap(find.text('Play again'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(find.text('Level cleared!'), findsNothing);
    await _settle(tester, 3000);
  });

  testWidgets('a blocked arrow bumps and costs a life; three end the level', (tester) async {
    final container = await _pumpGame(tester, blocked: true);
    final notifier = container.read(gameProvider(1).notifier);

    // Arrows 1, 2 and 3 are each blocked by arrow 0: three separate dead
    // ends, since running into the same one twice is free.
    await _tapCell(tester, const Cell(1, 0), width: 5); // arrow 1's head
    expect(notifier.state.mistakes, 1);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('2 lives left'), findsOneWidget);

    // The same arrow again: a bump, but no life.
    await _tapCell(tester, const Cell(1, 0), width: 5);
    expect(notifier.state.mistakes, 1);
    expect(find.bySemanticsLabel('2 lives left'), findsOneWidget);

    await _tapCell(tester, const Cell(1, 1), width: 5); // arrow 2
    await _tapCell(tester, const Cell(1, 2), width: 5); // arrow 3
    expect(notifier.state.phase, GamePhase.outOfLives);
    expect(find.text('Out of lives'), findsOneWidget);

    await tester.tap(find.text('Start over'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(notifier.state.mistakes, 0);
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
  });

  testWidgets('carrying on is earned: a riddle hands the life back', (tester) async {
    final container = await _pumpGame(tester, blocked: true);
    final notifier = container.read(gameProvider(1).notifier);
    await _tapCell(tester, const Cell(1, 0), width: 5);
    await _tapCell(tester, const Cell(1, 1), width: 5);
    await _tapCell(tester, const Cell(1, 2), width: 5);
    expect(find.text('Out of lives'), findsOneWidget);

    // The ending card no longer just waves the player through.
    await tester.tap(find.text('Solve a riddle'));
    await _settle(tester, 400);
    expect(find.text('Riddle me this'), findsOneWidget);
    expect(notifier.state.phase, GamePhase.outOfLives);

    // A wrong answer is not a way back onto the board.
    await tester.enterText(find.byType(TextField), 'definitely not it');
    await tester.tap(find.text("That's my answer"));
    await _settle(tester, 600);
    expect(notifier.state.phase, GamePhase.outOfLives);
    expect(container.read(riddleDeckProvider).solved, 0);

    // The keyboard belongs to the answer field while the card is up: the h
    // of "shadow" must not spend a hint, nor its space pause the level.
    final hintsBefore = notifier.state.hintsLeft;
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _settle(tester, 100);
    expect(notifier.state.hintsLeft, hintsBefore);
    expect(notifier.state.phase, GamePhase.outOfLives);

    // Backing out goes to the ending card, not onto the board.
    await tester.tap(find.text('Never mind'));
    await _settle(tester, 400);
    expect(find.text('Out of lives'), findsOneWidget);

    await _crackRiddle(tester, container);
    expect(notifier.state.phase, GamePhase.playing);
    expect(notifier.state.continues, 1);
    expect(container.read(riddleDeckProvider).solved, 1);
    expect(find.text('Out of lives'), findsNothing);
    // No heart comes back, and the arrows already out stay out.
    expect(find.bySemanticsLabel('0 lives left'), findsOneWidget);

    // The reprieve is one mistake long: a fresh dead end asks again, and
    // asks for another riddle.
    await _tapCell(tester, const Cell(1, 3), width: 5); // arrow 4
    await _settle(tester, 1200);
    expect(find.text('Out of lives'), findsOneWidget);
    await _crackRiddle(tester, container);
    expect(notifier.state.continues, 2);
    expect(container.read(riddleDeckProvider).solved, 2);

    // Clearing from here is still a clear.
    await _tapCell(tester, const Cell(2, 0), width: 5); // arrow 0, the wall
    await _tapCell(tester, const Cell(1, 0), width: 5);
    await _tapCell(tester, const Cell(1, 1), width: 5);
    await _tapCell(tester, const Cell(1, 2), width: 5);
    await _tapCell(tester, const Cell(1, 3), width: 5);
    await _settle(tester, 1500);
    expect(notifier.state.phase, GamePhase.cleared);
    expect(container.read(progressProvider.notifier).progressFor(1).completed, isTrue);
  });

  testWidgets('the crash that spends the last life is seen before the card', (tester) async {
    final container = await _pumpGame(tester, blocked: true);
    final notifier = container.read(gameProvider(1).notifier);
    await _tapCell(tester, const Cell(1, 0), width: 5);
    await _tapCell(tester, const Cell(1, 1), width: 5);

    // The third bump ends the attempt in the same frame as the tap — but the
    // card would then cover the board before the arrow had visibly hit
    // anything, and the player would never see what cost them the level.
    final board = find.descendant(
      of: find.byType(PuzzleBoard),
      matching: find.byType(CustomPaint),
    );
    final rect = tester.getRect(board);
    final cell = rect.width / 5;
    await tester.tapAt(rect.topLeft + Offset(1.5 * cell, 2.5 * cell));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(notifier.state.phase, GamePhase.outOfLives);
    expect(find.text('Out of lives'), findsNothing);

    // Past impact (a short run hits around 210 ms) the crash is plainly on
    // screen — the red edge is up — and the card still is not.
    await tester.pump(const Duration(milliseconds: 200));
    final flash = tester.widget<Opacity>(find.byKey(const ValueKey<String>('crash-flash')));
    expect(flash.opacity, greaterThan(0));
    expect(find.text('Out of lives'), findsNothing);

    // Once it has played out, the card arrives.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Out of lives'), findsOneWidget);
    await _settle(tester, 400); // the card's own entrance
  });

  testWidgets('a second riddle is a different riddle', (tester) async {
    final container = await _pumpGame(tester, blocked: true);
    await _tapCell(tester, const Cell(1, 0), width: 5);
    await _tapCell(tester, const Cell(1, 1), width: 5);
    await _tapCell(tester, const Cell(1, 2), width: 5);
    await tester.tap(find.text('Solve a riddle'));
    await _settle(tester, 400);
    final first = _riddleOnScreen(container);

    // Two misses put a different riddle on the table.
    for (var i = 0; i < 2; i++) {
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text("That's my answer"));
      await _settle(tester, 600);
    }
    await tester.tap(find.text('Try a different riddle'));
    await _settle(tester, 400);
    expect(_riddleOnScreen(container).id, isNot(first.id));
    expect(find.text(_riddleOnScreen(container).question), findsOneWidget);
  });

  test('the zoom ceiling stretches until a cell can reach a fingertip', () {
    // Big cells keep the plain 4x ceiling.
    expect(maxZoomFor(70), kMaxZoom);
    expect(maxZoomFor(kFingerCellPx / kMaxZoom + 1), kMaxZoom);
    // A level-18 cell (12 px on a phone) needs just under 4x, so 4x stands.
    expect(maxZoomFor(12.8), closeTo(kMaxZoom, 0.001));
    // A level-40 cell is 8 px: 4x would cap it at 33 px, so the ceiling
    // stretches to bring it up to a finger.
    expect(maxZoomFor(8.3), closeTo(kFingerCellPx / 8.3, 0.001));
    expect(maxZoomFor(8.3) * 8.3, closeTo(kFingerCellPx, 0.001));
    // And never beyond a sane limit, however small the cell.
    expect(maxZoomFor(1), 8.0);
    expect(maxZoomFor(0), kMaxZoom);
  });

  group('taps the player did not mean', () {
    /// The board's rect and cell size (the sample puzzle is 4x4).
    (Rect, double) boardRect(WidgetTester tester) {
      final board = find.descendant(
        of: find.byType(PuzzleBoard),
        matching: find.byType(CustomPaint),
      );
      final rect = tester.getRect(board);
      return (rect, rect.width / 4);
    }

    testWidgets('a tap in a gap takes the arrow it was plainly aimed at', (tester) async {
      // Slop is measured to cell centres, so it only bites where a cell is
      // smaller than a fingertip: a 48 px board of 4 cells is 12 px a cell,
      // the size of a level-18 board on a phone.
      int? tapped;
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: PuzzleBoard(
              state: GameState.fresh(sampleSpec, samplePuzzle()),
              showGrid: false,
              onTapArrow: (id) => tapped = id,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(CustomPaint).last);
      // (2,0) is empty; arrow 0's head sits just below it at (2,1), 7 px from
      // this tap. A finger landing that far off still means that arrow.
      await tester.tapAt(rect.topLeft + const Offset(30, 11));
      await tester.pump();
      expect(tapped, 0);

      // A cell that *is* occupied still wins: slop never overrides a hit.
      tapped = null;
      await tester.tapAt(rect.topLeft + const Offset(6, 42)); // arrow 2's tail
      await tester.pump();
      expect(tapped, 2);
    });

    testWidgets('a tap in open space, far from every arrow, does nothing', (tester) async {
      final container = await _pumpGame(tester);
      final (rect, cs) = boardRect(tester);
      await tester.tapAt(rect.topLeft + Offset(0.5 * cs, 0.5 * cs)); // (0,0)
      await _settle(tester, 300);
      expect(container.read(gameProvider(1)).moveToken, 0);
    });

    testWidgets('a stutter while the board is still moving is dropped', (tester) async {
      final container = await _pumpGame(tester);
      final (rect, cs) = boardRect(tester);
      await tester.tapAt(rect.topLeft + Offset(2.5 * cs, 1.5 * cs)); // arrow 0
      await tester.pump(const Duration(milliseconds: 30));
      expect(container.read(gameProvider(1)).removed, {0});
      // A second tap landing while arrow 0 is still sliding: a finger
      // finishing the last move, not a new one.
      await tester.tapAt(rect.topLeft + Offset(3.5 * cs, 3.5 * cs)); // arrow 1
      await _settle(tester, 1200);
      expect(container.read(gameProvider(1)).removed, {0});
      // Once it has settled, the same tap plays.
      await tester.tapAt(rect.topLeft + Offset(3.5 * cs, 3.5 * cs));
      await _settle(tester, 1200);
      expect(container.read(gameProvider(1)).removed, {0, 1});
    });

    testWidgets('one finger of a pinch does not play an arrow', (tester) async {
      final container = await _pumpGame(tester);
      final (rect, cs) = boardRect(tester);
      final first = await tester.startGesture(rect.topLeft + Offset(2.5 * cs, 1.5 * cs));
      final second = await tester.startGesture(rect.topLeft + Offset(3.5 * cs, 3.5 * cs));
      await tester.pump(const Duration(milliseconds: 40));
      await first.up();
      await second.up();
      await _settle(tester, 600);
      expect(container.read(gameProvider(1)).moveToken, 0);

      // The same spot, one finger: plays.
      await tester.tapAt(rect.topLeft + Offset(2.5 * cs, 1.5 * cs));
      await _settle(tester, 1000);
      expect(container.read(gameProvider(1)).removed, {0});
    });
  });

  testWidgets('a bump runs into the blocker, jolts it, and springs back', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint));
    final rect = tester.getRect(board);
    final cs = rect.width / 4;
    await tester.tapAt(rect.topLeft + Offset(1.5 * cs, 2.5 * cs)); // arrow 2's head
    expect(notifier.state.mistakes, 1);
    // Mid-flight, at impact and on the way home the board keeps painting.
    // Arrow 2 runs 0.4 of a cell: 180 ms in, 480 ms back.
    final flash = find.byKey(const ValueKey<String>('crash-flash'));
    double flashOpacity() => tester.widget<Opacity>(flash).opacity;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(PuzzleBoard), findsOneWidget);
    expect(flashOpacity(), 0); // nothing until the arrow hits
    await tester.pump(const Duration(milliseconds: 130));
    expect(flashOpacity(), closeTo(1, 0.05)); // impact: the screen goes red…
    await tester.pump(const Duration(milliseconds: 150));
    expect(flashOpacity(), inExclusiveRange(0, 1)); // …and fades as it springs back
    await tester.pump(const Duration(milliseconds: 400));
    expect(flashOpacity(), 0);
    expect(notifier.state.blockedCell, const Cell(1, 1));
  });

  testWidgets('leaving mid-level saves it; coming back offers to continue', (tester) async {
    final container = await _pumpGame(tester);
    await _tapCell(tester, const Cell(2, 1)); // arrow 0 out
    container.read(gameProvider(1).notifier).tick(4000);
    // Switching away saves the moment…
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    var saved = container.read(savedGameProvider);
    expect(saved?.level, 1);
    expect(saved?.removed, [0]);
    expect(saved?.elapsedMs, 4000);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString(SavedGameRepository.key), isNotNull);
    // …and so does leaving the level.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Resume'));
    await _settle(tester, 400);
    container.read(gameProvider(1).notifier).tick(1000);
    container.read(gameProvider(1).notifier).pause();
    await _settle(tester, 400);
    await tester.tap(find.text('Quit level'));
    await tester.pumpAndSettle();
    saved = container.read(savedGameProvider);
    expect(saved?.elapsedMs, 5000);
  });

  testWidgets('a saved game opens paused on the welcome-back card; Continue picks it up', (tester) async {
    final container = await _pumpGame(
      tester,
      seed: {
        SavedGameRepository.key: jsonEncode(const {
          'level': 1,
          'seed': 1 * 7919 + 17,
          'removed': [0],
          'mistakes': 1,
          'hintsLeft': 2,
          'elapsedMs': 5000,
        }),
      },
    );
    final notifier = container.read(gameProvider(1).notifier);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('You left this level with 1 of 3 arrows out and 0:05 on the clock.'), findsOneWidget);
    expect(notifier.state.phase, GamePhase.paused);
    expect(find.text('0:25'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(notifier.state.removed, {0});
    expect(find.text('Welcome back'), findsNothing);
    // Finishing the level empties the slot.
    await _tapCell(tester, const Cell(3, 3));
    await _tapCell(tester, const Cell(0, 3));
    expect(notifier.state.phase, GamePhase.cleared);
    expect(container.read(savedGameProvider), isNull);
    await _settle(tester, 3000);
  });

  testWidgets('Start over on the welcome-back card begins the level afresh', (tester) async {
    final container = await _pumpGame(
      tester,
      seed: {
        SavedGameRepository.key: jsonEncode(const {
          'level': 1,
          'seed': 1 * 7919 + 17,
          'removed': [0],
          'mistakes': 0,
          'hintsLeft': 3,
          'elapsedMs': 5000,
        }),
      },
    );
    final notifier = container.read(gameProvider(1).notifier);
    await tester.tap(find.text('Start over'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(notifier.state.removed, isEmpty);
    expect(notifier.state.elapsedMs, 0);
    expect(container.read(savedGameProvider), isNull);
    // Home from the card leaves too.
    notifier.pause();
    await _settle(tester, 400);
    await tester.tap(find.text('Quit level'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('taps outside the board or on empty cells do nothing', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    await _tapCell(tester, const Cell(0, 0)); // empty
    expect(notifier.state.moveToken, 0);
    expect(notifier.state.mistakes, 0);
  });

  testWidgets('running out the clock shows time up with a retry', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    notifier.tick(30000);
    await _settle(tester, 400);
    expect(find.text("Time's up!"), findsOneWidget);
    expect(find.text('So close — 0 of 3 arrows out. One more go?'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
    expect(find.text('0:30'), findsOneWidget);
  });

  testWidgets('the hints-left badge stays readable on the amber in dark theme', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const GameScreen(level: 1),
      extraOverrides: _overrides(),
      themeMode: ThemeMode.dark,
    );
    await _settle(tester, 300);
    final badge = tester.widget<Text>(
      find.descendant(of: find.byType(BoardToolbar), matching: find.text('3')),
    );
    expect(badge.style?.color, ArrowPalette.dark.onAccent);
    expect(badge.style?.color, isNot(ArrowPalette.dark.textInk));
  });

  testWidgets('a showing hint keeps pinging so the eye can find it', (tester) async {
    final container = await _pumpGame(tester);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byTooltip('Hint · 3 hints left'));
    await tester.pump();
    expect(container.read(gameProvider(1)).hintArrowId, isNotNull);
    // The ring repeats, so the board keeps painting until the hint clears.
    expect(tester.hasRunningAnimations, isTrue);
    await _settle(tester, 600);
    expect(tester.hasRunningAnimations, isTrue);

    await _tapCell(tester, const Cell(2, 1)); // any tap clears the hint
    expect(container.read(gameProvider(1)).hintArrowId, isNull);
    await _settle(tester, 700);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('hints: three per level, the button rests while one shows', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    await tester.tap(find.byTooltip('Hint · 3 hints left'));
    await _settle(tester, 300);
    expect(notifier.state.hintArrowId, 0);
    expect(find.byTooltip('Hint · 2 hints left'), findsOneWidget);
    await tester.tap(find.byTooltip('Hint · 2 hints left')); // resting: ignored
    await _settle(tester, 300);
    expect(notifier.state.hintsLeft, 2);

    await _tapCell(tester, const Cell(2, 1));
    expect(notifier.state.hintArrowId, isNull);
    await tester.tap(find.byTooltip('Hint · 2 hints left'));
    await _settle(tester, 300);
    await _tapCell(tester, const Cell(3, 3));
    await tester.tap(find.byTooltip('Hint · 1 hints left'));
    await _settle(tester, 300);
    expect(find.byTooltip('Hint · No hints left'), findsOneWidget);
  });

  testWidgets('grid lines are locked until level 4 is cleared, then toggle', (tester) async {
    final container = await _pumpGame(tester, unlockAll: false);
    expect(find.byTooltip('Grid lines unlock after level 4'), findsOneWidget);
    // Locked: the setting is on by default but the button does nothing, and
    // the board draws no lattice.
    await tester.tap(find.byTooltip('Grid lines unlock after level 4'));
    await _settle(tester, 200);
    expect(container.read(settingsProvider).gridLinesOn, isTrue);
    expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).showGrid, isFalse);

    await container.read(progressProvider.notifier).recordCompletion(4, 1000, 3);
    await _settle(tester, 200);
    expect(find.byTooltip('Grid lines'), findsOneWidget);
    // Earned: it is already on, and now it toggles.
    expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).showGrid, isTrue);
    await tester.tap(find.byTooltip('Grid lines'));
    await _settle(tester, 200);
    expect(container.read(settingsProvider).gridLinesOn, isFalse);
    await tester.tap(find.byTooltip('Grid lines'));
    await _settle(tester, 200);
    expect(container.read(settingsProvider).gridLinesOn, isTrue);
  });

  testWidgets('clearing level 4 announces the grid unlock', (tester) async {
    final container = await _pumpGame(tester, level: 4, unlockAll: false);
    final notifier = container.read(gameProvider(4).notifier);
    notifier.tapArrow(0);
    notifier.tapArrow(1);
    notifier.tapArrow(2);
    await _settle(tester, 1500);
    expect(find.text('Grid lines unlocked! Find the toggle under the board.'), findsOneWidget);
  });

  testWidgets('zoom buttons scale the board within bounds', (tester) async {
    await _pumpGame(tester);
    InteractiveViewer viewer() => tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer().transformationController!.value.getMaxScaleOnAxis(), 1.0);
    expect(find.byTooltip('Zoom out'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await _settle(tester, 100);
    expect(viewer().transformationController!.value.getMaxScaleOnAxis(), closeTo(kZoomStep, 1e-6));

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Zoom in'));
      await _settle(tester, 50);
    }
    expect(viewer().transformationController!.value.getMaxScaleOnAxis(), closeTo(kMaxZoom, 1e-6));

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Zoom out'));
      await _settle(tester, 50);
    }
    expect(viewer().transformationController!.value.getMaxScaleOnAxis(), closeTo(kMinZoom, 1e-6));
  });

  testWidgets('pinch-zooming updates the zoom buttons', (tester) async {
    await _pumpGame(tester);
    final viewer = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewer);
    final g1 = await tester.startGesture(center - const Offset(20, 0));
    final g2 = await tester.startGesture(center + const Offset(20, 0));
    await tester.pump();
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await tester.pump();
    await g1.up();
    await g2.up();
    await _settle(tester, 100);
    final scale = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale, greaterThan(1.0));
  });

  testWidgets('restart button starts the same puzzle over', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    notifier.tick(5000);
    notifier.tapArrow(0);
    await _settle(tester, 200);
    await tester.tap(find.byTooltip('Restart level'));
    await _settle(tester, 400);
    expect(notifier.state.elapsedMs, 0);
    expect(notifier.state.removed, isEmpty);
  });

  testWidgets('pause overlay freezes play; resume and quit work', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    await tester.tap(find.byTooltip('Pause'));
    await _settle(tester, 400);
    expect(find.text('Paused'), findsOneWidget);
    expect(notifier.state.phase, GamePhase.paused);
    await tester.tap(find.text('Resume'));
    await _settle(tester, 400);
    expect(notifier.state.phase, GamePhase.playing);
  });

  testWidgets('backgrounding the app pauses the game; quit leaves', (tester) async {
    final container = await _pumpGame(tester);
    final notifier = container.read(gameProvider(1).notifier);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(notifier.state.phase, GamePhase.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(notifier.state.phase, GamePhase.paused);
    await tester.tap(find.text('Quit level'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('the last level has no Next button and a finale message', (tester) async {
    final container = await _pumpGame(tester, level: totalLevels);
    final notifier = container.read(gameProvider(totalLevels).notifier);
    notifier.tapArrow(0);
    notifier.tapArrow(1);
    notifier.tapArrow(2);
    await _settle(tester, 1500);
    expect(find.text('Next level'), findsNothing);
    expect(find.text('You beat every level. Legend!'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('Next level replaces the screen with the following level', (tester) async {
    final container = await _pumpGame(tester, level: 2);
    final notifier = container.read(gameProvider(2).notifier);
    notifier.tapArrow(2); // one slip → two stars
    notifier.tapArrow(0);
    notifier.tapArrow(1);
    notifier.tapArrow(2);
    await _settle(tester, 1500);
    expect(find.text('Nice! One slip, two stars.'), findsOneWidget);
    await tester.tap(find.text('Next level'));
    await tester.pumpAndSettle();
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Tight Corners'), findsOneWidget);
  });

  testWidgets('two slips still clear with one star', (tester) async {
    final container = await _pumpGame(tester, level: 3, blocked: true);
    final notifier = container.read(gameProvider(3).notifier);
    notifier.tapArrow(1); // blocked
    notifier.tapArrow(2); // blocked, a different dead end
    notifier.tapArrow(0);
    notifier.tapArrow(1);
    notifier.tapArrow(2);
    notifier.tapArrow(3);
    notifier.tapArrow(4);
    await _settle(tester, 1500);
    expect(find.text('Made it! Fewer slips next time for more stars.'), findsOneWidget);
    expect(find.text('Tap an arrow to slide it out the way it points.'), findsNothing);
  });

  testWidgets('dark theme renders the board with grid lines on', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const GameScreen(level: totalLevels),
      seed: <String, Object>{'arrow_grid_lines': true},
      extraOverrides: _overrides(),
      themeMode: ThemeMode.dark,
    );
    await _settle(tester, 300);
    expect(find.text('Beyond the Edge'), findsOneWidget);
    expect(find.byType(PuzzleBoard), findsOneWidget);
  });

  testWidgets('shows a loading view until the board arrives', (tester) async {
    final completer = Completer<Puzzle>();
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const GameScreen(level: 1),
      extraOverrides: [
        gameProvider.overrideWith(
          (ref, level) => GameNotifier(
            sampleSpecFor(level),
            builder: (_) => completer.future,
            autoTick: false,
          ),
        ),
      ],
    );
    await _settle(tester, 100);
    expect(find.text('Laying out the arrows…'), findsOneWidget);
    expect(find.byType(PuzzleBoard), findsNothing);
    expect(find.byTooltip('Pause'), findsNothing);

    completer.complete(samplePuzzle());
    await _settle(tester, 300);
    expect(find.byType(PuzzleBoard), findsOneWidget);
    expect(find.text('Laying out the arrows…'), findsNothing);
  });

  testWidgets('the real level puzzle renders too', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const GameScreen(level: 7),
      extraOverrides: [
        gameProvider.overrideWith(
          (ref, level) => GameNotifier(
            specForLevel(level),
            puzzle: puzzleForLevel(specForLevel(level)),
            autoTick: false,
          ),
        ),
      ],
    );
    await _settle(tester, 300);
    expect(find.text('Knot'), findsOneWidget);
    expect(find.text('Level 7'), findsOneWidget);
  });

  group('keyboard shortcuts (web build on a laptop)', () {
    double scale(WidgetTester tester) => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    testWidgets('H asks for a hint', (tester) async {
      final container = await _pumpGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await _settle(tester, 100);
      expect(container.read(gameProvider(1)).hintArrowId, isNotNull);
      expect(container.read(gameProvider(1)).hintsLeft, 2);
      // A second press while the hint still shows spends nothing more.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await _settle(tester, 100);
      expect(container.read(gameProvider(1)).hintsLeft, 2);
    });

    testWidgets('+ and - zoom the board within bounds', (tester) async {
      await _pumpGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await _settle(tester, 50);
      expect(scale(tester), closeTo(kZoomStep, 1e-6));
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await _settle(tester, 50);
      expect(scale(tester), closeTo(kZoomStep * kZoomStep, 1e-6));
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.minus);
        await _settle(tester, 50);
      }
      expect(scale(tester), closeTo(kMinZoom, 1e-6));
    });

    testWidgets('space pauses and resumes; P too', (tester) async {
      final container = await _pumpGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester, 300);
      expect(container.read(gameProvider(1)).phase, GamePhase.paused);
      expect(find.text('Paused'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await _settle(tester, 300);
      expect(container.read(gameProvider(1)).phase, GamePhase.playing);
      expect(find.text('Paused'), findsNothing);
    });

    testWidgets('space is Continue on the Welcome back card', (tester) async {
      final container = await _pumpGame(
        tester,
        seed: <String, Object>{
          'arrow_saved_game': jsonEncode({
            'level': 1,
            'seed': 1 * 7919 + 17,
            'removed': [0],
            'mistakes': 0,
            'hintsLeft': 3,
            'elapsedMs': 5000,
          }),
        },
      );
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester, 300);
      expect(container.read(gameProvider(1)).phase, GamePhase.playing);
      expect(container.read(gameProvider(1)).removed, {0});
    });

    testWidgets('G toggles the grid lines once earned, never before', (tester) async {
      final container = await _pumpGame(tester, unlockAll: false);
      // Locked: G changes nothing, so the default stays as it is.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await _settle(tester, 100);
      expect(container.read(settingsProvider).gridLinesOn, isTrue);

      await container.read(progressProvider.notifier).recordCompletion(4, 1000, 3);
      await _settle(tester, 100);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await _settle(tester, 100);
      expect(container.read(settingsProvider).gridLinesOn, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await _settle(tester, 100);
      expect(container.read(settingsProvider).gridLinesOn, isTrue);
    });

    testWidgets('a shortcut with a modifier is left to the browser', (tester) async {
      final container = await _pumpGame(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await _settle(tester, 100);
      expect(container.read(gameProvider(1)).hintsLeft, 3);
      expect(scale(tester), 1.0);
    });

    testWidgets('an unrelated key does nothing', (tester) async {
      final container = await _pumpGame(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await _settle(tester, 100);
      expect(container.read(gameProvider(1)).phase, GamePhase.playing);
      expect(container.read(gameProvider(1)).hintsLeft, 3);
    });

    test('shortcutFor maps both keyboard rows', () {
      KeyEvent press(LogicalKeyboardKey key) => KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyA,
            logicalKey: key,
            timeStamp: Duration.zero,
          );
      expect(shortcutFor(press(LogicalKeyboardKey.add)), GameShortcut.zoomIn);
      expect(shortcutFor(press(LogicalKeyboardKey.numpadSubtract)), GameShortcut.zoomOut);
      expect(shortcutFor(press(LogicalKeyboardKey.keyA)), isNull);
    });
  });

  group('desktop-sized window', () {
    testWidgets('keeps the play column phone-wide and centred', (tester) async {
      await _pumpGame(tester, surface: const Size(1440, 900));
      expect(tester.takeException(), isNull);
      final toolbar = tester.getRect(find.byType(BoardToolbar));
      expect(toolbar.width, lessThanOrEqualTo(kMaxContentWidth));
      expect(toolbar.center.dx, closeTo(720, 1));
      final board = tester.getRect(find.byType(PuzzleBoard));
      expect(board.center.dx, closeTo(720, 1));
      expect(board.width, lessThanOrEqualTo(kMaxContentWidth));
      expect(find.byTooltip('Hint · 3 hints left'), findsOneWidget);
    });

    testWidgets('a squat window still shows the whole board and toolbar', (tester) async {
      await _pumpGame(tester, surface: const Size(1280, 600));
      expect(tester.takeException(), isNull);
      final board = tester.getRect(find.byType(PuzzleBoard));
      final toolbar = tester.getRect(find.byType(BoardToolbar));
      expect(board.bottom, lessThanOrEqualTo(toolbar.top));
      expect(toolbar.bottom, lessThanOrEqualTo(600));
    });
  });
}
