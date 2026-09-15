import 'package:arrow_game/models/reaction_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hop', () {
    test('starts squashed, springs past normal, and settles', () {
      // Squash first: shorter and wider than normal.
      expect(hopScaleY(0.02), lessThan(1));
      expect(hopScaleX(0.02), greaterThan(1));

      // Somewhere in the middle it springs up taller than normal.
      final tallest = [
        for (var i = 0; i <= 100; i++) hopScaleY(i / 100),
      ].reduce((a, b) => a > b ? a : b);
      expect(tallest, greaterThan(1 + kHopStretch * 0.5));

      // And it has all but settled by the end.
      expect(hopScaleY(1), closeTo(1, 0.01));
    });

    test('keeps its area: the axes are reciprocal', () {
      for (final t in [0.0, 0.1, 0.35, 0.7, 1.0]) {
        expect(hopScaleX(t) * hopScaleY(t), closeTo(1, 1e-9));
      }
    });

    test('is clamped outside 0..1', () {
      expect(hopScaleY(-1), hopScaleY(0));
      expect(hopScaleY(4), hopScaleY(1));
    });
  });

  group('slump', () {
    test('runs from nothing to fully drooped', () {
      expect(slumpProgress(0), 0);
      expect(slumpProgress(1), 1);
      // Eased: most of the sag happens early.
      expect(slumpProgress(0.5), greaterThan(0.5));
    });

    test('every arrow ends up drooped, and none by more than the cap', () {
      for (var id = 0; id < 40; id++) {
        expect(slumpDropFor(id, 0), 0, reason: 'arrow $id at rest');
        final drop = slumpDropFor(id, 1);
        expect(drop, greaterThan(0), reason: 'arrow $id droops');
        expect(drop, lessThanOrEqualTo(kSlumpDrop * 1.31), reason: 'arrow $id capped');
      }
    });

    test('arrows droop by different amounts, so the board sags raggedly', () {
      final drops = {for (var id = 0; id < 12; id++) slumpDropFor(id, 0.5)};
      expect(drops.length, greaterThan(6));
    });

    test('the same arrow always droops the same way', () {
      expect(slumpDropFor(7, 0.4), slumpDropFor(7, 0.4));
      expect(slumpTiltFor(7, 0.4), slumpTiltFor(7, 0.4));
    });

    test('tilts lean both ways and stay within the cap', () {
      expect(slumpTiltFor(0, 1), greaterThan(0));
      expect(slumpTiltFor(1, 1), lessThan(0));
      for (var id = 0; id < 40; id++) {
        expect(slumpTiltFor(id, 1).abs(), lessThanOrEqualTo(kSlumpTilt * 1.31));
      }
    });
  });
}
