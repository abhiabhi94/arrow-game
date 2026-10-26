/// The 200 levels, in seven chapters (`data/chapters.dart`): five flat
/// chapters of twenty, then two chapters of fifty on the block.
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
///
/// **Levels 151–200** are the squeeze, the block again with each face
/// packed so that one way out at a time is the aim (`openMoves` 1 where the
/// block has 2): a small teaching cube with no twists, three warm-up levels
/// with all four twists on faces of 20, 25 and 28 arrows, then from level
/// 155 a little more than level 150 (178 arrows and its twists), one level
/// gaining an arrow and the next a twist, to 200 arrows with 42 mirrors and
/// 18, 17 and 16 locks, hidden heads and pairs — every level a little more
/// than the one before, a face never over thirty-four arrows. Past the
/// warm-up the clock sits at the ten-minute cap, so the work grows and the
/// time does not.
library;

import '../models/level_spec.dart';

const int totalLevels = 200;

/// The share of the worked-out clock every level gets: each clock below is
/// the rule's (`tool/make_levels.dart`, and levels 1–20 as first tuned)
/// times this, since the full clocks played a little slack.
const double kClockTrim = 0.95;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 24700, openMoves: 3),
  LevelSpec(level: 2, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 5, timeLimitMs: 28500, openMoves: 3),
  LevelSpec(level: 3, width: 7, height: 9, arrows: 12, minLength: 2, maxLength: 6, timeLimitMs: 36100, openMoves: 3),
  LevelSpec(level: 4, width: 8, height: 11, arrows: 17, minLength: 2, maxLength: 6, timeLimitMs: 43700, openMoves: 2),
  LevelSpec(level: 5, width: 10, height: 13, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 63650, openMoves: 2),
  LevelSpec(level: 6, width: 12, height: 16, arrows: 30, minLength: 2, maxLength: 8, timeLimitMs: 76000, openMoves: 2),
  LevelSpec(level: 7, width: 14, height: 20, arrows: 40, minLength: 3, maxLength: 8, timeLimitMs: 95950, openMoves: 2),
  LevelSpec(level: 8, width: 19, height: 26, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 133950, openMoves: 2),
  LevelSpec(level: 9, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 134900, openMoves: 2),
  LevelSpec(level: 10, width: 21, height: 30, arrows: 67, minLength: 3, maxLength: 10, timeLimitMs: 172900, openMoves: 2),
  LevelSpec(level: 11, width: 22, height: 32, arrows: 74, minLength: 3, maxLength: 10, timeLimitMs: 190000, openMoves: 2),
  LevelSpec(level: 12, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 208050, openMoves: 2),
  LevelSpec(level: 13, width: 24, height: 36, arrows: 88, minLength: 3, maxLength: 10, timeLimitMs: 223250, openMoves: 2),
  LevelSpec(level: 14, width: 25, height: 38, arrows: 96, minLength: 3, maxLength: 10, timeLimitMs: 242250, openMoves: 2),
  LevelSpec(level: 15, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 262200, openMoves: 2),
  LevelSpec(level: 16, width: 27, height: 42, arrows: 110, minLength: 3, maxLength: 10, timeLimitMs: 274550, openMoves: 2),
  LevelSpec(level: 17, width: 28, height: 44, arrows: 117, minLength: 3, maxLength: 10, timeLimitMs: 290700, openMoves: 2),
  LevelSpec(level: 18, width: 29, height: 46, arrows: 126, minLength: 3, maxLength: 10, timeLimitMs: 312550, openMoves: 2),
  LevelSpec(level: 19, width: 30, height: 48, arrows: 128, minLength: 3, maxLength: 10, timeLimitMs: 316350, openMoves: 2),
  LevelSpec(level: 20, width: 32, height: 50, arrows: 144, minLength: 3, maxLength: 10, timeLimitMs: 353400, openMoves: 2),
  LevelSpec(level: 21, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 60800, openMoves: 3, features: LevelFeatures(mirrors: 3)),
  LevelSpec(level: 22, width: 15, height: 23, arrows: 30, minLength: 3, maxLength: 11, timeLimitMs: 103550, openMoves: 2, features: LevelFeatures(mirrors: 4), variant: 1),
  LevelSpec(level: 23, width: 17, height: 26, arrows: 37, minLength: 3, maxLength: 11, timeLimitMs: 124450, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 24, width: 18, height: 28, arrows: 43, minLength: 3, maxLength: 11, timeLimitMs: 141550, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 25, width: 20, height: 30, arrows: 50, minLength: 3, maxLength: 11, timeLimitMs: 162450, openMoves: 2, features: LevelFeatures(mirrors: 6)),
  LevelSpec(level: 26, width: 21, height: 32, arrows: 57, minLength: 3, maxLength: 11, timeLimitMs: 183350, openMoves: 2, features: LevelFeatures(mirrors: 7)),
  LevelSpec(level: 27, width: 22, height: 33, arrows: 63, minLength: 3, maxLength: 11, timeLimitMs: 201400, openMoves: 2, features: LevelFeatures(mirrors: 8)),
  LevelSpec(level: 28, width: 23, height: 35, arrows: 70, minLength: 3, maxLength: 11, timeLimitMs: 222300, openMoves: 2, features: LevelFeatures(mirrors: 9), variant: 1),
  LevelSpec(level: 29, width: 24, height: 37, arrows: 77, minLength: 3, maxLength: 11, timeLimitMs: 243200, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 30, width: 25, height: 38, arrows: 83, minLength: 3, maxLength: 11, timeLimitMs: 260300, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 31, width: 26, height: 40, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 281200, openMoves: 2, features: LevelFeatures(mirrors: 11)),
  LevelSpec(level: 32, width: 27, height: 42, arrows: 97, minLength: 3, maxLength: 12, timeLimitMs: 302100, openMoves: 2, features: LevelFeatures(mirrors: 12)),
  LevelSpec(level: 33, width: 28, height: 43, arrows: 103, minLength: 3, maxLength: 12, timeLimitMs: 320150, openMoves: 2, features: LevelFeatures(mirrors: 13)),
  LevelSpec(level: 34, width: 29, height: 44, arrows: 110, minLength: 3, maxLength: 12, timeLimitMs: 341050, openMoves: 2, features: LevelFeatures(mirrors: 14)),
  LevelSpec(level: 35, width: 30, height: 46, arrows: 117, minLength: 3, maxLength: 12, timeLimitMs: 361950, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 36, width: 30, height: 47, arrows: 123, minLength: 3, maxLength: 12, timeLimitMs: 379050, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 37, width: 31, height: 48, arrows: 130, minLength: 3, maxLength: 12, timeLimitMs: 399950, openMoves: 2, features: LevelFeatures(mirrors: 16)),
  LevelSpec(level: 38, width: 32, height: 49, arrows: 137, minLength: 3, maxLength: 12, timeLimitMs: 420850, openMoves: 2, features: LevelFeatures(mirrors: 17)),
  LevelSpec(level: 39, width: 33, height: 50, arrows: 143, minLength: 3, maxLength: 12, timeLimitMs: 438900, openMoves: 2, features: LevelFeatures(mirrors: 18)),
  LevelSpec(level: 40, width: 34, height: 52, arrows: 150, minLength: 3, maxLength: 12, timeLimitMs: 459800, openMoves: 2, features: LevelFeatures(mirrors: 19)),
  LevelSpec(level: 41, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 65550, openMoves: 3, features: LevelFeatures(locks: 2)),
  LevelSpec(level: 42, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 12, timeLimitMs: 114950, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 2), variant: 1),
  LevelSpec(level: 43, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 12, timeLimitMs: 137180, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 44, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 12, timeLimitMs: 155420, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 45, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 12, timeLimitMs: 181450, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 46, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 12, timeLimitMs: 202730, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 47, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 12, timeLimitMs: 221920, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3)),
  LevelSpec(level: 48, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 12, timeLimitMs: 247000, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 4)),
  LevelSpec(level: 49, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 12, timeLimitMs: 269230, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 50, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 12, timeLimitMs: 287470, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 51, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 12, timeLimitMs: 312550, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 5)),
  LevelSpec(level: 52, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 13, timeLimitMs: 334780, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 53, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 13, timeLimitMs: 353020, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 54, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 13, timeLimitMs: 379050, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 55, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 13, timeLimitMs: 400330, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 56, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 13, timeLimitMs: 419520, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6)),
  LevelSpec(level: 57, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 13, timeLimitMs: 444600, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 7), variant: 1),
  LevelSpec(level: 58, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 13, timeLimitMs: 466830, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 59, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 13, timeLimitMs: 485070, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 60, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 13, timeLimitMs: 511100, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 8)),
  LevelSpec(level: 61, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 63650, openMoves: 3, features: LevelFeatures(hidden: 2)),
  LevelSpec(level: 62, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 13, timeLimitMs: 127300, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 2)),
  LevelSpec(level: 63, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 13, timeLimitMs: 150195, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 64, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 13, timeLimitMs: 169005, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 65, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 13, timeLimitMs: 194750, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 66, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 13, timeLimitMs: 216695, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 67, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 13, timeLimitMs: 236455, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3)),
  LevelSpec(level: 68, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 13, timeLimitMs: 261250, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4)),
  LevelSpec(level: 69, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 13, timeLimitMs: 284145, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 70, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 13, timeLimitMs: 302955, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 71, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 13, timeLimitMs: 327750, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 5)),
  LevelSpec(level: 72, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 14, timeLimitMs: 350645, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 73, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 14, timeLimitMs: 369455, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 74, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 14, timeLimitMs: 395200, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 75, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 14, timeLimitMs: 417145, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 76, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 14, timeLimitMs: 436905, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 6)),
  LevelSpec(level: 77, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 14, timeLimitMs: 461700, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 7)),
  LevelSpec(level: 78, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 14, timeLimitMs: 484595, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 79, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 14, timeLimitMs: 503405, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 80, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 14, timeLimitMs: 529150, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 8)),
  LevelSpec(level: 81, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 63650, openMoves: 3, features: LevelFeatures(pairs: 2), variant: 4),
  LevelSpec(level: 82, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 14, timeLimitMs: 141550, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 83, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 14, timeLimitMs: 165110, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 84, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 14, timeLimitMs: 184490, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2)),
  LevelSpec(level: 85, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 14, timeLimitMs: 210900, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 86, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 14, timeLimitMs: 233510, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 87, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 14, timeLimitMs: 253840, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 88, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 14, timeLimitMs: 279300, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 89, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 14, timeLimitMs: 302860, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 90, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 14, timeLimitMs: 322240, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 91, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 14, timeLimitMs: 347700, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 92, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 15, timeLimitMs: 371260, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 93, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 15, timeLimitMs: 390640, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 94, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 15, timeLimitMs: 417050, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 95, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 15, timeLimitMs: 439660, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 96, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 15, timeLimitMs: 459990, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 97, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 15, timeLimitMs: 485450, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 98, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 15, timeLimitMs: 509010, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 99, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 15, timeLimitMs: 528390, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 100, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 15, timeLimitMs: 554800, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 4, pairs: 8)),
  LevelSpec(level: 101, width: 6, height: 6, arrows: 18, minLength: 2, maxLength: 4, timeLimitMs: 86450, openMoves: 3, faces: 6),
  LevelSpec(level: 102, width: 10, height: 10, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 173850, openMoves: 2, features: LevelFeatures(mirrors: 12), faces: 6),
  LevelSpec(level: 103, width: 12, height: 12, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 265050, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6), faces: 6),
  LevelSpec(level: 104, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 13, timeLimitMs: 350550, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 105, width: 15, height: 15, arrows: 132, minLength: 3, maxLength: 14, timeLimitMs: 395010, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 106, width: 15, height: 15, arrows: 133, minLength: 3, maxLength: 14, timeLimitMs: 397290, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 107, width: 15, height: 15, arrows: 134, minLength: 3, maxLength: 14, timeLimitMs: 399570, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 108, width: 15, height: 15, arrows: 135, minLength: 3, maxLength: 14, timeLimitMs: 402800, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 109, width: 15, height: 15, arrows: 136, minLength: 3, maxLength: 14, timeLimitMs: 407930, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 110, width: 15, height: 15, arrows: 137, minLength: 3, maxLength: 14, timeLimitMs: 411160, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 111, width: 15, height: 15, arrows: 138, minLength: 3, maxLength: 14, timeLimitMs: 416290, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 112, width: 15, height: 15, arrows: 139, minLength: 3, maxLength: 14, timeLimitMs: 422370, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 113, width: 15, height: 15, arrows: 140, minLength: 3, maxLength: 14, timeLimitMs: 425600, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 114, width: 15, height: 15, arrows: 141, minLength: 3, maxLength: 14, timeLimitMs: 427880, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 115, width: 15, height: 15, arrows: 142, minLength: 3, maxLength: 14, timeLimitMs: 431110, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 116, width: 15, height: 15, arrows: 143, minLength: 3, maxLength: 14, timeLimitMs: 433390, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 117, width: 15, height: 15, arrows: 144, minLength: 3, maxLength: 14, timeLimitMs: 435670, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 118, width: 16, height: 16, arrows: 145, minLength: 3, maxLength: 14, timeLimitMs: 438900, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 119, width: 16, height: 16, arrows: 146, minLength: 3, maxLength: 14, timeLimitMs: 446880, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 120, width: 16, height: 16, arrows: 147, minLength: 3, maxLength: 14, timeLimitMs: 453910, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 121, width: 16, height: 16, arrows: 148, minLength: 3, maxLength: 14, timeLimitMs: 456190, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 122, width: 16, height: 16, arrows: 149, minLength: 3, maxLength: 14, timeLimitMs: 458470, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 123, width: 16, height: 16, arrows: 150, minLength: 3, maxLength: 14, timeLimitMs: 461700, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 124, width: 16, height: 16, arrows: 151, minLength: 3, maxLength: 14, timeLimitMs: 463980, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 125, width: 16, height: 16, arrows: 152, minLength: 3, maxLength: 14, timeLimitMs: 467210, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 126, width: 16, height: 16, arrows: 153, minLength: 3, maxLength: 14, timeLimitMs: 469490, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 127, width: 16, height: 16, arrows: 154, minLength: 3, maxLength: 14, timeLimitMs: 475570, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 9, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 128, width: 16, height: 16, arrows: 155, minLength: 3, maxLength: 14, timeLimitMs: 484500, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 129, width: 16, height: 16, arrows: 156, minLength: 3, maxLength: 14, timeLimitMs: 486780, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 130, width: 16, height: 16, arrows: 157, minLength: 3, maxLength: 14, timeLimitMs: 490010, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 131, width: 16, height: 16, arrows: 158, minLength: 3, maxLength: 14, timeLimitMs: 492290, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 132, width: 16, height: 16, arrows: 159, minLength: 3, maxLength: 14, timeLimitMs: 494570, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 133, width: 16, height: 16, arrows: 160, minLength: 3, maxLength: 14, timeLimitMs: 497800, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 134, width: 16, height: 16, arrows: 161, minLength: 3, maxLength: 14, timeLimitMs: 500080, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 135, width: 16, height: 16, arrows: 162, minLength: 3, maxLength: 14, timeLimitMs: 507110, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 136, width: 16, height: 16, arrows: 163, minLength: 3, maxLength: 14, timeLimitMs: 512240, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 137, width: 16, height: 16, arrows: 164, minLength: 3, maxLength: 14, timeLimitMs: 514520, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 138, width: 16, height: 16, arrows: 165, minLength: 3, maxLength: 14, timeLimitMs: 520600, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 139, width: 16, height: 16, arrows: 166, minLength: 3, maxLength: 14, timeLimitMs: 522880, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 140, width: 16, height: 16, arrows: 167, minLength: 3, maxLength: 14, timeLimitMs: 526110, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 141, width: 16, height: 16, arrows: 168, minLength: 3, maxLength: 14, timeLimitMs: 528390, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 142, width: 17, height: 17, arrows: 169, minLength: 3, maxLength: 14, timeLimitMs: 534470, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 143, width: 17, height: 17, arrows: 170, minLength: 3, maxLength: 14, timeLimitMs: 537700, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 144, width: 17, height: 17, arrows: 171, minLength: 3, maxLength: 14, timeLimitMs: 539980, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 145, width: 17, height: 17, arrows: 172, minLength: 3, maxLength: 14, timeLimitMs: 546060, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 146, width: 17, height: 17, arrows: 173, minLength: 3, maxLength: 14, timeLimitMs: 548340, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 147, width: 17, height: 17, arrows: 174, minLength: 3, maxLength: 14, timeLimitMs: 553470, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 148, width: 17, height: 17, arrows: 175, minLength: 3, maxLength: 14, timeLimitMs: 556700, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 149, width: 17, height: 17, arrows: 176, minLength: 3, maxLength: 14, timeLimitMs: 558980, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 150, width: 17, height: 17, arrows: 177, minLength: 3, maxLength: 14, timeLimitMs: 566010, openMoves: 2, features: LevelFeatures(mirrors: 30, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 151, width: 8, height: 8, arrows: 36, minLength: 2, maxLength: 5, timeLimitMs: 137750, openMoves: 1, faces: 6),
  LevelSpec(level: 152, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 13, timeLimitMs: 367650, openMoves: 1, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 153, width: 16, height: 16, arrows: 150, minLength: 3, maxLength: 15, timeLimitMs: 438900, openMoves: 1, features: LevelFeatures(mirrors: 15, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 154, width: 16, height: 16, arrows: 168, minLength: 3, maxLength: 15, timeLimitMs: 482790, openMoves: 1, features: LevelFeatures(mirrors: 18, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 155, width: 17, height: 17, arrows: 178, minLength: 3, maxLength: 15, timeLimitMs: 568290, openMoves: 1, features: LevelFeatures(mirrors: 30, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 156, width: 17, height: 17, arrows: 178, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 157, width: 17, height: 17, arrows: 179, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 158, width: 17, height: 17, arrows: 179, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 159, width: 17, height: 17, arrows: 180, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 160, width: 17, height: 17, arrows: 180, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 11), faces: 6),
  LevelSpec(level: 161, width: 17, height: 17, arrows: 181, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 11), faces: 6),
  LevelSpec(level: 162, width: 17, height: 17, arrows: 181, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 163, width: 17, height: 17, arrows: 182, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 164, width: 17, height: 17, arrows: 182, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 165, width: 17, height: 17, arrows: 183, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 166, width: 17, height: 17, arrows: 183, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 167, width: 17, height: 17, arrows: 184, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 168, width: 17, height: 17, arrows: 184, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 12), faces: 6),
  LevelSpec(level: 169, width: 17, height: 17, arrows: 185, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 12), faces: 6),
  LevelSpec(level: 170, width: 17, height: 17, arrows: 185, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 171, width: 17, height: 17, arrows: 186, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 172, width: 17, height: 17, arrows: 186, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 173, width: 18, height: 18, arrows: 187, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 174, width: 18, height: 18, arrows: 187, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 175, width: 18, height: 18, arrows: 188, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 176, width: 18, height: 18, arrows: 188, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 13), faces: 6),
  LevelSpec(level: 177, width: 18, height: 18, arrows: 189, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 13), faces: 6),
  LevelSpec(level: 178, width: 18, height: 18, arrows: 189, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 179, width: 18, height: 18, arrows: 190, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 180, width: 18, height: 18, arrows: 190, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 181, width: 18, height: 18, arrows: 191, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 182, width: 18, height: 18, arrows: 191, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 183, width: 18, height: 18, arrows: 192, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 184, width: 18, height: 18, arrows: 192, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 14), faces: 6),
  LevelSpec(level: 185, width: 18, height: 18, arrows: 193, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 14), faces: 6),
  LevelSpec(level: 186, width: 18, height: 18, arrows: 193, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 187, width: 18, height: 18, arrows: 194, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 188, width: 18, height: 18, arrows: 194, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 189, width: 18, height: 18, arrows: 195, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 190, width: 18, height: 18, arrows: 195, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 191, width: 18, height: 18, arrows: 196, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 192, width: 18, height: 18, arrows: 196, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 15), faces: 6),
  LevelSpec(level: 193, width: 18, height: 18, arrows: 197, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 15), faces: 6),
  LevelSpec(level: 194, width: 18, height: 18, arrows: 197, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 195, width: 18, height: 18, arrows: 198, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 196, width: 18, height: 18, arrows: 198, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 197, width: 18, height: 18, arrows: 199, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 198, width: 18, height: 18, arrows: 199, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 199, width: 18, height: 18, arrows: 200, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 200, width: 18, height: 18, arrows: 200, minLength: 3, maxLength: 15, timeLimitMs: 569050, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 17, pairs: 16), faces: 6),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
