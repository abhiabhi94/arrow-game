/// The 100 levels, in six chapters (`data/chapters.dart`): five flat
/// chapters of ten, then fifty levels on the block.
///
/// **Levels 1–10** are the plain rectangle: one rule, the board growing
/// every level from 5 arrows on 5×6 to 105 on 26×40, with the clock brisk
/// (~1.7 s an arrow early, 2.5 s from level 8) so a level is a sprint of
/// quick reads. They are ten of the first release's twenty rows, kept as
/// they were but for the level number.
///
/// **Levels 11–50** are drawn by `tool/make_levels.dart` from one set of
/// rules. Each chapter brings one twist and keeps the ones before it —
/// mirrors (an arrow sliding into one turns a right angle), locks (an arrow
/// waits for its numbered key), hidden heads (shown once a neighbour
/// leaves), tethered pairs (one tap, two arrows) — and every chapter has
/// the same shape: a small, roomy teaching board first (12 arrows, the new
/// twist alone, three moves open at a time, and an illustrated card over it
/// on the first visit), then a steady climb from 30 arrows at its second
/// level to 120 at its tenth, the chapter's own twist thickening along the
/// way. Every chapter tops out at the same count: what makes a later
/// chapter harder is its twist, not more arrows. These were five chapters
/// of twenty; squeezing them into ten each made room for the block.
///
/// **Levels 51–100** are the block (`LevelSpec.faces`): six square faces,
/// each a board of its own that the arrows leave by its own edges, played
/// one face at a time while the player turns the block round. A teaching
/// cube first (three arrows a face), then a steady climb from 30 arrows to
/// 144 — five to twenty-four a face — with the twists coming back onto the
/// faces ten levels at a time: plain faces to 60, mirrors from 61, locks
/// from 71, hidden heads from 81, pairs from 91. So each level is a little
/// more than the one before it.
///
/// A flat board is sized so the cells an arrow may use — the rectangle
/// less its mirrors — come to ~11.3 an arrow, which the generator fills to
/// ~0.88; a face of the block the same. The clock is a pace per arrow that
/// grows chapter by chapter (3.0 s in Mirrors to 3.5 s on the block's last
/// faces: every twist is one more thing to read on every arrow) plus a few
/// seconds for every mirror, lock, hidden head and tether on the board,
/// plus slack — and on the block two seconds a face for turning it — and
/// never over ten minutes; teaching boards run at 3 s an arrow. Settings →
/// Extra time doubles all of it.
///
/// Every level from 8 is dealt from the first [LevelSpec.variant] whose
/// board keeps every rule the tests pin — the full count, every twist
/// placed, the player's choice held within the generator's slack at the
/// start and at its widest (on the block, face by face) — found by
/// `tool/pick_variants.dart`; re-run it after touching the table or the
/// generator, and write its picks in here.
library;

import '../models/level_spec.dart';

