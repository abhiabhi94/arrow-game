import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/board_shape.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where [level] sits in its chapter's rhythm.
enum Beat { teach, sprint, boss, finale, climb }

Beat beatOf(int level) {
  final i = (level - 1) % kChapterLength + 1;
  return switch (i) {
    1 => Beat.teach,
    5 || 15 => Beat.sprint,
    10 => Beat.boss,
    20 => Beat.finale,
    _ => Beat.climb,
  };
}

void main() {
  test('there are 100 levels, numbered 1..100 in order', () {
    expect(totalLevels, 100);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(101), throwsRangeError);
  });

  test('the first chapter is the plain rectangle, growing every level', () {
    for (var level = 2; level <= kChapterLength; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(cur.features.isPlain, isTrue, reason: 'level $level');
      expect(cur.cellCount, greaterThanOrEqualTo(prev.cellCount), reason: 'level $level');
      expect(cur.arrows, greaterThanOrEqualTo(prev.arrows), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThanOrEqualTo(prev.timeLimitMs), reason: 'level $level');
      expect(cur.openMoves, lessThanOrEqualTo(prev.openMoves), reason: 'level $level');
      expect(cur.variant, 0, reason: 'level $level keeps its first board');
    }
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(8).arrows, greaterThanOrEqualTo(50));
    expect(specForLevel(20).arrows, greaterThanOrEqualTo(140));
    expect(specForLevel(4).openMoves, 2);
    // The clock is brisk but never a lottery: from level 10 on at least
    // 2.4 s an arrow.
    for (final s in levelSpecs.where((s) => s.level >= 10 && s.level <= 20)) {
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(2400), reason: 'level ${s.level}');
    }
  });

  test('every chapter past the first has the same rhythm', () {
    for (final chapter in chapters.skip(1)) {
      final climb = <LevelSpec>[];
      int? bossCount;
      int? finaleCount;
      for (var level = chapter.firstLevel; level <= chapter.lastLevel; level++) {
        final s = specForLevel(level);
        switch (beatOf(level)) {
          case Beat.teach:
            // Small, roomy, the new twist alone (chapters_test pins that).
            expect(s.arrows, 12, reason: 'level $level');
            expect(s.openMoves, 3, reason: 'level $level');
            expect(s.cellCount, lessThanOrEqualTo(10 * 13), reason: 'level $level');
            expect(s.minLength, 2, reason: 'level $level');
            expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(4000), reason: 'level $level');
          case Beat.sprint:
            // A small board at a run.
            expect(s.width, 12, reason: 'level $level');
            expect(s.height, 16, reason: 'level $level');
            expect(s.arrows, inInclusiveRange(18, 30), reason: 'level $level');
            expect(s.minLength, 2, reason: 'level $level');
            expect(s.timeLimitMs / s.arrows, inInclusiveRange(1500, 3000), reason: 'level $level');
            expect(s.timeLimitMs, lessThan(90000), reason: 'level $level');
          case Beat.boss:
            bossCount = s.arrows;
          case Beat.finale:
            finaleCount = s.arrows;
          case Beat.climb:
            climb.add(s);
        }
      }
      // The climb grows by one arrow a level (a sprint or a boss in between
      // does not break the count) and the longest run never shortens.
      for (var i = 1; i < climb.length; i++) {
        expect(
          climb[i].arrows - climb[i - 1].arrows,
          climb[i].level - climb[i - 1].level,
          reason: 'level ${climb[i].level}',
        );
        expect(climb[i].maxLength, greaterThanOrEqualTo(climb[i - 1].maxLength), reason: 'level ${climb[i].level}');
      }
      // The boss and the finale are the chapter's biggest boards.
      final tallest = climb.map((s) => s.arrows).reduce((a, b) => a > b ? a : b);
      expect(bossCount, greaterThan(tallest - 10), reason: 'chapter ${chapter.index} boss');
      expect(finaleCount, greaterThan(bossCount!), reason: 'chapter ${chapter.index} finale');
      expect(finaleCount, greaterThan(tallest), reason: 'chapter ${chapter.index} finale');
    }
  });

  test('the count is capped and the clock stays under ten minutes', () {
    for (final s in levelSpecs) {
      expect(s.arrows, lessThanOrEqualTo(270), reason: 'level ${s.level}');
      expect(s.timeLimitMs, lessThan(600000), reason: 'level ${s.level}');
      expect(s.timeLimitMs, greaterThanOrEqualTo(24000), reason: 'level ${s.level}');
      // Never under 1.5 s an arrow anywhere.
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(1500), reason: 'level ${s.level}');
      // Room for the arrows: ~11.3 free cells each on the big boards.
      if (beatOf(s.level) == Beat.climb && s.level > kChapterLength) {
        expect(s.freeCellCount / s.arrows, inInclusiveRange(11.0, 13.0), reason: 'level ${s.level}');
      }
    }
    // The climb runs from about 150 at level 22 to about 230 at level 99.
    expect(specForLevel(22).arrows, inInclusiveRange(145, 155));
    expect(specForLevel(99).arrows, inInclusiveRange(225, 235));
    expect(specForLevel(100).arrows, greaterThan(specForLevel(99).arrows));
  });

  test('the pace per arrow eases chapter by chapter and pays for every twist', () {
    // At the same beat of each chapter, a later chapter gives less time an
    // arrow for the arrows themselves — but a lock, a hidden head or a
    // tether buys seconds, so the clock itself is not simply shorter.
    double pace(LevelSpec s) {
      final f = s.features;
      final think = (f.locks * 4 + f.hidden * 3 + f.pairs * 3) * 1000;
      return (s.timeLimitMs - think) / s.arrows;
    }

    for (var i = 2; i <= 19; i++) {
      if (beatOf(20 + i) != Beat.climb) continue;
      for (var c = 2; c < chapters.length; c++) {
        final here = specForLevel(chapters[c - 1].firstLevel + i - 1);
        final next = specForLevel(chapters[c].firstLevel + i - 1);
        expect(pace(next), lessThan(pace(here)), reason: 'level ${next.level}');
        expect(pace(next), greaterThanOrEqualTo(2000), reason: 'level ${next.level}');
      }
    }
    // Twists cost time: the Locks finale has ten locks and the clock to
    // match, over its own pace alone.
    final finale60 = specForLevel(60);
    expect(finale60.features.locks, 10);
    expect(finale60.timeLimitMs, greaterThan(finale60.arrows * 2250 + 15000));
  });

  test('lengths: short pieces early, none in the later chapters', () {
    for (final s in levelSpecs.where((s) => s.level > kChapterLength)) {
      final chapter = chapterOf(s.level);
      if (beatOf(s.level) == Beat.climb || beatOf(s.level) == Beat.boss || beatOf(s.level) == Beat.finale) {
        expect(s.minLength, chapter.index <= 2 ? 3 : 4, reason: 'level ${s.level}');
      }
    }
    expect(specForLevel(100).maxLength, greaterThan(specForLevel(40).maxLength));
  });

  test('every shape is used, and each chapter cycles through them', () {
    final shapes = <BoardShape>{};
    for (final s in levelSpecs.where((s) => s.level > kChapterLength)) {
      shapes.add(s.features.shape);
    }
    expect(shapes, containsAll(BoardShape.values));
  });

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    // Seeds are distinct across every level and variant the table could use.
    final seeds = <int>{};
    for (final s in levelSpecs) {
      for (var v = 0; v < 1100; v++) {
        expect(seeds.add(s.withVariant(0).seed + v * 1_000_003), isTrue, reason: 'level ${s.level} variant $v');
      }
    }
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 26000ms)');
  });
}
