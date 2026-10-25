/// The 150 levels, in six chapters (`data/chapters.dart`): five flat
/// chapters of twenty, then fifty levels on the block.
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
/// **Levels 101–150** are the block (`LevelSpec.faces`), also printed by
/// `tool/make_levels.dart`: six square faces, each a board of its own that
/// the arrows leave by its own edges, played one face at a time while the
/// player turns the block round. They come after the hundred flat levels,
/// which are untouched by them, and after a short warm-up they do not drop
/// back below level 100: a teaching cube (three arrows a face), three
/// levels that bring the twists back one at a time (mirrors, locks, hidden
/// heads) on faces of ten, fifteen and twenty arrows, then from level 105
/// all four twists on every face and about level 100's count over the
/// block (132), one more arrow every level to 177 and the twists
/// thickening each on its own schedule — every level a little more than the
/// one before, and never a big board: a face holds at most thirty arrows.
/// A face is sized to ~9.5 free cells an arrow, the clock runs at 2.4 s an
/// arrow (a small face is quicker to read than one big board) plus the
/// twists' seconds and 2 s a face for turning the block, and the generator
/// re-deals each face on its own until it keeps the rules, so no cube level
/// needs a variant.
library;

import '../models/level_spec.dart';

const int totalLevels = 150;

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
  LevelSpec(level: 101, width: 6, height: 6, arrows: 18, minLength: 2, maxLength: 4, timeLimitMs: 91000, openMoves: 3, faces: 6),
  LevelSpec(level: 102, width: 10, height: 10, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 183000, openMoves: 2, features: LevelFeatures(mirrors: 12), faces: 6),
  LevelSpec(level: 103, width: 12, height: 12, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 279000, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6), faces: 6),
  LevelSpec(level: 104, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 13, timeLimitMs: 369000, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 105, width: 15, height: 15, arrows: 132, minLength: 3, maxLength: 14, timeLimitMs: 415800, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 106, width: 15, height: 15, arrows: 133, minLength: 3, maxLength: 14, timeLimitMs: 418200, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 107, width: 15, height: 15, arrows: 134, minLength: 3, maxLength: 14, timeLimitMs: 420600, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 108, width: 15, height: 15, arrows: 135, minLength: 3, maxLength: 14, timeLimitMs: 424000, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 109, width: 15, height: 15, arrows: 136, minLength: 3, maxLength: 14, timeLimitMs: 429400, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 110, width: 15, height: 15, arrows: 137, minLength: 3, maxLength: 14, timeLimitMs: 432800, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 111, width: 15, height: 15, arrows: 138, minLength: 3, maxLength: 14, timeLimitMs: 438200, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 112, width: 15, height: 15, arrows: 139, minLength: 3, maxLength: 14, timeLimitMs: 444600, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 113, width: 15, height: 15, arrows: 140, minLength: 3, maxLength: 14, timeLimitMs: 448000, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 114, width: 15, height: 15, arrows: 141, minLength: 3, maxLength: 14, timeLimitMs: 450400, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 115, width: 15, height: 15, arrows: 142, minLength: 3, maxLength: 14, timeLimitMs: 453800, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 116, width: 15, height: 15, arrows: 143, minLength: 3, maxLength: 14, timeLimitMs: 456200, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 117, width: 15, height: 15, arrows: 144, minLength: 3, maxLength: 14, timeLimitMs: 458600, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 118, width: 16, height: 16, arrows: 145, minLength: 3, maxLength: 14, timeLimitMs: 462000, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 119, width: 16, height: 16, arrows: 146, minLength: 3, maxLength: 14, timeLimitMs: 470400, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 120, width: 16, height: 16, arrows: 147, minLength: 3, maxLength: 14, timeLimitMs: 477800, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 121, width: 16, height: 16, arrows: 148, minLength: 3, maxLength: 14, timeLimitMs: 480200, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 122, width: 16, height: 16, arrows: 149, minLength: 3, maxLength: 14, timeLimitMs: 482600, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 123, width: 16, height: 16, arrows: 150, minLength: 3, maxLength: 14, timeLimitMs: 486000, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 124, width: 16, height: 16, arrows: 151, minLength: 3, maxLength: 14, timeLimitMs: 488400, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 125, width: 16, height: 16, arrows: 152, minLength: 3, maxLength: 14, timeLimitMs: 491800, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 126, width: 16, height: 16, arrows: 153, minLength: 3, maxLength: 14, timeLimitMs: 494200, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 127, width: 16, height: 16, arrows: 154, minLength: 3, maxLength: 14, timeLimitMs: 500600, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 9, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 128, width: 16, height: 16, arrows: 155, minLength: 3, maxLength: 14, timeLimitMs: 510000, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 129, width: 16, height: 16, arrows: 156, minLength: 3, maxLength: 14, timeLimitMs: 512400, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 130, width: 16, height: 16, arrows: 157, minLength: 3, maxLength: 14, timeLimitMs: 515800, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 131, width: 16, height: 16, arrows: 158, minLength: 3, maxLength: 14, timeLimitMs: 518200, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 132, width: 16, height: 16, arrows: 159, minLength: 3, maxLength: 14, timeLimitMs: 520600, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 133, width: 16, height: 16, arrows: 160, minLength: 3, maxLength: 14, timeLimitMs: 524000, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 134, width: 16, height: 16, arrows: 161, minLength: 3, maxLength: 14, timeLimitMs: 526400, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 135, width: 16, height: 16, arrows: 162, minLength: 3, maxLength: 14, timeLimitMs: 533800, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 136, width: 16, height: 16, arrows: 163, minLength: 3, maxLength: 14, timeLimitMs: 539200, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 137, width: 16, height: 16, arrows: 164, minLength: 3, maxLength: 14, timeLimitMs: 541600, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 138, width: 16, height: 16, arrows: 165, minLength: 3, maxLength: 14, timeLimitMs: 548000, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 139, width: 16, height: 16, arrows: 166, minLength: 3, maxLength: 14, timeLimitMs: 550400, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 140, width: 16, height: 16, arrows: 167, minLength: 3, maxLength: 14, timeLimitMs: 553800, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 141, width: 16, height: 16, arrows: 168, minLength: 3, maxLength: 14, timeLimitMs: 556200, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 142, width: 17, height: 17, arrows: 169, minLength: 3, maxLength: 14, timeLimitMs: 562600, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 143, width: 17, height: 17, arrows: 170, minLength: 3, maxLength: 14, timeLimitMs: 566000, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 144, width: 17, height: 17, arrows: 171, minLength: 3, maxLength: 14, timeLimitMs: 568400, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 145, width: 17, height: 17, arrows: 172, minLength: 3, maxLength: 14, timeLimitMs: 574800, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 146, width: 17, height: 17, arrows: 173, minLength: 3, maxLength: 14, timeLimitMs: 577200, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 147, width: 17, height: 17, arrows: 174, minLength: 3, maxLength: 14, timeLimitMs: 582600, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 148, width: 17, height: 17, arrows: 175, minLength: 3, maxLength: 14, timeLimitMs: 586000, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 149, width: 17, height: 17, arrows: 176, minLength: 3, maxLength: 14, timeLimitMs: 588400, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 150, width: 17, height: 17, arrows: 177, minLength: 3, maxLength: 14, timeLimitMs: 595800, openMoves: 2, features: LevelFeatures(mirrors: 30, locks: 12, hidden: 11, pairs: 11), faces: 6),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
