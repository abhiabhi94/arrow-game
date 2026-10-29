import 'dart:math';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every level generates its full arrow count, solvable, within bounds, with its twists', () {
    for (final spec in levelSpecs) {
      final sw = Stopwatch()..start();
      final p = puzzleForLevel(spec);
      sw.stop();
      final faceSizes = [for (var f = 0; f < spec.faces; f++) spec.faceSizeOf(f)];
      expect(p.width, spec.isCube ? faceSizes.fold<int>(0, (w, f) => w + f.$1) : spec.width);
      expect(p.height, spec.isCube ? faceSizes.map((f) => f.$2).reduce(max) : spec.height);
      expect(p.isCube, spec.isCube);
      if (spec.isCube) {
        expect(p.faceCount, spec.faces);
        expect(p.faceSizes, faceSizes);
      }
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
          expect(p.isMirror(c), isFalse, reason: 'level ${spec.level} $a on a mirror');
        }
      }
      // Dense like a printed puzzle: at least four cells in five of the
      // board the mirrors leave are used. A teaching board is airy on
      // purpose, and a small sprint board has less room to pack.
      final used = p.arrows.fold<int>(0, (n, a) => n + a.length);
      final teaching = ruleTaughtAt(spec.level) != null;
      if (spec.isCube) {
        // A face of the block is a small board with a handful of arrows,
        // so the first faces are roomier; the block as a whole still packs.
        expect(used / spec.freeCellCount, greaterThanOrEqualTo(teaching ? 0.4 : 0.7), reason: 'level ${spec.level} fill');
        for (var f = 0; f < p.faceCount; f++) {
          final onFace = p.arrowsOn(f).fold<int>(0, (n, id) => n + p.arrows[id].length);
          final (fw, fh) = spec.faceSizeOf(f);
          final free = fw * fh - p.mirrors.keys.where((m) => p.faceOfCell(m) == f).length;
          expect(onFace / free, greaterThanOrEqualTo(teaching ? 0.3 : 0.6), reason: 'level ${spec.level} face $f fill');
        }
      } else {
        final floor = teaching ? 0.5 : (spec.cellCount < 300 ? 0.75 : 0.8);
        expect(used / spec.freeCellCount, greaterThanOrEqualTo(floor), reason: 'level ${spec.level} fill');
      }
      // Every twist the level asks for is on the board.
      final f = spec.features;
      expect(p.mirrors, hasLength(f.mirrors), reason: 'level ${spec.level} mirrors');
      for (final m in p.mirrors.keys) {
        // Mirrors stand clear of the edge (of their face) and of each other.
        final face = p.faceOfCell(m);
        expect(p.onFace(m).x, inInclusiveRange(kMirrorMargin, p.faceWidthOf(face) - 1 - kMirrorMargin), reason: 'level ${spec.level} $m');
        expect(m.y, inInclusiveRange(kMirrorMargin, p.faceHeightOf(face) - 1 - kMirrorMargin), reason: 'level ${spec.level} $m');
        for (final other in p.mirrors.keys) {
          if (other == m) continue;
          expect((m.x - other.x).abs() > 1 || (m.y - other.y).abs() > 1, isTrue, reason: 'level ${spec.level} $m $other');
        }
      }
      if (f.mirrors > 0) {
        // The mirrors are on the arrows' paths, not ornaments: most are on
        // some arrow's way out (one way out may cross two of them).
        final hit = p.mirrors.keys.where((m) => p.arrows.any((a) => p.rayOf(a.id).contains(m))).length;
        expect(hit, greaterThanOrEqualTo((f.mirrors * 0.6).ceil()), reason: 'level ${spec.level} mirrors hit');
        final bent = p.arrows.where((a) => p.bends(a.id)).length;
        expect(bent, greaterThanOrEqualTo((hit / 2).ceil()), reason: 'level ${spec.level} arrows bent');
      }
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

  test('built a face at a time, a level is the same board, with a pause before each face', () async {
    String shape(Puzzle p) =>
        '${p.faceSizes} ${p.arrows.map((a) => a.toString()).join()} ${p.mirrors} ${p.locks} ${p.hidden} ${p.pairs}';
    for (final level in <int>[9, 120, 201, 205]) {
      final spec = specForLevel(level);
      var pauses = 0;
      final stepped = await puzzleForLevelInSteps(spec, () async => pauses++);
      expect(shape(stepped), shape(puzzleForLevel(spec)), reason: 'level $level');
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
    final first = puzzleForLevel(specForLevel(1));
    final last = puzzleForLevel(specForLevel(100));
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
      if (spec.isCube) {
        // On the block the choice is the face's: each face holds it.
        for (final face in spec.faceSpecs) {
          expect(PuzzleGenerator.keepsRules(face, PuzzleGenerator.dealFace(face)), isTrue, reason: 'level ${spec.level} ${face.seed}');
        }
        continue;
      }
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
    for (final chapter in chapters.skip(2).where((c) => !c.rule.onBlock)) {
      final now = hunt(chapter);
      expect(now, greaterThan(before * 0.9), reason: 'chapter ${chapter.index}');
      before = now;
    }
  });

  test('on the block the faces keep to themselves and grow deeper level by level', () {
    // Every arrow leaves by its own face, and nothing on one face waits for
    // anything on another.
    for (final level in <int>[101, 120, 135, 150, 151, 175, 200, 201, 230, 250]) {
      final p = puzzleForLevel(specForLevel(level));
      for (final a in p.arrows) {
        final face = p.faceOf(a.id);
        expect(a.cells.every((c) => p.faceOfCell(c) == face), isTrue, reason: 'level $level $a');
        expect(p.rayOf(a.id).every((c) => p.faceOfCell(c) == face), isTrue, reason: 'level $level $a');
        expect(p.dependenciesOf(a.id).every((d) => p.faceOf(d) == face), isTrue, reason: 'level $level $a');
      }
      for (var f = 0; f < 6; f++) {
        expect(p.arrowsOn(f), isNotEmpty, reason: 'level $level face $f');
      }
    }
    // Each ten levels' faces are harder work than the ten before: longer
    // chains to unpick, face by face.
    double depth(int from) {
      var sum = 0;
      for (var level = from; level < from + 10; level++) {
        final spec = specForLevel(level);
        for (final face in spec.faceSpecs) {
          sum += PuzzleGenerator.dealFace(face).dependencyDepth;
        }
      }
      return sum / 60;
    }

    var before = depth(102);
    for (final from in <int>[111, 121, 131, 141]) {
      final now = depth(from);
      expect(now, greaterThan(before * 0.95), reason: 'levels $from+');
      before = now;
    }
    expect(depth(141), greaterThan(depth(102)));
  });

  test('the squeeze is a harder find than the block it follows', () {
    // One way out of a face at a time where the block let two, and more
    // on every face: more arrows to look through for every one that can go.
    double hunt(List<int> levels) =>
        levels.map((l) => puzzleForLevel(specForLevel(l)).arrowsPerOpenMove).reduce((a, b) => a + b) / levels.length;
    expect(hunt(<int>[175, 200]), greaterThan(hunt(<int>[145, 150])));
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
