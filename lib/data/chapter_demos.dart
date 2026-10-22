/// The tiny boards drawn on the chapter cards: one picture of each twist,
/// in the game's own ink, so the card shows the rule rather than describing
/// it. Each is a real [Puzzle] the board widget can draw — and a solvable
/// one, so the picture is never a lie. Pure Dart.
library;

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../models/level_spec.dart';
import 'chapters.dart';

/// The board that illustrates [rule].
Puzzle demoPuzzleFor(ChapterRule rule) => switch (rule) {
      // Two arrows: one with a clear run to the edge, one into a hole.
      ChapterRule.lines => Puzzle(
          width: 6,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(4, 3), Cell(4, 2)], heading: Direction.up),
          ],
        ),
      ChapterRule.shapes => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(1, 3), Cell(2, 3), Cell(3, 3)], heading: Direction.right),
            ArrowPiece(id: 2, cells: const [Cell(5, 0), Cell(5, 1)], heading: Direction.down),
          ],
          walls: {const Cell(4, 1), const Cell(0, 0), const Cell(6, 3)},
        ),
      // A locked arrow with a clear run, and its key across the board.
      ChapterRule.locks => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1), Cell(3, 1)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(5, 3), Cell(5, 2), Cell(5, 1)], heading: Direction.up),
          ],
          locks: const {0: 1},
        ),
      // A hidden head beside an arrow that can go.
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
      // Two tethered arrows that leave together.
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
    maxLength: 4,
    timeLimitMs: 60000,
  );
}
