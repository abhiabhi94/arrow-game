import 'package:arrow_game/data/level_specs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// The block, 101-150.
void main() {
  levelChecks(from: 101, to: 150);

  test('on the block the faces grow deeper level by level', () {
    // Each ten levels' faces are harder work than the ten before: longer
    // chains to unpick, face by face.
    double depth(int from) {
      var sum = 0;
      for (var level = from; level < from + 10; level++) {
        for (final face in specForLevel(level).faceSpecs) {
          sum += dealtFace(face).dependencyDepth;
        }
      }
      return sum / 60;
    }

    var before = depth(102);
    for (final from in <int>[111, 121, 131, 141]) {
      final now = depth(from);
      expect(now, greaterThan(before * 0.95), reason: 'levels $from+');
      before = now;
    }
    expect(depth(141), greaterThan(depth(102)));
  });
}
