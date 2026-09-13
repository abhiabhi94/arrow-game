import 'package:arrow_game/data/level_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are 20 levels, numbered 1..20 in order', () {
    expect(totalLevels, 20);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(21), throwsRangeError);
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
      // A minute at least, never past twenty; at least four seconds an arrow.
      expect(s.timeLimitMs, inInclusiveRange(60000, 1200000), reason: 'level ${s.level}');
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(4000), reason: 'level ${s.level}');
    }
    // The curve is steep: a handful to learn on, dozens by the middle,
    // well over a hundred by the end.
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(8).arrows, greaterThanOrEqualTo(50));
    expect(specForLevel(20).arrows, greaterThanOrEqualTo(140));
    // From level 4 on the player gets two moves to find, never a spread.
    expect(specForLevel(4).openMoves, 2);
    expect(specForLevel(20).openMoves, 2);
    // Thinking levels get a generous clock: over six seconds an arrow.
    for (final s in levelSpecs.where((s) => s.level >= 10)) {
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(6000), reason: 'level ${s.level}');
    }
  });

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 67000ms)');
  });
}
