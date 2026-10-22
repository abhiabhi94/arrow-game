import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/bump_motion.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

GameNotifier _notifier({SavedGame? savedGame, SnapshotCallback? onSnapshot}) => GameNotifier(
      featureSpecFor(1),
      puzzle: featurePuzzle(),
      savedGame: savedGame,
      onSnapshot: onSnapshot,
      autoTick: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the board opens with the key, the hidden arrow and nothing else playable', () {
    final n = _notifier();
    expect(n.state.puzzle!.removable(const {}), [0, 4]);
    expect(n.state.revealed, isEmpty);
    expect(n.state.headShown(4), isFalse);
    expect(n.state.headShown(0), isTrue);
    n.dispose();
  });

  test('a locked arrow with a clear path jabs at its lock and costs a life', () {
    fakeAsync((async) {
      final n = _notifier();
      n.tapArrow(1);
      expect(n.state.mistakes, 1);
      expect(n.state.lastOutcome, MoveOutcome.blocked);
      expect(n.state.lastMoveId, 1);
      expect(n.state.blockedCell, isNull);
      expect(n.state.blockedKey, 0);
      expect(n.state.bumped, {1});
      // The jab is short and over quickly.
      final motion = BumpMotion.forTap(n.state.puzzle!, 1, null);
      expect(motion.travel, BumpMotion.kLockJab);
      expect(motion.forwardMs, 180);
      // The key leaves; the lock opens and the arrow goes.
      n.tapArrow(0);
      expect(n.state.blockedKey, isNull);
      n.tapArrow(1);
      expect(n.state.removed, {0, 1});
      expect(n.state.mistakes, 1);
      async.elapse(const Duration(seconds: 2));
      n.dispose();
    });
  });

  test('a tethered pair leaves on one tap once both ways are clear', () {
    fakeAsync((async) {
      final n = _notifier();
      // 2's own way is clear but its partner 3 runs into 4: the partner
      // is the one that bumps, and both halves are marked as bumped.
      n.tapArrow(2);
      expect(n.state.mistakes, 1);
      expect(n.state.lastMoveId, 3);
      expect(n.state.blockedCell, const Cell(4, 4));
      expect(n.state.bumped, {2, 3});
      // A second run at either half is free.
      n.tapArrow(3);
      expect(n.state.mistakes, 1);
      n.tapArrow(4);
      n.tapArrow(3);
      expect(n.state.removed, {2, 3, 4});
      expect(n.state.lastMoveId, 3);
      expect(n.state.lastOutcome, MoveOutcome.exited);
      async.elapse(const Duration(seconds: 2));
      n.dispose();
    });
  });

  test('a hint that lands on a hidden arrow uncovers it', () {
    final n = _notifier();
    // The only neighbour of 4 is 2, and 2 cannot leave before 4, so on this
    // board 4 is only ever uncovered by a hint — which goes to it first,
    // since it frees the pair (two arrows) where 0 frees one.
    expect(n.state.puzzle!.neighboursOf(4), {2});
    n.useHint();
    expect(n.state.hintArrowId, 4);
    expect(n.state.revealed, {4});
    expect(n.state.headShown(4), isTrue);
    // A hint on an arrow already in view changes nothing.
    n.tapArrow(4);
    n.useHint();
    expect(n.state.hintArrowId, 0);
    expect(n.state.revealed, {4});
    n.dispose();
  });

  test('an arrow leaving uncovers the hidden heads beside it', () {
    // Flip the roles: hide 2, whose neighbour 4 is free to go first.
    final n = GameNotifier(
      featureSpecFor(1),
      puzzle: featurePuzzle(hidden: const {2}),
      autoTick: false,
    );
    expect(n.state.headShown(2), isFalse);
    n.tapArrow(0);
    expect(n.state.revealed, isEmpty);
    n.tapArrow(4);
    expect(n.state.revealed, {2});
    n.dispose();
  });

  test('a hint bought with a riddle uncovers a hidden head too', () {
    final n = _notifier();
    n.earnHint();
    expect(n.state.hintArrowId, 4);
    expect(n.state.revealed, {4});
    n.dispose();
  });

  test('the uncovered heads travel in the saved game and are worked out again on reopening', () {
    final snapshots = <SavedGame>[];
    final n = _notifier(onSnapshot: (s) => snapshots.add(SavedGame.fromState(s)));
    n.tapArrow(0);
    n.tapArrow(1);
    n.useHint();
    expect(snapshots.last.revealed, [4]);
    expect(snapshots.last.removed, [0, 1]);
    n.dispose();

    final m = _notifier(savedGame: snapshots.last);
    expect(m.state.phase, GamePhase.paused);
    expect(m.state.resumeOffered, isTrue);
    expect(m.state.revealed, {4});
    expect(m.state.removed, {0, 1});
    m.dispose();

    // A snapshot from before heads were stored still uncovers what the
    // departed arrows would have: with 4 out, its neighbour 2 shows.
    final old = SavedGame(
      level: 1,
      seed: featureSpecFor(1).seed,
      removed: const [0, 4],
      mistakes: 0,
      hintsLeft: 3,
      elapsedMs: 100,
    );
    expect(old.revealed, isEmpty);
    final k = GameNotifier(
      featureSpecFor(1),
      puzzle: featurePuzzle(hidden: const {2}),
      savedGame: old,
      autoTick: false,
    );
    expect(k.state.revealed, {2});
    k.dispose();
  });

  test('a restart hides the heads again', () {
    final n = _notifier();
    n.useHint();
    expect(n.state.revealed, {4});
    n.restart();
    expect(n.state.revealed, isEmpty);
    expect(n.state.blockedKey, isNull);
    n.dispose();
  });
}
