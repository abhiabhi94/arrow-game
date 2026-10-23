/// The bump: a blocked arrow slides forward until its head meets the arrow in
/// its way, then springs back to where it was. Pure Dart, so the provider
/// can time the knock and the buzz to the moment of impact and the board
/// can draw the same motion.
library;

import 'dart:math';

import '../engine/cell.dart';
import '../engine/puzzle.dart';

class BumpMotion {
  const BumpMotion({required this.travel});

  /// The bump of arrow [id] on [puzzle] against [blockedCell], the first
  /// occupied cell on its ray: the head runs up to that cell and stops just
  /// short of its centre, so the tip touches the blocker's edge. With no
  /// cell — the arrow was held by a lock, its path clear — it is a short
  /// jab forward against the lock, [kLockJab] of a cell.
  factory BumpMotion.forTap(Puzzle puzzle, int id, Cell? blockedCell) {
    if (blockedCell == null) return const BumpMotion(travel: kLockJab);
    final steps = puzzle.rayOf(id).indexOf(blockedCell) + 1;
    return BumpMotion(travel: steps - kStopShort);
  }

  /// How far short of the blocker's centre the head stops, in cells.
  static const double kStopShort = 0.6;

  /// How far a locked arrow jabs forward before the lock throws it back.
  static const double kLockJab = 0.35;

  /// The pause pressed against the blocker, tip to its edge, before the
  /// spring home: the moment the eye needs to see *what* was hit.
  static const int holdMs = 200;

  /// The back leg, a fixed glide home — also how long the screen shakes.
  /// It is a glide and not a snap: the first cut eased out of the hold
  /// with a cubic, which put two thirds of the way home in the first
  /// 150 ms, and the return was over before it was seen.
  static const int backMs = 600;

  /// Shakes of the screen over the back leg.
  static const int kJoltCycles = 3;

  /// Cells the head moves before impact.
  final double travel;

  /// The forward leg: an accelerating slide, longer for a longer run, and
  /// slow enough to be followed — the first cut ran a long bump (one that
  /// turned at a mirror and hit something far down its new column) in
  /// under half a second, which was over before the player knew which
  /// arrow had moved. Now a cell takes about a tenth of a second and the
  /// longest run just under a second. The jab at a lock keeps its snap: it
  /// costs nothing and is tapped often.
  int get forwardMs => travel <= kLockJab ? 180 : (200 + travel * 90).round().clamp(280, 900);

  int get totalMs => forwardMs + holdMs + backMs;

  /// The moment of impact as a fraction of [totalMs].
  double get impactAt => forwardMs / totalMs;

  /// The moment the spring home starts, as a fraction of [totalMs].
  double get releaseAt => (forwardMs + holdMs) / totalMs;

  /// The head's offset along its track, in cells, at progress [t] (0..1):
  /// accelerating into the blocker, pressed against it, then gliding back
  /// home at an even pace (a smoothstep: soft off the blocker, soft into
  /// place, and moving the whole way between).
  double offsetAt(double t) {
    final impact = impactAt;
    if (t <= 0) return 0;
    if (t < impact) {
      final u = t / impact;
      return travel * u * u;
    }
    final release = releaseAt;
    if (t < release) return travel;
    final u = ((t - release) / (1 - release)).clamp(0.0, 1.0);
    final back = 1 - u;
    return travel * back * back * (3 - 2 * back);
  }

  /// How hard the blocker is being shoved at [t]: a jolt at impact, held
  /// while the arrow is pressed against it, dying away over the back leg,
  /// 0..1.
  double shoveAt(double t) {
    if (t < impactAt) return 0;
    final release = releaseAt;
    if (t < release) return 1;
    final u = ((t - release) / (1 - release)).clamp(0.0, 1.0);
    final left = 1 - u;
    return left * left;
  }

  /// The blocked-cell flash, 0..1: full at impact, fading over the back leg.
  double flashAt(double t) => shoveAt(t);

  /// The whole screen's sideways jolt at [t], -1..1: nothing until impact,
  /// then [kJoltCycles] shakes that die away over the back leg, so a crash
  /// registers even when the eye is nowhere near the arrow.
  double joltAt(double t) {
    final impact = impactAt;
    if (t < impact) return 0;
    final u = ((t - impact) / (1 - impact)).clamp(0.0, 1.0);
    final left = 1 - u;
    return sin(u * kJoltCycles * 2 * pi) * left * left;
  }
}
