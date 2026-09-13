import 'package:arrow_game/engine/arrow_piece.dart';
import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/engine/puzzle.dart';
import 'package:arrow_game/models/level_spec.dart';

/// A tiny 4x4 board used by provider and widget tests:
///   0: (1,1)(2,1) → right, exits through (3,1): free.
///   1: (3,3)(3,2) ↑ up, exits through (3,1),(3,0): free.
///   2: (0,3)(1,3)(1,2) ↑ up, ray (1,1),(1,0): blocked by 0.
/// Solve: 0 then 2 (1 any time).
Puzzle samplePuzzle() => Puzzle(
      width: 4,
      height: 4,
      arrows: [
        ArrowPiece(id: 0, cells: const [Cell(1, 1), Cell(2, 1)], heading: Direction.right),
        ArrowPiece(id: 1, cells: const [Cell(3, 3), Cell(3, 2)], heading: Direction.up),
        ArrowPiece(id: 2, cells: const [Cell(0, 3), Cell(1, 3), Cell(1, 2)], heading: Direction.up),
      ],
    );

/// A spec matching [samplePuzzle] with a 30 s clock.
const LevelSpec sampleSpec = LevelSpec(
  level: 1,
  width: 4,
  height: 4,
  arrows: 3,
  minLength: 2,
  maxLength: 3,
  timeLimitMs: 30000,
);

/// [sampleSpec] under another level number (the puzzle is the same).
LevelSpec sampleSpecFor(int level) => LevelSpec(
      level: level,
      width: 4,
      height: 4,
      arrows: 3,
      minLength: 2,
      maxLength: 3,
      timeLimitMs: 30000,
    );
