import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/mirror.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a mirror turns every heading a right angle, and back the way it came', () {
    expect(Mirror.slash.reflect(Direction.right), Direction.up);
    expect(Mirror.slash.reflect(Direction.up), Direction.right);
    expect(Mirror.slash.reflect(Direction.left), Direction.down);
    expect(Mirror.slash.reflect(Direction.down), Direction.left);
    expect(Mirror.backslash.reflect(Direction.right), Direction.down);
    expect(Mirror.backslash.reflect(Direction.down), Direction.right);
    expect(Mirror.backslash.reflect(Direction.left), Direction.up);
    expect(Mirror.backslash.reflect(Direction.up), Direction.left);
    // Reflection is its own inverse: the way in from the other side.
    for (final m in Mirror.values) {
      for (final d in Direction.values) {
        expect(m.reflect(m.reflect(d)), d, reason: '$m $d');
      }
    }
  });

  test('a ray runs straight to the edge, or turns at every mirror on its way', () {
    final mirrors = <Cell, Mirror>{const Cell(4, 2): Mirror.slash, const Cell(4, 0): Mirror.backslash};
    RayTrace? trace(Cell head, Direction d) =>
        traceRay(head: head, heading: d, width: 7, height: 5, mirrorAt: (c) => mirrors[c]);
    final straight = trace(const Cell(1, 4), Direction.right)!;
    expect(straight.cells, const [Cell(2, 4), Cell(3, 4), Cell(4, 4), Cell(5, 4), Cell(6, 4)]);
    expect(straight.exitHeading, Direction.right);
    // Right along row 2 into the `/` at (4,2): up the column, into the `\`
    // at (4,0): left along row 0 to the edge.
    final bent = trace(const Cell(2, 2), Direction.right)!;
    expect(bent.cells, const [Cell(3, 2), Cell(4, 2), Cell(4, 1), Cell(4, 0), Cell(3, 0), Cell(2, 0), Cell(1, 0), Cell(0, 0)]);
    expect(bent.exitHeading, Direction.left);
    // A head on the edge facing out has no ray at all.
    expect(trace(const Cell(6, 4), Direction.right)!.cells, isEmpty);
  });

  test('four mirrors can send a ray round in a ring, which is no way out', () {
    final ring = <Cell, Mirror>{
      const Cell(4, 1): Mirror.backslash,
      const Cell(4, 3): Mirror.slash,
      const Cell(1, 3): Mirror.backslash,
      const Cell(1, 1): Mirror.slash,
    };
    final looped = traceRay(
      head: const Cell(2, 1),
      heading: Direction.right,
      width: 6,
      height: 5,
      mirrorAt: (c) => ring[c],
    );
    expect(looped, isNull);
  });

  group('on a puzzle', () {
    /// 0: (0,2)(1,2) → right into the `/` at (3,2), then up (3,1),(3,0).
    /// 1: (3,4)(3,3) ↑ up, straight through the same mirror: (3,2) turns it
    ///    right: (4,2),(5,2) — blocked by 2.
    /// 2: (5,3)(5,2) ↑ up, ray (5,1),(5,0): free.
    /// 3: (0,0)(1,0)(2,0)(3,0) → right, ray (4,0),(5,0): free, and lying
    ///    across the end of 0's bent ray.
    Puzzle puzzle() => Puzzle(
          width: 6,
          height: 5,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 2), Cell(1, 2)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(3, 4), Cell(3, 3)], heading: Direction.up),
            ArrowPiece(id: 2, cells: const [Cell(5, 3), Cell(5, 2)], heading: Direction.up),
            ArrowPiece(id: 3, cells: const [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0)], heading: Direction.right),
          ],
          mirrors: {const Cell(3, 2): Mirror.slash},
        );

    test('a mirror is a cell nobody sits on, that bends the rays through it and blocks none', () {
      final p = puzzle();
      expect(p.isMirror(const Cell(3, 2)), isTrue);
      expect(p.mirrorAt(const Cell(3, 2)), Mirror.slash);
      expect(p.mirrorAt(const Cell(2, 2)), isNull);
      expect(p.arrowAt(const Cell(3, 2)), isNull);
      expect(p.freeCellCount, 29);
      expect(p.arrowAt(const Cell(3, 0)), 3);
      expect(p.hasFeatures, isTrue);
      expect(p.rayOf(0), const [Cell(2, 2), Cell(3, 2), Cell(3, 1), Cell(3, 0)]);
      expect(p.exitHeadingOf(0), Direction.up);
      expect(p.bends(0), isTrue);
      expect(p.rayOf(1), const [Cell(3, 2), Cell(4, 2), Cell(5, 2)]);
      expect(p.exitHeadingOf(1), Direction.right);
      expect(p.bends(2), isFalse);
      expect(p.exitHeadingOf(2), Direction.up);
      // The mirror itself is never in the way: 0 waits for 3 only.
      expect(p.blockersOf(0), {3});
      expect(p.firstBlockedCell(0, const {}), const Cell(3, 0));
      expect(p.firstBlockedCell(0, const {3}), isNull);
      expect(p.blockersOf(1), {2});
      expect(p.blockersOf(3), isEmpty);
      // The mirror is nobody's neighbour.
      expect(p.neighboursOf(1), isEmpty);
      expect(p.solvingOrder(), [2, 1, 3, 0]);
      expect(p.openTapRisk, greaterThanOrEqualTo(0));
    });

    test('a mirror under an arrow, an arrow in its own bent way, and a ring are refused', () {
      expect(
        () => Puzzle(
          width: 6,
          height: 5,
          arrows: [ArrowPiece(id: 0, cells: const [Cell(0, 2), Cell(1, 2)], heading: Direction.right)],
          mirrors: {const Cell(1, 2): Mirror.slash},
        ),
        throwsA(isA<AssertionError>()),
      );
      // Up into a `\` at (2,0): left to a `/` at (0,0): down to a `\` at
      // (0,4): right along the bottom row — through the arrow's own tail
      // at (2,4).
      expect(
        () => Puzzle(
          width: 6,
          height: 5,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(2, 4), Cell(2, 3), Cell(2, 2), Cell(2, 1)], heading: Direction.up),
          ],
          mirrors: {const Cell(2, 0): Mirror.backslash, const Cell(0, 0): Mirror.slash, const Cell(0, 4): Mirror.backslash},
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Puzzle(
          width: 6,
          height: 5,
          arrows: [ArrowPiece(id: 0, cells: const [Cell(2, 1), Cell(3, 1)], heading: Direction.right)],
          mirrors: {
            const Cell(4, 1): Mirror.backslash,
            const Cell(4, 3): Mirror.slash,
            const Cell(1, 3): Mirror.backslash,
            const Cell(1, 1): Mirror.slash,
          },
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
