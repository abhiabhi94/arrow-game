/// The trail in seven chapters. The first five are flat boards of twenty
/// levels each, each built on one twist: plain lines, then mirrors, then
/// locks, then hidden heads, then tethered pairs. The sixth is the block:
/// fifty levels on a cube past the first hundred, six faces of arrows
/// played one at a time, the twists coming back one by one on the faces.
/// The seventh is the squeeze: fifty more on the block, each face packed so
/// that fewer of its arrows can leave at once, and the work climbing on from
/// level 150's.
/// Every chapter opens on a small teaching board that carries the new thing
/// alone, and the game screen puts an illustrated card over that board the
/// first time it is played.
/// Pure Dart.
library;

import 'level_specs.dart';

/// What a chapter adds to the game.
enum ChapterRule {
  /// The one rule: tap an arrow with a clear path and it slides out.
  lines,

  /// Mirrors turn an arrow's path a right angle.
  mirrors,

  /// Locked arrows wait for their numbered key.
  locks,

  /// Hidden heads show once a neighbour leaves.
  fog,

  /// Tethered pairs leave together.
  pairs,

  /// Six faces on a block, played one at a time: the block turns to bring
  /// the next face round.
  cube,

  /// The block packed tighter: fewer ways out of each face at once.
  squeeze;

  /// Whether the chapter is played on the block rather than a flat board.
  bool get onBlock => this == cube || this == squeeze;

  /// Whether the chapter opens on an illustrated card. The squeeze does
  /// not: it is the block again, with nothing new to show.
  bool get hasCard => this != squeeze;
}

class Chapter {
  const Chapter({
    required this.index,
    required this.rule,
    required this.firstLevel,
    required this.lastLevel,
  });

  /// 1-based.
  final int index;
  final ChapterRule rule;
  final int firstLevel;
  final int lastLevel;

  /// Levels in the chapter.
  int get length => lastLevel - firstLevel + 1;

  /// The level the chapter's illustrated card is shown on: its first.
  int get teachingLevel => firstLevel;

  bool contains(int level) => level >= firstLevel && level <= lastLevel;
}

/// Levels in each of the flat chapters.
const int kChapterLength = 20;

/// The first level on the block: it comes after the first hundred, which
/// are as they always were.
const int kFirstCubeLevel = 101;

/// The first level of the squeeze, the second chapter on the block.
const int kFirstSqueezeLevel = 151;

/// How many chapters are flat boards (the daily board borrows from these).
const int kFlatChapterCount = 5;

const List<Chapter> chapters = <Chapter>[
  Chapter(index: 1, rule: ChapterRule.lines, firstLevel: 1, lastLevel: 20),
  Chapter(index: 2, rule: ChapterRule.mirrors, firstLevel: 21, lastLevel: 40),
  Chapter(index: 3, rule: ChapterRule.locks, firstLevel: 41, lastLevel: 60),
  Chapter(index: 4, rule: ChapterRule.fog, firstLevel: 61, lastLevel: 80),
  Chapter(index: 5, rule: ChapterRule.pairs, firstLevel: 81, lastLevel: 100),
  Chapter(index: 6, rule: ChapterRule.cube, firstLevel: kFirstCubeLevel, lastLevel: kFirstSqueezeLevel - 1),
  Chapter(index: 7, rule: ChapterRule.squeeze, firstLevel: kFirstSqueezeLevel, lastLevel: totalLevels),
];

/// The chapter [level] (1..[totalLevels]) belongs to.
Chapter chapterOf(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return chapters.firstWhere((c) => c.contains(level));
}

/// The twist [level] teaches, when it is a chapter's first level past the
/// first chapter (which the walkthrough already taught); null otherwise.
ChapterRule? ruleTaughtAt(int level) {
  final chapter = chapterOf(level);
  if (chapter.index == 1 || chapter.teachingLevel != level) return null;
  return chapter.rule;
}

/// The chapter a player who has cleared [levelsCleared] levels is in: the
/// one their furthest level sits in, so 0–20 cleared is the first chapter,
/// 21–40 the second, and so on.
Chapter chapterForProgress(int levelsCleared) =>
    chapterOf(levelsCleared.clamp(1, totalLevels));

/// The chapter whose twists the daily board borrows for a player who has
/// cleared [levelsCleared] levels: the one they are in, or — once they are
/// on the block, since the daily board is flat — the last flat chapter.
Chapter dailyChapterFor(int levelsCleared) {
  final chapter = chapterForProgress(levelsCleared);
  return chapter.rule.onBlock ? chapters[kFlatChapterCount - 1] : chapter;
}
