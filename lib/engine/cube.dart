/// The block of a cube level in 3D: its faces, how it is turned, and how a
/// point on the screen lands on a face. Pure Dart (no Flutter).
///
/// A cube level is six faces, each a board of its own (`Puzzle.cube`). The
/// whole block is drawn at once, turned in space: [CubeCamera] holds its
/// orientation (a [Quat]) and works out, for every face, where it lies on
/// the screen and whether it faces the player. Each face has a fixed
/// frame — the way its own "right" and "up" point on the block — and
/// [faceOn] is the turn that shows a face square to the player and the
/// right way up, so the face being played always reads upright; the face
/// beside it in any direction is [cubeNeighbour].
///
/// Space here is the viewer's: x to the right, y up, z out of the screen
/// towards the player, who looks down -z from [CubeCamera.distance].
library;

import 'dart:math' as math;

/// A vector in space.
typedef Vec3 = (double, double, double);

double dot(Vec3 a, Vec3 b) => a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;

Vec3 _scale(Vec3 a, double k) => (a.$1 * k, a.$2 * k, a.$3 * k);

Vec3 _add(Vec3 a, Vec3 b) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3);

Vec3 _neg(Vec3 a) => (-a.$1, -a.$2, -a.$3);

/// Which way to turn the block: the face on that side comes round to the
/// front.
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

/// The faces by number — 0 front, 1 right, 2 back, 3 left, 4 top,
/// 5 bottom — each with its outward normal and its own right and up on
/// the block (so a face shown square is the right way up).
const List<Vec3> _normals = <Vec3>[
  (0, 0, 1),
  (1, 0, 0),
  (0, 0, -1),
  (-1, 0, 0),
  (0, 1, 0),
  (0, -1, 0),
];
const List<Vec3> _rights = <Vec3>[
  (1, 0, 0),
  (0, 0, -1),
  (-1, 0, 0),
  (0, 0, 1),
  (1, 0, 0),
  (1, 0, 0),
];
const List<Vec3> _ups = <Vec3>[
  (0, 1, 0),
  (0, 1, 0),
  (0, 1, 0),
  (0, 1, 0),
  (0, 0, -1),
  (0, 0, 1),
];

/// [face]'s outward normal, right and up on the block.
Vec3 faceNormal(int face) => _normals[face];
Vec3 faceRight(int face) => _rights[face];
Vec3 faceUp(int face) => _ups[face];

/// The face beside [face] on the side [turn] names, as it is seen square
/// on: the face whose normal is [face]'s right is on its right, and so on.
int cubeNeighbour(int face, CubeTurn turn) {
  final want = switch (turn) {
    CubeTurn.right => _rights[face],
    CubeTurn.left => _neg(_rights[face]),
    CubeTurn.up => _ups[face],
    CubeTurn.down => _neg(_ups[face]),
  };
  return _normals.indexOf(want);
}

/// The shortest way round to [to] from [from]: no turn, one, or two for
/// the face behind.
List<CubeTurn> cubePath(int from, int to) {
  if (from == to) return const <CubeTurn>[];
  for (final t in CubeTurn.values) {
    if (cubeNeighbour(from, t) == to) return <CubeTurn>[t];
  }
  return const <CubeTurn>[CubeTurn.right, CubeTurn.right];
}

/// A rotation, as a unit quaternion.
class Quat {
  const Quat(this.w, this.x, this.y, this.z);

  static const Quat identity = Quat(1, 0, 0, 0);

  final double w;
  final double x;
  final double y;
  final double z;

  /// A turn of [radians] about the unit [axis].
  factory Quat.axisAngle(Vec3 axis, double radians) {
    final s = math.sin(radians / 2);
    return Quat(math.cos(radians / 2), axis.$1 * s, axis.$2 * s, axis.$3 * s);
  }

