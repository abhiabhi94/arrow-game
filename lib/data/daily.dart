/// The daily board: one fresh deal a day, about five minutes long, with the
/// twists of the chapter the player has reached — and, once they have
/// cleared the hundred flat levels, on the 3D block. Pure Dart.
///
/// Every player gets their own: the seed mixes the day with a salt drawn
/// once per install, so two phones never share a board and the same phone
/// never sees the same one twice. The day is the local calendar day.
library;

import '../models/level_spec.dart';
import 'chapters.dart';

/// The daily clock, in minutes and in milliseconds. Five flat: the board is
/// sized to be read in about that at the trail's pace.
const int kDailyMinutes = 5;
const int kDailyTimeLimitMs = kDailyMinutes * 60 * 1000;

/// Days since the Unix epoch on the local calendar for [now].
int dayIndexOf(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  // Local midnight to UTC midnight of the epoch: the difference in whole
  // days is the calendar day, whatever the zone's offset.
  return local.difference(DateTime.utc(1970)).inHours ~/ 24;
}

/// The seed for [day] under [salt], mixed so neighbouring days share
/// nothing. A plain multiply-xor hash is plenty: the generator's `Random`
/// scrambles whatever it is given.
int dailySeed(int day, int salt) {
  var h = (day * 0x9E3779B1) ^ (salt * 0x85EBCA6B);
  h ^= h >>> 15;
  h = (h * 0x2C1B3C6D) & 0x7FFFFFFF;
  h ^= h >>> 12;
  return h & 0x3FFFFFFF;
}

/// The board for [day] in [chapter], seeded with [salt]. The number of
/// mirrors and the counts of the chapter's twists turn with the day, so a
/// week of boards in one chapter still differs board to board.
LevelSpec dailySpec({required int day, required Chapter chapter, required int salt}) {
  final seed = dailySeed(day, salt);
  if (chapter.rule.onBlock) return _dailyBlock(seed);
  final mirrors = chapter.index >= 2 ? 8 + seed % 5 : 0; // 8..12
  final twist = 3 + (seed >> 4) % 3; // 3..5 of the chapter's own
  final features = switch (chapter.rule) {
    ChapterRule.lines => LevelFeatures.none,
    ChapterRule.mirrors => LevelFeatures(mirrors: mirrors),
    ChapterRule.locks => LevelFeatures(mirrors: mirrors, locks: twist),
    ChapterRule.fog => LevelFeatures(mirrors: mirrors, locks: 2, hidden: twist),
    ChapterRule.pairs || ChapterRule.cube || ChapterRule.squeeze || ChapterRule.box => LevelFeatures(mirrors: mirrors, locks: 2, hidden: 2, pairs: twist),
  };
  // Eighty arrows at ~11.3 free cells each: 3.75 s an arrow of the five
  // minutes, the trail's own pace with room for the twists.
  return LevelSpec(
    level: LevelSpec.dailyLevel,
    width: 24,
    height: 37,
    arrows: 80,
    minLength: 3,
    maxLength: 10 + chapter.index,
    timeLimitMs: kDailyTimeLimitMs,
    openMoves: 2,
    features: features,
    seed: seed,
  );
}

/// Faces on the daily block.
const int kDailyFaces = 6;

/// The daily board on the block: six faces of fifteen arrows (12×12), every
/// twist on every face, the counts of mirrors and pairs turning with the
/// day. At the block's pace — 2.4 s an arrow, the twists' seconds and 2 s a
/// face for turning — that is the same five minutes as the flat board.
LevelSpec _dailyBlock(int seed) {
  final mirrors = 2 * kDailyFaces + seed % 5; // 12..16
  final pairs = kDailyFaces + (seed >> 4) % 3; // 6..8
  return LevelSpec(
    level: LevelSpec.dailyLevel,
    width: 12,
    height: 12,
    faces: kDailyFaces,
    arrows: 15 * kDailyFaces,
    minLength: 3,
    maxLength: 11,
    timeLimitMs: kDailyTimeLimitMs,
    openMoves: 2,
    features: LevelFeatures(mirrors: mirrors, locks: kDailyFaces, hidden: kDailyFaces, pairs: pairs),
    seed: seed,
  );
}
