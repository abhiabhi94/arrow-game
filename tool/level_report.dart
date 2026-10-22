// Prints, for each level, how the generator copes: arrows placed vs asked,
// board fill, average arrow length, dependency depth, arrows free at the
// start, moves open at a typical moment (and at most), arrows on the board
// per open move (hunt — see Puzzle.arrowsPerOpenMove), how many of the
// mirrors are on some arrow's way out and how many arrows bounce (hit,
// bend), how exposed the playable arrows are to a slipped finger (risk —
// see Puzzle.openTapRisk),
// the clock per arrow and generation time. Run after touching level_specs.dart or the generator:
//
//   dart run tool/level_report.dart            # all levels, the level's board
//   dart run tool/level_report.dart 8 3        # level 8 only, plus the next 3 variants
//
// The extra rows are the level under `LevelSpec.variant` 1, 2, 3…: the boards
// the level could be re-dealt to, so a level that came out looser than its
// neighbours can be given the variant that fits the curve.
import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';

void main(List<String> args) {
  final only = args.isNotEmpty ? int.parse(args[0]) : null;
  final extraVariants = args.length > 1 ? int.parse(args[1]) : 0;
  for (final base in levelSpecs) {
    if (only != null && base.level != only) continue;
    for (var extra = 0; extra <= extraVariants; extra++) {
      final spec = extra == 0 ? base : _variant(base, base.variant + extra);
      final sw = Stopwatch()..start();
      final p = PuzzleGenerator(random: Random(spec.seed)).generate(spec);
      sw.stop();
      final cells = p.arrows.fold<int>(0, (s, a) => s + a.length);
      final profile = p.openMoveProfile();
      final f = spec.features;
      final bent = p.arrows.where((a) => p.bends(a.id)).length;
      final used = p.mirrors.keys.where((m) => p.arrows.any((a) => p.rayOf(a.id).contains(m))).length;
      final twists = <String>[
        if (f.mirrors > 0) 'mirrors ${p.mirrors.length}/${f.mirrors} (hit $used, bend $bent)',
        if (f.locks > 0) 'locks ${p.locks.length}/${f.locks}',
        if (f.hidden > 0) 'hidden ${p.hidden.length}/${f.hidden}',
        if (f.pairs > 0) 'pairs ${p.pairs.length ~/ 2}/${f.pairs}',
      ];
      final line =
          '${twists.isEmpty ? '' : '[${twists.join(' ')}] '}'
          'fill ${(cells / spec.freeCellCount).toStringAsFixed(2)} '
          'len ${(cells / p.arrowCount).toStringAsFixed(1)} '
          'depth ${p.dependencyDepth} free ${p.removable(const {}).length} '
          'open ${p.meanOpenMoves.toStringAsFixed(2)} (max ${profile.reduce(max)}, want ${spec.openMoves}) '
          'hunt ${p.arrowsPerOpenMove.toStringAsFixed(0)} '
          'risk ${p.openTapRisk.toStringAsFixed(2)} '
          '${(spec.timeLimitMs / spec.arrows / 1000).toStringAsFixed(2)}s/arrow '
          '${sw.elapsedMilliseconds}ms';
      // ignore: avoid_print
      print('L${spec.level} v${spec.variant} ${spec.width}x${spec.height} '
          'len ${spec.minLength}-${spec.maxLength} want ${spec.arrows} got ${p.arrowCount} $line');
    }
  }
}

LevelSpec _variant(LevelSpec s, int variant) => s.withVariant(variant);
