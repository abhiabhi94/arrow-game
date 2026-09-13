/// A single arrow prompt and the answer it expects. Pure Dart (no Flutter).
library;

import 'direction.dart';

/// What twist (if any) an arrow carries.
///
/// - [normal]: answer the direction it points.
/// - [reverse]: answer the *opposite* direction (drawn in coral).
/// - [ghost]: points normally but disappears after a moment — answer from
///   memory.
/// - [decoy]: points normally but wears a word naming another direction —
///   trust the arrow, not the word.
enum ArrowKind { normal, reverse, ghost, decoy }

class Arrow {
  const Arrow({
    required this.id,
    required this.direction,
    this.kind = ArrowKind.normal,
    this.decoyLabel,
  }) : assert(
          (kind == ArrowKind.decoy) == (decoyLabel != null),
          'decoy arrows carry a label; other kinds never do',
        );

  /// Monotonic per game, so the UI can key entrance animations on it.
  final int id;

  /// Where the arrow points on screen.
  final Direction direction;

  final ArrowKind kind;

  /// For [ArrowKind.decoy]: the (wrong) direction written on the arrow.
  final Direction? decoyLabel;

  /// The direction the player must swipe to score this arrow.
  Direction get answer =>
      kind == ArrowKind.reverse ? direction.opposite : direction;

  bool accepts(Direction swiped) => swiped == answer;

  @override
  bool operator ==(Object other) =>
      other is Arrow &&
      other.id == id &&
      other.direction == direction &&
      other.kind == kind &&
      other.decoyLabel == decoyLabel;

  @override
  int get hashCode => Object.hash(id, direction, kind, decoyLabel);

  @override
  String toString() =>
      'Arrow#$id(${direction.name}, ${kind.name}${decoyLabel == null ? '' : ', says ${decoyLabel!.name}'})';
}
