import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/daily.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the day index counts local calendar days', () {
    expect(dayIndexOf(DateTime(1970, 1, 1, 13)), 0);
    expect(dayIndexOf(DateTime(1970, 1, 2, 0, 1)), 1);
    expect(dayIndexOf(DateTime(2026, 10, 22, 23, 59)), 20748);
    expect(dayIndexOf(DateTime(2026, 10, 23)), 20749);
  });

  test('the seed changes with the day and with the salt', () {
    final a = dailySeed(20748, 7);
    expect(a, dailySeed(20748, 7));
    expect(a, isNot(dailySeed(20749, 7)));
    expect(a, isNot(dailySeed(20748, 8)));
    expect(a, greaterThanOrEqualTo(0));
    // No two of a year's boards share a seed for one salt, and no two
    // salts share a day's.
    final seeds = <int>{for (var d = 0; d < 365; d++) dailySeed(20000 + d, 7)};
    expect(seeds, hasLength(365));
    final salts = <int>{for (var s = 0; s < 1000; s++) dailySeed(20748, s)};
    expect(salts, hasLength(1000));
  });

  test('the board borrows the chapter\'s twists and is about five minutes', () {
    for (final chapter in chapters) {
      final spec = dailySpec(day: 20748, chapter: chapter, salt: 3);
      expect(spec.isDaily, isTrue);
      expect(spec.level, LevelSpec.dailyLevel);
      expect(spec.timeLimitMs, kDailyTimeLimitMs);
      expect(spec.seed, dailySeed(20748, 3));
      final f = spec.features;
      switch (chapter.rule) {
        case ChapterRule.lines:
          expect(f.isPlain, isTrue);
        case ChapterRule.mirrors:
          expect(f.mirrors, inInclusiveRange(8, 12));
          expect(f.locks + f.hidden + f.pairs, 0);
        case ChapterRule.locks:
          expect(f.locks, inInclusiveRange(3, 5));
          expect(f.hidden + f.pairs, 0);
        case ChapterRule.fog:
          expect(f.hidden, inInclusiveRange(3, 5));
          expect(f.locks, 2);
          expect(f.pairs, 0);
        case ChapterRule.pairs:
          expect(spec.isCube, isFalse);
          expect(f.pairs, inInclusiveRange(3, 5));
          expect(f.hidden, 2);
        case ChapterRule.cube || ChapterRule.squeeze || ChapterRule.box:
          // On the block, the daily board is a block too: six faces of
          // fifteen, every twist on every face.
          expect(spec.isCube, isTrue);
          expect(spec.faces, kDailyFaces);
          expect(spec.arrows, 90);
          for (final n in <int>[f.mirrors, f.locks, f.hidden, f.pairs]) {
            expect(n, greaterThanOrEqualTo(spec.faces));
          }
          expect(f.mirrors, inInclusiveRange(12, 16));
          expect(f.pairs, inInclusiveRange(6, 8));
          // The block's clock rule (2.4 s an arrow, the twists' seconds and
          // 2 s a face) comes to about the same five minutes.
          final rule = spec.arrows * 2.4 + f.mirrors + 4 * f.locks + 3 * f.hidden + 3 * f.pairs + 2 * spec.faces;
          expect(rule, inInclusiveRange(270, 330));
          // A face's room, at the block's density.
          expect(spec.freeCellCount / spec.arrows, greaterThan(9));
          continue;
      }
      // Room for its arrows at the trail's density.
      expect(spec.freeCellCount / spec.arrows, greaterThan(10.5), reason: chapter.rule.name);
    }
  });

  test('the mirrors and the counts turn with the day', () {
    final mirrors = <int>{};
    final counts = <int>{};
    for (var d = 0; d < 30; d++) {
      final spec = dailySpec(day: 20700 + d, chapter: chapters[4], salt: 11);
      mirrors.add(spec.features.mirrors);
      counts.add(spec.features.pairs);
    }
    expect(mirrors, {8, 9, 10, 11, 12});
    expect(counts, {3, 4, 5});
  });

  test('the daily block\'s faces each keep the rules', () {
    for (var d = 0; d < 3; d++) {
      final spec = dailySpec(day: 20748 + d, chapter: chapters[5], salt: 5);
      for (final face in spec.faceSpecs) {
        expect(PuzzleGenerator.keepsRules(face, PuzzleGenerator.dealFace(face)), isTrue, reason: 'day $d ${face.seed}');
      }
    }
  });

  test('a daily board deals its full count with its twists, solvable', () {
    for (final chapter in chapters) {
      final spec = dailySpec(day: 20748, chapter: chapter, salt: 5);
      final p = puzzleForLevel(spec);
      expect(p.arrowCount, spec.arrows, reason: chapter.rule.name);
      expect(p.isSolvable, isTrue, reason: chapter.rule.name);
      expect(p.mirrors.length, spec.features.mirrors, reason: chapter.rule.name);
      expect(p.locks.length, spec.features.locks, reason: chapter.rule.name);
      expect(p.hidden.length, spec.features.hidden, reason: chapter.rule.name);
      expect(p.pairs.length ~/ 2, spec.features.pairs, reason: chapter.rule.name);
    }
  });
}
