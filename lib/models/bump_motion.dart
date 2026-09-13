/// The bump: a blocked arrow slides forward until its head meets the arrow in
/// its way, then springs back to where it was. Pure Dart, so the provider
/// can time the knock and the buzz to the moment of impact and the board
/// can draw the same motion.
library;

import '../engine/cell.dart';
import '../engine/puzzle.dart';

class BumpMotion {
  const BumpMotion({required this.travel});

  /// The bump of arrow [id] on [puzzle] against [blockedCell], the first
  /// occupied cell on its ray: the head runs up to that cell and stops just
  /// short of its centre, so the tip touches the blocker's edge.
  factory BumpMotion.forTap(Puzzle puzzle, int id, Cell blockedCell) {
    final ray = puzzle.arrows[id].exitRay(puzzle.width, puzzle.height);
    final steps = ray.indexOf(blockedCell) + 1;
    return BumpMotion(travel: steps - kStopShort);
  }

  /// How far short of the blocker's centre the head stops, in cells.
  static const double kStopShort = 0.6;

  /// The back leg, a fixed spring home.
  static const int backMs = 300;

  /// Cells the head moves before impact.
  final double travel;

  /// The forward leg: a quick accelerating slide, longer for a longer run.
  int get forwardMs => (90 + travel * 55).round().clamp(110, 320);

  int get totalMs => forwardMs + backMs;

  /// The moment of impact as a fraction of [totalMs].
  double get impactAt => forwardMs / totalMs;

  /// The head's offset along its track, in cells, at progress [t] (0..1):
  /// accelerating into the blocker, then easing back home.
  double offsetAt(double t) {
    final impact = impactAt;
    if (t <= 0) return 0;
    if (t < impact) {
      final u = t / impact;
      return travel * u * u;
    }
    final u = ((t - impact) / (1 - impact)).clamp(0.0, 1.0);
    final back = 1 - u;
    return travel * back * back * back;
  }

  /// How hard the blocker is being shoved at [t]: a jolt at impact that
  /// dies away over the back leg, 0..1.
  double shoveAt(double t) {
    final impact = impactAt;
    if (t < impact) return 0;
    final u = ((t - impact) / (1 - impact)).clamp(0.0, 1.0);
    final left = 1 - u;
    return left * left;
  }

  /// The blocked-cell flash, 0..1: full at impact, fading over the back leg.
  double flashAt(double t) => shoveAt(t);
}