const int totalLevels = 100;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 26000, openMoves: 3),
  LevelSpec(level: 2, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 5, timeLimitMs: 30000, openMoves: 3),
  LevelSpec(level: 3, width: 7, height: 9, arrows: 12, minLength: 2, maxLength: 6, timeLimitMs: 38000, openMoves: 3),
  LevelSpec(level: 4, width: 8, height: 11, arrows: 17, minLength: 2, maxLength: 6, timeLimitMs: 46000, openMoves: 2),
  LevelSpec(level: 5, width: 10, height: 13, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 67000, openMoves: 2),
  LevelSpec(level: 6, width: 12, height: 16, arrows: 30, minLength: 2, maxLength: 8, timeLimitMs: 80000, openMoves: 2),
  LevelSpec(level: 7, width: 14, height: 20, arrows: 40, minLength: 3, maxLength: 8, timeLimitMs: 101000, openMoves: 2),
  LevelSpec(level: 8, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 142000, openMoves: 2),
  LevelSpec(level: 9, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 219000, openMoves: 2),
  LevelSpec(level: 10, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 276000, openMoves: 2),
  LevelSpec(level: 11, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 64000, openMoves: 3, features: LevelFeatures(mirrors: 3)),
  LevelSpec(level: 12, width: 15, height: 23, arrows: 30, minLength: 3, maxLength: 11, timeLimitMs: 109000, openMoves: 2, features: LevelFeatures(mirrors: 4)),
  LevelSpec(level: 13, width: 18, height: 27, arrows: 41, minLength: 3, maxLength: 11, timeLimitMs: 143000, openMoves: 2, features: LevelFeatures(mirrors: 5), variant: 1),
  LevelSpec(level: 14, width: 20, height: 31, arrows: 53, minLength: 3, maxLength: 11, timeLimitMs: 181000, openMoves: 2, features: LevelFeatures(mirrors: 7)),
  LevelSpec(level: 15, width: 22, height: 34, arrows: 64, minLength: 3, maxLength: 11, timeLimitMs: 215000, openMoves: 2, features: LevelFeatures(mirrors: 8)),
  LevelSpec(level: 16, width: 24, height: 36, arrows: 75, minLength: 3, maxLength: 11, timeLimitMs: 249000, openMoves: 2, features: LevelFeatures(mirrors: 9)),
  LevelSpec(level: 17, width: 26, height: 40, arrows: 86, minLength: 3, maxLength: 12, timeLimitMs: 284000, openMoves: 2, features: LevelFeatures(mirrors: 11)),
  LevelSpec(level: 18, width: 27, height: 42, arrows: 98, minLength: 3, maxLength: 12, timeLimitMs: 321000, openMoves: 2, features: LevelFeatures(mirrors: 12)),
  LevelSpec(level: 19, width: 29, height: 44, arrows: 109, minLength: 3, maxLength: 12, timeLimitMs: 356000, openMoves: 2, features: LevelFeatures(mirrors: 14), variant: 1),
  LevelSpec(level: 20, width: 30, height: 46, arrows: 120, minLength: 3, maxLength: 12, timeLimitMs: 390000, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 21, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 69000, openMoves: 3, features: LevelFeatures(locks: 2)),
  LevelSpec(level: 22, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 12, timeLimitMs: 121000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 2), variant: 7),
  LevelSpec(level: 23, width: 18, height: 27, arrows: 41, minLength: 4, maxLength: 12, timeLimitMs: 157200, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 24, width: 20, height: 31, arrows: 53, minLength: 4, maxLength: 12, timeLimitMs: 200600, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 25, width: 22, height: 34, arrows: 64, minLength: 4, maxLength: 12, timeLimitMs: 236800, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3)),
  LevelSpec(level: 26, width: 24, height: 36, arrows: 75, minLength: 4, maxLength: 12, timeLimitMs: 276000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 4)),
  LevelSpec(level: 27, width: 26, height: 40, arrows: 86, minLength: 4, maxLength: 13, timeLimitMs: 312200, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 28, width: 27, height: 42, arrows: 98, minLength: 4, maxLength: 13, timeLimitMs: 355600, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 29, width: 29, height: 44, arrows: 109, minLength: 4, maxLength: 13, timeLimitMs: 391800, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 5)),
  LevelSpec(level: 30, width: 30, height: 46, arrows: 120, minLength: 4, maxLength: 13, timeLimitMs: 432000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6)),
  LevelSpec(level: 31, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(hidden: 2)),
  LevelSpec(level: 32, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 13, timeLimitMs: 134000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 2), variant: 2),
  LevelSpec(level: 33, width: 18, height: 27, arrows: 41, minLength: 4, maxLength: 13, timeLimitMs: 171300, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 34, width: 20, height: 31, arrows: 53, minLength: 4, maxLength: 13, timeLimitMs: 214900, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 35, width: 22, height: 34, arrows: 64, minLength: 4, maxLength: 13, timeLimitMs: 252200, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3)),
  LevelSpec(level: 36, width: 24, height: 36, arrows: 75, minLength: 4, maxLength: 13, timeLimitMs: 291500, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4)),
  LevelSpec(level: 37, width: 26, height: 40, arrows: 86, minLength: 4, maxLength: 14, timeLimitMs: 328800, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 38, width: 27, height: 42, arrows: 98, minLength: 4, maxLength: 14, timeLimitMs: 372400, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 39, width: 29, height: 44, arrows: 109, minLength: 4, maxLength: 14, timeLimitMs: 409700, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 5)),
  LevelSpec(level: 40, width: 30, height: 46, arrows: 120, minLength: 4, maxLength: 14, timeLimitMs: 450000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 6)),
  LevelSpec(level: 41, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(pairs: 2), variant: 1),
  LevelSpec(level: 42, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 14, timeLimitMs: 146000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 3, pairs: 2)),
  LevelSpec(level: 43, width: 18, height: 27, arrows: 41, minLength: 4, maxLength: 14, timeLimitMs: 184400, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 3, pairs: 2)),
  LevelSpec(level: 44, width: 20, height: 31, arrows: 53, minLength: 4, maxLength: 14, timeLimitMs: 229200, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3, pairs: 3)),
  LevelSpec(level: 45, width: 22, height: 34, arrows: 64, minLength: 4, maxLength: 14, timeLimitMs: 267600, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3, pairs: 3)),
  LevelSpec(level: 46, width: 24, height: 36, arrows: 75, minLength: 4, maxLength: 14, timeLimitMs: 308000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3, pairs: 4)),
  LevelSpec(level: 47, width: 26, height: 40, arrows: 86, minLength: 4, maxLength: 15, timeLimitMs: 346400, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 3, pairs: 4)),
  LevelSpec(level: 48, width: 27, height: 42, arrows: 98, minLength: 4, maxLength: 15, timeLimitMs: 391200, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 3, pairs: 5)),
  LevelSpec(level: 49, width: 29, height: 44, arrows: 109, minLength: 4, maxLength: 15, timeLimitMs: 429600, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 3, pairs: 5)),
  LevelSpec(level: 50, width: 30, height: 46, arrows: 120, minLength: 4, maxLength: 15, timeLimitMs: 471000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 3, pairs: 6)),
  LevelSpec(level: 51, width: 6, height: 6, arrows: 18, minLength: 2, maxLength: 4, timeLimitMs: 91000, openMoves: 3, faces: 6),
  LevelSpec(level: 52, width: 7, height: 7, arrows: 30, minLength: 2, maxLength: 6, timeLimitMs: 126000, openMoves: 2, faces: 6),
  LevelSpec(level: 53, width: 8, height: 8, arrows: 32, minLength: 2, maxLength: 7, timeLimitMs: 132600, openMoves: 2, faces: 6),
  LevelSpec(level: 54, width: 8, height: 8, arrows: 35, minLength: 2, maxLength: 7, timeLimitMs: 142500, openMoves: 2, faces: 6),
  LevelSpec(level: 55, width: 8, height: 8, arrows: 37, minLength: 2, maxLength: 7, timeLimitMs: 149100, openMoves: 2, faces: 6),
  LevelSpec(level: 56, width: 8, height: 8, arrows: 40, minLength: 2, maxLength: 7, timeLimitMs: 159000, openMoves: 2, faces: 6),
  LevelSpec(level: 57, width: 8, height: 8, arrows: 42, minLength: 2, maxLength: 7, timeLimitMs: 165600, openMoves: 2, faces: 6),
  LevelSpec(level: 58, width: 9, height: 9, arrows: 44, minLength: 2, maxLength: 8, timeLimitMs: 172200, openMoves: 2, faces: 6),
  LevelSpec(level: 59, width: 9, height: 9, arrows: 47, minLength: 2, maxLength: 8, timeLimitMs: 182100, openMoves: 2, faces: 6),
  LevelSpec(level: 60, width: 9, height: 9, arrows: 49, minLength: 2, maxLength: 8, timeLimitMs: 188700, openMoves: 2, faces: 6),
  LevelSpec(level: 61, width: 9, height: 9, arrows: 51, minLength: 2, maxLength: 8, timeLimitMs: 203850, openMoves: 2, features: LevelFeatures(mirrors: 6), faces: 6),
  LevelSpec(level: 62, width: 9, height: 9, arrows: 54, minLength: 2, maxLength: 8, timeLimitMs: 214900, openMoves: 2, features: LevelFeatures(mirrors: 7), faces: 6),
  LevelSpec(level: 63, width: 10, height: 10, arrows: 56, minLength: 3, maxLength: 9, timeLimitMs: 221600, openMoves: 2, features: LevelFeatures(mirrors: 7), faces: 6),
  LevelSpec(level: 64, width: 10, height: 10, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 231650, openMoves: 2, features: LevelFeatures(mirrors: 7), faces: 6),
  LevelSpec(level: 65, width: 10, height: 10, arrows: 61, minLength: 3, maxLength: 9, timeLimitMs: 239350, openMoves: 2, features: LevelFeatures(mirrors: 8), faces: 6),
  LevelSpec(level: 66, width: 10, height: 10, arrows: 63, minLength: 3, maxLength: 9, timeLimitMs: 246050, openMoves: 2, features: LevelFeatures(mirrors: 8), faces: 6),
  LevelSpec(level: 67, width: 10, height: 10, arrows: 66, minLength: 3, maxLength: 9, timeLimitMs: 256100, openMoves: 2, features: LevelFeatures(mirrors: 8), faces: 6),
  LevelSpec(level: 68, width: 11, height: 11, arrows: 68, minLength: 3, maxLength: 10, timeLimitMs: 263800, openMoves: 2, features: LevelFeatures(mirrors: 9), faces: 6),
  LevelSpec(level: 69, width: 11, height: 11, arrows: 70, minLength: 3, maxLength: 10, timeLimitMs: 270500, openMoves: 2, features: LevelFeatures(mirrors: 9), faces: 6),
  LevelSpec(level: 70, width: 11, height: 11, arrows: 73, minLength: 3, maxLength: 10, timeLimitMs: 280550, openMoves: 2, features: LevelFeatures(mirrors: 9), faces: 6),
  LevelSpec(level: 71, width: 11, height: 11, arrows: 75, minLength: 3, maxLength: 10, timeLimitMs: 312000, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 6), faces: 6),
  LevelSpec(level: 72, width: 11, height: 11, arrows: 78, minLength: 3, maxLength: 10, timeLimitMs: 323200, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 6), faces: 6),
  LevelSpec(level: 73, width: 12, height: 12, arrows: 80, minLength: 3, maxLength: 11, timeLimitMs: 330000, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 6), faces: 6),
  LevelSpec(level: 74, width: 12, height: 12, arrows: 82, minLength: 3, maxLength: 11, timeLimitMs: 340800, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 7), faces: 6),
  LevelSpec(level: 75, width: 12, height: 12, arrows: 85, minLength: 3, maxLength: 11, timeLimitMs: 351000, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 7), faces: 6),
  LevelSpec(level: 76, width: 12, height: 12, arrows: 87, minLength: 3, maxLength: 11, timeLimitMs: 357800, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 7), faces: 6),
  LevelSpec(level: 77, width: 12, height: 12, arrows: 89, minLength: 3, maxLength: 11, timeLimitMs: 368600, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 8), faces: 6),
  LevelSpec(level: 78, width: 12, height: 12, arrows: 92, minLength: 3, maxLength: 11, timeLimitMs: 379800, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 8), faces: 6),
  LevelSpec(level: 79, width: 12, height: 12, arrows: 94, minLength: 3, maxLength: 11, timeLimitMs: 386600, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 8), faces: 6),
  LevelSpec(level: 80, width: 13, height: 13, arrows: 97, minLength: 3, maxLength: 12, timeLimitMs: 400800, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 9), faces: 6),
  LevelSpec(level: 81, width: 13, height: 13, arrows: 99, minLength: 3, maxLength: 12, timeLimitMs: 418550, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 82, width: 13, height: 13, arrows: 101, minLength: 3, maxLength: 12, timeLimitMs: 425450, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 83, width: 13, height: 13, arrows: 104, minLength: 3, maxLength: 12, timeLimitMs: 436800, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 84, width: 13, height: 13, arrows: 106, minLength: 3, maxLength: 12, timeLimitMs: 446700, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6, hidden: 7), faces: 6),
  LevelSpec(level: 85, width: 13, height: 13, arrows: 108, minLength: 3, maxLength: 12, timeLimitMs: 453600, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6, hidden: 7), faces: 6),
  LevelSpec(level: 86, width: 14, height: 14, arrows: 111, minLength: 3, maxLength: 12, timeLimitMs: 463950, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6, hidden: 7), faces: 6),
  LevelSpec(level: 87, width: 14, height: 14, arrows: 113, minLength: 3, maxLength: 12, timeLimitMs: 473850, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6, hidden: 8), faces: 6),
  LevelSpec(level: 88, width: 14, height: 14, arrows: 116, minLength: 3, maxLength: 12, timeLimitMs: 485200, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 6, hidden: 8), faces: 6),
  LevelSpec(level: 89, width: 14, height: 14, arrows: 118, minLength: 3, maxLength: 12, timeLimitMs: 492100, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 6, hidden: 8), faces: 6),
  LevelSpec(level: 90, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 12, timeLimitMs: 502000, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 6, hidden: 9), faces: 6),
  LevelSpec(level: 91, width: 14, height: 14, arrows: 123, minLength: 3, maxLength: 12, timeLimitMs: 527500, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 92, width: 14, height: 14, arrows: 125, minLength: 3, maxLength: 12, timeLimitMs: 534500, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 93, width: 15, height: 15, arrows: 127, minLength: 3, maxLength: 12, timeLimitMs: 542500, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 94, width: 15, height: 15, arrows: 130, minLength: 3, maxLength: 12, timeLimitMs: 556000, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 95, width: 15, height: 15, arrows: 132, minLength: 3, maxLength: 12, timeLimitMs: 563000, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 96, width: 15, height: 15, arrows: 135, minLength: 3, maxLength: 12, timeLimitMs: 573500, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 97, width: 15, height: 15, arrows: 137, minLength: 3, maxLength: 12, timeLimitMs: 583500, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 6, hidden: 6, pairs: 8), faces: 6),
  LevelSpec(level: 98, width: 15, height: 15, arrows: 139, minLength: 3, maxLength: 12, timeLimitMs: 591500, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 8), faces: 6),
  LevelSpec(level: 99, width: 15, height: 15, arrows: 142, minLength: 3, maxLength: 12, timeLimitMs: 599000, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 8), faces: 6),
  LevelSpec(level: 100, width: 15, height: 15, arrows: 144, minLength: 3, maxLength: 12, timeLimitMs: 599000, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 9), faces: 6),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
