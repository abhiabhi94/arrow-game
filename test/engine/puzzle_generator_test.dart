import 'dart:math';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/board_shape.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every level generates its full arrow count, solvable, within bounds, with its twists', () {
    for (final spec in levelSpecs) {
      final sw = Stopwatch()..start();
      final p = puzzleForLevel(spec);
      sw.stop();
      expect(p.width, spec.width);
      expect(p.height, spec.height);
      expect(p.arrowCount, spec.arrows, reason: 'level ${spec.level} arrow count');
      expect(p.isSolvable, isTrue, reason: 'level ${spec.level} solvable');
      for (final a in p.arrows) {
        // Tails may grow past the nominal maximum while filling gaps.
        expect(
          a.length,
          inInclusiveRange(spec.minLength, spec.maxLength + kGapTailSlack),
          reason: 'level ${spec.level} $a',
        );
        for (final c in a.cells) {
          expect(p.isWall(c), isFalse, reason: 'level ${spec.level} $a on a wall');
        }
      }
      // Dense like a printed puzzle: at least four cells in five of the
      // board the shape leaves are used. A teaching board is airy on
      // purpose, and a small sprint board has less room to pack.
      final used = p.arrows.fold<int>(0, (n, a) => n + a.length);
      final teaching = ruleTaughtAt(spec.level) != null;
      final floor = teaching ? 0.5 : (spec.cellCount < 300 ? 0.75 : 0.8);
      expect(used / spec.freeCellCount, greaterThanOrEqualTo(floor), reason: 'level ${spec.level} fill');
      // The shape and every twist the level asks for are on the board.
      final f = spec.features;
      expect(p.walls, wallsFor(f.shape, spec.width, spec.height), reason: 'level ${spec.level} walls');
      expect(p.locks, hasLength(f.locks), reason: 'level ${spec.level} locks');
      expect(p.hidden, hasLength(f.hidden), reason: 'level ${spec.level} hidden');
      expect(p.pairs, hasLength(f.pairs * 2), reason: 'level ${spec.level} pairs');
      expect(sw.elapsedMilliseconds, lessThan(6000), reason: 'level ${spec.level} too slow');
    }
  });

  test('the twists are placed where they count', () {
    final p = puzzleForLevel(specForLevel(100));
    // One twist per arrow, so no piece is two things at once.
    final twisted = <int>[...p.locks.keys, ...p.locks.values, ...p.hidden, ...p.pairs.keys];
    expect(twisted.toSet(), hasLength(twisted.length));
    for (final e in p.locks.entries) {
      // Locks are numbered in pairs, and a key sits well away from its lock.
      expect(p.lockNumber(e.key), p.lockNumber(e.value));
      final a = p.arrows[e.key].head;
      final k = p.arrows[e.value].head;
      expect((a.x - k.x).abs() + (a.y - k.y).abs(), greaterThanOrEqualTo(kLockReach), reason: '${e.key}');
    }
    // Whether [from] waits, however indirectly, for [goal].
    bool waitsFor(int from, int goal) {
      final seen = <int>{};
      final stack = <int>[from];
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        if (i == goal) return true;
        if (!seen.add(i)) continue;
        stack.addAll(p.dependenciesOf(i));
        final partner = p.partnerOf(i);
        if (partner != null) stack.add(partner);
      }
      return false;
    }

    for (final h in p.hidden) {
      // Something beside a hidden head does not have to wait for it, so it
      // can always be uncovered rather than guessed.
      expect(p.neighboursOf(h).any((n) => !waitsFor(n, h)), isTrue, reason: 'hidden $h');
    }
    for (final e in p.pairs.entries) {
      expect(p.neighboursOf(e.key), contains(e.value), reason: 'pair ${e.key}');
    }
  });

  test('generation is deterministic in the seed', () {
    final spec = specForLevel(9);
    final a = PuzzleGenerator(random: Random(spec.seed)).generate(spec);
    final b = PuzzleGenerator(random: Random(spec.seed)).generate(spec);
    expect(a.arrows.map((x) => x.toString()), b.arrows.map((x) => x.toString()));
    final c = PuzzleGenerator(random: Random(1)).generate(spec);
    expect(c.arrowCount, spec.arrows);
  });

  test('later levels are more tangled than the first', () {
    final first = puzzleForLevel(specForLevel(1));
    final last = puzzleForLevel(specForLevel(totalLevels));
    expect(last.dependencyDepth, greaterThan(first.dependencyDepth));
    expect(last.difficultyScore, greaterThan(first.difficultyScore * 10));
  });

  test('no level is trivially free: some arrow must wait its turn', () {
    for (final spec in levelSpecs.where((s) => s.level >= 2)) {
      final p = puzzleForLevel(spec);
      expect(p.removable(const {}).length, lessThan(p.arrowCount), reason: 'level ${spec.level}');
    }
  });

  test('the choice stays narrow: a handful of taps at the start, few at any moment', () {
    for (final spec in levelSpecs) {
      final p = puzzleForLevel(spec);
      final profile = p.openMoveProfile();
      expect(profile, hasLength(p.arrowCount - p.pairs.length ~/ 2), reason: 'level ${spec.level} solvable');
      // The generator's cap is soft; this is the hard line the levels hold.
      expect(profile.first, lessThanOrEqualTo(spec.openMoves + PuzzleGenerator.startSlack), reason: 'level ${spec.level} start');
      expect(profile.reduce(max), lessThanOrEqualTo(spec.openMoves + PuzzleGenerator.widestSlack), reason: 'level ${spec.level} widest');
      expect(PuzzleGenerator.holdsChoice(spec, profile), isTrue, reason: 'level ${spec.level}');
      expect(p.meanOpenMoves, lessThanOrEqualTo(spec.openMoves + 1), reason: 'level ${spec.level} mean');
    }
  });

  test('each chapter is a harder find than the one before, taken as a whole', () {
    // The hunt — arrows on the board for every one that can go at a typical
    // moment — climbs chapter by chapter over the climb levels, even as the
    // count no longer runs away: the twists tangle the graph as much as
    // more arrows did.
    double hunt(Chapter c) {
      var sum = 0.0;
      var n = 0;
      for (var level = c.firstLevel + 1; level <= c.lastLevel - 1; level++) {
        final i = (level - 1) % kChapterLength + 1;
        if (i == 5 || i == 15 || i == 10) continue;
        sum += puzzleForLevel(specForLevel(level)).arrowsPerOpenMove;
        n++;
      }
      return sum / n;
    }

    final first = hunt(chapters[0]);
    var before = hunt(chapters[1]);
    expect(before, greaterThan(first));
    for (final chapter in chapters.skip(2)) {
      final now = hunt(chapter);
      expect(now, greaterThan(before * 0.9), reason: 'chapter ${chapter.index}');
      before = now;
    }
  });

  test('an arrow may point straight at another as long as nothing cycles', () {
    // Level 10 and up are full of arrows that wait for a neighbour; every one
    // of them still leaves in the greedy order.
    final p = puzzleForLevel(specForLevel(12));
    final waiting = p.arrows.where((a) => p.blockersOf(a.id).isNotEmpty).length;
    expect(waiting, greaterThan(p.arrowCount ~/ 2));
    expect(p.solvingOrder(), hasLength(p.arrowCount));
  });

  test('candidate count scales down with the arrow count', () {
    expect(candidatesFor(5), 24);
    expect(candidatesFor(60), 10);
    expect(candidatesFor(170), kMinCandidates);
    expect(candidatesFor(224), kMinCandidates);
    expect(candidatesFor(304), kMinCandidates);
    expect(candidatesFor(384), kMinCandidates);
  });

  test('a board that holds the choice beats a tighter one that spreads', () {
    const spec = LevelSpec(level: 1, width: 5, height: 5, arrows: 3, minLength: 2, maxLength: 3, timeLimitMs: 1000);
    expect(PuzzleGenerator.holdsChoice(spec, const <int>[]), isTrue);
    expect(PuzzleGenerator.holdsChoice(spec, const <int>[5, 1, 1]), isTrue);
    expect(PuzzleGenerator.holdsChoice(spec, const <int>[6, 1, 1]), isFalse);
    expect(PuzzleGenerator.holdsChoice(spec, const <int>[1, 7, 1]), isTrue);
    expect(PuzzleGenerator.holdsChoice(spec, const <int>[1, 8, 1]), isFalse);
  });

  test('places as many arrows as fit when the board cannot take them all', () {
    const impossible = LevelSpec(
      level: 1,
      width: 3,
      height: 3,
      arrows: 9,
      minLength: 3,
      maxLength: 3,
      timeLimitMs: 1000,
    );
    final p = PuzzleGenerator(random: Random(3)).generate(impossible);
    expect(p.arrowCount, lessThan(9));
    expect(p.arrowCount, greaterThan(0));
    expect(p.isSolvable, isTrue);
  });
}
