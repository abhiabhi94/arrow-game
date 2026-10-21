import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/l10n/app_localizations.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/widgets/board_semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hi = lookupAppLocalizations(const Locale('hi'));

  test('the board says its size and how many arrows are left', () {
    final fresh = GameState.fresh(sampleSpec, samplePuzzle());
    expect(boardLabel(en, fresh), 'Puzzle board, 4 by 4, 3 of 3 arrows left');
    expect(boardLabel(en, fresh.copyWith(removed: {0})), 'Puzzle board, 4 by 4, 2 of 3 arrows left');
    expect(boardLabel(hi, fresh), 'पहेली बोर्ड, 4 गुणा 4, 3 में से 3 तीर बाक़ी');
  });

  test('an arrow says where it is, which way it points and what lies ahead', () {
    final state = GameState.fresh(sampleSpec, samplePuzzle());
    // Arrow 0: (1,1)(2,1) → right, head at row 2 column 3, a clear run out.
    expect(
      arrowLabel(en, state, 0),
      'Arrow pointing right, 2 cells long, head at row 2, column 3. Clear path to the edge.',
    );
    // Arrow 2: (0,3)(1,3)(1,2) ↑, head at row 3 column 2, arrow 0 right in front.
    expect(
      arrowLabel(en, state, 2),
      'Arrow pointing up, 3 cells long, head at row 3, column 2. '
      'Another arrow is right in front of it.',
    );
    // Once arrow 0 has gone, arrow 2's path is clear.
    expect(arrowLabel(en, state.copyWith(removed: {0}), 2), endsWith('Clear path to the edge.'));
  });

  test('the distance to the blocker is counted in cells', () {
    final wall = GameState.fresh(blockedSpecFor(1), blockedPuzzle());
    // Arrow 1: (0,0)(1,0) →, the wall at (2,0): one cell ahead.
    expect(arrowLabel(en, wall, 1), endsWith('Another arrow is right in front of it.'));
    final spaced = GameState.fresh(sampleSpec, samplePuzzle()).copyWith(removed: {});
    // Arrow 1 of the sample board: (3,3)(3,2) ↑ with (3,1),(3,0) free.
    expect(arrowLabel(en, spaced, 1), endsWith('Clear path to the edge.'));
  });

  test('a hint and a paid-for bump are mentioned', () {
    final state = GameState.fresh(sampleSpec, samplePuzzle());
    expect(arrowLabel(en, state.copyWith(hintArrowId: 0), 0), endsWith('Hint: this one can go.'));
    expect(
      arrowLabel(en, state.copyWith(bumped: {2}), 2),
      endsWith('Bumped before; another bump here is free.'),
    );
    // A bumped arrow whose path has since cleared is not "free to bump".
    expect(
      arrowLabel(en, state.copyWith(bumped: {2}, removed: {0}), 2),
      isNot(contains('Bumped before')),
    );
  });

  test('every direction has a word in both languages', () {
    for (final d in Direction.values) {
      expect(directionName(en, d), isNotEmpty);
      expect(directionName(hi, d), isNotEmpty);
      expect(directionName(hi, d), isNot(directionName(en, d)));
    }
    expect(arrowLabel(hi, GameState.fresh(sampleSpec, samplePuzzle()), 0), startsWith('दाएँ की ओर तीर'));
  });
}
