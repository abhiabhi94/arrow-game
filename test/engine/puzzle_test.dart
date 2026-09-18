import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 4x4 board:
///   0: straight arrow on row 1 pointing right  (1,1)(2,1)→ exits right through (3,1)
///   1: vertical arrow in column 3 pointing up   (3,3)(3,2)→ crosses arrow 0's ray at (3,1)? no: (3,1) is its ray.
///      Actually arrow 1 occupies (3,3),(3,2); its ray is (3,1),(3,0) — clear.
///   2: bent arrow (0,3)(1,3)(1,2) pointing up: ray (1,1),(1,0) — (1,1) is arrow 0.
/// So: 1 and 0 can go at once; 2 must wait for 0.
Puzzle sample() => Puzzle(
      width: 4,
      height: 4,
      arrows: [
        ArrowPiece(id: 0, cells: const [Cell(1, 1), Cell(2, 1)], heading: Direction.right),
        ArrowPiece(id: 1, cells: const [Cell(3, 3), Cell(3, 2)], heading: Direction.up),
        ArrowPiece(id: 2, cells: const [Cell(0, 3), Cell(1, 3), Cell(1, 2)], heading: Direction.up),
      ],
    );

void main() {
  group('ArrowPiece', () {
    test('head, tail, ray to the edge', () {
      final a = ArrowPiece(id: 0, cells: const [Cell(0, 2), Cell(1, 2), Cell(1, 1)], heading: Direction.up);
      expect(a.head, const Cell(1, 1));
      expect(a.tail, const Cell(0, 2));
      expect(a.length, 3);
      expect(a.occupies(const Cell(1, 2)), isTrue);
      expect(a.occupies(const Cell(2, 2)), isFalse);
      expect(a.exitRay(4, 4), const [Cell(1, 0)]);
      expect(a.toString(), 'Arrow#0((0,2)→(1,2)→(1,1) up)');
    });

    test('a head on the edge facing out has an empty ray', () {
      final a = ArrowPiece(id: 0, cells: const [Cell(1, 0), Cell(0, 0)], heading: Direction.left);
      expect(a.exitRay(3, 3), isEmpty);
    });

    test('a single-cell arrow may point anywhere', () {
      final a = ArrowPiece(id: 0, cells: const [Cell(1, 1)], heading: Direction.down);
      expect(a.exitRay(3, 3), const [Cell(1, 2)]);
    });

    test('rejects broken paths and heads pointing across the last bend', () {
      expect(
        () => ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(2, 0)], heading: Direction.right),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0), Cell(0, 0)], heading: Direction.left),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.up),
        throwsA(isA<AssertionError>()),
      );
      expect(() => ArrowPiece(id: 0, cells: const [], heading: Direction.up), throwsA(isA<AssertionError>()));
    });
  });

  group('Puzzle', () {
    test('occupancy and blockers', () {
      final p = sample();
      expect(p.arrowCount, 3);
      expect(p.arrowAt(const Cell(2, 1)), 0);
      expect(p.arrowAt(const Cell(0, 0)), isNull);
      expect(p.blockersOf(0), isEmpty);
      expect(p.blockersOf(1), isEmpty);
      expect(p.blockersOf(2), {0});
    });

    test('canExit / firstBlockedCell honour removed arrows', () {
      final p = sample();
      expect(p.canExit(2, const {}), isFalse);
      expect(p.firstBlockedCell(2, const {}), const Cell(1, 1));
      expect(p.canExit(2, const {0}), isTrue);
      expect(p.firstBlockedCell(2, const {0}), isNull);
      expect(p.removable(const {}), [0, 1]);
      expect(p.removable(const {0, 1}), [2]);
    });

    test('solving order, solvability, depth and score', () {
      final p = sample();
      expect(p.solvingOrder(), [0, 1, 2]);
      expect(p.isSolvable, isTrue);
      expect(p.dependencyDepth, 2);
      // depth 2 * 4 + (3 - 2 free) * 4 + 1 edge
      expect(p.difficultyScore, 13);
      // 0 and 1 are playable at first; taking 0 frees 2; then only 2 is left.
      expect(p.openMoveProfile(), [2, 2, 1]);
      expect(p.meanOpenMoves, closeTo(5 / 3, 1e-9));
      // Three arrows for five thirds of a move: the hunt is 1.8 arrows a move.
      expect(p.arrowsPerOpenMove, closeTo(1.8, 1e-9));
    });

    test('openTapRisk counts the playable arrows crowded by blocked ones', () {
      // A wall of three cells with an arrow pressed against each side of it:
      //   0: (2,0)(2,1)(2,2) down, free — and every one of its cells touches
      //      one of 1, 2, 3, which are all blocked by it.
      //   1..3: (0,y)(1,y) right, each blocked by 0.
      final p = Puzzle(
        width: 5,
        height: 5,
        arrows: [
          ArrowPiece(
            id: 0,
            cells: const [Cell(2, 0), Cell(2, 1), Cell(2, 2)],
            heading: Direction.down,
          ),
          ArrowPiece(id: 1, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right),
          ArrowPiece(id: 2, cells: const [Cell(0, 1), Cell(1, 1)], heading: Direction.right),
          ArrowPiece(id: 3, cells: const [Cell(0, 2), Cell(1, 2)], heading: Direction.right),
        ],
      );
      // Step one offers only arrow 0, and all three of its cells sit against
      // a blocked arrow: aiming anywhere on it risks a life. Once it leaves,
      // 1, 2 and 3 are all playable and only touch each other, so nothing
      // after that is risky — 7 playable arrows over the solve, one exposed.
      expect(p.openTapRisk, closeTo(1 / 7, 1e-9));
    });

    test('openTapRisk is zero when nothing crowds the playable arrows', () {
      final p = Puzzle(
        width: 4,
        height: 4,
        arrows: [
          ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right),
          ArrowPiece(id: 1, cells: const [Cell(0, 3), Cell(1, 3)], heading: Direction.right),
        ],
      );
      // Both can go at once and neither touches the other.
      expect(p.removable(const {}), [0, 1]);
      expect(p.openTapRisk, 0);
    });

    test('an unsolvable board has an empty open-move profile', () {
      final p = Puzzle(
        width: 3,
        height: 3,
        arrows: [
          ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right),
          ArrowPiece(id: 1, cells: const [Cell(2, 0), Cell(2, 1)], heading: Direction.down),
          ArrowPiece(id: 2, cells: const [Cell(2, 2), Cell(1, 2)], heading: Direction.left),
          ArrowPiece(id: 3, cells: const [Cell(0, 2), Cell(0, 1)], heading: Direction.up),
        ],
      );
      expect(p.isSolvable, isFalse);
      expect(p.openMoveProfile(), isEmpty);
      expect(p.meanOpenMoves, 0);
      expect(p.arrowsPerOpenMove, 0);
    });

    test('a deadlock is unsolvable', () {
      // Four arrows chasing each other's tails around a ring: each one's exit
      // ray runs into the next.
      final p = Puzzle(
        width: 4,
        height: 4,
        arrows: [
          ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1)], heading: Direction.right),
          ArrowPiece(id: 1, cells: const [Cell(2, 0), Cell(2, 1)], heading: Direction.down),
          ArrowPiece(id: 2, cells: const [Cell(3, 2), Cell(2, 2)], heading: Direction.left),
          ArrowPiece(id: 3, cells: const [Cell(1, 3), Cell(1, 2)], heading: Direction.up),
        ],
      );
      expect(p.blockersOf(0), {1});
      expect(p.blockersOf(3), {0});
      expect(p.solvingOrder(), isNull);
      expect(p.isSolvable, isFalse);
      expect(p.hintFor(const {}), isNull);
    });

    test('hint picks the removable arrow that frees the most others', () {
      final p = sample();
      // 0 frees 2; 1 frees nobody.
      expect(p.hintFor(const {}), 0);
      expect(p.hintFor(const {0}), 1); // 1 and 2 both free 0 others -> lowest id
      expect(p.hintFor(const {0, 1, 2}), isNull);
    });

    test('rejects overlapping arrows, bad ids and off-board cells', () {
      expect(
        () => Puzzle(width: 3, height: 3, arrows: [
          ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right),
          ArrowPiece(id: 1, cells: const [Cell(1, 0), Cell(1, 1)], heading: Direction.down),
        ]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Puzzle(width: 3, height: 3, arrows: [
          ArrowPiece(id: 1, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right),
        ]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Puzzle(width: 2, height: 2, arrows: [
          ArrowPiece(id: 0, cells: const [Cell(1, 0), Cell(2, 0)], heading: Direction.right),
        ]),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
