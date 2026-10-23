import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/bump_motion.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/services/haptics_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_haptics.dart';
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

  test('a locked arrow with a clear path rattles for free and points at its key', () {
    fakeAsync((async) {
      final engine = RecordingHapticEngine();
      final n = GameNotifier(
        featureSpecFor(1),
        puzzle: featurePuzzle(),
        haptics: HapticsService(() => true, engine: engine),
        autoTick: false,
      );
      n.tapArrow(1);
      // Not a mistake: a locked arrow looks locked.
      expect(n.state.mistakes, 0);
      expect(n.state.livesLeft, 3);
      expect(n.state.lastOutcome, MoveOutcome.locked);
      expect(n.state.lastMoveId, 1);
      expect(n.state.blockedCell, isNull);
      expect(n.state.blockedKey, 0);
      expect(n.state.bumped, isEmpty);
      expect(n.state.moveToken, 1);
      // A light tick for the finger, no crash.
      async.elapse(const Duration(seconds: 1));
      expect(engine.calls, ['selection']);
      // The jab the board plays is short.
      final motion = BumpMotion.forTap(n.state.puzzle!, 1, null);
      expect(motion.travel, BumpMotion.kLockJab);
      expect(motion.forwardMs, 180);
      // The key leaves; the lock opens and the arrow goes.
      n.tapArrow(0);
      expect(n.state.blockedKey, isNull);
      n.tapArrow(1);
      expect(n.state.removed, {0, 1});
      expect(n.state.mistakes, 0);
      n.dispose();
    });
  });

  test('a cell bump after a lock tap forgets the key, and the other way round', () {
    final n = _notifier();
    n.tapArrow(1);
    expect(n.state.blockedKey, 0);
    n.tapArrow(2); // the pair's partner runs into 4
    expect(n.state.blockedKey, isNull);
    expect(n.state.blockedCell, const Cell(4, 4));
    n.tapArrow(1);
    expect(n.state.blockedCell, isNull);
    expect(n.state.blockedKey, 0);
    n.dispose();
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

  test('a tap on a hidden arrow whose way is not clear costs nothing and points at what uncovers it', () {
    fakeAsync((async) {
      final engine = RecordingHapticEngine();
      // 2 hidden: its own way is clear but its partner 3 runs into 4, and
      // 4 — its one neighbour — is free to go, so 4 is what uncovers it.
      final n = GameNotifier(
        featureSpecFor(1),
        puzzle: featurePuzzle(hidden: const {2}),
        haptics: HapticsService(() => true, engine: engine),
        autoTick: false,
      );
      n.tapArrow(2);
      expect(n.state.lastOutcome, MoveOutcome.hidden);
      expect(n.state.lastMoveId, 2);
      expect(n.state.mistakes, 0);
      expect(n.state.livesLeft, 3);
      expect(n.state.bumped, isEmpty);
      expect(n.state.blockedCell, isNull);
      expect(n.state.blockedKey, isNull);
      expect(n.state.moveToken, 1);
      expect(n.state.puzzle!.revealersOf(2), {4});
      async.elapse(const Duration(seconds: 1));
      expect(engine.calls, ['selection']);
      // The board plays the same short jab as a lock.
      expect(BumpMotion.forTap(n.state.puzzle!, 2, null).travel, BumpMotion.kLockJab);
      // Once 4 has gone the head shows — and with 4 out of the partner's
      // way the pair can go: a tap is a tap again.
      n.tapArrow(4);
      expect(n.state.revealed, {2});
      n.tapArrow(2);
      expect(n.state.lastOutcome, MoveOutcome.exited);
      expect(n.state.removed, {2, 3, 4});
      expect(n.state.mistakes, 0);
      async.elapse(const Duration(seconds: 2));
      n.dispose();
    });
  });

  test('a hidden arrow whose way is clear still goes on a tap', () {
    final n = _notifier();
    // 4 is hidden and free: a lucky guess slides it out.
    n.tapArrow(4);
    expect(n.state.lastOutcome, MoveOutcome.exited);
    expect(n.state.removed, {4});
    n.dispose();
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
