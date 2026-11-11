import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// [rushSpec] under [level].
LevelSpec _rushAt(int level) => LevelSpec(
      level: level,
      width: rushSpec.width,
      height: rushSpec.height,
      arrows: rushSpec.arrows,
      minLength: rushSpec.minLength,
      maxLength: rushSpec.maxLength,
      timeLimitMs: rushSpec.timeLimitMs,
      drops: rushSpec.drops,
    );

Future<ProviderContainer> _pump(WidgetTester tester, int level) async {
  await usePhoneSurface(tester);
  final container = await pumpApp(
    tester,
    GameScreen(level: level),
    seed: {
      IntroRepository.key: [for (final r in ChapterRule.values) r.name],
    },
    extraOverrides: [
      gameProvider.overrideWith(
        (ref, level) => GameNotifier(
          _rushAt(level),
          puzzle: rushPuzzle(),
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
    ],
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

void main() {
  testWidgets('the Rush opens with its line under the board, and arrows land as it is played', (tester) async {
    final container = await _pump(tester, kFirstRushLevel);
    expect(find.text('New arrows appear as time goes by.'), findsOneWidget);
    expect(container.read(gameProvider(kFirstRushLevel)).phase, GamePhase.playing);
    // The keyboard's cursor on an arrow: a drop landing keeps it there.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    final screen = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
    final cursor = screen.focusedArrowId;
    container.read(gameProvider(kFirstRushLevel).notifier).tick(1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    container.read(gameProvider(kFirstRushLevel).notifier).tick(800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(gameProvider(kFirstRushLevel)).drops, 1);
    expect(tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)).focusedArrowId, cursor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Rush with blocks says so', (tester) async {
    await _pump(tester, kFirstBlocksLevel);
    expect(find.text('New arrows appear as time goes by, and blocks too.'), findsOneWidget);
  });

  for (final (level, line) in <(int, String)>[
    (kFirstCubeLevel, 'Drag the block to turn it. Play the face in front; tap a side to bring it round.'),
    (kFirstBoxLevel, 'This block is a box: its faces come in three sizes. Turn it to see each one.'),
  ]) {
    testWidgets('level $level keeps its own line under the board', (tester) async {
      await _pump(tester, level);
      expect(find.text(line), findsOneWidget);
    });
  }
}
