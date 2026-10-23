import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where [level] sits in its chapter's shape.
enum Beat { teach, climb }

Beat beatOf(int level) => (level - 1) % kChapterLength == 0 ? Beat.teach : Beat.climb;

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

  test('every chapter past the first opens easy and climbs steadily to the same top', () {
    for (final chapter in chapters.skip(1)) {
      final climb = <LevelSpec>[];
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
          case Beat.climb:
            climb.add(s);
        }
      }
      // The second level is a modest board — no cliff after the card — and
      // the twentieth the chapter's biggest, with a steady step between
      // (six or seven arrows a level) and the longest run never shortening.
      expect(climb.first.arrows, inInclusiveRange(25, 40), reason: 'chapter ${chapter.index} opens');
      expect(climb.last.arrows, inInclusiveRange(140, 160), reason: 'chapter ${chapter.index} ends');
      for (var i = 1; i < climb.length; i++) {
        expect(climb[i].arrows - climb[i - 1].arrows, inInclusiveRange(5, 8), reason: 'level ${climb[i].level}');
        expect(climb[i].maxLength, greaterThanOrEqualTo(climb[i - 1].maxLength), reason: 'level ${climb[i].level}');
        expect(climb[i].timeLimitMs, greaterThan(climb[i - 1].timeLimitMs), reason: 'level ${climb[i].level}');
      }
      // Every chapter tops out at the same count: what makes a later chapter
      // harder is its twist, not more arrows.
      expect(climb.last.arrows, specForLevel(40).arrows, reason: 'chapter ${chapter.index} finale');
    }
  });

  test('the count is capped and the clock stays under ten minutes', () {
    for (final s in levelSpecs) {
      expect(s.arrows, lessThanOrEqualTo(160), reason: 'level ${s.level}');
      expect(s.timeLimitMs, lessThan(600000), reason: 'level ${s.level}');
      expect(s.timeLimitMs, greaterThanOrEqualTo(24000), reason: 'level ${s.level}');
      // Room for the arrows: ~11.3 free cells each on the climb.
      if (beatOf(s.level) == Beat.climb && s.level > kChapterLength) {
        expect(s.freeCellCount / s.arrows, inInclusiveRange(11.0, 13.5), reason: 'level ${s.level}');
      }
    }
    // No level past the plain chapter is bigger than its finale.
    final top = specForLevel(20).arrows;
    for (final s in levelSpecs.where((s) => s.level > kChapterLength)) {
      expect(s.arrows, lessThanOrEqualTo(top + 10), reason: 'level ${s.level}');
    }
  });

  test('the pace per arrow grows chapter by chapter and pays for every twist', () {
    // A mirror, a lock, a hidden head or a tether is one more thing to read
    // on every arrow, so a later chapter gives *more* time an arrow for the
    // arrows themselves — never under three seconds past the plain chapter
    // — and every twist on the board buys seconds on top.
    double pace(LevelSpec s) {
      final f = s.features;
      final think = (f.mirrors * 1 + f.locks * 4 + f.hidden * 3 + f.pairs * 3) * 1000;
      return (s.timeLimitMs - think) / s.arrows;
    }

    for (var i = 2; i <= 20; i++) {
      for (var c = 2; c < chapters.length; c++) {
        final here = specForLevel(chapters[c - 1].firstLevel + i - 1);
        final next = specForLevel(chapters[c].firstLevel + i - 1);
        expect(pace(next), greaterThan(pace(here)), reason: 'level ${next.level}');
      }
      for (final chapter in chapters.skip(1)) {
        expect(pace(specForLevel(chapter.firstLevel + i - 1)), greaterThanOrEqualTo(3000), reason: 'level ${chapter.firstLevel + i - 1}');
      }
    }
    // Twists cost time: the Locks finale has eight locks and the clock to
    // match, over its own pace alone.
    final finale60 = specForLevel(60);
    expect(finale60.features.locks, 8);
    expect(finale60.timeLimitMs, greaterThan(finale60.arrows * 3200 + 15000));
    // The twists buy time, so a late chapter's level is never shorter on
    // the clock than the same level of the chapter before.
    for (var i = 2; i <= 20; i++) {
      for (var c = 2; c < chapters.length; c++) {
        expect(
          specForLevel(chapters[c].firstLevel + i - 1).timeLimitMs,
          greaterThan(specForLevel(chapters[c - 1].firstLevel + i - 1).timeLimitMs),
          reason: 'level ${chapters[c].firstLevel + i - 1}',
        );
      }
    }
  });

  test('lengths: short pieces early, none in the later chapters', () {
    for (final s in levelSpecs.where((s) => s.level > kChapterLength)) {
      final chapter = chapterOf(s.level);
      if (beatOf(s.level) == Beat.climb) {
        expect(s.minLength, chapter.index <= 2 ? 3 : 4, reason: 'level ${s.level}');
      }
    }
    expect(specForLevel(100).maxLength, greaterThan(specForLevel(40).maxLength));
  });

  test('mirrors stand on every board from the Mirrors chapter on, a handful to a couple of dozen', () {
    for (final s in levelSpecs.where((s) => s.level > kChapterLength)) {
      final f = s.features;
      if (ruleTaughtAt(s.level) != null && chapterOf(s.level).rule != ChapterRule.mirrors) {
        expect(f.mirrors, 0, reason: 'level ${s.level} teaches another twist alone');
        continue;
      }
      expect(f.mirrors, inInclusiveRange(2, 25), reason: 'level ${s.level}');
      // Thickest through their own chapter: about one for every eight
      // arrows there, one for every fourteen after, never fewer than two.
      if (beatOf(s.level) == Beat.climb) {
        final want = (s.arrows / (chapterOf(s.level).index == 2 ? 8 : 14)).round();
        expect(f.mirrors, want < 2 ? 2 : want, reason: 'level ${s.level}');
      }
    }
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
