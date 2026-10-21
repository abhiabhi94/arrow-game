import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/models/board_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  // The sample board's heads: 0 at (2,1), 1 at (3,2), 2 at (1,2).
  final puzzle = samplePuzzle();

  test('with no cursor, any key lands on the first arrow in reading order', () {
    for (final d in Direction.values) {
      expect(cursorStep(puzzle, const {}, null, d), 0, reason: d.name);
    }
    // Once the top one has gone, the next row's leftmost head.
    expect(firstArrow(puzzle, const {0}), 2);
    expect(firstArrow(puzzle, const {0, 1, 2}), isNull);
  });

  test('steps to the nearest arrow in that direction', () {
    expect(cursorStep(puzzle, const {}, 0, Direction.down), 2); // (1,2) is straighter than (3,2)
    expect(cursorStep(puzzle, const {}, 2, Direction.right), 1);
    expect(cursorStep(puzzle, const {}, 1, Direction.left), 2);
    expect(cursorStep(puzzle, const {}, 1, Direction.up), 0);
    expect(cursorStep(puzzle, const {}, 2, Direction.up), 0);
  });

  test('nothing that way leaves the cursor where it is', () {
    expect(cursorStep(puzzle, const {}, 0, Direction.up), isNull);
    expect(cursorStep(puzzle, const {}, 2, Direction.left), isNull);
    expect(cursorStep(puzzle, const {}, 1, Direction.down), isNull);
  });

  test('arrows that have left are skipped, but still anchor the step', () {
    expect(cursorStep(puzzle, const {2}, 0, Direction.down), 1);
    // The cursor sat on arrow 2 when it slid out: a step right still goes
    // from where it was.
    expect(cursorStep(puzzle, const {2}, 2, Direction.right), 1);
    expect(cursorStep(puzzle, const {1, 2}, 0, Direction.down), isNull);
  });

  test('a wall of blocked arrows is walked one by one', () {
    final wall = blockedPuzzle(); // heads: 0 at (2,3); 1..4 at (1,0)..(1,3)
    expect(firstArrow(wall, const {}), 1);
    expect(cursorStep(wall, const {}, 1, Direction.down), 2);
    expect(cursorStep(wall, const {}, 2, Direction.down), 3);
    expect(cursorStep(wall, const {}, 3, Direction.down), 4);
    expect(cursorStep(wall, const {}, 4, Direction.right), 0);
    expect(cursorStep(wall, const {}, 0, Direction.left), 4);
  });
}
