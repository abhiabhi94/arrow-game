import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';
import '../support/semantics.dart';

Future<void> _pumpBoard(
  WidgetTester tester,
  GameState state, {
  ValueChanged<int>? onTap,
  int? focused,
  bool reduceMotion = false,
}) async {
  await pumpApp(
    tester,
    Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: PuzzleBoard(
          state: state,
          showGrid: true,
          onTapArrow: onTap ?? (_) {},
          focusedArrowId: focused,
          reduceMotion: reduceMotion,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a screen reader gets the board and one button per arrow', (tester) async {
    final handle = tester.ensureSemantics();
    final state = GameState.fresh(sampleSpec, samplePuzzle());
    int? tapped;
    await _pumpBoard(tester, state, onTap: (id) => tapped = id);

    expect(find.bySemanticsLabel('Puzzle board, 4 by 4, 3 of 3 arrows left'), findsOneWidget);
    final arrows = semanticsNodes(tester, RegExp(r'^Arrow pointing'));
    expect(arrows, hasLength(3));
    // In reading order: arrow 0's head is on row 2, the other two on row 3,
    // arrow 2's (column 2) before arrow 1's (column 4).
    expect(arrows.map((n) => n.label.split(',').first).toList(), [
      'Arrow pointing right',
      'Arrow pointing up',
      'Arrow pointing up',
    ]);
    expect(arrows[1].label, contains('column 2'));

    // Each node sits over its arrow's cells, is a button, and plays it.
    final node = semanticsNode(tester, RegExp(r'^Arrow pointing right'));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.hintOverrides?.onTapHint, 'Slide it out');
    final cell = tester.getRect(find.byType(CustomPaint).last).width / 4;
    expect(node.rect.width, closeTo(2 * cell, 0.01)); // (1,1)(2,1)
    expect(node.rect.height, closeTo(cell, 0.01));
    performSemanticsAction(tester, node, SemanticsAction.tap);
    expect(tapped, 0);
    handle.dispose();
  });

  testWidgets('an arrow that has left loses its node; the count follows', (tester) async {
    final handle = tester.ensureSemantics();
    final state = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(removed: {0});
    await _pumpBoard(tester, state);
    expect(find.bySemanticsLabel('Puzzle board, 4 by 4, 2 of 3 arrows left'), findsOneWidget);
    expect(semanticsNodes(tester, RegExp(r'^Arrow pointing')), hasLength(2));
    // With its blocker gone, arrow 2 now reports a clear path.
    expect(semanticsNodes(tester, RegExp(r'^Arrow pointing up, 3 cells.*Clear path')), hasLength(1));
    handle.dispose();
  });

  testWidgets('outside play the arrows are described but not playable', (tester) async {
    final handle = tester.ensureSemantics();
    int? tapped;
    final state = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(phase: GamePhase.paused);
    await _pumpBoard(tester, state, onTap: (id) => tapped = id);
    final node = semanticsNode(tester, RegExp(r'^Arrow pointing right'));
    expect(node.flagsCollection.isEnabled == Tristate.isTrue, isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(tapped, isNull);
    handle.dispose();
  });

  testWidgets('the keyboard cursor is a ring on the board and a focus to a reader', (tester) async {
    final handle = tester.ensureSemantics();
    final state = GameState.fresh(sampleSpec, samplePuzzle());
    await _pumpBoard(tester, state, focused: 2);
    final node = semanticsNode(tester, RegExp(r'^Arrow pointing up, 3'));
    expect(node.flagsCollection.isFocused == Tristate.isTrue, isTrue);
    final other = semanticsNode(tester, RegExp(r'^Arrow pointing right'));
    expect(other.flagsCollection.isFocused == Tristate.isTrue, isFalse);
    // A cursor on an arrow that has gone, or off the board, draws nothing.
    await _pumpBoard(tester, state.copyWith(removed: {2}), focused: 2);
    await _pumpBoard(tester, state, focused: 7);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('with motion reduced a bump flashes without travelling and nothing slumps',
      (tester) async {
    final state = GameState.fresh(sampleSpec, samplePuzzle());
    await _pumpBoard(tester, state, reduceMotion: true);
    // A blocked tap on arrow 2 (into arrow 0 at (1,1)).
    final bumped = state.copyWith(
      lastMoveId: 2,
      lastOutcome: MoveOutcome.blocked,
      blockedCell: const Cell(1, 1),
      moveToken: 1,
      mistakes: 3,
      phase: GamePhase.outOfLives,
    );
    await _pumpBoard(tester, bumped, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 2000));
    // The hint glow holds still too.
    await _pumpBoard(tester, state.copyWith(hintArrowId: 0), reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 1500));
    // And flipping the setting mid-level is harmless.
    await _pumpBoard(tester, state.copyWith(hintArrowId: 0), reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
