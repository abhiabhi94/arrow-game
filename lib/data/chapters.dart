/// The trail in five chapters of twenty levels, each built on one twist:
/// plain lines, then shaped boards, then locks, then hidden heads, then
/// tethered pairs. Every chapter opens on a small teaching board that
/// carries the new twist alone, and the game screen puts an illustrated
/// card over that board the first time it is played. Pure Dart.
library;

import 'level_specs.dart';

/// What a chapter adds to the game.
enum ChapterRule {
  /// The one rule: tap an arrow with a clear path and it slides out.
  lines,

  /// Shaped boards: walls are holes an arrow falls into.
  shapes,

  /// Locked arrows wait for their numbered key.
  locks,

  /// Hidden heads show once a neighbour leaves.
  fog,

  /// Tethered pairs leave together.
  pairs,
}

class Chapter {
  const Chapter({required this.index, required this.rule});

  /// 1-based.
  final int index;
  final ChapterRule rule;

  int get firstLevel => (index - 1) * kChapterLength + 1;
  int get lastLevel => index * kChapterLength;

  /// The level the chapter's illustrated card is shown on: its first.
  int get teachingLevel => firstLevel;

  bool contains(int level) => level >= firstLevel && level <= lastLevel;
}

/// Levels per chapter.
const int kChapterLength = 20;

const List<Chapter> chapters = <Chapter>[
  Chapter(index: 1, rule: ChapterRule.lines),
  Chapter(index: 2, rule: ChapterRule.shapes),
  Chapter(index: 3, rule: ChapterRule.locks),
  Chapter(index: 4, rule: ChapterRule.fog),
  Chapter(index: 5, rule: ChapterRule.pairs),
];

/// The chapter [level] (1..[totalLevels]) belongs to.
Chapter chapterOf(int level) {
  if (level < 1 || level > totalLevels) {
    throw RangeError.range(level, 1, totalLevels, 'level');
  }
  return chapters[(level - 1) ~/ kChapterLength];
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
/// 21–40 the second, and so on. The daily board borrows its twists.
Chapter chapterForProgress(int levelsCleared) {
  final n = levelsCleared.clamp(0, totalLevels);
  final index = n == 0 ? 1 : ((n - 1) ~/ kChapterLength + 1).clamp(1, chapters.length);
  return chapters[index - 1];
}
