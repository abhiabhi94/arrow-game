import 'package:arrow_game/data/level_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are 80 levels, numbered 1..80 in order', () {
    expect(totalLevels, 80);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(81), throwsRangeError);
  });

  test('boards, arrow counts and lengths never shrink; the clock is reasonable', () {
    for (var level = 2; level <= totalLevels; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(cur.cellCount, greaterThanOrEqualTo(prev.cellCount), reason: 'level $level');
      expect(cur.arrows, greaterThanOrEqualTo(prev.arrows), reason: 'level $level');
      expect(cur.minLength, greaterThanOrEqualTo(prev.minLength), reason: 'level $level');
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
    // over a hundred by level 20, past three hundred by level 60 and close
    // to four hundred by the end, with the longest runs stretching as the
    // boards grow.
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(8).arrows, greaterThanOrEqualTo(50));
    expect(specForLevel(20).arrows, greaterThanOrEqualTo(140));
    expect(specForLevel(40).arrows, greaterThanOrEqualTo(220));
    expect(specForLevel(60).arrows, greaterThanOrEqualTo(300));
    expect(specForLevel(80).arrows, greaterThanOrEqualTo(380));
    expect(specForLevel(40).maxLength, greaterThan(specForLevel(20).maxLength));
    expect(specForLevel(60).maxLength, greaterThan(specForLevel(40).maxLength));
    expect(specForLevel(80).maxLength, greaterThan(specForLevel(60).maxLength));
    // From level 4 on the player gets two moves to find, never a spread.
    expect(specForLevel(4).openMoves, 2);
    expect(specForLevel(totalLevels).openMoves, 2);
    // The clock is brisk but never a lottery: from level 10 on at least
    // 2.4 s an arrow (it was 2.5 before every level lost 5% of its clock).
    for (final s in levelSpecs.where((s) => s.level >= 10 && s.level <= 40)) {
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(2400), reason: 'level ${s.level}');
    }
    // The endgame tightens the pace a little every level, from ~2.54 s an
    // arrow at 41 down to 2.30 s at 60, and the last act keeps squeezing it
    // to 2.00 s on the finale — never under, and never more than a few
    // hundredths of a second a level, so the limits still grow with the
    // count, just slower and slower: 11 minutes 40 seconds on level 60 and
    // only 12 minutes 48 seconds on the finale for eighty more arrows. The
    // clock is part of the difficulty, not a match for it.
    for (var level = 41; level <= totalLevels; level++) {
      final pace = specForLevel(level).timeLimitMs / specForLevel(level).arrows;
      expect(pace, greaterThanOrEqualTo(level <= 60 ? 2300 : 2000), reason: 'level $level');
      if (level > 41) {
        final before = specForLevel(level - 1).timeLimitMs / specForLevel(level - 1).arrows;
        expect(pace, lessThan(before), reason: 'level $level');
        expect(before - pace, lessThan(30), reason: 'level $level');
      }
    }
    expect(specForLevel(41).timeLimitMs, 580000);
    expect(specForLevel(60).timeLimitMs, 700000);
    expect(specForLevel(totalLevels).timeLimitMs, 768000);
    // Eighty more arrows for barely a minute more: the last act's clock
    // grows by under a tenth while its arrow count grows by a quarter.
    expect(specForLevel(80).timeLimitMs / specForLevel(60).timeLimitMs, lessThan(1.1));
    expect(specForLevel(80).arrows / specForLevel(60).arrows, greaterThan(1.25));
  });

  test('the endgame has no short arrows and is dealt from a chosen variant', () {
    for (var level = 1; level <= 40; level++) {
      expect(specForLevel(level).variant, 0, reason: 'level $level keeps its first board');
    }
    for (var level = 41; level <= totalLevels; level++) {
      expect(specForLevel(level).minLength, 4, reason: 'level $level');
    }
  });

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    // Seeds are distinct across every level and variant the table could use
    // (the last act's picks run into the hundreds).
    final seeds = <int>{};
    for (final s in levelSpecs) {
      for (var v = 0; v < 640; v++) {
        expect(seeds.add(s.seed + v * 1_000_003), isTrue, reason: 'level ${s.level} variant $v');
      }
    }
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 26000ms)');
  });
}
