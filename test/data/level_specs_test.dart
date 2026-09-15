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
      expect(cur.minLength, greaterThanOrEqualTo(prev.minLength), reason: 'level $level');
      // The choice only ever narrows.
      expect(cur.openMoves, lessThanOrEqualTo(prev.openMoves), reason: 'level $level');
    }
    // The board is capped, so consecutive levels may share a size and count
    // and differ only in the puzzle — but never for long: the ramp moves at
    // least one axis within three levels.
    var plateau = 1;
    for (var level = 2; level <= totalLevels; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      final same = cur.cellCount == prev.cellCount &&
          cur.arrows == prev.arrows &&
          cur.minLength == prev.minLength &&
          cur.maxLength == prev.maxLength;
      plateau = same ? plateau + 1 : 1;
      expect(plateau, lessThanOrEqualTo(3), reason: 'level $level repeats the level before it');
    }
    for (final s in levelSpecs) {
      // Half a minute at least, never past five; at least 3.5 s an arrow.
      expect(s.timeLimitMs, inInclusiveRange(25000, 300000), reason: 'level ${s.level}');
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(3500), reason: 'level ${s.level}');
      // Every board fits a phone with no zoom: 12x18 is the biggest grid that
      // still draws a finger-sized cell on a 360x800 screen.
      expect(s.width, lessThanOrEqualTo(12), reason: 'level ${s.level}');
      expect(s.height, lessThanOrEqualTo(18), reason: 'level ${s.level}');
    }
    // The board grows from a handful of cells to the cap by level 45 and the
    // arrow count roughly five-fold, with the longest runs stretching as it
    // goes. The counts stay small on purpose — the difficulty is the tangle.
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(45).cellCount, 12 * 18);
    expect(specForLevel(totalLevels).arrows, greaterThanOrEqualTo(25));
    expect(specForLevel(60).maxLength, greaterThan(specForLevel(20).maxLength));
    expect(specForLevel(60).minLength, greaterThan(specForLevel(20).minLength));
    // The axis that matters: the board offers a choice for two thirds of the
    // game, then stops. From level 41 there is usually exactly one move.
    expect(specForLevel(1).openMoves, 2);
    expect(specForLevel(40).openMoves, 2);
    expect(specForLevel(41).openMoves, 1);
    expect(specForLevel(totalLevels).openMoves, 1);
    // The clock loosens as the choice narrows — finding the only move takes
    // longer than picking one of three — and the finale is just over 4 min.
    expect(specForLevel(1).timeLimitMs / specForLevel(1).arrows, lessThan(6000));
    expect(
      specForLevel(60).timeLimitMs / specForLevel(60).arrows,
      greaterThan(specForLevel(1).timeLimitMs / specForLevel(1).arrows),
    );
    expect(specForLevel(totalLevels).timeLimitMs, 244000);
  });

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 28000ms)');
  });
}
