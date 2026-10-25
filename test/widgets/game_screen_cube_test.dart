import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/cube.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/widgets/cube_map.dart';
import 'package:arrow_game/widgets/cube_stage.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// A level on the block, past its teaching level, with every card seen.
const int _level = 60;

List<Override> _overrides() => [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          sampleCubeSpecFor(level),
          puzzle: sampleCubePuzzle(),
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

Future<ProviderContainer> _pump(WidgetTester tester) async {
  await usePhoneSurface(tester);
  final container = await pumpApp(
    tester,
    const GameScreen(level: _level),
    seed: const {
      IntroRepository.key: ['mirrors', 'locks', 'fog', 'pairs', 'cube'],
    },
    extraOverrides: _overrides(),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

/// The face on show (the only board, once the block is at rest).
int _face(WidgetTester tester) => tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).face!;

/// Lets a turn (and anything queued behind it) play out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Taps the centre of [cell] (in the face's own cells) on the face shown.
Future<void> _tapCell(WidgetTester tester, Cell cell) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint)).first;
  final rect = tester.getRect(board);
  final cs = rect.width / 4;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
}

void main() {
  testWidgets('a level on the block shows one face at a time and turns to the next', (tester) async {
    final container = await _pump(tester);
    expect(find.byType(CubeStage), findsOneWidget);
    expect(find.byType(CubeControls), findsOneWidget);
    expect(_face(tester), 0);
    expect(find.text('0 of 6 faces clear'), findsOneWidget);
    expect(find.text('3 arrows on this face'), findsOneWidget);
    // The board is the face alone: four cells across.
    expect(find.bySemanticsLabel(RegExp('^Face 1 of the block, 4 by 4, 3 of 3 arrows left')), findsOneWidget);

    await tester.tap(find.byTooltip('Turn to the face on the right'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Mid-turn both faces are drawn, and neither can be tapped.
    expect(find.byType(PuzzleBoard), findsNWidgets(2));
    await _settle(tester);
    expect(_face(tester), 1);
    expect(find.text('1 arrow on this face'), findsOneWidget);
    // Its arrow slides out by its own face's edge.
    await _tapCell(tester, const Cell(1, 1));
    final state = container.read(gameProvider(_level));
    expect(state.removed, {3});
    expect(state.mistakes, 0);
    expect(find.text('1 of 6 faces clear'), findsOneWidget);
  });

  testWidgets('a cleared face turns the block on to the next face by itself', (tester) async {
    final container = await _pump(tester);
    await _tapCell(tester, const Cell(1, 1)); // 0
    await _tapCell(tester, const Cell(3, 3)); // 1
    await _tapCell(tester, const Cell(1, 3)); // 2, which waited for 0
    expect(container.read(gameProvider(_level)).removed, {0, 1, 2});
    await tester.pump(kCubeAutoTurnDelay);
    await _settle(tester);
    expect(_face(tester), 1, reason: 'the face to the right');
    // Every face cleared, the level is.
    for (var i = 0; i < 5; i++) {
      await _tapCell(tester, const Cell(1, 1));
      await tester.pump(kCubeAutoTurnDelay);
      await _settle(tester);
    }
    expect(container.read(gameProvider(_level)).phase, GamePhase.cleared);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a hint lit on another face turns the block round to it', (tester) async {
    final container = await _pump(tester);
    // Clear face 0, then turn back to it before the block moves on.
    await _tapCell(tester, const Cell(1, 1));
    await _tapCell(tester, const Cell(3, 3));
    await _tapCell(tester, const Cell(1, 3));
    await tester.pump(kCubeAutoTurnDelay);
    await _settle(tester);
    await tester.tap(find.byTooltip('Turn to the face on the left'));
    await _settle(tester);
    expect(_face(tester), 0);
    await tester.tap(find.byTooltip(RegExp('^Hint')));
    await tester.pump();
    final hint = container.read(gameProvider(_level)).hintArrowId!;
    final puzzle = container.read(gameProvider(_level)).puzzle!;
    await _settle(tester);
    expect(_face(tester), puzzle.faceOf(hint));
  });

  testWidgets('Shift with an arrow key turns the block; a restart puts it back', (tester) async {
    await _pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await _settle(tester);
    expect(_face(tester), const CubeView().up);
    // A plain arrow key walks the cursor, on this face only.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(GameScreen)));
    final focused = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId;
    expect(container.read(gameProvider(_level)).puzzle!.faceOf(focused!), _face(tester));
    await tester.tap(find.byTooltip('Restart level'));
    await tester.pump();
    await _settle(tester);
    expect(_face(tester), 0);
  });

  test('Shift and an arrow key mean a turn that way', () {
    expect(cubeTurnFor(GameShortcut.cursorLeft), CubeTurn.left);
    expect(cubeTurnFor(GameShortcut.cursorRight), CubeTurn.right);
    expect(cubeTurnFor(GameShortcut.cursorUp), CubeTurn.up);
    expect(cubeTurnFor(GameShortcut.cursorDown), CubeTurn.down);
    expect(cubeTurnFor(GameShortcut.hint), isNull);
    expect(cubeTurnFor(null), isNull);
  });
}
