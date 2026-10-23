/// The 100 levels, in five chapters of twenty (`data/chapters.dart`).
///
/// **Levels 1–20** are the plain rectangle: one rule, the board growing
/// every level from 5 arrows on 5×6 to 144 on 32×50, with the clock brisk
/// (~1.7 s an arrow early, 2.5 s from level 10) so a level is a sprint of
/// quick reads. Untouched since the first release.
///
/// **Levels 21–100** are drawn by `tool/make_levels.dart` from one set of
/// rules, after the first hundred turned out to be the same level played
/// eighty times: from level 20 nothing changed but the count, which
/// climbed to 464 arrows and a fifteen-minute read. Now each chapter brings
/// one twist and keeps the ones before it — mirrors (an arrow sliding into
/// one turns a right angle), locks (an arrow waits for its numbered key),
/// hidden heads (shown once a neighbour leaves), tethered pairs (one tap,
/// two arrows) — and every chapter has the same shape: a small, roomy
/// teaching board first (12 arrows, the new twist alone, three moves open
/// at a time, and an illustrated card over it on the first visit), then a
/// steady climb from 30 arrows at its second level to 150 at its twentieth,
/// the chapter's own twist thickening along the way. Every chapter tops
/// out at the same count: what makes a later chapter harder is its twist,
/// not more arrows — the first cut went from the teaching board straight
/// to 150 and on to 265, a cliff after every card and a slog by the end.
///
/// The board is sized so the cells an arrow may use — the rectangle less
/// its mirrors — come to ~11.3 an arrow, which the generator fills to
/// ~0.88. The clock is a pace per arrow that grows chapter by chapter
/// (3.0 s in Mirrors to 3.4 s in Pairs: every twist is one more thing to
/// read on every arrow) plus a few seconds for every mirror, lock, hidden
/// head and tether on the board, plus slack, and never over ten minutes;
/// teaching boards run at 3 s an arrow. Settings → Extra time doubles all
/// of it.
///
/// Every level is dealt from the first [LevelSpec.variant] whose board keeps
/// every rule the tests pin — the full count, every twist placed, the
/// player's choice held within the generator's slack at the start and at
/// its widest — found by `tool/pick_variants.dart`; re-run it after
/// touching the table or the generator, and write its picks in here.
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
  LevelSpec(level: 8, width: 19, height: 26, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 141000, openMoves: 2),
  LevelSpec(level: 9, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 142000, openMoves: 2),
  LevelSpec(level: 10, width: 21, height: 30, arrows: 67, minLength: 3, maxLength: 10, timeLimitMs: 182000, openMoves: 2),
  LevelSpec(level: 11, width: 22, height: 32, arrows: 74, minLength: 3, maxLength: 10, timeLimitMs: 200000, openMoves: 2),
  LevelSpec(level: 12, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 219000, openMoves: 2),
  LevelSpec(level: 13, width: 24, height: 36, arrows: 88, minLength: 3, maxLength: 10, timeLimitMs: 235000, openMoves: 2),
  LevelSpec(level: 14, width: 25, height: 38, arrows: 96, minLength: 3, maxLength: 10, timeLimitMs: 255000, openMoves: 2),
  LevelSpec(level: 15, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 276000, openMoves: 2),
  LevelSpec(level: 16, width: 27, height: 42, arrows: 110, minLength: 3, maxLength: 10, timeLimitMs: 289000, openMoves: 2),
  LevelSpec(level: 17, width: 28, height: 44, arrows: 117, minLength: 3, maxLength: 10, timeLimitMs: 306000, openMoves: 2),
  LevelSpec(level: 18, width: 29, height: 46, arrows: 126, minLength: 3, maxLength: 10, timeLimitMs: 329000, openMoves: 2),
  LevelSpec(level: 19, width: 30, height: 48, arrows: 128, minLength: 3, maxLength: 10, timeLimitMs: 333000, openMoves: 2),
  LevelSpec(level: 20, width: 32, height: 50, arrows: 144, minLength: 3, maxLength: 10, timeLimitMs: 372000, openMoves: 2),
  LevelSpec(level: 21, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 64000, openMoves: 3, features: LevelFeatures(mirrors: 3)),
  LevelSpec(level: 22, width: 15, height: 23, arrows: 30, minLength: 3, maxLength: 11, timeLimitMs: 109000, openMoves: 2, features: LevelFeatures(mirrors: 4), variant: 1),
  LevelSpec(level: 23, width: 17, height: 26, arrows: 37, minLength: 3, maxLength: 11, timeLimitMs: 131000, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 24, width: 18, height: 28, arrows: 43, minLength: 3, maxLength: 11, timeLimitMs: 149000, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 25, width: 20, height: 30, arrows: 50, minLength: 3, maxLength: 11, timeLimitMs: 171000, openMoves: 2, features: LevelFeatures(mirrors: 6)),
  LevelSpec(level: 26, width: 21, height: 32, arrows: 57, minLength: 3, maxLength: 11, timeLimitMs: 193000, openMoves: 2, features: LevelFeatures(mirrors: 7)),
  LevelSpec(level: 27, width: 22, height: 33, arrows: 63, minLength: 3, maxLength: 11, timeLimitMs: 212000, openMoves: 2, features: LevelFeatures(mirrors: 8)),
  LevelSpec(level: 28, width: 23, height: 35, arrows: 70, minLength: 3, maxLength: 11, timeLimitMs: 234000, openMoves: 2, features: LevelFeatures(mirrors: 9), variant: 1),
  LevelSpec(level: 29, width: 24, height: 37, arrows: 77, minLength: 3, maxLength: 11, timeLimitMs: 256000, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 30, width: 25, height: 38, arrows: 83, minLength: 3, maxLength: 11, timeLimitMs: 274000, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 31, width: 26, height: 40, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 296000, openMoves: 2, features: LevelFeatures(mirrors: 11)),
  LevelSpec(level: 32, width: 27, height: 42, arrows: 97, minLength: 3, maxLength: 12, timeLimitMs: 318000, openMoves: 2, features: LevelFeatures(mirrors: 12)),
  LevelSpec(level: 33, width: 28, height: 43, arrows: 103, minLength: 3, maxLength: 12, timeLimitMs: 337000, openMoves: 2, features: LevelFeatures(mirrors: 13)),
  LevelSpec(level: 34, width: 29, height: 44, arrows: 110, minLength: 3, maxLength: 12, timeLimitMs: 359000, openMoves: 2, features: LevelFeatures(mirrors: 14)),
  LevelSpec(level: 35, width: 30, height: 46, arrows: 117, minLength: 3, maxLength: 12, timeLimitMs: 381000, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 36, width: 30, height: 47, arrows: 123, minLength: 3, maxLength: 12, timeLimitMs: 399000, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 37, width: 31, height: 48, arrows: 130, minLength: 3, maxLength: 12, timeLimitMs: 421000, openMoves: 2, features: LevelFeatures(mirrors: 16)),
  LevelSpec(level: 38, width: 32, height: 49, arrows: 137, minLength: 3, maxLength: 12, timeLimitMs: 443000, openMoves: 2, features: LevelFeatures(mirrors: 17)),
  LevelSpec(level: 39, width: 33, height: 50, arrows: 143, minLength: 3, maxLength: 12, timeLimitMs: 462000, openMoves: 2, features: LevelFeatures(mirrors: 18)),
  LevelSpec(level: 40, width: 34, height: 52, arrows: 150, minLength: 3, maxLength: 12, timeLimitMs: 484000, openMoves: 2, features: LevelFeatures(mirrors: 19)),
  LevelSpec(level: 41, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 69000, openMoves: 3, features: LevelFeatures(locks: 2)),
  LevelSpec(level: 42, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 12, timeLimitMs: 121000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 2), variant: 1),
  LevelSpec(level: 43, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 12, timeLimitMs: 144400, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 44, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 12, timeLimitMs: 163600, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 45, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 12, timeLimitMs: 191000, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 46, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 12, timeLimitMs: 213400, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 47, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 12, timeLimitMs: 233600, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3)),
  LevelSpec(level: 48, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 12, timeLimitMs: 260000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 4)),
  LevelSpec(level: 49, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 12, timeLimitMs: 283400, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 50, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 12, timeLimitMs: 302600, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 51, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 12, timeLimitMs: 329000, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 5)),
  LevelSpec(level: 52, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 13, timeLimitMs: 352400, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 53, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 13, timeLimitMs: 371600, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 54, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 13, timeLimitMs: 399000, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 55, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 13, timeLimitMs: 421400, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 56, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 13, timeLimitMs: 441600, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6)),
  LevelSpec(level: 57, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 13, timeLimitMs: 468000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 7), variant: 1),
  LevelSpec(level: 58, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 13, timeLimitMs: 491400, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 59, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 13, timeLimitMs: 510600, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 60, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 13, timeLimitMs: 538000, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 8)),
  LevelSpec(level: 61, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(hidden: 2)),
  LevelSpec(level: 62, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 13, timeLimitMs: 134000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 2)),
  LevelSpec(level: 63, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 13, timeLimitMs: 158100, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 64, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 13, timeLimitMs: 177900, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 65, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 13, timeLimitMs: 205000, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 66, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 13, timeLimitMs: 228100, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 67, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 13, timeLimitMs: 248900, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3)),
  LevelSpec(level: 68, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 13, timeLimitMs: 275000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4)),
  LevelSpec(level: 69, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 13, timeLimitMs: 299100, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 70, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 13, timeLimitMs: 318900, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 71, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 13, timeLimitMs: 345000, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 5)),
  LevelSpec(level: 72, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 14, timeLimitMs: 369100, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 73, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 14, timeLimitMs: 388900, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 74, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 14, timeLimitMs: 416000, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 75, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 14, timeLimitMs: 439100, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 76, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 14, timeLimitMs: 459900, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 6)),
  LevelSpec(level: 77, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 14, timeLimitMs: 486000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 7)),
  LevelSpec(level: 78, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 14, timeLimitMs: 510100, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 79, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 14, timeLimitMs: 529900, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 80, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 14, timeLimitMs: 557000, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 8)),
  LevelSpec(level: 81, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 67000, openMoves: 3, features: LevelFeatures(pairs: 2), variant: 4),
  LevelSpec(level: 82, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 14, timeLimitMs: 149000, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 83, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 14, timeLimitMs: 173800, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 84, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 14, timeLimitMs: 194200, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2)),
  LevelSpec(level: 85, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 14, timeLimitMs: 222000, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 86, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 14, timeLimitMs: 245800, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 87, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 14, timeLimitMs: 267200, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 88, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 14, timeLimitMs: 294000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 89, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 14, timeLimitMs: 318800, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 90, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 14, timeLimitMs: 339200, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 91, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 14, timeLimitMs: 366000, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 92, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 15, timeLimitMs: 390800, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 93, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 15, timeLimitMs: 411200, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 94, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 15, timeLimitMs: 439000, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 95, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 15, timeLimitMs: 462800, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 96, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 15, timeLimitMs: 484200, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 97, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 15, timeLimitMs: 511000, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 98, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 15, timeLimitMs: 535800, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 99, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 15, timeLimitMs: 556200, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 100, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 15, timeLimitMs: 584000, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 4, pairs: 8)),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
