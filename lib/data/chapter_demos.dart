/// The tiny boards the chapter cards play: one picture of each twist, in
/// the game's own ink, with the script of taps that shows it off. Each is
/// a real, solvable [Puzzle] the board widget can draw and animate, so the
/// card never shows anything the game would not do. Pure Dart.
library;

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../models/level_spec.dart';
import 'chapters.dart';

/// The board that illustrates [rule].
Puzzle demoPuzzleFor(ChapterRule rule) => switch (rule) {
      ChapterRule.lines => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(4, 3), Cell(4, 2)], heading: Direction.up),
          ],
        ),
      // A wall block in the middle; the arrows bend around it on their way
      // out, and none aims at it.
      ChapterRule.shapes => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(
              id: 0,
              cells: const [Cell(1, 2), Cell(1, 1), Cell(2, 1), Cell(3, 1), Cell(4, 1), Cell(5, 1)],
              heading: Direction.right,
            ),
            ArrowPiece(id: 1, cells: const [Cell(5, 3), Cell(4, 3), Cell(4, 2)], heading: Direction.up),
            ArrowPiece(id: 2, cells: const [Cell(1, 3), Cell(2, 3)], heading: Direction.right),
          ],
          walls: {const Cell(2, 2), const Cell(3, 2)},
        ),
      // A locked arrow with a clear run, and its key across the board. The
      // script taps the lock first (it rattles and points at the key), then
      // the key, then the lock.
      ChapterRule.locks => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(3, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(5, 3), Cell(5, 2)], heading: Direction.up),
          ],
          locks: const {0: 1},
        ),
      // A hidden head beside an arrow that can go: that one leaves, the
      // head appears, then it leaves too.
      ChapterRule.fog => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(1, 0), Cell(2, 0), Cell(3, 0), Cell(4, 0)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(1, 1), Cell(2, 1), Cell(3, 1), Cell(4, 1)], heading: Direction.right),
            ArrowPiece(id: 2, cells: const [Cell(2, 3), Cell(3, 3)], heading: Direction.right),
          ],
          hidden: const {1},
        ),
      // Two tethered arrows that leave together on one tap.
      ChapterRule.pairs => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(1, 1), Cell(2, 1), Cell(3, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(3, 2), Cell(2, 2), Cell(1, 2)], heading: Direction.left),
            ArrowPiece(id: 2, cells: const [Cell(5, 3), Cell(5, 2)], heading: Direction.up),
          ],
          pairs: const {0: 1},
        ),
    };

/// The taps the card plays on [demoPuzzleFor]'s board, in order. A tap on a
/// locked arrow first is deliberate: it shows the rattle and the pointer to
/// the key before the key goes.
List<int> demoScriptFor(ChapterRule rule) => switch (rule) {
      ChapterRule.lines => const [0, 1],
      ChapterRule.shapes => const [0, 1, 2],
      ChapterRule.locks => const [0, 1, 0],
      ChapterRule.fog => const [0, 1, 2],
      ChapterRule.pairs => const [0, 2],
    };

/// A spec that fits [demoPuzzleFor]'s boards (nothing on it matters but the
/// size and the count).
LevelSpec demoSpecFor(ChapterRule rule) {
  final p = demoPuzzleFor(rule);
  return LevelSpec(
    level: 1,
    width: p.width,
    height: p.height,
    arrows: p.arrowCount,
    minLength: 2,
    maxLength: 6,
    timeLimitMs: 60000,
  );
}
