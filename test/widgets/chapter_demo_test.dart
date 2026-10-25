import 'package:arrow_game/data/chapter_demos.dart';
import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/widgets/chapter_demo.dart';
import 'package:arrow_game/widgets/cube_stage.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  for (final rule in ChapterRule.values.where((r) => r != ChapterRule.cube)) {
    testWidgets('the ${rule.name} demo plays its script and starts over', (tester) async {
      await pumpApp(tester, Center(child: SizedBox(width: 300, child: ChapterDemoBoard(rule: rule))));
      expect(find.byType(PuzzleBoard), findsOneWidget);
      final steps = demoScriptFor(rule).length;
      // One tap a step, animations in between, then a rest and a restart:
      // nothing throws along the way, and the board is still there after.
      for (var i = 0; i < steps + 2; i++) {
        await tester.pump(kDemoStep);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$rule step $i');
      }
      await tester.pump(kDemoRest);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PuzzleBoard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the block\'s demo turns from face to face as it plays them, and starts over', (tester) async {
    await pumpApp(tester, const Center(child: SizedBox(width: 300, child: ChapterDemoBoard(rule: ChapterRule.cube))));
    expect(find.byType(CubeStage), findsOneWidget);
    final shown = <int?>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'step $i');
      for (final board in tester.widgetList<PuzzleBoard>(find.byType(PuzzleBoard))) {
        if (shown.isEmpty || shown.last != board.face) shown.add(board.face);
      }
    }
    // Round the middle of the block and back to the front.
    expect(shown.toSet(), containsAll(<int>[0, 1, 2, 3]));
    expect(shown.where((f) => f == 0).length, greaterThan(1));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(PuzzleBoard), findsOneWidget);
  });

  testWidgets('with motion reduced the demo stands still', (tester) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const Center(child: SizedBox(width: 300, child: ChapterDemoBoard(rule: ChapterRule.locks))),
      ),
    );
    await tester.pump(kDemoStep * 3);
    expect(find.byType(PuzzleBoard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
