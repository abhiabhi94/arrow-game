// Finds, for each level given (default: every level from 21), the first
// variant whose board keeps every rule the level table is tested for: the
// full arrow count, every twist placed, most of the mirrors on some arrow's
// way out, and the player's choice held within the generator's slack at
// the start and at its widest. Prints a
// `level variant` line per level — the ones that are not `0` go into
// `LevelSpec.variant` in lib/data/level_specs.dart. Run after touching the
// table or the generator. A level on the block fits when every face fits
// its own share of the level (the generator re-deals a face on its own
// until it does, so a cube level rarely needs a variant):
//
//   dart run tool/pick_variants.dart            # levels 21..150
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
      final ok = spec.isCube
          ? spec.faceSpecs.every((f) => fits(f, PuzzleGenerator.dealFace(f)))
          : fits(spec, PuzzleGenerator(random: Random(spec.seed)).generate(spec));
      if (ok) {
        chosen = v;
        break;
      }
    }
    // ignore: avoid_print
    print('$level ${chosen ?? 'none'}');
  }
}

/// Whether [p] keeps every rule for [spec].
bool fits(LevelSpec spec, Puzzle p) => PuzzleGenerator.keepsRules(spec, p);
