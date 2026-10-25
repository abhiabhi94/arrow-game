import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/cube.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/mirror.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 4×4 face with the given arrows.
Puzzle face(List<ArrowPiece> arrows, {Map<Cell, Mirror> mirrors = const {}, Map<int, int> locks = const {}}) =>
    Puzzle(width: 4, height: 4, arrows: arrows, mirrors: mirrors, locks: locks);

void main() {
  group('CubeView', () {
    test('starts with face 0 in front and face 4 on top', () {
      const v = CubeView();
      expect(v.front, 0);
      expect(v.up, 4);
      expect(v.right, 1);
      expect(v.back, 2);
      expect(v.left, 3);
      expect(v.down, 5);
    });

    test('four turns the same way come back to the start', () {
      for (final turn in CubeTurn.values) {
        var v = const CubeView();
        final seen = <int>{};
        for (var i = 0; i < 4; i++) {
          v = v.turned(turn);
          seen.add(v.front);
        }
        expect(v, const CubeView(), reason: turn.name);
        expect(seen, hasLength(4), reason: turn.name);
      }
    });

    test('a turn and its opposite undo each other, from any standing', () {
      final views = <CubeView>{const CubeView()};
      for (var i = 0; i < 4; i++) {
        for (final v in views.toList()) {
          for (final t in CubeTurn.values) {
            views.add(v.turned(t));
          }
        }
      }
      // All 24 ways a cube can stand are reached.
      expect(views, hasLength(24));
      for (final v in views) {
        for (final t in CubeTurn.values) {
          expect(v.turned(t).turned(t.opposite), v, reason: '$v $t');
          expect(v.turned(t).front, v.faceTowards(t));
        }
        expect({v.front, v.up, v.right, v.left, v.down, v.back}, hasLength(6));
      }
    });

    test('a turn to the side keeps the top, and a turn up brings it round', () {
      const v = CubeView();
      expect(v.turned(CubeTurn.right), const CubeView(front: 1, up: 4));
      expect(v.turned(CubeTurn.left).front, 3);
      expect(v.turned(CubeTurn.up), const CubeView(front: 4, up: 2));
      expect(v.turned(CubeTurn.down), const CubeView(front: 5, up: 0));
    });

    test('the way to any face is at most two turns', () {
      const v = CubeView();
      expect(v.pathTo(0), isEmpty);
      expect(v.pathTo(1), [CubeTurn.right]);
      expect(v.pathTo(4), [CubeTurn.up]);
      expect(v.pathTo(2), hasLength(2));
      var w = v;
      for (final t in v.pathTo(2)) {
        w = w.turned(t);
      }
      expect(w.front, 2);
      expect(CubeTurn.up.isHorizontal, isFalse);
      expect(CubeTurn.left.isHorizontal, isTrue);
      expect(v.toString(), 'CubeView(front 0, up 4)');
      expect(v.hashCode, const CubeView().hashCode);
    });
  });

  group('Puzzle.cube', () {
    // Face 0: an arrow pointing right with nothing in its way on its face —
    // but face 1's arrow sits just past its edge in the strip, and must not
    // count. Face 1: a lock and its key.
    final p = Puzzle.cube([
      face([
        ArrowPiece(id: 0, cells: const [Cell(1, 1), Cell(2, 1), Cell(3, 1)], heading: Direction.right),
        ArrowPiece(id: 1, cells: const [Cell(0, 3), Cell(1, 3)], heading: Direction.right),
      ]),
      face(
        [
          ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(0, 2)], heading: Direction.down),
          ArrowPiece(id: 1, cells: const [Cell(2, 0), Cell(3, 0)], heading: Direction.right),
        ],
        locks: const {0: 1},
        mirrors: {const Cell(2, 3): Mirror.slash},
      ),
    ]);

    test('lays the faces side by side, ids and cells shifted', () {
      expect(p.isCube, isTrue);
      expect(p.faceSize, 4);
      expect(p.faceCount, 2);
      expect(p.width, 8);
      expect(p.faceWidth, 4);
      expect(p.arrowCount, 4);
      expect(p.arrows[2].cells, const [Cell(4, 1), Cell(4, 2)]);
      expect(p.faceOf(0), 0);
      expect(p.faceOf(3), 1);
      expect(p.arrowsOn(1), [2, 3]);
      expect(p.locks, {2: 3});
      expect(p.mirrors.keys, [const Cell(6, 3)]);
      expect(p.onFace(const Cell(6, 3)), const Cell(2, 3));
      expect(p.faceOfCell(const Cell(5, 0)), 1);
    });

    test('a way out ends at its own face\'s edge', () {
      // Arrow 0's head is on face 0's right edge: it leaves at once, though
      // face 1's arrow 2 lies right beside it in the strip.
      expect(p.rayOf(0), isEmpty);
      expect(p.canExit(0, const {}), isTrue);
      expect(p.rayOf(1), const [Cell(2, 3), Cell(3, 3)]);
      // Arrow 2 slides down off face 1 through its bottom row.
      expect(p.rayOf(2), const [Cell(4, 3)]);
      expect(p.rayOf(3), isEmpty);
      // The lock still holds on its own face.
      expect(p.canExit(2, const {}), isFalse);
      expect(p.canExit(2, const {3}), isTrue);
      expect(p.isSolvable, isTrue);
    });

    test('arrows across a face\'s edge are not neighbours', () {
      expect(p.neighboursOf(0), isEmpty);
      expect(p.neighboursOf(2), isEmpty);
    });

    test('a hint goes to the face in front when it can', () {
      // Over the whole block the key is the best move (it frees its lock);
      // looking at face 0, a move on face 0.
      expect(p.hintFor(const {}), 3);
      expect(p.hintFor(const {}, face: 0), 0);
      expect(p.hintFor(const {}, face: 1), 3);
      // Nothing on face 1 can go once its key has gone and its lock too:
      // the hint falls back to the rest of the block.
      expect(p.hintFor(const {2, 3}, face: 1), 0);
    });

    test('a flat board is one face', () {
      final flat = face([ArrowPiece(id: 0, cells: const [Cell(0, 0), Cell(1, 0)], heading: Direction.right)]);
      expect(flat.isCube, isFalse);
      expect(flat.faceCount, 1);
      expect(flat.faceWidth, 4);
      expect(flat.faceOf(0), 0);
      expect(flat.onFace(const Cell(3, 2)), const Cell(3, 2));
      expect(flat.arrowsOn(0), [0]);
    });
  });
}
