/// What the board says to a screen reader.
///
/// The arrows are ink on a canvas, so without this a blind player hears
/// "puzzle board" and nothing else. Each arrow becomes its own node, placed
/// over the cells it covers, and its label says what a sighted player sees
/// when they look at it: where it is, which way it points, how long it is,
/// and what lies along its path — a clear run to the edge, or another arrow
/// so many cells ahead. That last part is the game: it is exactly what the
/// eye reads off the board, made audible, and no more. The engine's answer
/// (which arrows free which) stays its own.
library;

import '../engine/direction.dart';
import '../l10n/app_localizations.dart';
import '../models/game_state.dart';

/// The label of the board as a whole.
String boardLabel(AppLocalizations l10n, GameState state) {
  final puzzle = state.puzzle!;
  return l10n.boardLabel(
    puzzle.width,
    puzzle.height,
    puzzle.arrowCount - state.removed.length,
    puzzle.arrowCount,
  );
}

/// The label of arrow [id] on the board of [state].
String arrowLabel(AppLocalizations l10n, GameState state, int id) {
  final puzzle = state.puzzle!;
  final arrow = puzzle.arrows[id];
  final blocked = puzzle.firstBlockedCell(id, state.removed);
  final path = blocked == null
      ? l10n.arrowPathClear
      : l10n.arrowPathBlocked(
          (blocked.x - arrow.head.x).abs() + (blocked.y - arrow.head.y).abs(),
        );
  final parts = <String>[
    l10n.arrowLabel(
      directionName(l10n, arrow.heading),
      arrow.length,
      arrow.head.y + 1,
      arrow.head.x + 1,
      path,
    ),
    if (state.hintArrowId == id) l10n.arrowHinted,
    if (state.bumped.contains(id) && blocked != null) l10n.arrowBumpedBefore,
  ];
  return parts.join(' ');
}

/// [direction] in the app's language.
String directionName(AppLocalizations l10n, Direction direction) => switch (direction) {
  Direction.up => l10n.directionUp,
  Direction.right => l10n.directionRight,
  Direction.down => l10n.directionDown,
  Direction.left => l10n.directionLeft,
};
