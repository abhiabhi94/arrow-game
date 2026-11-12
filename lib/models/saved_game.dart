/// A level in progress, kept so the player can pick it up after closing the
/// app, switching away or backing out. The board itself is not stored: a
/// level's puzzle is fixed by its seed, so the seed, the arrows out, the
/// slips, the hints spent and the clock are enough to rebuild the moment —
/// plus, in the Rush chapters, what has landed on it since ([dropped],
/// [mirrors]), which depends on how it was played. Pure Dart.
library;

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/mirror.dart';
import '../engine/puzzle.dart';
import 'game_state.dart';

class SavedGame {
  const SavedGame({
    required this.level,
    required this.seed,
    required this.removed,
    required this.mistakes,
    required this.hintsLeft,
    required this.elapsedMs,
    this.bumped = const <int>[],
    this.revealed = const <int>[],
    this.continues = 0,
    this.drops = 0,
    this.dropped = const <List<Cell>>[],
    this.mirrors = const <Cell, Mirror>{},
  });

  /// A snapshot of [state], which must have its board and be mid-level.
  factory SavedGame.fromState(GameState state) => SavedGame(
        level: state.level,
        seed: state.spec.seed,
        removed: List<int>.unmodifiable(state.removed.toList()..sort()),
        bumped: List<int>.unmodifiable(state.bumped.toList()..sort()),
        revealed: List<int>.unmodifiable(state.revealed.toList()..sort()),
        mistakes: state.mistakes,
        hintsLeft: state.hintsLeft,
        elapsedMs: state.elapsedMs,
        continues: state.continues,
        drops: state.drops,
        dropped: <List<Cell>>[
          for (final a in state.puzzle?.arrows.skip(state.dealtArrows) ?? const <ArrowPiece>[]) a.cells,
        ],
        // The mirrors that landed: the board's less the dealt board's, which
        // the seed brings back on its own.
        mirrors: state.puzzle == null || !state.puzzle!.grows
            ? const <Cell, Mirror>{}
            : <Cell, Mirror>{
                for (final e in state.puzzle!.mirrors.entries)
                  if (!state.dealtMirrors.contains(e.key)) e.key: e.value,
              },
      );

  /// Rebuilds a snapshot from [toJson]; null when the map is not one.
  static SavedGame? fromJson(Map<String, Object?> json) {
    final level = json['level'];
    final seed = json['seed'];
    final removed = json['removed'];
    final mistakes = json['mistakes'];
    final hintsLeft = json['hintsLeft'];
    final elapsedMs = json['elapsedMs'];
    // The seed is what says which board the arrows out belong to. A snapshot
    // without one was written before a level could be re-dealt, so there is
    // no telling whether its board is still the level's: it is not trusted.
    if (level is! int ||
        seed is! int ||
        removed is! List ||
        removed.any((e) => e is! int) ||
        mistakes is! int ||
        hintsLeft is! int ||
        elapsedMs is! int) {
      return null;
    }
    // Both were added after the first release, so a snapshot without them is
    // still good: it just forgets which dead ends were already paid for.
    final bumped = json['bumped'];
    final revealed = json['revealed'];
    // What landed on a Rush board, as flat x, y lists. Anything malformed is
    // read as nothing having landed — and then the snapshot's arrow ids no
    // longer fit the board, so it is not resumed.
    final dropped = <List<Cell>>[];
    final rawDropped = json['dropped'];
    if (rawDropped is List) {
      for (final a in rawDropped) {
        final cells = _cells(a);
        if (cells == null || cells.length < 2) return null;
        dropped.add(cells);
      }
    }
    final mirrors = <Cell, Mirror>{};
    final rawMirrors = json['mirrors'];
    if (rawMirrors is List && rawMirrors.length % 3 == 0 && rawMirrors.every((e) => e is int)) {
      final v = rawMirrors.cast<int>();
      for (var i = 0; i < v.length; i += 3) {
        if (v[i + 2] < 0 || v[i + 2] >= Mirror.values.length) return null;
        mirrors[Cell(v[i], v[i + 1])] = Mirror.values[v[i + 2]];
      }
    }
    final drops = json['drops'];
    return SavedGame(
      level: level,
      seed: seed,
      removed: List<int>.unmodifiable(removed.cast<int>()),
      bumped: bumped is List && bumped.every((e) => e is int)
          ? List<int>.unmodifiable(bumped.cast<int>())
          : const <int>[],
      revealed: revealed is List && revealed.every((e) => e is int)
          ? List<int>.unmodifiable(revealed.cast<int>())
          : const <int>[],
      mistakes: mistakes,
      hintsLeft: hintsLeft,
      elapsedMs: elapsedMs,
      continues: switch (json['continues']) {
        final int n when n >= 0 => n,
        // The flag this replaced, from a snapshot written before the count.
        true => 1,
        _ => 0,
      },
      drops: drops is int && drops >= 0 ? drops : 0,
      dropped: List<List<Cell>>.unmodifiable(dropped),
      mirrors: Map<Cell, Mirror>.unmodifiable(mirrors),
    );
  }

