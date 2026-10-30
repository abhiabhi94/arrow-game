import 'dart:math';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

// Dealing a level is the slow part of the suite (all 250 take about two
// minutes), and the checks below used to deal every level three or four
// times over in one file, which ran alone on one core for twelve minutes.
// Now a level is dealt once per test file and shared, and the levels are
// split over several files (test/engine/levels_*_test.dart) so they run in
// parallel. A test file is its own isolate, so the cache never crosses files.

final _levels = <int, Puzzle>{};
final _faces = <(int, int, int, int, int?), Puzzle>{};

/// One face of a block, dealt once in this test file.
Puzzle dealtFace(LevelSpec face, {int? candidates}) => _faces.putIfAbsent(
  (face.seed, face.width, face.height, face.arrows, candidates),
  () => PuzzleGenerator.dealFace(face, candidates: candidates),
);

/// [puzzleForLevel] for a level of the table, dealt once in this test file.
/// A block is put together from [dealtFace] exactly as the generator does it,
/// so its faces can be checked one by one without dealing them again (the
/// generator test pins that this is the board [puzzleForLevel] gives).
Puzzle dealtLevel(int level) => _levels.putIfAbsent(level, () {
  final spec = specForLevel(level);
  if (!spec.isCube) return puzzleForLevel(spec);
  return Puzzle.cube(<Puzzle>[
    for (final face in spec.faceSpecs) dealtFace(face, candidates: PuzzleGenerator.faceCandidatesFor(spec)),
  ]);
});

/// Every level from [from] to [to] deals in full and keeps every pinned rule:
/// its arrow count, solvable, within bounds, every twist placed, no level
/// trivially free, the choice held narrow. These are what guarantee a level
/// is playable; every level of the table is covered by exactly one file.
void levelChecks({required int from, required int to}) {
  final specs = levelSpecs.where((s) => s.level >= from && s.level <= to).toList();

  test('levels $from-$to generate their full arrow count, solvable, within bounds, with their twists', () {
    for (final spec in specs) {
      final sw = Stopwatch()..start();
      final p = dealtLevel(spec.level);
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

  test('levels $from-$to: no level is trivially free, some arrow must wait its turn', () {
    for (final spec in specs.where((s) => s.level >= 2)) {
      final p = dealtLevel(spec.level);
      expect(p.removable(const {}).length, lessThan(p.arrowCount), reason: 'level ${spec.level}');
    }
  });

  test('levels $from-$to: the choice stays narrow, a handful of taps at the start, few at any moment', () {
    for (final spec in specs) {
      if (spec.isCube) {
        // On the block the choice is the face's: each face, as it is dealt
        // for the level, holds it.
        for (final face in spec.faceSpecs) {
          final p = dealtFace(face, candidates: PuzzleGenerator.faceCandidatesFor(spec));
          expect(PuzzleGenerator.keepsRules(face, p), isTrue, reason: 'level ${spec.level} ${face.seed}');
        }
        continue;
      }
      final p = dealtLevel(spec.level);
      final profile = p.openMoveProfile();
      expect(profile, hasLength(p.arrowCount - p.pairs.length ~/ 2), reason: 'level ${spec.level} solvable');
      // The generator's cap is soft; this is the hard line the levels hold.
      expect(profile.first, lessThanOrEqualTo(spec.openMoves + PuzzleGenerator.startSlack), reason: 'level ${spec.level} start');
      expect(profile.reduce(max), lessThanOrEqualTo(spec.openMoves + PuzzleGenerator.widestSlack), reason: 'level ${spec.level} widest');
      expect(PuzzleGenerator.holdsChoice(spec, profile), isTrue, reason: 'level ${spec.level}');
      expect(p.meanOpenMoves, lessThanOrEqualTo(spec.openMoves + 1), reason: 'level ${spec.level} mean');
    }
  });

  final blocks = <int>[101, 120, 135, 150, 151, 175, 200, 201, 230, 250].where((l) => l >= from && l <= to);
  if (blocks.isEmpty) return;
  test('levels $from-$to: on the block the faces keep to themselves', () {
    // Every arrow leaves by its own face, and nothing on one face waits for
    // anything on another.
    for (final level in blocks) {
      final p = dealtLevel(level);
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
  });
}
