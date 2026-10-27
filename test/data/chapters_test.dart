import 'package:arrow_game/data/chapter_demos.dart';
import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('five chapters of twenty levels, then two of fifty on the block, cover the trail in order', () {
    expect(chapters, hasLength(7));
    expect(chapters.first.firstLevel, 1);
    expect(chapters.last.lastLevel, totalLevels);
    for (var i = 1; i < chapters.length; i++) {
      expect(chapters[i].firstLevel, chapters[i - 1].lastLevel + 1);
    }
    for (final c in chapters.take(5)) {
      expect(c.length, kChapterLength);
    }
    expect(chapters[5].firstLevel, kFirstCubeLevel);
    expect(chapters[5].length, 50);
    expect(chapters.last.firstLevel, kFirstSqueezeLevel);
    expect(chapters.last.length, 50);
    expect(chapters.where((c) => !c.rule.onBlock), hasLength(kFlatChapterCount));
    expect(chapterOf(1).rule, ChapterRule.lines);
    expect(chapterOf(20).rule, ChapterRule.lines);
    expect(chapterOf(21).rule, ChapterRule.mirrors);
    expect(chapterOf(40).index, 2);
    expect(chapterOf(41).rule, ChapterRule.locks);
    expect(chapterOf(61).rule, ChapterRule.fog);
    expect(chapterOf(81).rule, ChapterRule.pairs);
    expect(chapterOf(100).rule, ChapterRule.pairs);
    expect(chapterOf(100).contains(81), isTrue);
    expect(chapterOf(100).contains(80), isFalse);
    expect(chapterOf(101).rule, ChapterRule.cube);
    expect(chapterOf(150).rule, ChapterRule.cube);
    expect(chapterOf(151).rule, ChapterRule.squeeze);
    expect(chapterOf(200).rule, ChapterRule.squeeze);
    expect(() => chapterOf(0), throwsRangeError);
    expect(() => chapterOf(201), throwsRangeError);
  });

  test('each chapter past the first teaches its twist on its first level', () {
    expect(ruleTaughtAt(1), isNull);
    expect(ruleTaughtAt(2), isNull);
    expect(ruleTaughtAt(21), ChapterRule.mirrors);
    expect(ruleTaughtAt(22), isNull);
    expect(ruleTaughtAt(41), ChapterRule.locks);
    expect(ruleTaughtAt(61), ChapterRule.fog);
    expect(ruleTaughtAt(81), ChapterRule.pairs);
    expect(ruleTaughtAt(100), isNull);
    expect(ruleTaughtAt(101), ChapterRule.cube);
    expect(ruleTaughtAt(111), isNull);
    expect(ruleTaughtAt(151), ChapterRule.squeeze);
    // The squeeze is the block again: it has no card of its own.
    expect(ChapterRule.squeeze.hasCard, isFalse);
    expect(ChapterRule.values.where((r) => !r.hasCard), [ChapterRule.squeeze]);
    expect(ruleTaughtAt(152), isNull);
  });

  test('the level table matches the chapters: a twist appears with its chapter and stays', () {
    for (final s in levelSpecs.where((s) => !s.isCube)) {
      final chapter = chapterOf(s.level);
      final f = s.features;
      final teaching = ruleTaughtAt(s.level) != null;
      // Nothing from a later chapter ever leaks back.
      if (chapter.index < 2) expect(f.mirrors, 0, reason: 'level ${s.level}');
      if (chapter.index < 3) expect(f.locks, 0, reason: 'level ${s.level}');
      if (chapter.index < 4) expect(f.hidden, 0, reason: 'level ${s.level}');
      if (chapter.index < 5) expect(f.pairs, 0, reason: 'level ${s.level}');
      // The chapter's own twist is on every one of its levels.
      switch (chapter.rule) {
        case ChapterRule.lines:
          expect(f.isPlain, isTrue, reason: 'level ${s.level}');
        case ChapterRule.mirrors:
          expect(f.mirrors, greaterThan(0), reason: 'level ${s.level}');
        case ChapterRule.locks:
          expect(f.locks, greaterThan(0), reason: 'level ${s.level}');
        case ChapterRule.fog:
          expect(f.hidden, greaterThan(0), reason: 'level ${s.level}');
        case ChapterRule.pairs:
          expect(f.pairs, greaterThan(0), reason: 'level ${s.level}');
        case ChapterRule.cube || ChapterRule.squeeze:
          fail('level ${s.level} is flat');
      }
      // A teaching board carries the new twist alone, on a small board.
      if (teaching) {
        expect(s.arrows, lessThanOrEqualTo(12), reason: 'level ${s.level}');
        expect(s.openMoves, 3, reason: 'level ${s.level}');
        final twists = (f.locks > 0 ? 1 : 0) + (f.hidden > 0 ? 1 : 0) + (f.pairs > 0 ? 1 : 0) + (f.mirrors > 0 ? 1 : 0);
        expect(twists, 1, reason: 'level ${s.level}');
      }
    }
  });

  test('the chapter for a player follows the levels cleared, twenty a chapter', () {
    expect(chapterForProgress(0).index, 1);
    expect(chapterForProgress(1).index, 1);
    expect(chapterForProgress(20).index, 1);
    expect(chapterForProgress(21).index, 2);
    expect(chapterForProgress(40).index, 2);
    expect(chapterForProgress(41).index, 3);
    expect(chapterForProgress(60).index, 3);
    expect(chapterForProgress(61).index, 4);
    expect(chapterForProgress(80).index, 4);
    expect(chapterForProgress(81).index, 5);
    expect(chapterForProgress(100).index, 5);
    expect(chapterForProgress(101).index, 6);
    expect(chapterForProgress(150).index, 6);
    expect(chapterForProgress(151).index, 7);
    expect(chapterForProgress(500).index, 7);
    expect(chapterForProgress(-3).index, 1);
  });

  test('the daily board borrows the last flat chapter once the player is on the block', () {
    expect(dailyChapterFor(0).rule, ChapterRule.lines);
    expect(dailyChapterFor(45).rule, ChapterRule.locks);
    expect(dailyChapterFor(99).rule, ChapterRule.pairs);
    // Every flat level cleared: the block is open, and so is the daily one.
    expect(dailyChapterFor(100).rule, ChapterRule.cube);
    expect(dailyChapterFor(101).rule, ChapterRule.cube);
    expect(dailyChapterFor(150).rule, ChapterRule.cube);
    expect(dailyChapterFor(151).rule, ChapterRule.cube);
    expect(dailyChapterFor(200).rule, ChapterRule.cube);
  });

  test('every chapter card has a small, solvable board that shows its twist, and a script that plays it', () {
    for (final rule in ChapterRule.values.where((r) => r.hasCard)) {
      final p = demoPuzzleFor(rule);
      expect(p.isSolvable, isTrue, reason: rule.name);
      expect(p.arrowCount, lessThanOrEqualTo(rule.onBlock ? 4 : 3), reason: rule.name);
      final spec = demoSpecFor(rule);
      expect(spec.width, p.faceWidth);
      expect(spec.isCube, p.isCube);
      expect(spec.arrows, p.arrowCount);
      // The script clears the board in order: every tap but a deliberate
      // first tap on a lock (or on a hidden head) slides something out.
      final removed = <int>{};
      for (final id in demoScriptFor(rule)) {
        if (p.canExit(id, removed)) {
          removed.addAll(p.exitGroup(id));
        } else if (p.hidden.contains(id) && !p.revealedBy(removed).contains(id)) {
          expect(p.revealersOf(id), isNotEmpty, reason: '$rule tap $id');
        } else {
          expect(p.blockOf(id, removed)!.isLock, isTrue, reason: '$rule tap $id');
        }
      }
      expect(removed, hasLength(p.arrowCount), reason: rule.name);
      switch (rule) {
        case ChapterRule.lines:
          expect(p.hasFeatures, isFalse);
        case ChapterRule.mirrors:
          expect(p.mirrors, hasLength(2));
          // Both arrows bounce, and the second is turned up the column the
          // first lies across, so it has to go second.
          expect(p.bends(0), isTrue);
          expect(p.bends(1), isTrue);
          expect(p.blockersOf(1), {0});
        case ChapterRule.locks:
          expect(p.locks, {0: 1});
          expect(p.lockNumber(0), 1);
          expect(p.lockNumber(1), 1);
        case ChapterRule.fog:
          expect(p.hidden, {1});
          expect(p.revealedBy({0}), {1});
        case ChapterRule.pairs:
          expect(p.partnerOf(0), 1);
        case ChapterRule.cube:
          // One arrow on each face round the block's middle, played in turn.
          expect(p.isCube, isTrue);
          expect(p.faceCount, 6);
          expect(<int>[for (final id in demoScriptFor(rule)) p.faceOf(id)], [0, 1, 2, 3]);
        case ChapterRule.squeeze:
          fail('the squeeze has no card');
      }
    }
  });
}
