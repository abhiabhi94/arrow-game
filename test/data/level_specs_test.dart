import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where [level] sits in its chapter's shape.
enum Beat { teach, climb }

Beat beatOf(int level) => chapterOf(level).firstLevel == level ? Beat.teach : Beat.climb;

/// The flat chapters past the plain rectangle.
Iterable<Chapter> get twistChapters => chapters.where((c) => c.index >= 2 && c.rule != ChapterRule.cube);

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

  test('the first half is flat, the second half is the block', () {
    for (final s in levelSpecs) {
      expect(s.isCube, s.level >= kFirstCubeLevel, reason: 'level ${s.level}');
      if (s.isCube) {
        expect(s.faces, 6, reason: 'level ${s.level}');
        expect(s.width, s.height, reason: 'level ${s.level}: a face is square');
      }
    }
  });

  test('the first chapter is the plain rectangle, growing every level', () {
    for (var level = 2; level <= chapters.first.lastLevel; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(cur.features.isPlain, isTrue, reason: 'level $level');
      expect(cur.cellCount, greaterThan(prev.cellCount), reason: 'level $level');
      expect(cur.arrows, greaterThan(prev.arrows), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThan(prev.timeLimitMs), reason: 'level $level');
      expect(cur.openMoves, lessThanOrEqualTo(prev.openMoves), reason: 'level $level');
    }
    expect(specForLevel(1).arrows, lessThanOrEqualTo(6));
    expect(specForLevel(4).openMoves, 2);
    expect(specForLevel(10).arrows, greaterThanOrEqualTo(100));
    // The clock is brisk but never a lottery: from level 8 on at least
    // 2.3 s an arrow.
    for (final s in levelSpecs.where((s) => s.level >= 8 && s.level <= 10)) {
      expect(s.timeLimitMs / s.arrows, greaterThanOrEqualTo(2300), reason: 'level ${s.level}');
    }
  });

  test('every flat chapter past the first opens easy and climbs steadily to the same top', () {
    for (final chapter in twistChapters) {
      expect(chapter.length, kFlatChapterLength);
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
      // the tenth the chapter's biggest, with a steady step between (ten to
      // twelve arrows a level) and the longest run never shortening.
      expect(climb.first.arrows, inInclusiveRange(25, 40), reason: 'chapter ${chapter.index} opens');
      expect(climb.last.arrows, inInclusiveRange(110, 130), reason: 'chapter ${chapter.index} ends');
      for (var i = 1; i < climb.length; i++) {
        expect(climb[i].arrows - climb[i - 1].arrows, inInclusiveRange(10, 13), reason: 'level ${climb[i].level}');
        expect(climb[i].maxLength, greaterThanOrEqualTo(climb[i - 1].maxLength), reason: 'level ${climb[i].level}');
        expect(climb[i].timeLimitMs, greaterThan(climb[i - 1].timeLimitMs), reason: 'level ${climb[i].level}');
      }
      // Every chapter tops out at the same count: what makes a later chapter
      // harder is its twist, not more arrows.
      expect(climb.last.arrows, specForLevel(20).arrows, reason: 'chapter ${chapter.index} finale');
    }
  });

  test('the block climbs a little every level, from a teaching cube to the top', () {
    final cube = chapters.last;
    expect(cube.rule, ChapterRule.cube);
    final teach = specForLevel(cube.firstLevel);
    expect(teach.arrows, 18, reason: 'three arrows a face');
    expect(teach.openMoves, 3);
    expect(teach.features.isPlain, isTrue);
    for (var level = cube.firstLevel + 2; level <= cube.lastLevel; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      // A few more arrows every level, never a cliff.
      expect(cur.arrows - prev.arrows, inInclusiveRange(2, 3), reason: 'level $level');
      expect(cur.width, greaterThanOrEqualTo(prev.width), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThanOrEqualTo(prev.timeLimitMs), reason: 'level $level');
      expect(cur.maxLength, greaterThanOrEqualTo(prev.maxLength), reason: 'level $level');
    }
    expect(specForLevel(cube.firstLevel + 1).arrows, inInclusiveRange(25, 36));
    expect(specForLevel(totalLevels).arrows, inInclusiveRange(130, 150));
    // A face is never a big board: it has to read at phone width.
    for (var level = cube.firstLevel; level <= cube.lastLevel; level++) {
      expect(specForLevel(level).width, lessThanOrEqualTo(18), reason: 'level $level');
    }
  });

  test('on the block the twists come back ten levels at a time and stay', () {
    // Plain faces to 60, mirrors from 61, locks from 71, hidden heads from
    // 81, pairs from 91.
    for (var level = kFirstCubeLevel; level <= totalLevels; level++) {
      final f = specForLevel(level).features;
      expect(f.mirrors > 0, level >= 61, reason: 'level $level mirrors');
      expect(f.locks > 0, level >= 71, reason: 'level $level locks');
      expect(f.hidden > 0, level >= 81, reason: 'level $level hidden');
      expect(f.pairs > 0, level >= 91, reason: 'level $level pairs');
      // At least one of each on every face once it is back.
      if (f.mirrors > 0) expect(f.mirrors, greaterThanOrEqualTo(6), reason: 'level $level');
      if (f.locks > 0) expect(f.locks, greaterThanOrEqualTo(6), reason: 'level $level');
      if (f.hidden > 0) expect(f.hidden, greaterThanOrEqualTo(6), reason: 'level $level');
      if (f.pairs > 0) expect(f.pairs, greaterThanOrEqualTo(6), reason: 'level $level');
    }
  });

  test('a cube level shares its arrows and twists out over its faces', () {
    final s = specForLevel(100);
    final faces = s.faceSpecs;
    expect(faces, hasLength(6));
    expect(faces.fold<int>(0, (n, f) => n + f.arrows), s.arrows);
    expect(faces.fold<int>(0, (n, f) => n + f.features.mirrors), s.features.mirrors);
    expect(faces.fold<int>(0, (n, f) => n + f.features.locks), s.features.locks);
    expect(faces.fold<int>(0, (n, f) => n + f.features.hidden), s.features.hidden);
    expect(faces.fold<int>(0, (n, f) => n + f.features.pairs), s.features.pairs);
    for (final f in faces) {
      expect(f.isCube, isFalse);
      expect(f.width, s.width);
      expect(f.height, s.height);
      expect((f.arrows - s.arrows / 6).abs(), lessThan(1));
    }
    // Every face is its own deal.
    expect(faces.map((f) => f.seed).toSet(), hasLength(6));
    expect(specForLevel(1).faceSpecs, isEmpty);
    expect(s.cellCount, 6 * s.width * s.height);
  });

  test('the count is capped and the clock stays under ten minutes', () {
    for (final s in levelSpecs) {
      expect(s.arrows, lessThanOrEqualTo(150), reason: 'level ${s.level}');
      expect(s.timeLimitMs, lessThan(600000), reason: 'level ${s.level}');
      expect(s.timeLimitMs, greaterThanOrEqualTo(24000), reason: 'level ${s.level}');
      // Room for the arrows: ~11.3 free cells each on the flat climb, ~9.5
      // on a face of the block (which grows a whole row and column at a
      // time, so a little more room on the levels just after it grows).
      if (beatOf(s.level) == Beat.climb && s.level > chapters.first.lastLevel) {
        final (low, high) = s.isCube ? (8.5, 13.0) : (11.0, 13.5);
        expect(s.freeCellCount / s.arrows, inInclusiveRange(low, high), reason: 'level ${s.level}');
      }
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

    final flat = twistChapters.toList();
    for (var i = 2; i <= kFlatChapterLength; i++) {
      for (var c = 1; c < flat.length; c++) {
        final here = specForLevel(flat[c - 1].firstLevel + i - 1);
        final next = specForLevel(flat[c].firstLevel + i - 1);
        expect(pace(next), greaterThan(pace(here)), reason: 'level ${next.level}');
        // The twists buy time, so a late chapter's level is never shorter on
        // the clock than the same level of the chapter before.
        expect(next.timeLimitMs, greaterThan(here.timeLimitMs), reason: 'level ${next.level}');
      }
      for (final chapter in flat) {
        expect(pace(specForLevel(chapter.firstLevel + i - 1)), greaterThanOrEqualTo(3000), reason: 'level ${chapter.firstLevel + i - 1}');
      }
    }
    // Twists cost time: the Locks finale has six locks and the clock to
    // match, over its own pace alone.
    final finale = specForLevel(30);
    expect(finale.features.locks, 6);
    expect(finale.timeLimitMs, greaterThan(finale.arrows * 3200 + 15000));
    // On the block, never under the flat chapters' last pace, short of the
    // ten-minute cap.
    for (var level = kFirstCubeLevel + 1; level <= totalLevels; level++) {
      final s = specForLevel(level);
      if (s.timeLimitMs < 599000) expect(pace(s), greaterThanOrEqualTo(3300), reason: 'level $level');
    }
  });

  test('lengths: short pieces early, none in the later flat chapters', () {
    for (final s in levelSpecs.where((s) => s.level > chapters.first.lastLevel && !s.isCube)) {
      final chapter = chapterOf(s.level);
      if (beatOf(s.level) == Beat.climb) {
        expect(s.minLength, chapter.index <= 2 ? 3 : 4, reason: 'level ${s.level}');
      }
    }
    expect(specForLevel(50).maxLength, greaterThan(specForLevel(20).maxLength));
    // On the block an arrow is never longer than a face is wide.
    for (final s in levelSpecs.where((s) => s.isCube)) {
      expect(s.maxLength, lessThan(s.width), reason: 'level ${s.level}');
    }
  });

  test('mirrors stand on every flat board from the Mirrors chapter on, a handful to a couple of dozen', () {
    for (final s in levelSpecs.where((s) => s.level > chapters.first.lastLevel && !s.isCube)) {
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
    expect(specForLevel(51).toString(), startsWith('LevelSpec(51: 6 faces of 6x6, 18 arrows'));
    // The variant, the clock factor and the faces all carry over.
    final s = specForLevel(70);
    expect(s.withVariant(3).faces, 6);
    expect(s.withClockFactor(2).faces, 6);
    expect(s.withClockFactor(2).timeLimitMs, s.timeLimitMs * 2);
  });
}