  static List<Cell>? _cells(Object? raw) {
    if (raw is! List || raw.length.isOdd || raw.any((e) => e is! int)) return null;
    final xy = raw.cast<int>();
    return <Cell>[for (var i = 0; i < xy.length; i += 2) Cell(xy[i], xy[i + 1])];
  }

  /// The board [dealt] with what this snapshot says landed on it, or null
  /// when that cannot be on it: a cell off the board, an arrow that is not
  /// a chain of neighbouring cells, or a mirror where an arrow has sat or
  /// a mirror already stands.
  Puzzle? rebuild(Puzzle dealt) {
    if (dropped.isEmpty && mirrors.isEmpty) return dealt;
    final arrows = <ArrowPiece>[];
    for (final cells in dropped) {
      if (cells.any((c) => !c.isInside(dealt.width, dealt.height))) return null;
      if (cells.toSet().length != cells.length) return null;
      for (var i = 1; i < cells.length; i++) {
        if (cells[i - 1].directionTo(cells[i]) == null) return null;
      }
      arrows.add(ArrowPiece(
        id: dealt.arrowCount + arrows.length,
        cells: cells,
        heading: cells[cells.length - 2].directionTo(cells.last)!,
      ));
    }
    final sat = <Cell>{for (final a in dealt.arrows) ...a.cells, for (final a in arrows) ...a.cells};
    if (mirrors.keys.any((c) => !c.isInside(dealt.width, dealt.height) || dealt.isMirror(c) || sat.contains(c))) {
      return null;
    }
    return dealt.grownBy(arrows, mirrors: mirrors);
  }

  final int level;

  /// The seed of the board the snapshot was taken on (`LevelSpec.seed`). A
  /// level that has since been re-dealt gets a different one, and a snapshot
  /// whose arrows belong to another board must not be put on this one.
  final int seed;

  /// Ids of the arrows already out, ascending.
  final List<int> removed;

  /// Ids of the arrows that have already bumped, ascending: those no longer
  /// cost a life.
  final List<int> bumped;

  /// Ids of the hidden arrows whose head has been uncovered, ascending. The
  /// ones a departed neighbour uncovered are worked out again from
  /// [removed]; this keeps the ones a hint lit.
  final List<int> revealed;

  /// How many times the player spent the allowance and chose to play on.
  final int continues;

  /// How many drops had landed (the Rush chapters).
  final int drops;

  /// The cells (tail → head) of each arrow that landed during play, in the
  /// order they landed: their ids run on from the dealt board's.
  final List<List<Cell>> dropped;

  /// The mirrors that landed.
  final Map<Cell, Mirror> mirrors;
  final int mistakes;
  final int hintsLeft;
  final int elapsedMs;

  int get arrowsOut => removed.length;

  /// Whether there is anything worth coming back to.
  bool get hasProgress => removed.isNotEmpty || mistakes > 0 || hintsLeft < maxHints;

  Map<String, Object?> toJson() => <String, Object?>{
        'level': level,
        'seed': seed,
        'removed': removed,
        'bumped': bumped,
        'revealed': revealed,
        'mistakes': mistakes,
        'hintsLeft': hintsLeft,
        'elapsedMs': elapsedMs,
        'continues': continues,
        if (drops > 0) 'drops': drops,
        if (dropped.isNotEmpty) 'dropped': <List<int>>[
          for (final a in dropped) <int>[for (final c in a) ...<int>[c.x, c.y]],
        ],
        if (mirrors.isNotEmpty)
          'mirrors': <int>[for (final e in mirrors.entries) ...<int>[e.key.x, e.key.y, e.value.index]],
      };

  @override
  bool operator ==(Object other) =>
      other is SavedGame &&
      other.level == level &&
      other.seed == seed &&
      other.mistakes == mistakes &&
      other.hintsLeft == hintsLeft &&
      other.elapsedMs == elapsedMs &&
      other.continues == continues &&
      other.drops == drops &&
      other.dropped.length == dropped.length &&
      other.mirrors.length == mirrors.length &&
      other.removed.length == removed.length &&
      other.removed.every(removed.contains) &&
      other.bumped.length == bumped.length &&
      other.bumped.every(bumped.contains) &&
      other.revealed.length == revealed.length &&
      other.revealed.every(revealed.contains);

  @override
  int get hashCode => Object.hash(
        level,
        seed,
        mistakes,
        hintsLeft,
        elapsedMs,
        removed.length,
        bumped.length,
        continues,
        drops,
      );

  @override
  String toString() => 'SavedGame(level $level, $arrowsOut out, $mistakes slips, ${elapsedMs}ms)';
}
