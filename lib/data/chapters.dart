/// The trail in nine chapters. The first five are flat boards of twenty
/// levels each, each built on one twist: plain lines, then mirrors, then
/// locks, then hidden heads, then tethered pairs. The sixth and seventh are
/// the Rush, twenty-five levels each on the plain rectangle again: new
/// arrows land on the board while it is played, and in the seventh,
/// mirrors land with them, turning the ways out that run through them. The eighth is the block: fifty levels on a
/// cube, six faces of arrows played one at a time, each face packed so
/// that few of its arrows can leave at once. The ninth is the box: fifty
/// on a block that is no longer a cube, its faces of three sizes and
/// bigger than the cube's. Every chapter opens on a small teaching board
/// that carries the new thing alone; the game screen puts an illustrated
/// card over that board the first time it is played (the box, the block
/// again, has only a line under it).
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

  /// New arrows land on the board while it is played.
  rush,

  /// New arrows land, and mirrors with them that turn the ways out.
  rushMirrors,

  /// Six faces on a block, played one at a time: the block turns to bring
  /// the next face round.
  cube,

  /// The block as a box: faces of three sizes, bigger than the cube's.
  box;

  /// Whether the chapter is played on the block rather than a flat board.
  bool get onBlock => this == cube || this == box;

  /// Whether arrows land on the chapter's boards while they are played.
  bool get isRush => this == rush || this == rushMirrors;

  /// Whether the chapter opens on an illustrated card. The box does not:
  /// it is the block again, and a line under the board says what is new.
  bool get hasCard => this != box;
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

/// The first level of the Rush: it comes after the first hundred, which are
/// as they always were.
const int kFirstRushLevel = 101;

/// The first level of the Rush with mirrors landing.
const int kFirstMirrorsLevel = 126;

/// The first level on the block.
const int kFirstCubeLevel = 151;

/// The first level of the box, the second chapter on the block.
const int kFirstBoxLevel = 201;

/// How many chapters are flat boards (the daily board borrows from these).
const int kFlatChapterCount = 5;

const List<Chapter> chapters = <Chapter>[
  Chapter(index: 1, rule: ChapterRule.lines, firstLevel: 1, lastLevel: 20),
  Chapter(index: 2, rule: ChapterRule.mirrors, firstLevel: 21, lastLevel: 40),
  Chapter(index: 3, rule: ChapterRule.locks, firstLevel: 41, lastLevel: 60),
  Chapter(index: 4, rule: ChapterRule.fog, firstLevel: 61, lastLevel: 80),
  Chapter(index: 5, rule: ChapterRule.pairs, firstLevel: 81, lastLevel: 100),
  Chapter(index: 6, rule: ChapterRule.rush, firstLevel: kFirstRushLevel, lastLevel: kFirstMirrorsLevel - 1),
  Chapter(index: 7, rule: ChapterRule.rushMirrors, firstLevel: kFirstMirrorsLevel, lastLevel: kFirstCubeLevel - 1),
  Chapter(index: 8, rule: ChapterRule.cube, firstLevel: kFirstCubeLevel, lastLevel: kFirstBoxLevel - 1),
  Chapter(index: 9, rule: ChapterRule.box, firstLevel: kFirstBoxLevel, lastLevel: totalLevels),
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

/// The block's chapter.
final Chapter cubeChapter = chapters.firstWhere((c) => c.rule == ChapterRule.cube);

/// The chapter the daily board is dealt in for a player who has cleared
/// [levelsCleared] levels: the one they are in, or — once every one of the
/// five twist chapters is cleared — the block, as it has been since the
/// block came straight after level 100 (the Rush keeps its drops to the
/// trail).
Chapter dailyChapterFor(int levelsCleared) {
  if (levelsCleared >= kFlatChapterCount * kChapterLength) return cubeChapter;
  return chapterForProgress(levelsCleared);
}

/// The chapter a stored daily [index] (from [dailyChapterFor]) deals in:
/// a twist chapter, or the block for anything past them — including the
/// index the block had before the Rush took its place.
Chapter dailyChapterAt(int index) =>
    index >= 1 && index <= kFlatChapterCount ? chapters[index - 1] : cubeChapter;
