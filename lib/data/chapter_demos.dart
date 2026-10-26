/// The tiny boards the chapter cards play: one picture of each twist, in
/// the game's own ink, with the script of taps that shows it off. Each is
/// a real, solvable [Puzzle] the board widget can draw and animate, so the
/// card never shows anything the game would not do. Pure Dart.
library;

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/mirror.dart';
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
      // Two mirrors. The first arrow slides right into one and leaves up
      // the top; the second slides left into the other and is turned up the
      // column the first arrow was lying across — so it has to go second.
      ChapterRule.mirrors => Puzzle(
          width: 7,
          height: 5,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(0, 2), Cell(1, 2), Cell(2, 2)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(6, 4), Cell(5, 4)], heading: Direction.left),
          ],
          mirrors: {const Cell(4, 2): Mirror.slash, const Cell(2, 4): Mirror.backslash},
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
      // A hidden head beside an arrow that can go, and an arrow standing
      // in the hidden one's way. The script taps the hidden one first (it
      // rattles, for free, and points at the arrow above it), then that
      // one leaves and the head comes out of the fog, then the arrow in
      // its way goes, then it does.
      ChapterRule.fog => Puzzle(
          width: 7,
          height: 4,
          arrows: [
            ArrowPiece(id: 0, cells: const [Cell(1, 0), Cell(2, 0), Cell(3, 0), Cell(4, 0)], heading: Direction.right),
            ArrowPiece(id: 1, cells: const [Cell(1, 1), Cell(2, 1), Cell(3, 1)], heading: Direction.right),
            ArrowPiece(id: 2, cells: const [Cell(5, 3), Cell(5, 2), Cell(5, 1)], heading: Direction.up),
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
      ChapterRule.cube => _cubeDemo,
    };

/// The block: one arrow on each face round its middle, each pointing a
/// different way, so the card turns the block from face to face as it
/// clears them. The top and bottom are left empty.
final Puzzle _cubeDemo = Puzzle.cube(<Puzzle>[
  _face([const Cell(0, 2), const Cell(1, 2), const Cell(2, 2)], Direction.right),
  _face([const Cell(2, 3), const Cell(2, 2), const Cell(2, 1)], Direction.up),
  _face([const Cell(3, 1), const Cell(2, 1), const Cell(1, 1)], Direction.left),
  _face([const Cell(1, 0), const Cell(1, 1), const Cell(1, 2)], Direction.down),
  Puzzle(width: 4, height: 4, arrows: const <ArrowPiece>[]),
  Puzzle(width: 4, height: 4, arrows: const <ArrowPiece>[]),
]);

Puzzle _face(List<Cell> cells, Direction heading) =>
    Puzzle(width: 4, height: 4, arrows: [ArrowPiece(id: 0, cells: cells, heading: heading)]);

/// The taps the card plays on [demoPuzzleFor]'s board, in order. A tap on a
/// locked (or hidden) arrow first is deliberate: it shows the rattle and the
/// pointer to the key (or to the arrow that uncovers the head) before that
/// one goes.
List<int> demoScriptFor(ChapterRule rule) => switch (rule) {
      ChapterRule.lines => const [0, 1],
      ChapterRule.mirrors => const [0, 1],
      ChapterRule.locks => const [0, 1, 0],
      ChapterRule.fog => const [1, 0, 2, 1],
      ChapterRule.pairs => const [0, 2],
      ChapterRule.cube => const [0, 1, 2, 3],
    };

/// A spec that fits [demoPuzzleFor]'s boards (nothing on it matters but the
/// size and the count).
LevelSpec demoSpecFor(ChapterRule rule) {
  final p = demoPuzzleFor(rule);
  return LevelSpec(
    level: 1,
    width: p.faceWidth,
    height: p.height,
    faces: p.isCube ? p.faceCount : 0,
    arrows: p.arrowCount,
    minLength: 2,
    maxLength: 6,
    timeLimitMs: 60000,
  );
}
