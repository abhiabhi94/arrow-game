import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where [level] sits in its chapter's shape.
enum Beat { teach, climb }

Beat beatOf(int level) => chapterOf(level).firstLevel == level ? Beat.teach : Beat.climb;

/// The flat chapters (the first hundred levels), and their levels.
final List<Chapter> flatChapters = chapters.where((c) => !c.rule.onBlock).toList();
final List<LevelSpec> flatSpecs = levelSpecs.where((s) => !s.isCube).toList();

/// A level's clock as its rule worked it out, before [kClockTrim]: the
/// paces below are the rule's.
int untrimmed(LevelSpec s) => (s.timeLimitMs / kClockTrim).round();

void main() {
  test('there are 200 levels, numbered 1..200 in order', () {
    expect(totalLevels, 200);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(201), throwsRangeError);
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
      expect(untrimmed(s) / s.arrows, greaterThanOrEqualTo(2400), reason: 'level ${s.level}');
    }
  });

  test('every chapter past the first opens easy and climbs steadily to the same top', () {
    for (final chapter in flatChapters.skip(1)) {
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
            expect(untrimmed(s) / s.arrows, greaterThanOrEqualTo(4000), reason: 'level $level');
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

  test('every clock is trimmed to 95% of what its rule works out', () {
    expect(kClockTrim, 0.95);
    // Level 1 was 26 s and level 100 584 s before the trim.
    expect(specForLevel(1).timeLimitMs, 24700);
    expect(specForLevel(100).timeLimitMs, 554800);
    for (final s in levelSpecs) {
      expect(s.timeLimitMs, lessThanOrEqualTo((599000 * kClockTrim).round()), reason: 'level ${s.level}');
    }
  });

  test('the count is capped and the clock stays under ten minutes', () {
    for (final s in flatSpecs) {
      expect(s.arrows, lessThanOrEqualTo(160), reason: 'level ${s.level}');
      expect(s.timeLimitMs, lessThan(600000), reason: 'level ${s.level}');
      expect(untrimmed(s), greaterThanOrEqualTo(24000), reason: 'level ${s.level}');
      // Room for the arrows: ~11.3 free cells each on the climb.
      if (beatOf(s.level) == Beat.climb && s.level > kChapterLength) {
        expect(s.freeCellCount / s.arrows, inInclusiveRange(11.0, 13.5), reason: 'level ${s.level}');
      }
    }
    // No level past the plain chapter is bigger than its finale.
    final top = specForLevel(20).arrows;
    for (final s in flatSpecs.where((s) => s.level > kChapterLength)) {
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
      return (untrimmed(s) - think) / s.arrows;
    }

    for (var i = 2; i <= 20; i++) {
      for (var c = 2; c < flatChapters.length; c++) {
        final here = specForLevel(flatChapters[c - 1].firstLevel + i - 1);
        final next = specForLevel(flatChapters[c].firstLevel + i - 1);
        expect(pace(next), greaterThan(pace(here)), reason: 'level ${next.level}');
      }
      for (final chapter in flatChapters.skip(1)) {
        expect(pace(specForLevel(chapter.firstLevel + i - 1)), greaterThanOrEqualTo(3000), reason: 'level ${chapter.firstLevel + i - 1}');
      }
    }
    // Twists cost time: the Locks finale has eight locks and the clock to
    // match, over its own pace alone.
    final finale60 = specForLevel(60);
    expect(finale60.features.locks, 8);
    expect(untrimmed(finale60), greaterThan(finale60.arrows * 3200 + 15000));
    // The twists buy time, so a late chapter's level is never shorter on
    // the clock than the same level of the chapter before.
    for (var i = 2; i <= 20; i++) {
      for (var c = 2; c < flatChapters.length; c++) {
        expect(
          specForLevel(flatChapters[c].firstLevel + i - 1).timeLimitMs,
          greaterThan(specForLevel(flatChapters[c - 1].firstLevel + i - 1).timeLimitMs),
          reason: 'level ${flatChapters[c].firstLevel + i - 1}',
        );
      }
    }
  });

  test('lengths: short pieces early, none in the later chapters', () {
    for (final s in flatSpecs.where((s) => s.level > kChapterLength)) {
      final chapter = chapterOf(s.level);
      if (beatOf(s.level) == Beat.climb) {
        expect(s.minLength, chapter.index <= 2 ? 3 : 4, reason: 'level ${s.level}');
      }
    }
    expect(specForLevel(100).maxLength, greaterThan(specForLevel(40).maxLength));
  });

  test('mirrors stand on every board from the Mirrors chapter on, a handful to a couple of dozen', () {
    for (final s in flatSpecs.where((s) => s.level > kChapterLength)) {
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

  test('the first hundred are flat and as they were; the block comes after', () {
    for (final s in levelSpecs) {
      expect(s.isCube, s.level >= kFirstCubeLevel, reason: 'level ${s.level}');
      if (s.isCube) {
        expect(s.faces, 6, reason: 'level ${s.level}');
        expect(s.width, s.height, reason: 'level ${s.level}: a face is square');
      }
    }
    expect(kFirstCubeLevel, 101);
    // The block's clock: never under the flat chapters' last pace, short of
    // the ten-minute cap, and never shorter than the level before.
    double pace(LevelSpec s) {
      final f = s.features;
      final think = (f.mirrors * 1 + f.locks * 4 + f.hidden * 3 + f.pairs * 3) * 1000;
      return (untrimmed(s) - think) / s.arrows;
    }

    for (var level = kFirstCubeLevel + 1; level <= totalLevels; level++) {
      final s = specForLevel(level);
      expect(s.timeLimitMs, lessThan(600000), reason: 'level $level');
      // A face is a small board, quicker to read than level 100's one big
      // one: 2.4 s an arrow before the twists' seconds — until the clock
      // reaches its ten-minute cap, where the squeeze holds it.
      if (untrimmed(s) < 599000) {
        expect(pace(s), greaterThanOrEqualTo(2400), reason: 'level $level');
      }
      // Room on each face: ~9.5 free cells an arrow (a face grows a whole
      // row and column at a time, so a little more just after it grows).
      expect(s.freeCellCount / s.arrows, inInclusiveRange(8.5, 13.0), reason: 'level $level');
      // An arrow is never longer than a face is wide.
      expect(s.maxLength, lessThan(s.width), reason: 'level $level');
    }
    expect(specForLevel(101).toString(), startsWith('LevelSpec(101: 6 faces of 6x6, 18 arrows'));
    final s = specForLevel(120);
    expect(s.withVariant(3).faces, 6);
    expect(s.withClockFactor(2).faces, 6);
    expect(s.withClockFactor(2).timeLimitMs, s.timeLimitMs * 2);
    // No clock (the default) keeps it a block too.
    expect(s.untimed().faces, 6);
    expect(s.untimed().seed, s.seed);
  });

  test('the block warms up, then never drops below level 100 and climbs a little every level', () {
    final cube = chapters[5];
    expect(cube.rule, ChapterRule.cube);
    // How much there is to do on a board: the arrows and the twists, each
    // twist weighed like the seconds the clock gives it.
    int work(LevelSpec s) {
      final f = s.features;
      return s.arrows + 2 * f.mirrors + 4 * f.locks + 3 * f.hidden + 3 * f.pairs;
    }

    final teach = specForLevel(cube.firstLevel);
    expect(teach.arrows, 18, reason: 'three arrows a face');
    expect(teach.openMoves, 3);
    expect(teach.features.isPlain, isTrue);
    // The warm-up brings the twists back one a level.
    expect(specForLevel(102).features, const LevelFeatures(mirrors: 12));
    expect(specForLevel(103).features.locks, greaterThan(0));
    expect(specForLevel(103).features.hidden, 0);
    expect(specForLevel(104).features.hidden, greaterThan(0));
    expect(specForLevel(104).features.pairs, 0);
    // From 105 on: all four twists on every face, about level 100's work,
    // and one more arrow every level.
    final flatTop = specForLevel(100);
    expect(work(specForLevel(105)), greaterThanOrEqualTo(work(flatTop) * 0.95));
    for (var level = 105; level <= cube.lastLevel; level++) {
      final s = specForLevel(level);
      final f = s.features;
      for (final n in <int>[f.mirrors, f.locks, f.hidden, f.pairs]) {
        expect(n, greaterThanOrEqualTo(s.faces), reason: 'level $level: every twist on every face');
      }
      expect(s.arrows, greaterThanOrEqualTo(130), reason: 'level $level');
      if (level > 105) expect(s.arrows - specForLevel(level - 1).arrows, 1, reason: 'level $level');
    }
    // Every level past the teaching cube is a little more than the one
    // before — never the same, never less — and the clock never shrinks.
    for (var level = cube.firstLevel + 2; level <= cube.lastLevel; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(work(cur), greaterThan(work(prev)), reason: 'level $level');
      expect(cur.width, greaterThanOrEqualTo(prev.width), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThanOrEqualTo(prev.timeLimitMs), reason: 'level $level');
    }
    expect(work(specForLevel(totalLevels)), greaterThan(work(flatTop) * 1.4));
    // But never a big board: a face holds at most thirty arrows, and is
    // never wider than eighteen cells.
    for (var level = cube.firstLevel; level <= cube.lastLevel; level++) {
      final s = specForLevel(level);
      expect((s.arrows / s.faces).ceil(), lessThanOrEqualTo(30), reason: 'level $level');
      expect(s.width, lessThanOrEqualTo(18), reason: 'level $level');
    }
  });

  test('the squeeze packs the block tighter and climbs on from level 150', () {
    final squeeze = chapters.last;
    expect(squeeze.rule, ChapterRule.squeeze);
    int work(LevelSpec s) {
      final f = s.features;
      return s.arrows + 2 * f.mirrors + 4 * f.locks + 3 * f.hidden + 3 * f.pairs;
    }

    // One way out of each face at a time, from the teaching cube on.
    for (var level = squeeze.firstLevel; level <= squeeze.lastLevel; level++) {
      final s = specForLevel(level);
      expect(s.isCube, isTrue, reason: 'level $level');
      expect(s.openMoves, 1, reason: 'level $level');
    }
    // A small teaching cube with no twists, then all four twists on every
    // face through the warm-up.
    final teach = specForLevel(squeeze.firstLevel);
    expect(teach.features.isPlain, isTrue);
    expect(teach.arrows, lessThanOrEqualTo(6 * 6));
    for (var level = squeeze.firstLevel + 1; level <= squeeze.lastLevel; level++) {
      final s = specForLevel(level);
      final f = s.features;
      for (final n in <int>[f.mirrors, f.locks, f.hidden, f.pairs]) {
        expect(n, greaterThanOrEqualTo(s.faces), reason: 'level $level: every twist on every face');
      }
    }
    // Past the warm-up it starts a little above level 150 and every level
    // is a little more than the one before, by an arrow or a twist.
    final block = specForLevel(squeeze.firstLevel - 1);
    expect(work(specForLevel(squeeze.firstLevel + 4)), greaterThan(work(block)));
    for (var level = squeeze.firstLevel + 2; level <= squeeze.lastLevel; level++) {
      final prev = specForLevel(level - 1);
      final cur = specForLevel(level);
      expect(work(cur), greaterThan(work(prev)), reason: 'level $level');
      expect(cur.arrows, greaterThanOrEqualTo(prev.arrows), reason: 'level $level');
      expect(cur.width, greaterThanOrEqualTo(prev.width), reason: 'level $level');
      expect(cur.timeLimitMs, greaterThanOrEqualTo(prev.timeLimitMs), reason: 'level $level');
    }
    expect(work(specForLevel(totalLevels)), greaterThan(work(block) * 1.15));
    // Still never a big board: at most thirty-four arrows on a face.
    for (var level = squeeze.firstLevel; level <= squeeze.lastLevel; level++) {
      final s = specForLevel(level);
      expect((s.arrows / s.faces).ceil(), lessThanOrEqualTo(34), reason: 'level $level');
      expect(s.width, lessThanOrEqualTo(18), reason: 'level $level');
    }
  });

  test('a cube level shares its arrows and twists out over its faces', () {
    final s = specForLevel(150);
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

  test('seed and toString', () {
    expect(specForLevel(1).seed, isNot(specForLevel(2).seed));
    // Seeds are distinct across every level and variant the table could use.
    final seeds = <int>{};
    for (final s in levelSpecs) {
      for (var v = 0; v < 1100; v++) {
        expect(seeds.add(s.withVariant(0).seed + v * 1_000_003), isTrue, reason: 'level ${s.level} variant $v');
      }
    }
    expect(specForLevel(1).toString(), 'LevelSpec(1: 5x6, 5 arrows, 24700ms)');
  });
}
