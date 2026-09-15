// Prints, for each level, how the generator copes: arrows placed vs asked,
// board fill, average arrow length, dependency depth, arrows free at the
// start, moves open at a typical moment (and at most), how exposed the
// playable arrows are to a slipped finger (risk — see Puzzle.openTapRisk),
// and generation time. Run after touching level_specs.dart or the generator:
//
//   dart run tool/level_report.dart            # all levels, the level's seed
//   dart run tool/level_report.dart 8 3        # level 8 only, 3 extra seeds
import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';

void main(List<String> args) {
  final only = args.isNotEmpty ? int.parse(args[0]) : null;
  final extraSeeds = args.length > 1 ? int.parse(args[1]) : 0;
  for (final spec in levelSpecs) {
    if (only != null && spec.level != only) continue;
    final counts = <int>[];
    var line = '';
    for (var seed = 0; seed <= extraSeeds; seed++) {
      final random = seed == 0 ? Random(spec.seed) : Random(seed * 101 + spec.level);
      final sw = Stopwatch()..start();
      final p = PuzzleGenerator(random: random).generate(spec);
      sw.stop();
      counts.add(p.arrowCount);
      if (seed == 0) {
        final cells = p.arrows.fold<int>(0, (s, a) => s + a.length);
        final profile = p.openMoveProfile();
        line =
            'fill ${(cells / spec.cellCount).toStringAsFixed(2)} '
            'len ${(cells / p.arrowCount).toStringAsFixed(1)} '
            'depth ${p.dependencyDepth} free ${p.removable(const {}).length} '
            'open ${p.meanOpenMoves.toStringAsFixed(1)} (max ${profile.reduce(max)}, want ${spec.openMoves}) '
            'risk ${p.openTapRisk.toStringAsFixed(2)} '
            '${sw.elapsedMilliseconds}ms';
      }
    }
    // ignore: avoid_print
    print('L${spec.level} ${spec.width}x${spec.height} want ${spec.arrows} got $counts $line');
  }
}
