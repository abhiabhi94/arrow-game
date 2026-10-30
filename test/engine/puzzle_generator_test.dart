import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// Every level of the table is dealt and checked in full, a range to a file,
// in levels_*_test.dart beside this one (see test/support/dealt_levels.dart).
void main() {
  test('the twists are placed where they count', () {
    final p = dealtLevel(100);
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

  test('built a face at a time, a level is the same board, with a pause before each face', () async {
    String shape(Puzzle p) =>
        '${p.faceSizes} ${p.arrows.map((a) => a.toString()).join()} ${p.mirrors} ${p.locks} ${p.hidden} ${p.pairs}';
    for (final level in <int>[9, 120, 201, 205]) {
      final spec = specForLevel(level);
      var pauses = 0;
      final stepped = await puzzleForLevelInSteps(spec, () async => pauses++);
      expect(shape(stepped), shape(puzzleForLevel(spec)), reason: 'level $level');
      // The levels_*_test.dart files check the board they share, so it has
      // to be the one the game deals.
      expect(shape(dealtLevel(level)), shape(puzzleForLevel(spec)), reason: 'level $level');
      expect(pauses, spec.isCube ? spec.faces : 1, reason: 'level $level');
    }
  });

  test('a box picks each face from fewer boards; a cube is dealt as it always was', () {
    expect(PuzzleGenerator.faceCandidatesFor(specForLevel(150)), isNull);
    expect(PuzzleGenerator.faceCandidatesFor(specForLevel(200)), isNull);
    expect(PuzzleGenerator.faceCandidatesFor(specForLevel(201)), PuzzleGenerator.kBoxFaceCandidates);
    expect(PuzzleGenerator.faceCandidatesFor(specForLevel(250)), PuzzleGenerator.kBoxFaceCandidates);
    // A face of a box, dealt from five boards, keeps every rule.
    final face = specForLevel(230).faceSpecs.first;
    final p = PuzzleGenerator.dealFace(face, candidates: PuzzleGenerator.kBoxFaceCandidates);
    expect(PuzzleGenerator.keepsRules(face, p), isTrue);
  });

  test('later levels are more tangled than the first', () {
    final first = dealtLevel(1);
    final last = dealtLevel(100);
    expect(last.dependencyDepth, greaterThan(first.dependencyDepth));
    expect(last.difficultyScore, greaterThan(first.difficultyScore * 10));
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
