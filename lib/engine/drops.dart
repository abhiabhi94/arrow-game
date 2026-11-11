/// What lands on the board in the Rush chapters (`LevelDrops`): a few new
/// arrows packed into a small shape on empty cells, and maybe a block or
/// two. Pure Dart.
///
/// Two promises hold after every drop. **The board can still be cleared:**
/// a new arrow may land across the way out of an arrow already there (that
/// is the point — the board fills back in where it was emptying), but never
/// so that something waits, through a chain, for itself. **A block never
/// shuts anyone in:** it lands only on a cell no arrow on the board has to
/// cross, and no new arrow is dealt with its way out through a block, so a
/// block that stays for the rest of the level is only ever in the way of
/// where the next arrows can land.
library;

import 'dart:math';

import '../models/level_spec.dart';
import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';
import 'puzzle.dart';

/// One drop: the arrows (ids running on from the board's) and blocks it
/// brings.
class Drop {
  const Drop({required this.arrows, required this.blocks});

  final List<ArrowPiece> arrows;
  final Set<Cell> blocks;

  /// The board with this drop landed on it.
  Puzzle landOn(Puzzle puzzle) => puzzle.grownBy(arrows, blocks: blocks);
}

/// The shapes a drop's arrows are packed into, by how many arrows it
/// brings: a small block of cells, turned any of four ways.
const List<List<String>> kDropShapes = <List<String>>[
  <String>['##', '##'],
  <String>['##', '##', '##'],
  <String>['###', '###', '###'],
  <String>['#.', '#.', '##', '##'],
  <String>['###', '.#.', '.#.'],
  <String>['####', '####'],
  <String>['.##.', '####', '####', '.##.'],
];

/// A drop lands at once, without waiting for its time, when this many
/// arrows or fewer are left on the board: a quick player is never left
/// looking at an empty board.
const int kDropLowWater = 3;

/// The random a level's [index]th drop (from 0) is planned with: the same
/// level, played the same way, gets the same drops.
Random dropRandom(LevelSpec spec, int index) => Random(spec.seed * 31 + (index + 1) * 7919);

/// How many random spots each turned shape is tried at before the next.
const int kDropSpotTries = 40;

/// The shapes for a drop of [arrows]: big enough to hold that many arrows of
/// two or three cells, not so big that one drop covers half the board.
List<List<String>> dropShapesFor(int arrows) {
  final fits = <List<String>>[
    for (final s in kDropShapes)
      if (_cellsOf(s, 0).length >= arrows * 2 && _cellsOf(s, 0).length <= arrows * 3 + 4) s,
  ];
  return fits.isEmpty ? <List<String>>[kDropShapes.last] : fits;
}

/// The cells of [shape] turned [turns] quarter turns, from (0, 0).
List<Cell> _cellsOf(List<String> shape, int turns) {
  var cells = <(int, int)>[
    for (var y = 0; y < shape.length; y++)
      for (var x = 0; x < shape[y].length; x++)
        if (shape[y][x] == '#') (x, y),
  ];
  for (var t = 0; t < turns; t++) {
    cells = <(int, int)>[for (final (x, y) in cells) (-y, x)];
  }
  final minX = cells.map((c) => c.$1).reduce(min);
  final minY = cells.map((c) => c.$2).reduce(min);
  return <Cell>[for (final (x, y) in cells) Cell(x - minX, y - minY)];
}

/// Plans the next drop on [puzzle] with [removed] arrows already out, or
/// null when there is no room for one — the board is too full (a drop that
/// is due waits for the player to make room).
Drop? planDrop(Puzzle puzzle, Set<int> removed, LevelDrops drops, Random random) {
  final planner = _DropPlanner(puzzle, removed, drops, random);
  final footprint = planner.footprint();
  if (footprint == null) return null;
  final arrows = planner.fill(footprint);
  if (arrows.isEmpty) return null;
  return Drop(arrows: arrows, blocks: planner.blocks(footprint));
}

class _DropPlanner {
  _DropPlanner(this.puzzle, this.removed, this.drops, this.random) {
    for (final a in puzzle.arrows) {
      if (removed.contains(a.id)) continue;
      live.add(a.id);
      taken.addAll(a.cells);
      liveRays.addAll(puzzle.rayOf(a.id));
    }
    for (final id in live) {
      waits[id] = <int>{
        for (final b in puzzle.blockersOf(id))
          if (!removed.contains(b)) b,
      };
    }
  }

  final Puzzle puzzle;
  final Set<int> removed;
  final LevelDrops drops;
  final Random random;

  final Set<int> live = <int>{};
  final Set<Cell> taken = <Cell>{};
  final Set<Cell> liveRays = <Cell>{};

  /// Arrow id → the arrows on the board (or landing with it) in its way.
  final Map<int, Set<int>> waits = <int, Set<int>>{};

  /// The arrows planned so far, and their cells and ways out.
  final List<ArrowPiece> planned = <ArrowPiece>[];
  final Map<Cell, int> plannedAt = <Cell, int>{};
  final Map<int, List<Cell>> plannedRays = <int, List<Cell>>{};

  bool free(Cell c) =>
      c.isInside(puzzle.width, puzzle.height) &&
      !taken.contains(c) &&
      !puzzle.isBlock(c) &&
      !puzzle.isMirror(c);

