// Plays the Rush levels (101–150) through with a quick player — every tap
// an arrow that can go, picked at random, [tapMs] apart (level 125 was
// cleared in about 1.1 s a tap on a laptop) — and prints what landed:
// arrows at the start, drops landed (of those asked), mirrors landed,
// arrows in all, how full the board got, and the time it took against the
// clock.
//
//   dart run tool/rush_report.dart [from] [to]

import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/drops.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';

/// Time between taps, in milliseconds.
const int tapMs = 1200;

void main(List<String> args) {
  final from = args.isNotEmpty ? int.parse(args[0]) : 101;
  final to = args.length > 1 ? int.parse(args[1]) : (args.isNotEmpty ? from : 150);
  for (var level = from; level <= to; level++) {
    final spec = specForLevel(level);
    final drops = spec.drops;
    if (drops == null) continue;
    final sw = Stopwatch()..start();
    var puzzle = puzzleForLevel(spec);
    final dealMs = sw.elapsedMilliseconds;
    final fill0 = _fill(puzzle, const <int>{});
    final removed = <int>{};
    final random = Random(level);
    var t = 0;
    var nextDrop = drops.everyMs;
    var landed = 0, waited = 0, mirrors = 0, dropCells = 0, dropArrows = 0;
    var maxFill = fill0;
    var openSum = 0, steps = 0;
    while (true) {
      final live = puzzle.arrowCount - removed.length;
      if (landed < drops.count && (live <= kDropLowWater || t >= nextDrop)) {
        final drop = planDrop(puzzle, removed, drops, dropRandom(spec, landed));
        if (drop != null) {
          puzzle = drop.landOn(puzzle);
          mirrors += drop.mirrors.length;
          dropArrows += drop.arrows.length;
          for (final a in drop.arrows) {
            dropCells += a.length;
          }
          landed++;
          nextDrop = t + drops.everyMs;
          maxFill = max(maxFill, _fill(puzzle, removed));
        } else {
          waited++;
        }
      }
      final open = puzzle.removable(removed);
      if (open.isEmpty) {
        if (removed.length == puzzle.arrowCount && landed == drops.count) break;
        if (removed.length == puzzle.arrowCount) {
          t += 500;
          continue;
        }
        // ignore: avoid_print
        print('$level: STUCK with ${puzzle.arrowCount - removed.length} arrows left');
        return;
      }
      openSum += open.length;
      steps++;
      removed.addAll(puzzle.exitGroup(open[random.nextInt(open.length)]));
      t += tapMs;
    }
    // ignore: avoid_print
    print('$level: ${spec.width}x${spec.height} start ${spec.arrows} (fill ${(fill0 * 100).round()}%) '
        'drops $landed/${drops.count} (arrows ${(dropCells / max(1, dropArrows)).toStringAsFixed(1)} long) waited $waited mirrors +$mirrors → ${puzzle.arrowCount} arrows, '
        'max fill ${(maxFill * 100).round()}%, open ${(openSum / steps).toStringAsFixed(1)}, '
        '${(t / 1000).round()}s of ${(spec.timeLimitMs / 1000).round()}s, deal ${dealMs}ms');
  }
}

double _fill(Puzzle p, Set<int> removed) {
  var cells = 0;
  for (final a in p.arrows) {
    if (!removed.contains(a.id)) cells += a.length;
  }
  return cells / (p.width * p.height);
}