  /// The rotation whose matrix has rows [r], [u] and [n] — it takes [r] to
  /// x, [u] to y and [n] to z.
  factory Quat.fromRows(Vec3 r, Vec3 u, Vec3 n) {
    final m00 = r.$1, m01 = r.$2, m02 = r.$3;
    final m10 = u.$1, m11 = u.$2, m12 = u.$3;
    final m20 = n.$1, m21 = n.$2, m22 = n.$3;
    final trace = m00 + m11 + m22;
    if (trace > 0) {
      final s = math.sqrt(trace + 1) * 2;
      return Quat(
        s / 4,
        (m21 - m12) / s,
        (m02 - m20) / s,
        (m10 - m01) / s,
      ).normalized;
    } else if (m00 > m11 && m00 > m22) {
      final s = math.sqrt(1 + m00 - m11 - m22) * 2;
      return Quat(
        (m21 - m12) / s,
        s / 4,
        (m01 + m10) / s,
        (m02 + m20) / s,
      ).normalized;
    } else if (m11 > m22) {
      final s = math.sqrt(1 + m11 - m00 - m22) * 2;
      return Quat(
        (m02 - m20) / s,
        (m01 + m10) / s,
        s / 4,
        (m12 + m21) / s,
      ).normalized;
    }
    final s = math.sqrt(1 + m22 - m00 - m11) * 2;
    return Quat(
      (m10 - m01) / s,
      (m02 + m20) / s,
      (m12 + m21) / s,
      s / 4,
    ).normalized;
  }

  /// This rotation after [other]: `(a * b).rotate(v) == a.rotate(b.rotate(v))`.
  Quat operator *(Quat o) => Quat(
    w * o.w - x * o.x - y * o.y - z * o.z,
    w * o.x + x * o.w + y * o.z - z * o.y,
    w * o.y - x * o.z + y * o.w + z * o.x,
    w * o.z + x * o.y - y * o.x + z * o.w,
  );

  /// The turn back: this rotation undone (for a unit quaternion).
  Quat get conjugate => Quat(w, -x, -y, -z);

  Quat get normalized {
    final n = math.sqrt(w * w + x * x + y * y + z * z);
    return Quat(w / n, x / n, y / n, z / n);
  }

  /// [v] turned by this rotation.
  Vec3 rotate(Vec3 v) {
    final (vx, vy, vz) = v;
    // t = 2 q.xyz × v; v' = v + w t + q.xyz × t
    final tx = 2 * (y * vz - z * vy);
    final ty = 2 * (z * vx - x * vz);
    final tz = 2 * (x * vy - y * vx);
    return (
      vx + w * tx + (y * tz - z * ty),
      vy + w * ty + (z * tx - x * tz),
      vz + w * tz + (x * ty - y * tx),
    );
  }

  /// The way from this rotation to [to], [t] (0..1) of the way along the
  /// shorter arc.
  Quat slerp(Quat to, double t) {
    var d = w * to.w + x * to.x + y * to.y + z * to.z;
    var b = to;
    if (d < 0) {
      d = -d;
      b = Quat(-to.w, -to.x, -to.y, -to.z);
    }
    if (d > 0.9995) {
      return Quat(
        w + (b.w - w) * t,
        x + (b.x - x) * t,
        y + (b.y - y) * t,
        z + (b.z - z) * t,
      ).normalized;
    }
    final theta = math.acos(d);
    final s = math.sin(theta);
    final a = math.sin((1 - t) * theta) / s;
    final c = math.sin(t * theta) / s;
    return Quat(
      a * w + c * b.w,
      a * x + c * b.x,
      a * y + c * b.y,
      a * z + c * b.z,
    );
  }

  /// How far apart two rotations are, 0 (the same) to 1 (half a turn).
  double distanceTo(Quat o) =>
      1 - (w * o.w + x * o.x + y * o.y + z * o.z).abs();

  @override
  String toString() => 'Quat($w, $x, $y, $z)';
}

/// The block turned so [face] looks straight at the player, right way up:
/// the pose to play it in.
Quat faceOn(int face) =>
    Quat.fromRows(_rights[face], _ups[face], _normals[face]);

/// The block's lean when a level opens: turned a little to the right and
/// tipped a little forward, so the top and the right side show beside
/// [face] and the block reads as a block. Only the opening pose — once the
/// player has turned it, it stays where they leave it, and a turn to a face
/// shows that face square ([faceOn]).
const double kOpeningYaw = -0.4;
const double kOpeningPitch = 0.42;

/// The opening lean on its own: the turn [openingPose] puts on a face
/// squared up ([faceOn]).
final Quat kOpeningLean =
    Quat.axisAngle((1, 0, 0), kOpeningPitch) *
    Quat.axisAngle((0, 1, 0), kOpeningYaw);

Quat openingPose(int face) => kOpeningLean * faceOn(face);

/// How the block in [orientation] leans away from [face] squared up: the
/// turn that, put on [faceOn] of any face, shows that face exactly the way
/// [face] is shown now. A turn to another face keeps the player's lean.
Quat leanOf(Quat orientation, int face) =>
    (orientation * faceOn(face).conjugate).normalized;