  /// Empty cells in one of the drop's shapes, or null when none fits.
  Set<Cell>? footprint() {
    final options = <List<Cell>>[
      for (final shape in dropShapesFor(drops.arrows))
        for (var t = 0; t < 4; t++) _cellsOf(shape, t),
    ]..shuffle(random);
    for (final cells in options) {
      for (var i = 0; i < kDropSpotTries; i++) {
        final ox = random.nextInt(puzzle.width);
        final oy = random.nextInt(puzzle.height);
        final placed = <Cell>[for (final c in cells) Cell(c.x + ox, c.y + oy)];
        if (placed.every(free)) return placed.toSet();
      }
    }
    return null;
  }

  /// Up to [LevelDrops.arrows] arrows inside [footprint].
  List<ArrowPiece> fill(Set<Cell> footprint) {
    for (var attempt = 0; attempt < 40 && planned.length < drops.arrows; attempt++) {
      final open = <Cell>[for (final c in footprint) if (!plannedAt.containsKey(c)) c];
      if (open.length < 2) break;
      final body = _walk(open[random.nextInt(open.length)], footprint);
      if (body == null) continue;
      for (final cells in <List<Cell>>[body, body.reversed.toList()]..shuffle(random)) {
        if (_accept(cells)) break;
      }
    }
    return List<ArrowPiece>.of(planned);
  }

  /// A path of two to [LevelDrops.maxLength] cells from [start] inside
  /// [footprint], or null when it cannot take a second step.
  List<Cell>? _walk(Cell start, Set<Cell> footprint) {
    final target = 2 + random.nextInt(drops.maxLength - 1);
    final body = <Cell>[start];
    var heading = Direction.values[random.nextInt(4)];
    while (body.length < target) {
      Cell? next;
      for (var a = 0; a < 6 && next == null; a++) {
        final d = a == 0 && random.nextDouble() < 0.6 ? heading : Direction.values[random.nextInt(4)];
        final c = body.last.step(d);
        if (footprint.contains(c) && !plannedAt.containsKey(c) && !body.contains(c)) {
          next = c;
          heading = d;
        }
      }
      if (next == null) break;
      body.add(next);
    }
    return body.length < 2 ? null : body;
  }

  /// Takes [cells] (tail → head) as a new arrow if its way out is straight
  /// and free of blocks and mirrors, misses its own body, and makes no
  /// arrow wait for itself.
  bool _accept(List<Cell> cells) {
    final heading = cells[cells.length - 2].directionTo(cells.last)!;
    final ray = <Cell>[];
    for (var c = cells.last.step(heading); c.isInside(puzzle.width, puzzle.height); c = c.step(heading)) {
      if (puzzle.isBlock(c) || puzzle.isMirror(c) || cells.contains(c)) return false;
      ray.add(c);
    }
    final id = puzzle.arrowCount + planned.length;
    final inTheWay = <int>{
      for (final c in ray) ...?_occupantOf(c),
    };
    final behind = <int>{
      for (final other in live)
        if (puzzle.rayOf(other).any(cells.contains)) other,
      for (final e in plannedRays.entries)
        if (e.value.any(cells.contains)) e.key,
    };
    if (_reaches(inTheWay, behind)) return false;
    planned.add(ArrowPiece(id: id, cells: cells, heading: heading));
    for (final c in cells) {
      plannedAt[c] = id;
    }
    plannedRays[id] = ray;
    waits[id] = inTheWay;
    for (final b in behind) {
      waits[b]!.add(id);
    }
    return true;
  }

  /// The arrow on [c] that a new arrow's way out would run into: one still
  /// on the board, or one landing with it.
  Set<int>? _occupantOf(Cell c) {
    final p = plannedAt[c];
    if (p != null) return <int>{p};
    final id = puzzle.arrowAt(c);
    return id != null && !removed.contains(id) ? <int>{id} : null;
  }

  /// Whether any of [from] waits, through a chain, for one of [goal].
  bool _reaches(Set<int> from, Set<int> goal) {
    if (goal.isEmpty) return false;
    final seen = <int>{};
    final stack = List<int>.of(from);
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (goal.contains(id)) return true;
      if (!seen.add(id)) continue;
      stack.addAll(waits[id] ?? const <int>{});
    }
    return false;
  }

  /// Up to [LevelDrops.blocks] blocks: empty cells no arrow on the board
  /// (or landing now) has to cross, beside an arrow where there is one.
  Set<Cell> blocks(Set<Cell> footprint) {
    if (drops.blocks == 0) return const <Cell>{};
    final crossed = <Cell>{...liveRays, for (final r in plannedRays.values) ...r};
    final candidates = <Cell>[
      for (var y = 0; y < puzzle.height; y++)
        for (var x = 0; x < puzzle.width; x++)
          if (free(Cell(x, y)) && !plannedAt.containsKey(Cell(x, y)) && !crossed.contains(Cell(x, y))) Cell(x, y),
    ];
    bool besideAnArrow(Cell c) =>
        Direction.values.any((d) => taken.contains(c.step(d)) || plannedAt.containsKey(c.step(d)));
    final near = candidates.where(besideAnArrow).toList()..shuffle(random);
    final far = candidates.where((c) => !besideAnArrow(c)).toList()..shuffle(random);
    return <Cell>{...near, ...far}.take(drops.blocks).toSet();
  }
}
