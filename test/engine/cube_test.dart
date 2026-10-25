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
  group('the block in space', () {
    bool near(double a, double b) => (a - b).abs() < 1e-9;
    bool same(Vec3 a, Vec3 b) => near(a.$1, b.$1) && near(a.$2, b.$2) && near(a.$3, b.$3);

    test('every face has a frame, and its neighbours are the faces its edges touch', () {
      for (var f = 0; f < 6; f++) {
        expect(dot(faceRight(f), faceUp(f)), 0, reason: 'face $f');
        expect(dot(faceRight(f), faceNormal(f)), 0, reason: 'face $f');
        final around = {for (final t in CubeTurn.values) cubeNeighbour(f, t)};
        expect(around, hasLength(4), reason: 'face $f');
        expect(around, isNot(contains(f)));
        for (final t in CubeTurn.values) {
          // The face beside it lies that way, and nothing lies further than
          // a quarter turn away.
          final n = cubeNeighbour(f, t);
          expect(dot(faceNormal(f), faceNormal(n)), 0, reason: 'face $f $t');
        }
      }
      expect(cubeNeighbour(0, CubeTurn.right), 1);
      expect(cubeNeighbour(0, CubeTurn.left), 3);
      expect(cubeNeighbour(0, CubeTurn.up), 4);
      expect(cubeNeighbour(0, CubeTurn.down), 5);
      // Round the middle and back.
      var f = 0;
      for (var i = 0; i < 4; i++) {
        f = cubeNeighbour(f, CubeTurn.right);
      }
      expect(f, 0);
      expect(cubePath(0, 0), isEmpty);
      expect(cubePath(0, 4), [CubeTurn.up]);
      expect(cubePath(0, 2), hasLength(2));
      expect(CubeTurn.up.opposite, CubeTurn.down);
      expect(CubeTurn.left.isHorizontal, isTrue);
    });

    test('a face turned on looks straight at the player, the right way up', () {
      for (var f = 0; f < 6; f++) {
        final q = faceOn(f);
        expect(same(q.rotate(faceNormal(f)), (0, 0, 1)), isTrue, reason: 'face $f');
        expect(same(q.rotate(faceRight(f)), (1, 0, 0)), isTrue, reason: 'face $f');
        expect(same(q.rotate(faceUp(f)), (0, 1, 0)), isTrue, reason: 'face $f');
      }
    });

    test('quaternions compose, turn and blend', () {
      final a = Quat.axisAngle((0, 1, 0), 0.7);
      final b = Quat.axisAngle((1, 0, 0), -0.4);
      const v = (0.3, -0.2, 0.9);
      expect(same((a * b).rotate(v), a.rotate(b.rotate(v))), isTrue);
      expect(same(a.slerp(b, 0).rotate(v), a.rotate(v)), isTrue);
      expect(same(a.slerp(b, 1).rotate(v), b.rotate(v)), isTrue);
      expect(a.distanceTo(a), closeTo(0, 1e-12));
      expect(a.distanceTo(b), greaterThan(0));
      expect(same(Quat.identity.slerp(Quat.identity, 0.5).rotate(v), v), isTrue);
      expect(Quat.identity.toString(), 'Quat(1.0, 0.0, 0.0, 0.0)');
    });

    test('at rest the face being played is nearest, and the top and a side show beside it', () {
      for (var f = 0; f < 6; f++) {
        final cam = CubeCamera(orientation: faceOn(f), side: 300);
        expect(cam.nearestFace, f);
        final shown = cam.visibleFaces;
        expect(shown, hasLength(3), reason: 'face $f');
        expect(shown.last, f, reason: 'painted last, on top');
        expect(shown, contains(cubeNeighbour(f, CubeTurn.up)));
        expect(shown, contains(cubeNeighbour(f, CubeTurn.right)));
      }
    });

    test('a touch lands where the face was drawn', () {
      final cam = CubeCamera(orientation: faceOn(2), side: 240, zoom: 1.3);
      for (final (face, u, v) in <(int, double, double)>[(2, 120, 120), (2, 20, 200), (2, 230, 15), (4, 120, 200), (3, 200, 120)]) {
        final (sx, sy) = cam.project(cam.pointOn(face, u, v));
        final hit = cam.hit(sx, sy)!;
        expect(hit.face, face, reason: '$face $u $v');
        expect(hit.u, closeTo(u, 1e-6));
        expect(hit.v, closeTo(v, 1e-6));
      }
      // Far off the block, nothing.
      expect(cam.hit(2000, 2000), isNull);
    });

    test('the face matrix draws a face where its points project', () {
      final cam = CubeCamera(orientation: faceOn(0), side: 200);
      for (final f in cam.visibleFaces) {
        final m = cam.faceMatrix(f);
        for (final (px, py) in <(double, double)>[(-100, -100), (100, 40), (0, 0)]) {
          // Column-major: x' = m0 px + m4 py + m12, w = m3 px + m7 py + m15.
          final w = m[3] * px + m[7] * py + m[15];
          final x = (m[0] * px + m[4] * py + m[12]) / w;
          final y = (m[1] * px + m[5] * py + m[13]) / w;
          final (sx, sy) = cam.project(cam.pointOn(f, px + 100, py + 100));
          expect(x, closeTo(sx, 1e-6), reason: 'face $f');
          expect(y, closeTo(sy, 1e-6), reason: 'face $f');
        }
      }
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
