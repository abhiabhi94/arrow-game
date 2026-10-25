/// Turning the block of a cube level. Pure Dart (no Flutter).
///
/// A cube level is six faces, each a board of its own (`Puzzle.cube`), and
/// the player looks at one at a time. Which one, and which way the block is
/// standing, is a [CubeView]: the face towards the player and the face on
/// top. Turning the block to look at the face on the right, the left, above
/// or below ([CubeTurn]) is a real quarter turn of a real cube — four turns
/// the same way come back to the start, and the face above is still above
/// after a turn to the side — so the block can be found your way around.
///
/// Every face is drawn upright whichever way the block stands: the faces
/// never touch each other's arrows, so how a face is turned on the block
/// would only make its arrows harder to read.
library;

/// Which way to turn the block: towards the face on that side.
enum CubeTurn { left, right, up, down }

extension CubeTurnX on CubeTurn {
  /// The turn that undoes this one.
  CubeTurn get opposite => switch (this) {
        CubeTurn.left => CubeTurn.right,
        CubeTurn.right => CubeTurn.left,
        CubeTurn.up => CubeTurn.down,
        CubeTurn.down => CubeTurn.up,
      };

  bool get isHorizontal => this == CubeTurn.left || this == CubeTurn.right;
}

/// The six faces, by number: 0 front, 1 right, 2 back, 3 left, 4 top,
/// 5 bottom, as the block stands at the start. Each is its outward normal.
const List<(int, int, int)> _normals = <(int, int, int)>[
  (0, 0, 1),
  (1, 0, 0),
  (0, 0, -1),
  (-1, 0, 0),
  (0, 1, 0),
  (0, -1, 0),
];

int _faceOf((int, int, int) v) => _normals.indexOf(v);

(int, int, int) _neg((int, int, int) v) => (-v.$1, -v.$2, -v.$3);

(int, int, int) _cross((int, int, int) a, (int, int, int) b) => (
      a.$2 * b.$3 - a.$3 * b.$2,
      a.$3 * b.$1 - a.$1 * b.$3,
      a.$1 * b.$2 - a.$2 * b.$1,
    );

/// How the block stands: the face towards the player and the one on top.
class CubeView {
  const CubeView({this.front = 0, this.up = 4})
      : assert(front >= 0 && front < 6 && up >= 0 && up < 6);

  /// The face the player sees and plays.
  final int front;

  /// The face on top.
  final int up;

  (int, int, int) get _f => _normals[front];
  (int, int, int) get _u => _normals[up];

  /// The face on the player's right.
  int get right => _faceOf(_cross(_u, _f));
  int get left => _faceOf(_neg(_cross(_u, _f)));
  int get down => _faceOf(_neg(_u));
  int get back => _faceOf(_neg(_f));

  /// The face a [turn] brings to the front.
  int faceTowards(CubeTurn turn) => switch (turn) {
        CubeTurn.left => left,
        CubeTurn.right => right,
        CubeTurn.up => up,
        CubeTurn.down => down,
      };

  /// The block after a quarter [turn] towards that side.
  CubeView turned(CubeTurn turn) => switch (turn) {
        CubeTurn.left || CubeTurn.right => CubeView(front: faceTowards(turn), up: up),
        CubeTurn.up => CubeView(front: up, up: back),
        CubeTurn.down => CubeView(front: down, up: front),
      };

  /// The shortest run of turns that brings [face] to the front: none, one,
  /// or — for the face behind — two.
  List<CubeTurn> pathTo(int face) {
    if (face == front) return const <CubeTurn>[];
    for (final t in CubeTurn.values) {
      if (faceTowards(t) == face) return <CubeTurn>[t];
    }
    return const <CubeTurn>[CubeTurn.right, CubeTurn.right];
  }

  @override
  bool operator ==(Object other) => other is CubeView && other.front == front && other.up == up;

  @override
  int get hashCode => Object.hash(front, up);

  @override
  String toString() => 'CubeView(front $front, up $up)';
}
