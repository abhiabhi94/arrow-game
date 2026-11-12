import 'dart:math';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/drops.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:arrow_game/widgets/puzzle_board.dart' show tetherCells;
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
  // The Rush's boards start half empty on purpose; [rushChecks] has theirs.
  final specs = levelSpecs.where((s) => s.level >= from && s.level <= to && !s.isDynamic).toList();
  if (specs.isEmpty) return;

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
      // Only a gross bound — a deal gone pathological (a retry loop that no
      // longer ends), not a speed check. The suite runs a file per core, so a
      // deal's wall time here depends on what the other cores are doing:
      // level 181 deals in ~2.7 s alone and took 6.1 s on a busy release
      // runner, which failed a 6 s bound with nothing wrong. Deal speed is
      // the Performance job's (`tool/perf.mjs`, its own budget at 4x
      // throttle, one level at a time).
      expect(sw.elapsedMilliseconds, lessThan(30_000), reason: 'level ${spec.level} too slow');
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

  test('levels $from-$to: no tether ring sits on an arrow\'s head', () {
    for (final spec in specs.where((s) => s.features.pairs > 0)) {
      final p = dealtLevel(spec.level);
      for (final e in p.pairs.entries) {
        final a = p.arrows[e.key];
        final b = p.arrows[e.value];
        final (ca, cb) = tetherCells(a, b);
        expect(ca == a.head || cb == b.head, isFalse, reason: 'level ${spec.level} pair ${a.id}-${b.id}');
      }
    }
  });

  final blocks = <int>[151, 175, 200, 201, 230, 250].where((l) => l >= from && l <= to);
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

/// A Rush level from deal to clear, played by a quick player: every tap an
/// arrow that can go, picked at random, [tapMs] apart (level 125 was
/// cleared at about 1.1 s a tap on a laptop), the drops landing on their
/// time or at once when the board runs low. Asserts what must hold at every
/// moment — every arrow on the board has a way out that leaves, and the
/// board is still clearable — and returns how it went.
({int drops, int arrows, int mirrors, double dropLength, int playedMs, double startFill}) playRush(int level,
    {int tapMs = 1200}) {
  final spec = specForLevel(level);
  final drops = spec.drops!;
  var puzzle = dealtLevel(level);
  final startFill = puzzle.arrows.fold<int>(0, (n, a) => n + a.length) / (spec.width * spec.height);
  final removed = <int>{};
  final random = Random(level);
  var t = 0;
  var nextDrop = drops.everyMs;
  var landed = 0;
  var mirrors = 0;
  var dropCells = 0;
  var dropArrows = 0;
  bool clearable() {
    final gone = <int>{...removed};
    while (true) {
      final open = puzzle.removable(gone);
      if (open.isEmpty) return gone.length == puzzle.arrowCount;
      gone.addAll(open);
    }
  }

  while (true) {
    final left = puzzle.arrowCount - removed.length;
    if (landed < drops.count && (left <= kDropLowWater || t >= nextDrop)) {
      final drop = planDrop(puzzle, removed, drops, dropRandom(spec, landed));
      if (drop != null) {
        expect(drop.arrows.length, inInclusiveRange(1, drops.arrows), reason: 'level $level drop $landed');
        expect(drop.mirrors.length, lessThanOrEqualTo(drops.mirrors), reason: 'level $level drop $landed');
        for (final a in drop.arrows) {
          expect(a.length, inInclusiveRange(2, drops.maxLength), reason: 'level $level $a');
          dropCells += a.length;
          dropArrows++;
        }
        mirrors += drop.mirrors.length;
        puzzle = drop.landOn(puzzle);
        landed++;
        nextDrop = t + drops.everyMs;
        for (final a in puzzle.arrows.where((a) => !removed.contains(a.id))) {
          final ray = puzzle.rayOf(a.id);
          final out = ray.isEmpty ? a.head.step(a.heading) : ray.last.step(puzzle.exitHeadingOf(a.id));
          expect(out.isInside(puzzle.width, puzzle.height), isFalse, reason: 'level $level: $a has no way out');
          expect(ray.any(a.cells.contains), isFalse, reason: 'level $level: $a is in its own way');
        }
        expect(clearable(), isTrue, reason: 'level $level drop $landed');
      }
    }
    final open = puzzle.removable(removed);
    if (open.isEmpty) {
      expect(removed.length, puzzle.arrowCount, reason: 'level $level stuck');
      if (landed == drops.count) break;
      t += 500;
      continue;
    }
    removed.addAll(puzzle.exitGroup(open[random.nextInt(open.length)]));
    t += tapMs;
  }
  return (
    drops: landed,
    arrows: puzzle.arrowCount,
    mirrors: mirrors,
    dropLength: dropArrows == 0 ? 0 : dropCells / dropArrows,
    playedMs: t,
    startFill: startFill,
  );
}

/// Every Rush level from [from] to [to] deals in full and plays through:
/// its starting arrows and every twist it asks for, solvable, half empty
/// for the drops to land in, and every drop landing, the board clearable
/// after each, the late drops bringing long arrows, and the level done
/// inside the clock at a quick pace.
void rushChecks({required int from, required int to}) {
  final specs = levelSpecs.where((s) => s.level >= from && s.level <= to && s.isDynamic).toList();

  test('levels $from-$to deal their starting arrows, solvable, with room for the drops', () {
    for (final spec in specs) {
      final p = dealtLevel(spec.level);
      expect(p.isCube, isFalse);
      expect(p.width, spec.width);
      expect(p.height, spec.height);
      expect(p.arrowCount, spec.arrows, reason: 'level ${spec.level} arrow count');
      expect(p.isSolvable, isTrue, reason: 'level ${spec.level} solvable');
      final f = spec.features;
      expect(p.mirrors, hasLength(f.mirrors), reason: 'level ${spec.level} mirrors');
      expect(p.locks, hasLength(f.locks), reason: 'level ${spec.level} locks');
      expect(p.hidden, hasLength(f.hidden), reason: 'level ${spec.level} hidden');
      expect(p.pairs, hasLength(f.pairs * 2), reason: 'level ${spec.level} pairs');
      for (final a in p.arrows) {
        // No gap pass on a Rush board: its leftover cells are the drops'.
        expect(a.length, inInclusiveRange(spec.minLength, spec.maxLength), reason: 'level ${spec.level} $a');
      }
      final used = p.arrows.fold<int>(0, (n, a) => n + a.length) / spec.freeCellCount;
      expect(used, inInclusiveRange(0.2, 0.7), reason: 'level ${spec.level} fill');
    }
  });

  test('levels $from-$to play through: every drop lands, the board stays clearable, inside the clock', () {
    for (final spec in specs) {
      final run = playRush(spec.level);
      expect(run.drops, spec.drops!.count, reason: 'level ${spec.level} drops');
      // The mirrors that are meant to land (nearly) all find a place.
      expect(run.mirrors, greaterThanOrEqualTo((spec.drops!.count * spec.drops!.mirrors * 0.8).floor()),
          reason: 'level ${spec.level} mirrors landed');
      // Late in each half the drops bring long arrows.
      if (spec.drops!.maxLength >= 7) {
        expect(run.dropLength, greaterThanOrEqualTo(spec.drops!.maxLength - 2.5), reason: 'level ${spec.level} drop length');
      }
      expect(run.arrows, greaterThan(spec.arrows + spec.drops!.count), reason: 'level ${spec.level} arrows in all');
      expect(run.playedMs, lessThan(spec.timeLimitMs), reason: 'level ${spec.level} clock');
    }
  });
}
