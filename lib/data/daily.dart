/// The daily board: one fresh deal a day, about five minutes long, with the
/// twists of the chapter the player has reached. Pure Dart.
///
/// Every player gets their own: the seed mixes the day with a salt drawn
/// once per install, so two phones never share a board and the same phone
/// never sees the same one twice. The day is the local calendar day.
library;

import '../engine/board_shape.dart';
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

/// The board for [day] in [chapter], seeded with [salt]. The shape and the
/// counts of the chapter's twists turn with the day, so a week of boards
/// in one chapter still differs board to board.
LevelSpec dailySpec({required int day, required Chapter chapter, required int salt}) {
  final seed = dailySeed(day, salt);
  final shapes = <BoardShape>[BoardShape.hole, BoardShape.pillars, BoardShape.bars, BoardShape.blocks];
  final shape = chapter.index >= 2 ? shapes[seed % shapes.length] : BoardShape.plain;
  final twist = 3 + (seed >> 4) % 3; // 3..5 of the chapter's own
  final features = switch (chapter.rule) {
    ChapterRule.lines => LevelFeatures.none,
    ChapterRule.shapes => LevelFeatures(shape: shape),
    ChapterRule.locks => LevelFeatures(shape: shape, locks: twist),
    ChapterRule.fog => LevelFeatures(shape: shape, locks: 2, hidden: twist),
    ChapterRule.pairs => LevelFeatures(shape: shape, locks: 2, hidden: 2, pairs: twist),
  };
  // About a hundred arrows at ~11.3 free cells each; a shape takes ~12%.
  final plain = chapter.index == 1;
  return LevelSpec(
    level: LevelSpec.dailyLevel,
    width: plain ? 27 : 29,
    height: plain ? 42 : 44,
    arrows: plain ? 90 : 100,
    minLength: 3,
    maxLength: 10 + chapter.index,
    timeLimitMs: kDailyTimeLimitMs,
    openMoves: 2,
    features: features,
    seed: seed,
  );
}
