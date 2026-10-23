// Finds, for each level given (default: every level from 21), the first
// variant whose board keeps every rule the level table is tested for: the
// full arrow count, every twist placed, most of the mirrors on some arrow's
// way out, and the player's choice held within the generator's slack at
// the start and at its widest. Prints a
// `level variant` line per level — the ones that are not `0` go into
// `LevelSpec.variant` in lib/data/level_specs.dart. Run after touching the
// table or the generator:
//
//   dart run tool/pick_variants.dart            # levels 21..100
//   dart run tool/pick_variants.dart 38 46 80   # just these
import 'dart:math';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/engine/puzzle_generator.dart';
import 'package:arrow_game/models/level_spec.dart';

const int kMaxVariants = 24;

void main(List<String> args) {
  final levels = args.isEmpty
      ? List<int>.generate(totalLevels - 20, (i) => i + 21)
      : args.map(int.parse).toList();
  for (final level in levels) {
    final base = specForLevel(level);
    int? chosen;
    for (var v = base.variant; v < base.variant + kMaxVariants; v++) {
      final spec = base.withVariant(v);
      final p = PuzzleGenerator(random: Random(spec.seed)).generate(spec);
      if (fits(spec, p)) {
        chosen = v;
        break;
      }
    }
    // ignore: avoid_print
    print('$level ${chosen ?? 'none'}');
  }
}

/// Whether [p] keeps every rule for [spec].
bool fits(LevelSpec spec, Puzzle p) {
  if (p.arrowCount != spec.arrows) return false;
  final f = spec.features;
  if (p.locks.length < f.locks || p.hidden.length < f.hidden || p.pairs.length ~/ 2 < f.pairs) {
    return false;
  }
  // The mirrors are on the arrows' paths (the generator test's line: at
  // least 60% of them, and half as many arrows bouncing as mirrors hit).
  if (f.mirrors > 0) {
    final hit = p.mirrors.keys.where((m) => p.arrows.any((a) => p.rayOf(a.id).contains(m))).length;
    final bent = p.arrows.where((a) => p.bends(a.id)).length;
    if (hit < (f.mirrors * 0.6).ceil() || bent < (hit / 2).ceil()) return false;
  }
  // The choice is held at the start and at its widest, and is narrow on
  // average too (the generator test's line: within one of `openMoves`).
  return PuzzleGenerator.holdsChoice(spec, p.openMoveProfile()) &&
      p.meanOpenMoves <= spec.openMoves + 1;
}
