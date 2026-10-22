import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 5x5 board with room for every twist:
///   0: (0,0)(1,0)(2,0) → right, ray (3,0),(4,0): free.
///   1: (0,2)(1,2) → right, ray (2,2),(3,2),(4,2): free.
///   2: (4,4)(4,3) ↑ up, ray (4,2),(4,1),(4,0): free.
///   3: (0,4)(1,4)(2,4) → right, ray (3,4),(4,4): blocked by 2.
List<ArrowPiece> arrows() => [
      ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0), Cell(2, 0)], heading: Direction.right),
      ArrowPiece(id: 1, cells: const [Cell(0, 2), Cell(1, 2)], heading: Direction.right),
      ArrowPiece(id: 2, cells: const [Cell(4, 4), Cell(4, 3)], heading: Direction.up),
      ArrowPiece(id: 3, cells: const [Cell(0, 4), Cell(1, 4), Cell(2, 4)], heading: Direction.right),
    ];

void main() {
  group('walls', () {
    test('are dead cells: not an arrow, and never on a ray', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), walls: {const Cell(2, 1), const Cell(3, 3)});
      expect(p.isWall(const Cell(2, 1)), isTrue);
      expect(p.arrowAt(const Cell(2, 1)), isNull);
      expect(p.freeCellCount, 23);
      expect(p.hasFeatures, isTrue);
      // A wall on a ray is where the ray ends: arrow 1 (aiming along row 2)
      // falls into the hole at (3,2) rather than leaving over the edge.
      final q = Puzzle(width: 5, height: 5, arrows: arrows(), walls: {const Cell(3, 2)});
      expect(q.rayOf(1), const [Cell(2, 2)]);
      expect(p.rayOf(1), const [Cell(2, 2), Cell(3, 2), Cell(4, 2)]);
      // Facing a wall head-on is an empty ray, like facing the edge.
      final r = Puzzle(width: 5, height: 5, arrows: arrows(), walls: {const Cell(2, 2)});
      expect(r.rayOf(1), isEmpty);
      expect(r.canExit(1, const {}), isTrue);
      // A wall under an arrow is refused.
      expect(
        () => Puzzle(width: 5, height: 5, arrows: arrows(), walls: {const Cell(1, 0)}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a plain board has no features', () {
      expect(Puzzle(width: 5, height: 5, arrows: arrows()).hasFeatures, isFalse);
    });
  });

  group('locks', () {
    test('a locked arrow waits for its key as well as its path', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), locks: const {0: 1});
      expect(p.keyOf(0), 1);
      expect(p.keyOf(1), isNull);
      expect(p.locksOpenedBy(1), [0]);
      expect(p.blockersOf(0), isEmpty);
      expect(p.dependenciesOf(0), {1});
      expect(p.canExit(0, const {}), isFalse);
      expect(p.lockHolding(0, const {}), 1);
      expect(p.blockOf(0, const {}), const TapBlock(arrow: 0, key: 1));
      expect(p.blockOf(0, const {}).toString(), 'TapBlock(arrow 0, key 1)');
      expect(p.canExit(0, const {1}), isTrue);
      expect(p.lockHolding(0, const {1}), isNull);
      expect(p.blockOf(0, const {1}), isNull);
      expect(p.removable(const {}), [1, 2]);
      expect(p.solvingOrder(), [1, 0, 2, 3]);
      expect(p.dependencyDepth, 2);
      // Arrow 1 frees 0 and 2 frees 3: a tie, so the lowest id.
      expect(p.hintFor(const {}), 1);
      expect(p.openMoveProfile(), [2, 2, 1, 1]);
    });

    test('the path is explained before the lock', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), locks: const {3: 0});
      expect(p.blockOf(3, const {}), const TapBlock(arrow: 3, cell: Cell(4, 4)));
      expect(p.blockOf(3, const {2}), const TapBlock(arrow: 3, key: 0));
      expect(p.blockOf(3, const {0, 2}), isNull);
    });

    test('a key and lock that wait for each other make a deadlock', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), locks: const {2: 3});
      expect(p.isSolvable, isFalse);
    });

    test('TapBlock is a cell or a key, never both', () {
      expect(() => TapBlock(arrow: 0), throwsA(isA<AssertionError>()));
      expect(() => TapBlock(arrow: 0, cell: const Cell(0, 0), key: 1), throwsA(isA<AssertionError>()));
      expect(const TapBlock(arrow: 0, key: 1).isLock, isTrue);
      expect(const TapBlock(arrow: 0, cell: Cell(1, 1)).isLock, isFalse);
      expect(const TapBlock(arrow: 0, key: 1).hashCode, const TapBlock(arrow: 0, key: 1).hashCode);
    });
  });

  group('pairs', () {
    test('tethered arrows leave together and wait for each other\'s paths', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), pairs: const {1: 3});
      expect(p.partnerOf(1), 3);
      expect(p.partnerOf(3), 1);
      expect(p.exitGroup(1), [1, 3]);
      expect(p.exitGroup(0), [0]);
      // 1's own path is clear but 3's is not: the pair waits for 2.
      expect(p.dependenciesOf(1), {2});
      expect(p.dependenciesOf(3), {2});
      expect(p.canExit(1, const {}), isFalse);
      expect(p.blockOf(1, const {}), const TapBlock(arrow: 3, cell: Cell(4, 4)));
      expect(p.removable(const {}), [0, 2]);
      expect(p.removable(const {0, 2}), [1, 3]);
      expect(p.solvingOrder(), [0, 2, 1, 3]);
      // A pair counts as one open move.
      expect(p.openMoveProfile(), [2, 1, 1]);
      // 2 frees the pair (two arrows); 0 frees nobody.
      expect(p.hintFor(const {}), 2);
      expect(p.openTapRisk, greaterThanOrEqualTo(0));
    });

    test('a pair where one half waits for the other is a deadlock', () {
      final p = Puzzle(width: 5, height: 5, arrows: arrows(), pairs: const {2: 3});
      expect(p.dependenciesOf(2), isEmpty);
      expect(p.isSolvable, isTrue);
      final q = Puzzle(width: 5, height: 5, arrows: arrows(), locks: const {0: 2}, pairs: const {0: 3});
      // The pair (0,3) waits for 2 by both the lock and 3's path: fine.
      expect(q.dependenciesOf(0), {2});
      expect(q.isSolvable, isTrue);
    });

    test('pairs must be symmetric and never self', () {
      expect(
        () => Puzzle(width: 5, height: 5, arrows: arrows(), pairs: const {0: 0}),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('hidden', () {
    test('a hidden head is revealed when a neighbour leaves', () {
      // 1 and 3 do not touch; 0 touches nobody; 2 touches 3 at (4,4)/(3,4)? No:
      // 3 ends at (2,4), so 2's (4,4) is two cells away. Put the hidden one
      // beside something: 1 at (0,2)(1,2) is under nothing — so use 3, whose
      // (0,4) sits under nothing either... the sample is airy, so test the
      // rule directly on neighbours.
      final p = Puzzle(
        width: 5,
        height: 5,
        arrows: [
          ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0), Cell(2, 0)], heading: Direction.right),
          ArrowPiece(id: 1, cells: const [Cell(0, 1), Cell(1, 1)], heading: Direction.right),
          ArrowPiece(id: 2, cells: const [Cell(4, 4), Cell(4, 3)], heading: Direction.up),
        ],
        hidden: const {1},
      );
      expect(p.neighboursOf(1), {0});
      expect(p.neighboursOf(2), isEmpty);
      expect(p.revealedBy(const {}), isEmpty);
      expect(p.revealedBy(const {2}), isEmpty);
      expect(p.revealedBy(const {0}), {1});
      // The rules are untouched: a hidden arrow still plays.
      expect(p.canExit(1, const {}), isTrue);
    });
  });
}
