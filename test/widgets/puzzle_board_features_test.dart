import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/l10n/app_localizations.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/widgets/board_semantics.dart';
import 'package:arrow_game/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';
import '../support/semantics.dart';

/// Pumps the board in a [StatefulBuilder] so a test can push new states
/// through it (and so start the slide and bump animations).
Future<void Function(GameState)> _pumpBoard(
  WidgetTester tester,
  GameState initial, {
  bool reduceMotion = false,
  ThemeMode themeMode = ThemeMode.light,
  VoidCallback? onBounce,
}) async {
  var state = initial;
  late StateSetter setter;
  await pumpApp(
    tester,
    Center(
      child: SizedBox(
        width: 240,
        height: 200,
        child: StatefulBuilder(
          builder: (context, setState) {
            setter = setState;
            return PuzzleBoard(
              state: state,
              showGrid: true,
              onTapArrow: (_) {},
              onBounce: onBounce,
              reduceMotion: reduceMotion,
            );
          },
        ),
      ),
    ),
    themeMode: themeMode,
  );
  return (next) => setter(() => state = next);
}

void main() {
  testWidgets('draws a board with every twist in both themes', (tester) async {
    for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final state = GameState.fresh(featureSpecFor(1), featurePuzzle());
      await _pumpBoard(tester, state, themeMode: mode);
      expect(find.byType(PuzzleBoard), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a reader hears the lock, the key, the tether and the hidden head', (tester) async {
    final handle = tester.ensureSemantics();
    final state = GameState.fresh(featureSpecFor(1), featurePuzzle());
    await _pumpBoard(tester, state);
    final labels = semanticsNodes(tester, RegExp(r'^Arrow')).map((n) => n.label).toList();
    expect(labels, hasLength(5));
    expect(labels, contains(contains('Key 1: it opens lock 1.')));
    expect(labels, contains(contains('Lock 1: it also waits for key 1 to leave.')));
    // The locked arrow's way out turns at the mirror, and a reader hears so.
    expect(labels, contains(contains('Clear path to the edge. Its path bounces off a mirror. Lock 1')));
    expect(labels.where((l) => l.contains('bounces')), hasLength(1));
    expect(labels.where((l) => l.contains('Tethered to another arrow')), hasLength(2));
    // The hidden one gives away neither its direction nor its path.
    final hidden = labels.singleWhere((l) => l.startsWith('Arrow with a hidden head'));
    expect(
      hidden,
      'Arrow with a hidden head, 2 cells long, from row 5, column 5. Which way it points shows once an arrow beside it leaves. '
      'Tapping it costs nothing: the board points at the arrow that uncovers it.',
    );
    expect(hidden, isNot(contains('pointing')));
    expect(labels, contains(contains('Clear path to the edge.')));
    handle.dispose();
  });

  testWidgets('once the key has left the lock reads as open; a lit hidden head reads normally', (tester) async {
    final handle = tester.ensureSemantics();
    final state = GameState.fresh(featureSpecFor(1), featurePuzzle()).copyWith(
      removed: const {0},
      revealed: const {4},
      hintArrowId: 4,
    );
    await _pumpBoard(tester, state);
    final labels = semanticsNodes(tester, RegExp(r'^Arrow')).map((n) => n.label).toList();
    expect(labels, hasLength(4));
    expect(labels, contains(contains('Lock 1 is open.')));
    expect(labels, contains(contains('Arrow pointing up, 2 cells long, head at row 4, column 5. Clear path to the edge. Hint: this one can go.')));
    expect(labels.any((l) => l.contains('hidden head')), isFalse);
    handle.dispose();
  });

  test('a bumped lock reads as free to bump again only while it is still shut', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));
    final state = GameState.fresh(featureSpecFor(1), featurePuzzle()).copyWith(bumped: const {1});
    expect(arrowLabel(en, state, 1), endsWith('Bumped before; another bump here is free.'));
    expect(arrowLabel(en, state.copyWith(removed: const {0}), 1), isNot(contains('Bumped before')));
    expect(arrowLabel(hi, state, 0), contains('चाबी 1'));
    expect(arrowLabel(hi, state, 1), contains('ताला 1'));
    expect(arrowLabel(hi, state, 4), startsWith('छिपे सिरे वाला तीर'));
    expect(arrowLabel(hi, state, 2), contains('बँधा'));
  });

  testWidgets('a locked tap rattles and points at the key; the lock pops open; a pair leaves together', (tester) async {
    final puzzle = featurePuzzle();
    final fresh = GameState.fresh(featureSpecFor(1), puzzle);
    final push = await _pumpBoard(tester, fresh);
    // Held by the lock: the locked arrow rattles, a line runs to the key
    // and a ring pulses on it — nothing is charged.
    push(fresh.copyWith(
      lastMoveId: 1,
      lastOutcome: MoveOutcome.locked,
      blockedKey: 0,
      moveToken: 1,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    // The key leaves over the edge; once it has gone a spark flies to the
    // padlock, which swings open with a ring.
    push(fresh.copyWith(
      removed: const {0},
      lastMoveId: 0,
      lastOutcome: MoveOutcome.exited,
      moveToken: 2,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300)); // the spark
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500)); // the pop
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
    // Arrow 1 leaves; a hidden head (4) is lit by a hint and springs in.
    push(fresh.copyWith(
      removed: const {0, 1},
      revealed: const {4},
      hintArrowId: 4,
      lastMoveId: 1,
      lastOutcome: MoveOutcome.exited,
      moveToken: 3,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    // The pair's partner runs into 4: a cell bump on the partner, and
    // both halves move together, the tether between them.
    push(fresh.copyWith(
      removed: const {0, 1},
      mistakes: 1,
      bumped: const {2, 3},
      lastMoveId: 3,
      lastOutcome: MoveOutcome.blocked,
      blockedCell: const Cell(4, 4),
      moveToken: 4,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 700));
    // 4 leaves (uncovering nothing, it is the hidden one), then the pair
    // goes together: two slides at once, the tether gone with them.
    push(fresh.copyWith(
      removed: const {0, 1, 4},
      revealed: const {4},
      lastMoveId: 4,
      lastOutcome: MoveOutcome.exited,
      moveToken: 5,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    push(fresh.copyWith(
      removed: const {0, 1, 2, 3, 4},
      revealed: const {4},
      phase: GamePhase.cleared,
      lastMoveId: 2,
      lastOutcome: MoveOutcome.exited,
      moveToken: 6,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Both halves of the pair are mid-slide at once.
    final boardState = tester.state<State<PuzzleBoard>>(find.byType(PuzzleBoard));
    expect(boardState, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('a second locked tap before the first pointer is done throws nothing', (tester) async {
    // The first tap's pointer replaced by the second's as it ends. On the
    // web the frame's rebuild runs before the first pointer's completion
    // callback (natively, and here, the callback runs first), so the
    // rebuild disposed it and the callback disposed it again, which threw:
    // tool/perf.mjs caught it on level 250. This pins the sequence the
    // tests can play; the profiler, which fails on any JS error, pins the
    // web's order.
    final puzzle = featurePuzzle();
    final fresh = GameState.fresh(featureSpecFor(1), puzzle);
    final push = await _pumpBoard(tester, fresh);
    GameState locked(int token) =>
        fresh.copyWith(lastMoveId: 1, lastOutcome: MoveOutcome.locked, blockedKey: 0, moveToken: token);
    push(locked(1));
    await tester.pump();
    push(locked(2));
    await tester.pump(const Duration(milliseconds: kKeyPingMs));
    expect(tester.takeException(), isNull);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('a tap on a hidden arrow rattles it and points at the arrows that uncover it', (tester) async {
    final puzzle = featurePuzzle(hidden: const {2});
    final fresh = GameState.fresh(featureSpecFor(1), puzzle);
    final push = await _pumpBoard(tester, fresh);
    push(fresh.copyWith(lastMoveId: 2, lastOutcome: MoveOutcome.hidden, moveToken: 1));
    await tester.pump();
    // The jab, the dashed line to 4 and the two pings, then it all fades.
    for (final ms in <int>[100, 300, 600, 900, 300]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(tester.takeException(), isNull);
    }
    // 4 leaves: nothing to point at any more, and 2's head comes out of
    // the fog once the slide is over.
    push(fresh.copyWith(
      removed: const {4},
      revealed: const {2},
      lastMoveId: 4,
      lastOutcome: MoveOutcome.exited,
      moveToken: 2,
    ));
    await tester.pump();
    for (final ms in <int>[100, 400, 500, 600, 400]) {
      await tester.pump(Duration(milliseconds: ms));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the bounce is reported once per mirror as the head reaches it', (tester) async {
    var bounces = 0;
    final puzzle = featurePuzzle();
    final fresh = GameState.fresh(featureSpecFor(1), puzzle).copyWith(removed: const {0});
    final push = await _pumpBoard(tester, fresh, onBounce: () => bounces++);
    // Arrow 1's way out turns at the mirror two cells past its head.
    push(fresh.copyWith(
      removed: const {0, 1},
      lastMoveId: 1,
      lastOutcome: MoveOutcome.exited,
      moveToken: 1,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(bounces, 0); // not yet at the glass
    await tester.pump(const Duration(milliseconds: 900));
    expect(bounces, 1);
    await tester.pump(const Duration(milliseconds: 900));
    expect(bounces, 1);
    // A straight exit never bounces.
    push(fresh.copyWith(
      removed: const {0, 1, 4},
      lastMoveId: 4,
      lastOutcome: MoveOutcome.exited,
      moveToken: 2,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(bounces, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the hint veil redraws a hidden arrow without its twist', (tester) async {
    final state = GameState.fresh(featureSpecFor(1), featurePuzzle()).copyWith(hintArrowId: 4, revealed: const {4});
    await _pumpBoard(tester, state, reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
