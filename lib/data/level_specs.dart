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

const int totalLevels = 250;

/// The share of the worked-out clock every level gets: each clock below is
/// the rule's (`tool/make_levels.dart`, and levels 1–20 as first tuned)
/// times this. The full clocks played slack, so they were trimmed to 95%,
/// and then another 10% off that (0.95 × 0.9).
const double kClockTrim = 0.855;

const List<LevelSpec> levelSpecs = <LevelSpec>[
  LevelSpec(level: 1, width: 5, height: 6, arrows: 5, minLength: 2, maxLength: 5, timeLimitMs: 22230, openMoves: 3),
  LevelSpec(level: 2, width: 6, height: 7, arrows: 8, minLength: 2, maxLength: 5, timeLimitMs: 25650, openMoves: 3),
  LevelSpec(level: 3, width: 7, height: 9, arrows: 12, minLength: 2, maxLength: 6, timeLimitMs: 32490, openMoves: 3),
  LevelSpec(level: 4, width: 8, height: 11, arrows: 17, minLength: 2, maxLength: 6, timeLimitMs: 39330, openMoves: 2),
  LevelSpec(level: 5, width: 10, height: 13, arrows: 24, minLength: 2, maxLength: 7, timeLimitMs: 57285, openMoves: 2),
  LevelSpec(level: 6, width: 12, height: 16, arrows: 30, minLength: 2, maxLength: 8, timeLimitMs: 68400, openMoves: 2),
  LevelSpec(level: 7, width: 14, height: 20, arrows: 40, minLength: 3, maxLength: 8, timeLimitMs: 86355, openMoves: 2),
  LevelSpec(level: 8, width: 19, height: 26, arrows: 59, minLength: 3, maxLength: 9, timeLimitMs: 120555, openMoves: 2),
  LevelSpec(level: 9, width: 20, height: 28, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 121410, openMoves: 2),
  LevelSpec(level: 10, width: 21, height: 30, arrows: 67, minLength: 3, maxLength: 10, timeLimitMs: 155610, openMoves: 2),
  LevelSpec(level: 11, width: 22, height: 32, arrows: 74, minLength: 3, maxLength: 10, timeLimitMs: 171000, openMoves: 2),
  LevelSpec(level: 12, width: 23, height: 34, arrows: 82, minLength: 3, maxLength: 10, timeLimitMs: 187245, openMoves: 2),
  LevelSpec(level: 13, width: 24, height: 36, arrows: 88, minLength: 3, maxLength: 10, timeLimitMs: 200925, openMoves: 2),
  LevelSpec(level: 14, width: 25, height: 38, arrows: 96, minLength: 3, maxLength: 10, timeLimitMs: 218025, openMoves: 2),
  LevelSpec(level: 15, width: 26, height: 40, arrows: 105, minLength: 3, maxLength: 10, timeLimitMs: 235980, openMoves: 2),
  LevelSpec(level: 16, width: 27, height: 42, arrows: 110, minLength: 3, maxLength: 10, timeLimitMs: 247095, openMoves: 2),
  LevelSpec(level: 17, width: 28, height: 44, arrows: 117, minLength: 3, maxLength: 10, timeLimitMs: 261630, openMoves: 2),
  LevelSpec(level: 18, width: 29, height: 46, arrows: 126, minLength: 3, maxLength: 10, timeLimitMs: 281295, openMoves: 2),
  LevelSpec(level: 19, width: 30, height: 48, arrows: 128, minLength: 3, maxLength: 10, timeLimitMs: 284715, openMoves: 2),
  LevelSpec(level: 20, width: 32, height: 50, arrows: 144, minLength: 3, maxLength: 10, timeLimitMs: 318060, openMoves: 2),
  LevelSpec(level: 21, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 54720, openMoves: 3, features: LevelFeatures(mirrors: 3)),
  LevelSpec(level: 22, width: 15, height: 23, arrows: 30, minLength: 3, maxLength: 11, timeLimitMs: 93195, openMoves: 2, features: LevelFeatures(mirrors: 4), variant: 1),
  LevelSpec(level: 23, width: 17, height: 26, arrows: 37, minLength: 3, maxLength: 11, timeLimitMs: 112005, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 24, width: 18, height: 28, arrows: 43, minLength: 3, maxLength: 11, timeLimitMs: 127395, openMoves: 2, features: LevelFeatures(mirrors: 5)),
  LevelSpec(level: 25, width: 20, height: 30, arrows: 50, minLength: 3, maxLength: 11, timeLimitMs: 146205, openMoves: 2, features: LevelFeatures(mirrors: 6)),
  LevelSpec(level: 26, width: 21, height: 32, arrows: 57, minLength: 3, maxLength: 11, timeLimitMs: 165015, openMoves: 2, features: LevelFeatures(mirrors: 7)),
  LevelSpec(level: 27, width: 22, height: 33, arrows: 63, minLength: 3, maxLength: 11, timeLimitMs: 181260, openMoves: 2, features: LevelFeatures(mirrors: 8)),
  LevelSpec(level: 28, width: 23, height: 35, arrows: 70, minLength: 3, maxLength: 11, timeLimitMs: 200070, openMoves: 2, features: LevelFeatures(mirrors: 9), variant: 1),
  LevelSpec(level: 29, width: 24, height: 37, arrows: 77, minLength: 3, maxLength: 11, timeLimitMs: 218880, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 30, width: 25, height: 38, arrows: 83, minLength: 3, maxLength: 11, timeLimitMs: 234270, openMoves: 2, features: LevelFeatures(mirrors: 10)),
  LevelSpec(level: 31, width: 26, height: 40, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 253080, openMoves: 2, features: LevelFeatures(mirrors: 11)),
  LevelSpec(level: 32, width: 27, height: 42, arrows: 97, minLength: 3, maxLength: 12, timeLimitMs: 271890, openMoves: 2, features: LevelFeatures(mirrors: 12)),
  LevelSpec(level: 33, width: 28, height: 43, arrows: 103, minLength: 3, maxLength: 12, timeLimitMs: 288135, openMoves: 2, features: LevelFeatures(mirrors: 13)),
  LevelSpec(level: 34, width: 29, height: 44, arrows: 110, minLength: 3, maxLength: 12, timeLimitMs: 306945, openMoves: 2, features: LevelFeatures(mirrors: 14)),
  LevelSpec(level: 35, width: 30, height: 46, arrows: 117, minLength: 3, maxLength: 12, timeLimitMs: 325755, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 36, width: 30, height: 47, arrows: 123, minLength: 3, maxLength: 12, timeLimitMs: 341145, openMoves: 2, features: LevelFeatures(mirrors: 15)),
  LevelSpec(level: 37, width: 31, height: 48, arrows: 130, minLength: 3, maxLength: 12, timeLimitMs: 359955, openMoves: 2, features: LevelFeatures(mirrors: 16)),
  LevelSpec(level: 38, width: 32, height: 49, arrows: 137, minLength: 3, maxLength: 12, timeLimitMs: 378765, openMoves: 2, features: LevelFeatures(mirrors: 17)),
  LevelSpec(level: 39, width: 33, height: 50, arrows: 143, minLength: 3, maxLength: 12, timeLimitMs: 395010, openMoves: 2, features: LevelFeatures(mirrors: 18)),
  LevelSpec(level: 40, width: 34, height: 52, arrows: 150, minLength: 3, maxLength: 12, timeLimitMs: 413820, openMoves: 2, features: LevelFeatures(mirrors: 19)),
  LevelSpec(level: 41, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 58995, openMoves: 3, features: LevelFeatures(locks: 2)),
  LevelSpec(level: 42, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 12, timeLimitMs: 103455, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 2), variant: 1),
  LevelSpec(level: 43, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 12, timeLimitMs: 123462, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 44, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 12, timeLimitMs: 139878, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 2)),
  LevelSpec(level: 45, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 12, timeLimitMs: 163305, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 46, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 12, timeLimitMs: 182457, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3)),
  LevelSpec(level: 47, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 12, timeLimitMs: 199728, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3)),
  LevelSpec(level: 48, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 12, timeLimitMs: 222300, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 4)),
  LevelSpec(level: 49, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 12, timeLimitMs: 242307, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 50, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 12, timeLimitMs: 258723, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 4)),
  LevelSpec(level: 51, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 12, timeLimitMs: 281295, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 5)),
  LevelSpec(level: 52, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 13, timeLimitMs: 301302, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 53, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 13, timeLimitMs: 317718, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 5)),
  LevelSpec(level: 54, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 13, timeLimitMs: 341145, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 55, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 13, timeLimitMs: 360297, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 6)),
  LevelSpec(level: 56, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 13, timeLimitMs: 377568, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 6)),
  LevelSpec(level: 57, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 13, timeLimitMs: 400140, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 7), variant: 1),
  LevelSpec(level: 58, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 13, timeLimitMs: 420147, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 59, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 13, timeLimitMs: 436563, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 7)),
  LevelSpec(level: 60, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 13, timeLimitMs: 459990, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 8)),
  LevelSpec(level: 61, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 57285, openMoves: 3, features: LevelFeatures(hidden: 2)),
  LevelSpec(level: 62, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 13, timeLimitMs: 114570, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 2)),
  LevelSpec(level: 63, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 13, timeLimitMs: 135176, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 64, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 13, timeLimitMs: 152105, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 2)),
  LevelSpec(level: 65, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 13, timeLimitMs: 175275, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 66, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 13, timeLimitMs: 195026, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 3)),
  LevelSpec(level: 67, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 13, timeLimitMs: 212810, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 3)),
  LevelSpec(level: 68, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 13, timeLimitMs: 235125, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4)),
  LevelSpec(level: 69, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 13, timeLimitMs: 255731, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 70, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 13, timeLimitMs: 272660, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4)),
  LevelSpec(level: 71, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 13, timeLimitMs: 294975, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 5)),
  LevelSpec(level: 72, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 14, timeLimitMs: 315581, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 73, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 14, timeLimitMs: 332510, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 5)),
  LevelSpec(level: 74, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 14, timeLimitMs: 355680, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 75, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 14, timeLimitMs: 375431, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 6)),
  LevelSpec(level: 76, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 14, timeLimitMs: 393215, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 6)),
  LevelSpec(level: 77, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 14, timeLimitMs: 415530, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 7)),
  LevelSpec(level: 78, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 14, timeLimitMs: 436136, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 79, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 14, timeLimitMs: 453065, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 7)),
  LevelSpec(level: 80, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 14, timeLimitMs: 476235, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 8)),
  LevelSpec(level: 81, width: 10, height: 13, arrows: 12, minLength: 2, maxLength: 5, timeLimitMs: 57285, openMoves: 3, features: LevelFeatures(pairs: 2), variant: 4),
  LevelSpec(level: 82, width: 15, height: 23, arrows: 30, minLength: 4, maxLength: 14, timeLimitMs: 127395, openMoves: 2, features: LevelFeatures(mirrors: 2, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 83, width: 17, height: 26, arrows: 37, minLength: 4, maxLength: 14, timeLimitMs: 148599, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2), variant: 1),
  LevelSpec(level: 84, width: 18, height: 28, arrows: 43, minLength: 4, maxLength: 14, timeLimitMs: 166041, openMoves: 2, features: LevelFeatures(mirrors: 3, locks: 3, hidden: 4, pairs: 2)),
  LevelSpec(level: 85, width: 19, height: 30, arrows: 50, minLength: 4, maxLength: 14, timeLimitMs: 189810, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 86, width: 21, height: 32, arrows: 57, minLength: 4, maxLength: 14, timeLimitMs: 210159, openMoves: 2, features: LevelFeatures(mirrors: 4, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 87, width: 22, height: 33, arrows: 63, minLength: 4, maxLength: 14, timeLimitMs: 228456, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 3)),
  LevelSpec(level: 88, width: 23, height: 35, arrows: 70, minLength: 4, maxLength: 14, timeLimitMs: 251370, openMoves: 2, features: LevelFeatures(mirrors: 5, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 89, width: 24, height: 37, arrows: 77, minLength: 4, maxLength: 14, timeLimitMs: 272574, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 90, width: 25, height: 38, arrows: 83, minLength: 4, maxLength: 14, timeLimitMs: 290016, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 4)),
  LevelSpec(level: 91, width: 26, height: 40, arrows: 90, minLength: 4, maxLength: 14, timeLimitMs: 312930, openMoves: 2, features: LevelFeatures(mirrors: 6, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 92, width: 27, height: 41, arrows: 97, minLength: 4, maxLength: 15, timeLimitMs: 334134, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 93, width: 28, height: 43, arrows: 103, minLength: 4, maxLength: 15, timeLimitMs: 351576, openMoves: 2, features: LevelFeatures(mirrors: 7, locks: 3, hidden: 4, pairs: 5)),
  LevelSpec(level: 94, width: 29, height: 44, arrows: 110, minLength: 4, maxLength: 15, timeLimitMs: 375345, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 95, width: 30, height: 46, arrows: 117, minLength: 4, maxLength: 15, timeLimitMs: 395694, openMoves: 2, features: LevelFeatures(mirrors: 8, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 96, width: 30, height: 47, arrows: 123, minLength: 4, maxLength: 15, timeLimitMs: 413991, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 6)),
  LevelSpec(level: 97, width: 31, height: 48, arrows: 130, minLength: 4, maxLength: 15, timeLimitMs: 436905, openMoves: 2, features: LevelFeatures(mirrors: 9, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 98, width: 32, height: 49, arrows: 137, minLength: 4, maxLength: 15, timeLimitMs: 458109, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 99, width: 33, height: 50, arrows: 143, minLength: 4, maxLength: 15, timeLimitMs: 475551, openMoves: 2, features: LevelFeatures(mirrors: 10, locks: 3, hidden: 4, pairs: 7)),
  LevelSpec(level: 100, width: 34, height: 52, arrows: 150, minLength: 4, maxLength: 15, timeLimitMs: 499320, openMoves: 2, features: LevelFeatures(mirrors: 11, locks: 3, hidden: 4, pairs: 8)),
  LevelSpec(level: 101, width: 6, height: 6, arrows: 18, minLength: 2, maxLength: 4, timeLimitMs: 77805, openMoves: 3, faces: 6),
  LevelSpec(level: 102, width: 10, height: 10, arrows: 60, minLength: 3, maxLength: 9, timeLimitMs: 156465, openMoves: 2, features: LevelFeatures(mirrors: 12), faces: 6),
  LevelSpec(level: 103, width: 12, height: 12, arrows: 90, minLength: 3, maxLength: 11, timeLimitMs: 238545, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6), faces: 6),
  LevelSpec(level: 104, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 13, timeLimitMs: 315495, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6), faces: 6),
  LevelSpec(level: 105, width: 15, height: 15, arrows: 132, minLength: 3, maxLength: 14, timeLimitMs: 355509, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 106, width: 15, height: 15, arrows: 133, minLength: 3, maxLength: 14, timeLimitMs: 357561, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 107, width: 15, height: 15, arrows: 134, minLength: 3, maxLength: 14, timeLimitMs: 359613, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 108, width: 15, height: 15, arrows: 135, minLength: 3, maxLength: 14, timeLimitMs: 362520, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 109, width: 15, height: 15, arrows: 136, minLength: 3, maxLength: 14, timeLimitMs: 367137, openMoves: 2, features: LevelFeatures(mirrors: 13, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 110, width: 15, height: 15, arrows: 137, minLength: 3, maxLength: 14, timeLimitMs: 370044, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 6, pairs: 7), faces: 6),
  LevelSpec(level: 111, width: 15, height: 15, arrows: 138, minLength: 3, maxLength: 14, timeLimitMs: 374661, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 6, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 112, width: 15, height: 15, arrows: 139, minLength: 3, maxLength: 14, timeLimitMs: 380133, openMoves: 2, features: LevelFeatures(mirrors: 14, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 113, width: 15, height: 15, arrows: 140, minLength: 3, maxLength: 14, timeLimitMs: 383040, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 114, width: 15, height: 15, arrows: 141, minLength: 3, maxLength: 14, timeLimitMs: 385092, openMoves: 2, features: LevelFeatures(mirrors: 15, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 115, width: 15, height: 15, arrows: 142, minLength: 3, maxLength: 14, timeLimitMs: 387999, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 116, width: 15, height: 15, arrows: 143, minLength: 3, maxLength: 14, timeLimitMs: 390051, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 117, width: 15, height: 15, arrows: 144, minLength: 3, maxLength: 14, timeLimitMs: 392103, openMoves: 2, features: LevelFeatures(mirrors: 16, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 118, width: 16, height: 16, arrows: 145, minLength: 3, maxLength: 14, timeLimitMs: 395010, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 7, pairs: 7), faces: 6),
  LevelSpec(level: 119, width: 16, height: 16, arrows: 146, minLength: 3, maxLength: 14, timeLimitMs: 402192, openMoves: 2, features: LevelFeatures(mirrors: 17, locks: 7, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 120, width: 16, height: 16, arrows: 147, minLength: 3, maxLength: 14, timeLimitMs: 408519, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 121, width: 16, height: 16, arrows: 148, minLength: 3, maxLength: 14, timeLimitMs: 410571, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 122, width: 16, height: 16, arrows: 149, minLength: 3, maxLength: 14, timeLimitMs: 412623, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 123, width: 16, height: 16, arrows: 150, minLength: 3, maxLength: 14, timeLimitMs: 415530, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 124, width: 16, height: 16, arrows: 151, minLength: 3, maxLength: 14, timeLimitMs: 417582, openMoves: 2, features: LevelFeatures(mirrors: 19, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 125, width: 16, height: 16, arrows: 152, minLength: 3, maxLength: 14, timeLimitMs: 420489, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 126, width: 16, height: 16, arrows: 153, minLength: 3, maxLength: 14, timeLimitMs: 422541, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 8, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 127, width: 16, height: 16, arrows: 154, minLength: 3, maxLength: 14, timeLimitMs: 428013, openMoves: 2, features: LevelFeatures(mirrors: 20, locks: 9, hidden: 8, pairs: 8), faces: 6),
  LevelSpec(level: 128, width: 16, height: 16, arrows: 155, minLength: 3, maxLength: 14, timeLimitMs: 436050, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 129, width: 16, height: 16, arrows: 156, minLength: 3, maxLength: 14, timeLimitMs: 438102, openMoves: 2, features: LevelFeatures(mirrors: 21, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 130, width: 16, height: 16, arrows: 157, minLength: 3, maxLength: 14, timeLimitMs: 441009, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 131, width: 16, height: 16, arrows: 158, minLength: 3, maxLength: 14, timeLimitMs: 443061, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 132, width: 16, height: 16, arrows: 159, minLength: 3, maxLength: 14, timeLimitMs: 445113, openMoves: 2, features: LevelFeatures(mirrors: 22, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 133, width: 16, height: 16, arrows: 160, minLength: 3, maxLength: 14, timeLimitMs: 448020, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 134, width: 16, height: 16, arrows: 161, minLength: 3, maxLength: 14, timeLimitMs: 450072, openMoves: 2, features: LevelFeatures(mirrors: 23, locks: 9, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 135, width: 16, height: 16, arrows: 162, minLength: 3, maxLength: 14, timeLimitMs: 456399, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 9, pairs: 9), faces: 6),
  LevelSpec(level: 136, width: 16, height: 16, arrows: 163, minLength: 3, maxLength: 14, timeLimitMs: 461016, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 137, width: 16, height: 16, arrows: 164, minLength: 3, maxLength: 14, timeLimitMs: 463068, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 10, hidden: 10, pairs: 9), faces: 6),
  LevelSpec(level: 138, width: 16, height: 16, arrows: 165, minLength: 3, maxLength: 14, timeLimitMs: 468540, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 139, width: 16, height: 16, arrows: 166, minLength: 3, maxLength: 14, timeLimitMs: 470592, openMoves: 2, features: LevelFeatures(mirrors: 25, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 140, width: 16, height: 16, arrows: 167, minLength: 3, maxLength: 14, timeLimitMs: 473499, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 141, width: 16, height: 16, arrows: 168, minLength: 3, maxLength: 14, timeLimitMs: 475551, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 10, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 142, width: 17, height: 17, arrows: 169, minLength: 3, maxLength: 14, timeLimitMs: 481023, openMoves: 2, features: LevelFeatures(mirrors: 26, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 143, width: 17, height: 17, arrows: 170, minLength: 3, maxLength: 14, timeLimitMs: 483930, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 144, width: 17, height: 17, arrows: 171, minLength: 3, maxLength: 14, timeLimitMs: 485982, openMoves: 2, features: LevelFeatures(mirrors: 27, locks: 11, hidden: 10, pairs: 10), faces: 6),
  LevelSpec(level: 145, width: 17, height: 17, arrows: 172, minLength: 3, maxLength: 14, timeLimitMs: 491454, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 146, width: 17, height: 17, arrows: 173, minLength: 3, maxLength: 14, timeLimitMs: 493506, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 10), faces: 6),
  LevelSpec(level: 147, width: 17, height: 17, arrows: 174, minLength: 3, maxLength: 14, timeLimitMs: 498123, openMoves: 2, features: LevelFeatures(mirrors: 28, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 148, width: 17, height: 17, arrows: 175, minLength: 3, maxLength: 14, timeLimitMs: 501030, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 149, width: 17, height: 17, arrows: 176, minLength: 3, maxLength: 14, timeLimitMs: 503082, openMoves: 2, features: LevelFeatures(mirrors: 29, locks: 11, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 150, width: 17, height: 17, arrows: 177, minLength: 3, maxLength: 14, timeLimitMs: 509409, openMoves: 2, features: LevelFeatures(mirrors: 30, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 151, width: 8, height: 8, arrows: 36, minLength: 2, maxLength: 5, timeLimitMs: 123975, openMoves: 1, faces: 6),
  LevelSpec(level: 152, width: 14, height: 14, arrows: 120, minLength: 3, maxLength: 13, timeLimitMs: 330885, openMoves: 1, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 153, width: 16, height: 16, arrows: 150, minLength: 3, maxLength: 15, timeLimitMs: 395010, openMoves: 1, features: LevelFeatures(mirrors: 15, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 154, width: 16, height: 16, arrows: 168, minLength: 3, maxLength: 15, timeLimitMs: 434511, openMoves: 1, features: LevelFeatures(mirrors: 18, locks: 6, hidden: 6, pairs: 6), faces: 6),
  LevelSpec(level: 155, width: 17, height: 17, arrows: 178, minLength: 3, maxLength: 15, timeLimitMs: 511461, openMoves: 1, features: LevelFeatures(mirrors: 30, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 156, width: 17, height: 17, arrows: 178, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 157, width: 17, height: 17, arrows: 179, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 12, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 158, width: 17, height: 17, arrows: 179, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 159, width: 17, height: 17, arrows: 180, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 11, pairs: 11), faces: 6),
  LevelSpec(level: 160, width: 17, height: 17, arrows: 180, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 11), faces: 6),
  LevelSpec(level: 161, width: 17, height: 17, arrows: 181, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 11), faces: 6),
  LevelSpec(level: 162, width: 17, height: 17, arrows: 181, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 163, width: 17, height: 17, arrows: 182, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 32, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 164, width: 17, height: 17, arrows: 182, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 165, width: 17, height: 17, arrows: 183, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 13, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 166, width: 17, height: 17, arrows: 183, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 167, width: 17, height: 17, arrows: 184, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 12, pairs: 12), faces: 6),
  LevelSpec(level: 168, width: 17, height: 17, arrows: 184, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 12), faces: 6),
  LevelSpec(level: 169, width: 17, height: 17, arrows: 185, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 12), faces: 6),
  LevelSpec(level: 170, width: 17, height: 17, arrows: 185, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 171, width: 17, height: 17, arrows: 186, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 34, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 172, width: 17, height: 17, arrows: 186, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 173, width: 18, height: 18, arrows: 187, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 14, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 174, width: 18, height: 18, arrows: 187, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 175, width: 18, height: 18, arrows: 188, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 13, pairs: 13), faces: 6),
  LevelSpec(level: 176, width: 18, height: 18, arrows: 188, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 13), faces: 6),
  LevelSpec(level: 177, width: 18, height: 18, arrows: 189, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 13), faces: 6),
  LevelSpec(level: 178, width: 18, height: 18, arrows: 189, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 179, width: 18, height: 18, arrows: 190, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 36, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 180, width: 18, height: 18, arrows: 190, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 181, width: 18, height: 18, arrows: 191, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 15, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 182, width: 18, height: 18, arrows: 191, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 183, width: 18, height: 18, arrows: 192, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 14, pairs: 14), faces: 6),
  LevelSpec(level: 184, width: 18, height: 18, arrows: 192, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 14), faces: 6),
  LevelSpec(level: 185, width: 18, height: 18, arrows: 193, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 14), faces: 6),
  LevelSpec(level: 186, width: 18, height: 18, arrows: 193, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 187, width: 18, height: 18, arrows: 194, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 38, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 188, width: 18, height: 18, arrows: 194, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 189, width: 18, height: 18, arrows: 195, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 190, width: 18, height: 18, arrows: 195, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 191, width: 18, height: 18, arrows: 196, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 15, pairs: 15), faces: 6),
  LevelSpec(level: 192, width: 18, height: 18, arrows: 196, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 15), faces: 6),
  LevelSpec(level: 193, width: 18, height: 18, arrows: 197, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 15), faces: 6),
  LevelSpec(level: 194, width: 18, height: 18, arrows: 197, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 195, width: 18, height: 18, arrows: 198, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 40, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 196, width: 18, height: 18, arrows: 198, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 197, width: 18, height: 18, arrows: 199, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 198, width: 18, height: 18, arrows: 199, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 199, width: 18, height: 18, arrows: 200, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 16, pairs: 16), faces: 6),
  LevelSpec(level: 200, width: 18, height: 18, arrows: 200, minLength: 3, maxLength: 15, timeLimitMs: 512145, openMoves: 1, features: LevelFeatures(mirrors: 42, locks: 18, hidden: 17, pairs: 16), faces: 6),
  LevelSpec(level: 201, width: 6, height: 8, arrows: 24, minLength: 2, maxLength: 4, timeLimitMs: 93195, openMoves: 3, faces: 6, depth: 4),
  LevelSpec(level: 202, width: 9, height: 17, arrows: 100, minLength: 3, maxLength: 8, timeLimitMs: 289845, openMoves: 2, features: LevelFeatures(mirrors: 12, locks: 6, hidden: 6, pairs: 6), faces: 6, depth: 13),
  LevelSpec(level: 203, width: 17, height: 21, arrows: 140, minLength: 3, maxLength: 7, timeLimitMs: 385605, openMoves: 2, features: LevelFeatures(mirrors: 18, locks: 7, hidden: 7, pairs: 7), faces: 6, depth: 8),
  LevelSpec(level: 204, width: 15, height: 20, arrows: 170, minLength: 3, maxLength: 14, timeLimitMs: 460845, openMoves: 2, features: LevelFeatures(mirrors: 24, locks: 8, hidden: 8, pairs: 8), faces: 6, depth: 15),
  LevelSpec(level: 205, width: 18, height: 24, arrows: 190, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6, depth: 12),
  LevelSpec(level: 206, width: 16, height: 27, arrows: 191, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 40, locks: 16, hidden: 15, pairs: 15), faces: 6, depth: 11),
  LevelSpec(level: 207, width: 12, height: 24, arrows: 191, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 16, hidden: 15, pairs: 15), faces: 6, depth: 18),
  LevelSpec(level: 208, width: 20, height: 25, arrows: 191, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 15, pairs: 15), faces: 6, depth: 10),
  LevelSpec(level: 209, width: 16, height: 21, arrows: 192, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 15, pairs: 15), faces: 6, depth: 16),
  LevelSpec(level: 210, width: 18, height: 24, arrows: 192, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 15), faces: 6, depth: 12),
  LevelSpec(level: 211, width: 16, height: 27, arrows: 192, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6, depth: 11),
  LevelSpec(level: 212, width: 12, height: 24, arrows: 193, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 42, locks: 17, hidden: 16, pairs: 16), faces: 6, depth: 18),
  LevelSpec(level: 213, width: 20, height: 25, arrows: 193, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 17, hidden: 16, pairs: 16), faces: 6, depth: 10),
  LevelSpec(level: 214, width: 16, height: 21, arrows: 193, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 18, hidden: 16, pairs: 16), faces: 6, depth: 16),
  LevelSpec(level: 215, width: 18, height: 24, arrows: 194, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 18, hidden: 16, pairs: 16), faces: 6, depth: 12),
  LevelSpec(level: 216, width: 17, height: 28, arrows: 194, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 18, hidden: 17, pairs: 16), faces: 6, depth: 11),
  LevelSpec(level: 217, width: 12, height: 24, arrows: 194, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 18, hidden: 17, pairs: 17), faces: 6, depth: 18),
  LevelSpec(level: 218, width: 20, height: 25, arrows: 195, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 44, locks: 18, hidden: 17, pairs: 17), faces: 6, depth: 10),
  LevelSpec(level: 219, width: 16, height: 21, arrows: 195, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 18, hidden: 17, pairs: 17), faces: 6, depth: 16),
  LevelSpec(level: 220, width: 18, height: 24, arrows: 195, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 19, hidden: 17, pairs: 17), faces: 6, depth: 12),
  LevelSpec(level: 221, width: 17, height: 28, arrows: 196, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 19, hidden: 17, pairs: 17), faces: 6, depth: 11),
  LevelSpec(level: 222, width: 12, height: 24, arrows: 196, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 19, hidden: 18, pairs: 17), faces: 6, depth: 18),
  LevelSpec(level: 223, width: 20, height: 25, arrows: 196, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 19, hidden: 18, pairs: 18), faces: 6, depth: 10),
  LevelSpec(level: 224, width: 16, height: 22, arrows: 197, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 46, locks: 19, hidden: 18, pairs: 18), faces: 6, depth: 16),
  LevelSpec(level: 225, width: 18, height: 24, arrows: 197, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 19, hidden: 18, pairs: 18), faces: 6, depth: 12),
  LevelSpec(level: 226, width: 17, height: 28, arrows: 197, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 20, hidden: 18, pairs: 18), faces: 6, depth: 11),
  LevelSpec(level: 227, width: 12, height: 24, arrows: 198, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 20, hidden: 18, pairs: 18), faces: 6, depth: 18),
  LevelSpec(level: 228, width: 20, height: 25, arrows: 198, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 20, hidden: 19, pairs: 18), faces: 6, depth: 10),
  LevelSpec(level: 229, width: 16, height: 22, arrows: 198, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 20, hidden: 19, pairs: 19), faces: 6, depth: 16),
  LevelSpec(level: 230, width: 18, height: 24, arrows: 199, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 48, locks: 20, hidden: 19, pairs: 19), faces: 6, depth: 12),
  LevelSpec(level: 231, width: 17, height: 28, arrows: 199, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 20, hidden: 19, pairs: 19), faces: 6, depth: 11),
  LevelSpec(level: 232, width: 12, height: 24, arrows: 199, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 21, hidden: 19, pairs: 19), faces: 6, depth: 18),
  LevelSpec(level: 233, width: 20, height: 25, arrows: 200, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 21, hidden: 19, pairs: 19), faces: 6, depth: 10),
  LevelSpec(level: 234, width: 16, height: 22, arrows: 200, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 21, hidden: 20, pairs: 19), faces: 6, depth: 16),
  LevelSpec(level: 235, width: 18, height: 24, arrows: 200, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 21, hidden: 20, pairs: 20), faces: 6, depth: 12),
  LevelSpec(level: 236, width: 17, height: 28, arrows: 201, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 50, locks: 21, hidden: 20, pairs: 20), faces: 6, depth: 11),
  LevelSpec(level: 237, width: 12, height: 25, arrows: 201, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 21, hidden: 20, pairs: 20), faces: 6, depth: 18),
  LevelSpec(level: 238, width: 20, height: 25, arrows: 201, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 22, hidden: 20, pairs: 20), faces: 6, depth: 10),
  LevelSpec(level: 239, width: 16, height: 22, arrows: 202, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 22, hidden: 20, pairs: 20), faces: 6, depth: 16),
  LevelSpec(level: 240, width: 18, height: 25, arrows: 202, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 22, hidden: 21, pairs: 20), faces: 6, depth: 12),
  LevelSpec(level: 241, width: 17, height: 28, arrows: 202, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 22, hidden: 21, pairs: 21), faces: 6, depth: 11),
  LevelSpec(level: 242, width: 12, height: 25, arrows: 203, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 52, locks: 22, hidden: 21, pairs: 21), faces: 6, depth: 19),
  LevelSpec(level: 243, width: 20, height: 26, arrows: 203, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 22, hidden: 21, pairs: 21), faces: 6, depth: 10),
  LevelSpec(level: 244, width: 16, height: 22, arrows: 203, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 23, hidden: 21, pairs: 21), faces: 6, depth: 16),
  LevelSpec(level: 245, width: 19, height: 25, arrows: 204, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 23, hidden: 21, pairs: 21), faces: 6, depth: 12),
  LevelSpec(level: 246, width: 17, height: 28, arrows: 204, minLength: 3, maxLength: 10, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 23, hidden: 22, pairs: 21), faces: 6, depth: 11),
  LevelSpec(level: 247, width: 12, height: 25, arrows: 204, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 23, hidden: 22, pairs: 22), faces: 6, depth: 19),
  LevelSpec(level: 248, width: 21, height: 26, arrows: 205, minLength: 3, maxLength: 9, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 54, locks: 23, hidden: 22, pairs: 22), faces: 6, depth: 10),
  LevelSpec(level: 249, width: 17, height: 22, arrows: 205, minLength: 3, maxLength: 14, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 56, locks: 23, hidden: 22, pairs: 22), faces: 6, depth: 17),
  LevelSpec(level: 250, width: 19, height: 25, arrows: 205, minLength: 3, maxLength: 11, timeLimitMs: 512145, openMoves: 2, features: LevelFeatures(mirrors: 56, locks: 24, hidden: 22, pairs: 22), faces: 6, depth: 12),
];

/// The spec for 1-based [level]; throws for a level outside 1..[totalLevels].
LevelSpec specForLevel(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return levelSpecs[level - 1];
}
