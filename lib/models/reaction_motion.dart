/// How the game reacts to an ending, as plain numbers. Pure Dart (no
/// Flutter), so the shapes are testable without pumping a widget.
///
/// Two moods, and neither is subtle — the point is that an ending should be
/// felt without reading the card:
///
/// * a **hop** for a cleared level: the screen squashes, springs up tall,
///   and settles, the way a cartoon does when it is pleased with itself;
/// * a **slump** for a spent allowance or a run-out clock: every arrow left
///   on the board droops and tilts, like the whole puzzle giving up.
library;

import 'dart:math';

/// How long the hop takes.
const int kHopMs = 620;

/// How long the slump takes to settle.
const int kSlumpMs = 720;

/// How far the hop stretches at its tallest, as a fraction (0.12 = 12%).
const double kHopStretch = 0.12;

/// How far an arrow droops at full slump, in cells.
const double kSlumpDrop = 0.55;

/// How far an arrow tilts at full slump, in radians (~4.6°).
const double kSlumpTilt = 0.08;

/// The vertical scale of a hop at [t] (0..1), where 1.0 is unchanged. Squash
/// down, spring up past normal, then a small overshoot on the way back.
double hopScaleY(double t) {
  final u = t.clamp(0.0, 1.0);
  // Two parts, because one damped oscillator spends its amplitude on the
  // squash and leaves the spring too small to read: a squash that is gone
  // inside the first fifth, and a spring that overshoots and rings out.
  final squash = -exp(-u * 26);
  final spring = sin(u * pi * 1.9) * exp(-u * 2.6);
  return 1 + kHopStretch * (squash + 1.35 * spring);
}

/// The horizontal scale of a hop at [t] — the opposite of [hopScaleY], so
/// the screen keeps its area and reads as squash-and-stretch rather than a
/// zoom.
double hopScaleX(double t) => 1 / hopScaleY(t);

/// How far into the slump [t] (0..1) is, eased so the arrows sag quickly and
/// then sink the last little way.
double slumpProgress(double t) {
  final u = t.clamp(0.0, 1.0);
  return 1 - pow(1 - u, 2.4).toDouble();
}

/// How far the arrow with id [id] has drooped at [t], in cells. Each arrow
/// gets its own amount and its own little delay from its id, so the board
/// sags raggedly instead of moving as one block.
double slumpDropFor(int id, double t) {
  final lag = 0.18 * _jitter(id, 3);
  final own = (t - lag) / (1 - lag);
  return slumpProgress(own) * kSlumpDrop * (0.55 + 0.75 * _jitter(id, 5));
}

/// How far the arrow with id [id] has tilted at [t], in radians. Half lean
/// left, half right.
double slumpTiltFor(int id, double t) {
  final lean = id.isEven ? 1.0 : -1.0;
  return slumpProgress(t) * kSlumpTilt * lean * (0.4 + 0.9 * _jitter(id, 7));
}

/// A stable pseudo-random 0..1 from an id, so an arrow droops the same way
/// every time the same board slumps.
double _jitter(int id, int salt) => ((id * 2654435761 + salt * 40503) % 1000) / 1000;
