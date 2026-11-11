import 'package:arrow_game/engine/drops.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// Pumps the board in a [StatefulBuilder] so a test can push new states
/// through it.
Future<void Function(GameState)> _pumpBoard(WidgetTester tester, GameState initial, {bool reduceMotion = false}) async {
  var state = initial;
  late StateSetter setter;
  await pumpApp(
    tester,
    Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return PuzzleBoard(state: state, showGrid: true, onTapArrow: (_) {}, reduceMotion: reduceMotion);
          },
        ),
      ),
    ),
  );
  return (next) => setter(() => state = next);
}

void main() {
  testWidgets('a drop pops its arrows and blocks in, and the board at rest keeps them', (tester) async {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    addTearDown(n.dispose);
    final push = await _pumpBoard(tester, n.state);
    n.tick(rushSpec.drops!.everyMs);
    expect(n.state.drops, 1);
    boardPaintCounts.clear();
    push(n.state);
    await tester.pump();
    // Mid-arrival the moving layer draws every frame.
    await tester.pump(const Duration(milliseconds: kArriveMs ~/ 2));
    expect(boardPaintCounts[BoardLayer.moving] ?? 0, greaterThan(0));
    await tester.pump(const Duration(milliseconds: kArriveMs));
    await tester.pump();
    // Settled: nothing left moving, nothing thrown.
    boardPaintCounts.clear();
    await tester.pump(const Duration(milliseconds: 100));
    expect(boardPaintCounts[BoardLayer.moving] ?? 0, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a drop landing mid-slide does not cut the slide short', (tester) async {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    addTearDown(n.dispose);
    final push = await _pumpBoard(tester, n.state);
    // The tap that leaves three arrows brings a drop at once: one state
    // that is both a move and a grown board.
    n.tapArrow(0);
    expect(n.state.drops, 1);
    expect(n.state.lastOutcome, MoveOutcome.exited);
    push(n.state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final board = tester.state<PuzzleBoardState>(find.byType(PuzzleBoard));
    expect(board.mounted, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('with motion reduced a drop is simply there', (tester) async {
    final n = GameNotifier(rushSpec, puzzle: rushPuzzle(), autoTick: false);
    addTearDown(n.dispose);
    final push = await _pumpBoard(tester, n.state, reduceMotion: true);
    n.tick(rushSpec.drops!.everyMs);
    push(n.state);
    await tester.pump();
    boardPaintCounts.clear();
    await tester.pump(const Duration(milliseconds: 100));
    expect(boardPaintCounts[BoardLayer.moving] ?? 0, 0);
    // And a restart after it is a fresh board again.
    n.restart();
    push(n.state);
    await tester.pump();
    expect(n.state.drops, 0);
    expect(tester.takeException(), isNull);
  });

  test('drops are planned from a seed of the level and the drop', () {
    expect(dropRandom(rushSpec, 0).nextInt(1 << 30), dropRandom(rushSpec, 0).nextInt(1 << 30));
    expect(dropRandom(rushSpec, 0).nextInt(1 << 30), isNot(dropRandom(rushSpec, 1).nextInt(1 << 30)));
  });
}
