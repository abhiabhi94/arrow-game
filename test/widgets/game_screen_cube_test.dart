import 'dart:math';

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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// A level on the block, past its teaching level, with every card seen.
const int _level = 110;

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

/// The face being played.
int _face(WidgetTester tester) => tester.widget<CubeStage>(find.byType(CubeStage)).face;

/// Lets a turn (and anything queued behind it) play out.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Where the centre of [cell] (in its face's own cells) on [face] is drawn
/// on the screen, as the block stands now.
Offset _onScreen(WidgetTester tester, int face, Cell cell) {
  final stage = tester.state<CubeStageState>(find.byType(CubeStage));
  final cam = stage.camera;
  final cs = (cam.faceSize(face).$1 - 2 * kFacePadding) / 4;
  final (sx, sy) = cam.project(
    cam.pointOn(face, kFacePadding + (cell.x + 0.5) * cs, kFacePadding + (cell.y + 0.5) * cs),
  );
  return tester.getCenter(find.byType(CubeStage)) + Offset(sx, sy);
}

/// Taps the centre of [cell] on the face being played.
Future<void> _tapCell(WidgetTester tester, Cell cell) async {
  await tester.tapAt(_onScreen(tester, _face(tester), cell));
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

    // The whole block shows at once: the face in front, the top and a side.
    expect(find.byType(PuzzleBoard), findsNWidgets(3));
    await tester.tap(find.byTooltip('Turn to the face on the right'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Mid-turn nothing on the block can be played.
    expect(tester.state<CubeStageState>(find.byType(CubeStage)).settled, isFalse);
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
    expect(_face(tester), cubeNeighbour(0, CubeTurn.up));
    // A plain arrow key walks the cursor, on this face only.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(GameScreen)));
    final focused = tester
        .widgetList<PuzzleBoard>(find.byType(PuzzleBoard))
        .firstWhere((b) => b.face == _face(tester))
        .focusedArrowId;
    expect(container.read(gameProvider(_level)).puzzle!.faceOf(focused!), _face(tester));
    await tester.tap(find.byTooltip('Restart level'));
    await tester.pump();
    await _settle(tester);
    expect(_face(tester), 0);
  });

  testWidgets('the block stays where a drag leaves it, and the face most towards the player is played', (tester) async {
    final container = await _pump(tester);
    final centre = tester.getCenter(find.byType(CubeStage));
    // A slow drag to the left, about a quarter turn: the right face comes
    // round to the front.
    final gesture = await tester.startGesture(centre);
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(-7, 0));
      await tester.pump(const Duration(milliseconds: 40));
    }
    final held = tester.state<CubeStageState>(find.byType(CubeStage)).camera.orientation;
    await gesture.up();
    await _settle(tester);
    final stage = tester.state<CubeStageState>(find.byType(CubeStage));
    expect(_face(tester), cubeNeighbour(0, CubeTurn.right));
    // Not settled back to any pose: exactly where the finger let go.
    expect(stage.camera.orientation.distanceTo(held), closeTo(0, 1e-9));
    expect(stage.camera.orientation.distanceTo(faceOn(_face(tester))), greaterThan(1e-4));
    expect(stage.settled, isTrue);
    final lean = leanOf(held, _face(tester));
    // Pausing and resuming, and time passing, leave it where it is.
    await tester.tap(find.byTooltip('Pause'));
    await _settle(tester);
    await tester.tap(find.text('Resume'));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(stage.camera.orientation.distanceTo(held), closeTo(0, 1e-9));
    // And the face it is left on plays, as it stands.
    final played = _face(tester);
    await _tapCell(tester, const Cell(1, 1));
    expect(container.read(gameProvider(_level)).removed, {played + 2});
    // That cleared the face, and the block has turned on to the next one —
    // leaning just the way the player left it, not swung back square or to
    // the opening pose.
    await _settle(tester);
    final now = tester.state<CubeStageState>(find.byType(CubeStage)).camera;
    expect(_face(tester), isNot(played));
    expect(now.nearestFace, _face(tester));
    expect(now.orientation.distanceTo(lean * faceOn(_face(tester))), closeTo(0, 1e-6));
    expect(now.orientation.distanceTo(faceOn(_face(tester))), greaterThan(1e-4));
    expect(now.orientation.distanceTo(openingPose(_face(tester))), greaterThan(1e-4));
  });

  testWidgets('a tap on a side that shows turns the block to it, and does not play', (tester) async {
    final container = await _pump(tester);
    final top = cubeNeighbour(0, CubeTurn.up);
    await tester.tapAt(_onScreen(tester, top, const Cell(1, 1)));
    await tester.pump();
    await _settle(tester);
    expect(_face(tester), top);
    expect(container.read(gameProvider(_level)).removed, isEmpty);
    // Now it is in front, the same tap plays its arrow.
    await _tapCell(tester, const Cell(1, 1));
    expect(container.read(gameProvider(_level)).removed, {top + 2});
  });

  test('Shift and an arrow key mean a turn that way', () {
    expect(cubeTurnFor(GameShortcut.cursorLeft), CubeTurn.left);
    expect(cubeTurnFor(GameShortcut.cursorRight), CubeTurn.right);
    expect(cubeTurnFor(GameShortcut.cursorUp), CubeTurn.up);
    expect(cubeTurnFor(GameShortcut.cursorDown), CubeTurn.down);
    expect(cubeTurnFor(GameShortcut.hint), isNull);
    expect(cubeTurnFor(null), isNull);
  });

  group('a box', () {
    const level = 210;
    final spec = sampleBoxSpecFor(level);

    Future<ProviderContainer> pumpBox(WidgetTester tester) async {
      await usePhoneSurface(tester);
      final container = await pumpApp(
        tester,
        const GameScreen(level: level),
        seed: const {
          IntroRepository.key: ['mirrors', 'locks', 'fog', 'pairs', 'cube'],
        },
        extraOverrides: [
          gameProvider.overrideWith(
            (ref, level) => GameNotifier(spec, puzzle: sampleBoxPuzzle(), autoTick: false),
          ),
          progressProvider.overrideWith(
            (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider), unlockAllLevels: true),
          ),
          ...silentFeedback(),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return container;
    }

    /// Where the centre of [cell] on [face] is drawn: the face's board is
    /// its own width and height of cells, centred in the face's card.
    Offset onBox(WidgetTester tester, int face, Cell cell) {
      final cam = tester.state<CubeStageState>(find.byType(CubeStage)).camera;
      final (fw, fh) = cam.faceSize(face);
      final (w, h) = spec.faceSizeOf(face);
      final bw = fw - 2 * kFacePadding, bh = fh - 2 * kFacePadding;
      final cs = bw / w < bh / h ? bw / w : bh / h;
      final u = kFacePadding + (bw - cs * w) / 2 + (cell.x + 0.5) * cs;
      final v = kFacePadding + (bh - cs * h) / 2 + (cell.y + 0.5) * cs;
      final (sx, sy) = cam.project(cam.pointOn(face, u, v));
      return tester.getCenter(find.byType(CubeStage)) + Offset(sx, sy);
    }

    testWidgets('faces of their own sizes, the block filling the stage, and taps on the right cell', (tester) async {
      final container = await pumpBox(tester);
      final stage = tester.state<CubeStageState>(find.byType(CubeStage));
      final cam = stage.camera;
      // The front is 3 by 5, the side 4 by 5, the top 3 by 4, in cells.
      final (w0, h0) = cam.faceSize(0);
      final (w1, h1) = cam.faceSize(1);
      final (w4, h4) = cam.faceSize(4);
      expect(w0 / h0, closeTo(3 / 5, 1e-9));
      expect(w1 / h1, closeTo(4 / 5, 1e-9));
      expect(w4 / h4, closeTo(3 / 4, 1e-9));
      expect(find.bySemanticsLabel(RegExp('^Face 1 of the block, 3 by 5, 1 of 1 arrow')), findsOneWidget);
      // At rest the block fills most of the stage, and stays inside it.
      final size = tester.getSize(find.byType(CubeStage));
      final b = cam.bounds;
      expect(-b.left, lessThanOrEqualTo(size.width / 2));
      expect(b.right, lessThanOrEqualTo(size.width / 2));
      expect(-b.top, lessThanOrEqualTo(size.height / 2));
      expect(b.bottom, lessThanOrEqualTo(size.height / 2));
      expect(
        2 * max(-b.left, b.right) / size.width > 0.8 || 2 * max(-b.top, b.bottom) / size.height > 0.8,
        isTrue,
        reason: 'the block fills the stage one way or the other: $b in $size',
      );

      // An empty cell at the foot of the tall front plays nothing.
      await tester.tapAt(onBox(tester, 0, const Cell(2, 4)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(container.read(gameProvider(level)).removed, isEmpty);
      // The arrow's own cell plays it.
      await tester.tapAt(onBox(tester, 0, const Cell(1, 0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(container.read(gameProvider(level)).removed, {0});

      // The cleared front turns the block on to the deeper side by itself,
      // and its arrow is played in turn.
      await tester.pump(kCubeAutoTurnDelay);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(_face(tester), 1);
      expect(find.bySemanticsLabel(RegExp('^Face 2 of the block, 4 by 5')), findsOneWidget);
      await tester.tapAt(onBox(tester, 1, const Cell(0, 0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(container.read(gameProvider(level)).removed, {0, 1});
      expect(container.read(gameProvider(level)).mistakes, 0);
    });
  });
}