/// The block in front of the player: how it is turned ([orientation], from
/// the block's own axes to the viewer's), how big it is ([side], the length
/// of an edge on screen at [zoom] 1), and how far the eye is ([distance]).
///
/// Screen coordinates are measured from the middle of the stage, x to the
/// right and y *down*, the way the widget layer counts.
class CubeCamera {
  const CubeCamera({
    required this.orientation,
    required this.side,
    this.zoom = 1,
    this.distance = 0,
  });

  final Quat orientation;
  final double side;
  final double zoom;

  /// The eye's distance from the block's middle; 0 for [side] × 3.2.
  final double distance;

  double get eye => distance > 0 ? distance : side * 3.2;

  /// The whole turn from the block's own axes to the viewer's.
  Quat get view => orientation;

  /// [v] (on the block) as the viewer sees it.
  Vec3 toView(Vec3 v) => view.rotate(v);

  /// How squarely [face] looks at the player: its normal's z, 1 head on,
  /// 0 edge on, below 0 turned away.
  double facing(int face) => toView(_normals[face]).$3;

  /// The face looking most squarely at the player.
  int get nearestFace {
    var best = 0;
    for (var f = 1; f < 6; f++) {
      if (facing(f) > facing(best)) best = f;
    }
    return best;
  }

  /// The faces the player can see, the furthest first (the order to paint
  /// them in).
  List<int> get visibleFaces {
    final faces = <int>[
      for (var f = 0; f < 6; f++)
        if (facing(f) > 0.02) f,
    ];
    return faces..sort((a, b) => facing(a).compareTo(facing(b)));
  }

  /// A point in space projected to the screen (from the stage's middle, y
  /// down).
  (double, double) project(Vec3 p) {
    final k = eye / (eye - p.$3) * zoom;
    return (p.$1 * k, -p.$2 * k);
  }

  /// The point at ([u], [v]) on [face] — from its top-left corner, in the
  /// face's own units of [side] — in the viewer's space.
  Vec3 pointOn(int face, double u, double v) {
    final h = side / 2;
    final local = _add(
      _add(_scale(_normals[face], h), _scale(_rights[face], u - h)),
      _scale(_ups[face], h - v),
    );
    return toView(local);
  }

  /// The 4×4 matrix (column-major, the way Flutter's `Matrix4` stores it)
  /// that draws a [side]-square face widget, laid out centred on the
  /// stage, as [face] on the turned block.
  List<double> faceMatrix(int face) {
    final r = toView(_rights[face]);
    final u = toView(_ups[face]);
    final n = toView(_normals[face]);
    final h = side / 2;
    final d = eye;
    // A face-widget point (px, py) — from its middle, y down — is the block
    // point n·h + r·px − u·py; the screen keeps x, flips y, and divides by
    // w = 1 − z / d for perspective. Zoom scales x and y.
    final k = zoom;
    return <double>[
      // column 0: px
      r.$1 * k, -r.$2 * k, r.$3, -r.$3 / d,
      // column 1: py
      -u.$1 * k, u.$2 * k, -u.$3, u.$3 / d,
      // column 2: z (unused by a flat widget, kept so the matrix inverts)
      n.$1 * k, -n.$2 * k, n.$3, -n.$3 / d,
      // column 3: the face's middle
      n.$1 * h * k, -n.$2 * h * k, n.$3 * h, 1 - n.$3 * h / d,
    ];
  }

  /// Where a touch at ([sx], [sy]) on the screen (from the stage's middle,
  /// y down) lands on the block: the nearest face it meets, and the point
  /// on it from its top-left corner in units of [side]; null when it misses
  /// the block.
  ({int face, double u, double v})? hit(double sx, double sy) {
    final d = eye;
    // The ray from the eye through the touch on the screen plane (z = 0).
    final dir = (sx / zoom, -sy / zoom, -d);
    final faces = visibleFaces.reversed; // nearest first
    final h = side / 2;
    for (final f in faces) {
      final n = toView(_normals[f]);
      final denom = dot(n, dir);
      if (denom.abs() < 1e-9) continue;
      final t = (h - n.$3 * d) / denom;
      if (t <= 0) continue;
      final p = (dir.$1 * t, dir.$2 * t, d + dir.$3 * t);
      final u = dot(p, toView(_rights[f])) + h;
      final v = h - dot(p, toView(_ups[f]));
      if (u >= 0 && u <= side && v >= 0 && v <= side) {
        return (face: f, u: u, v: v);
      }
    }
    return null;
  }
}
