import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/providers/settings_provider.dart';
import 'package:arrow_game/screens/onboarding_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

Future<void> _settle(WidgetTester tester, int ms) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// Taps grid [cell] on the (4x3) tutorial board.
Future<void> _tapCell(WidgetTester tester, Cell cell) async {
  final board = find.descendant(of: find.byType(PuzzleBoard), matching: find.byType(CustomPaint));
  final rect = tester.getRect(board);
  final cs = rect.width / 4;
  await tester.tapAt(rect.topLeft + Offset((cell.x + 0.5) * cs, (cell.y + 0.5) * cs));
  await _settle(tester, 1000);
}

void main() {
  test('tutorial boards are what the copy says they are', () {
    final one = tutorialPuzzleOne();
    expect(one.arrowCount, 1);
    expect(one.canExit(0, const {}), isTrue);
    final two = tutorialPuzzleTwo();
    expect(two.canExit(0, const {}), isTrue);
    expect(two.canExit(1, const {}), isFalse);
    expect(two.isSolvable, isTrue);
  });

  testWidgets('walks through all three steps and marks onboarding done', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const OnboardingScreen());
    await _settle(tester, 400);
    expect(find.text('Tap an arrow'), findsOneWidget);
    // Next is disabled until the demo arrow is out.
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await _tapCell(tester, const Cell(1, 1));
    expect(find.text("That's it — one down!"), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await _settle(tester, 400);

    expect(find.text('Watch for blockers'), findsOneWidget);
    await _tapCell(tester, const Cell(2, 1)); // the blocked one
    expect(find.textContaining('Bumped!'), findsOneWidget);
    await _tapCell(tester, const Cell(2, 1));
    await _tapCell(tester, const Cell(2, 1)); // third bump: demo restarts silently
    expect(find.text('Watch for blockers'), findsOneWidget);
    await _tapCell(tester, const Cell(0, 0)); // top arrow out
    await _tapCell(tester, const Cell(2, 1)); // now free
    expect(find.text("Order matters — you've got it."), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await _settle(tester, 600);

    expect(find.text("That's the whole game"), findsOneWidget);
    expect(find.textContaining('bump costs a life'), findsOneWidget);
    expect(container.read(settingsProvider).onboardingDone, isFalse);
    await tester.tap(find.text("Let's play!"));
    await _settle(tester, 300);
    expect(container.read(settingsProvider).onboardingDone, isTrue);
  });

  testWidgets('skip marks onboarding done at once', (tester) async {
    await usePhoneSurface(tester);
    final container = await pumpApp(tester, const OnboardingScreen());
    await _settle(tester, 300);
    await tester.tap(find.text('Skip'));
    await _settle(tester, 300);
    expect(container.read(settingsProvider).onboardingDone, isTrue);
  });

  testWidgets('a replay pops back when finished', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OnboardingScreen(replay: true)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await _settle(tester, 500);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await _settle(tester, 500);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
