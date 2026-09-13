import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every level generates its full arrow count, solvable, within bounds', () {
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
      }
      // Dense like a printed puzzle: at least four cells in five are used.
      final used = p.arrows.fold<int>(0, (n, a) => n + a.length);
      expect(used / spec.cellCount, greaterThanOrEqualTo(0.8), reason: 'level ${spec.level} fill');
      expect(sw.elapsedMilliseconds, lessThan(6000), reason: 'level ${spec.level} too slow');
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
    final last = puzzleForLevel(specForLevel(20));
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
      expect(profile, hasLength(p.arrowCount), reason: 'level ${spec.level} solvable');
      // The generator's cap is soft; this is the hard line the levels hold.
      expect(profile.first, lessThanOrEqualTo(spec.openMoves + 3), reason: 'level ${spec.level} start');
      expect(profile.reduce(max), lessThanOrEqualTo(spec.openMoves + 5), reason: 'level ${spec.level} widest');
      expect(p.meanOpenMoves, lessThanOrEqualTo(spec.openMoves + 1), reason: 'level ${spec.level} mean');
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
