import 'package:arrow_game/data/level_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are 60 levels, numbered 1..60 in order', () {
    expect(totalLevels, 60);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(61), throwsRangeError);
  });

  test('boards, arrow counts and lengths never shrink; the clock is reasonable', () {
    for (var level = 2; level <= totalLevels; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(cur.cellCount, greaterThanOrEqualTo(prev.cellCount), reason: 'level $level');
      expect(cur.arrows, greaterThanOrEqualTo(prev.arrows), reason: 'level $level');
      expect(cur.maxLength, greaterThanOrEqualTo(prev.maxLength), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThanOrEqualTo(prev.timeLimitMs), reason: 'level $level');
      // The choice only ever narrows.
      expect(cur.openMoves, lessThanOrEqualTo(prev.openMoves), reason: 'level $level');
      // Something must get harder every level.
      expect(
        cur.cellCount > prev.cellCount || cur.arrows > prev.arrows || cur.maxLength > prev.maxLength,
        isTrue,
        reason: 'level $level',
      );
    }
    for (final s in levelSpecs) {
      // Twenty-odd seconds at least, never past thirteen minutes; at least
      // 1.5 s an arrow.
      expect(s.timeLimitMs, inInclusiveRange(24000, 780000), reason: 'level ${s.level}');
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(1500), reason: 'level ${s.level}');
    }
    // The curve is steep: a handful to learn on, dozens by level 8, well
    // over a hundred by level 20 and past three hundred by the end, with
    // the longest runs stretching as the boards grow.
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(8).arrows, greaterThanOrEqualTo(50));
    expect(specForLevel(20).arrows, greaterThanOrEqualTo(140));
    expect(specForLevel(40).arrows, greaterThanOrEqualTo(220));
    expect(specForLevel(60).arrows, greaterThanOrEqualTo(300));
    expect(specForLevel(40).maxLength, greaterThan(specForLevel(20).maxLength));
    expect(specForLevel(60).maxLength, greaterThan(specForLevel(40).maxLength));
    // From level 4 on the player gets two moves to find, never a spread.
    expect(specForLevel(4).openMoves, 2);
    expect(specForLevel(totalLevels).openMoves, 2);
    // The clock is brisk but never a lottery: from level 10 on at least
    // 2.4 s an arrow (it was 2.5 before every level lost 5% of its clock),
    // and the finale is a shade under thirteen minutes.
    for (final s in levelSpecs.where((s) => s.level >= 10)) {
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(2400), reason: 'level ${s.level}');
    }
    expect(specForLevel(totalLevels).timeLimitMs, 770000);
  });

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 26000ms)');
  });
}
