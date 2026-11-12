/// What lands on the board in the Rush chapters (`LevelDrops`): a few new
/// arrows packed into a shape on empty cells, and — in the second half —
/// a mirror or two that turn the ways out running through them. Pure Dart.
///
/// The promise that holds after every drop: **the board can still be
/// cleared.** A new arrow may land across an old one's way out, and a new
/// mirror may send an old arrow's way out somewhere else entirely — that is
/// the point, the board changes under the player — but nothing lands that
/// makes an arrow wait, through a chain, for itself, sends a way out round
/// in a ring or back through its own arrow. Every drop is checked against
/// the board as it would be once it has landed before it is offered.
library;

import 'dart:math';

import '../models/level_spec.dart';
import 'arrow_piece.dart';
import 'cell.dart';
import 'direction.dart';
import 'mirror.dart';
import 'puzzle.dart';

/// One drop: the arrows (ids running on from the board's) and mirrors it
/// brings.
class Drop {
  const Drop({required this.arrows, this.mirrors = const <Cell, Mirror>{}});

  final List<ArrowPiece> arrows;
  final Map<Cell, Mirror> mirrors;

  /// Every cell the drop lands on: its arrows' and its mirrors'.
  Set<Cell> get cells => <Cell>{for (final a in arrows) ...a.cells, ...mirrors.keys};

  /// The board with this drop landed on it.
  Puzzle landOn(Puzzle puzzle) => puzzle.grownBy(arrows, mirrors: mirrors);
}

/// The shapes a drop's arrows are packed into, small to large, each turned
/// any of four ways; [dropShapesFor] picks the ones that suit a drop.
const List<List<String>> kDropShapes = <List<String>>[
  <String>['##', '##'],
  <String>['##', '##', '##'],
  <String>['###', '###', '###'],
  <String>['#.', '#.', '##', '##'],
  <String>['###', '.#.', '.#.'],
  <String>['####', '####'],
  <String>['.##.', '####', '####', '.##.'],
  <String>['####', '####', '####'],
  <String>['###', '###', '###', '###', '###'],
  <String>['####', '####', '####', '####'],
  <String>['#....', '#....', '#####', '#####', '#####'],
  <String>['#####', '#####', '#####', '#####'],
  <String>['.###.', '#####', '#####', '#####', '.###.'],
  <String>['####', '####', '####', '####', '####', '####', '####'],
  <String>['#####', '#####', '#####', '#####', '#####', '#####'],
  <String>['######', '######', '######', '######', '######', '######'],
];

/// A drop lands at once, without waiting for its time, when this many
/// arrows or fewer are left on the board: a quick player is never left
/// looking at an empty board.
const int kDropLowWater = 3;

/// How long the cells a drop will land on glow before it lands, in
/// milliseconds of play: the arrows (and mirrors) are seen coming rather
/// than appearing out of thin air.
const int kDropWarnMs = 800;

/// The random a level's [index]th drop (from 0) is planned with: the same
/// level, played the same way, gets the same drops.
Random dropRandom(LevelSpec spec, int index) => Random(spec.seed * 31 + (index + 1) * 7919);

/// How many random spots each turned shape is tried at before the next.
const int kDropSpotTries = 40;

/// The cells a drop of [arrows] arrows up to [maxLength] long wants: room
/// for each to run its full length.
int dropCellsFor(int arrows, int maxLength) => arrows * maxLength;

/// The shapes that suit a drop of [arrows] arrows up to [maxLength] long:
/// between about two thirds and one and a half times [dropCellsFor], so a
/// late drop is a big shape of long arrows and an early one a small one.
List<List<String>> dropShapesFor(int arrows, int maxLength) {
  final want = dropCellsFor(arrows, maxLength);
  final fits = <List<String>>[
    for (final s in kDropShapes)
      if (_cellsOf(s, 0).length * 3 >= want * 2 && _cellsOf(s, 0).length * 2 <= want * 3) s,
  ];
  if (fits.isNotEmpty) return fits;
  // Nothing in the band: the nearest size there is.
  final nearest = List<List<String>>.of(kDropShapes)
    ..sort((a, b) => (_cellsOf(a, 0).length - want).abs().compareTo((_cellsOf(b, 0).length - want).abs()));
  return <List<String>>[nearest.first];
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

/// Whether [puzzle] can be cleared from where it stands, with [removed]
/// arrows out: whatever can go goes, until nothing can (leaving never
/// stops anything else leaving, so this is the whole question).
bool clearableFrom(Puzzle puzzle, Set<int> removed) {
  final gone = <int>{...removed};
  while (true) {
    final next = puzzle.removable(gone);
    if (next.isEmpty) return gone.length == puzzle.arrowCount;
    gone.addAll(next);
  }
}

/// Plans the next drop on [puzzle] with [removed] arrows already out, or
/// null when there is no room for one — the board is too full (a drop that
/// is due waits for the player to make room). A mirror never lands on the
/// way out of an arrow in [avoid] (one still sliding off the board), whose
/// slide would otherwise swerve in mid-air.
Drop? planDrop(Puzzle puzzle, Set<int> removed, LevelDrops drops, Random random, {Set<int> avoid = const <int>{}}) {
  final planner = _DropPlanner(puzzle, removed, drops, random);
  final footprint = planner.footprint();
  if (footprint == null) return null;
  final arrows = planner.fill(footprint);
  if (arrows.isEmpty) return null;
  // The arrows alone keep the board clearable by construction; check it.
  if (!clearableFrom(puzzle.grownBy(arrows), removed)) return null;
  final mirrors = planner.mirrors(arrows, avoid: <Cell>{for (final id in avoid) ...puzzle.rayOf(id)});
  return Drop(arrows: arrows, mirrors: mirrors);
}

class _DropPlanner {
  _DropPlanner(this.puzzle, this.removed, this.drops, this.random) {
    for (final a in puzzle.arrows) {
      if (removed.contains(a.id)) continue;
      live.add(a.id);
      taken.addAll(a.cells);
    }
    for (final id in live) {
      waits[id] = <int>{
        for (final d in puzzle.dependenciesOf(id))
          if (!removed.contains(d)) d,
      };
    }
  }

  final Puzzle puzzle;
  final Set<int> removed;
  final LevelDrops drops;
  final Random random;

  final Set<int> live = <int>{};
  final Set<Cell> taken = <Cell>{};

  /// Arrow id → what it waits for (on the board, or landing with it).
  final Map<int, Set<int>> waits = <int, Set<int>>{};

  /// The arrows planned so far, and their cells and ways out.
  final List<ArrowPiece> planned = <ArrowPiece>[];
  final Map<Cell, int> plannedAt = <Cell, int>{};
  final Map<int, List<Cell>> plannedRays = <int, List<Cell>>{};

  bool free(Cell c) => c.isInside(puzzle.width, puzzle.height) && !taken.contains(c) && !puzzle.isMirror(c);

  /// Empty cells in one of the drop's shapes, or null when none fits.
  /// The shapes that suit the drop come first, biggest first, so a late
  /// drop brings its long arrows whenever the board has the room; on a
  /// crowded board it falls back to smaller ones rather than not landing.
  Set<Cell>? footprint() {
    List<List<Cell>> turned(Iterable<List<String>> shapes) => <List<Cell>>[
          for (final shape in shapes)
            for (var t = 0; t < 4; t++) _cellsOf(shape, t),
        ]
          ..shuffle(random)
          ..sort((a, b) => b.length.compareTo(a.length));
    final suited = dropShapesFor(drops.arrows, drops.maxLength);
    final options = <List<Cell>>[
      ...turned(suited),
      ...turned(kDropShapes.where((s) => !suited.contains(s) && _cellsOf(s, 0).length < _cellsOf(suited.last, 0).length)),
    ];
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

  /// Up to [LevelDrops.arrows] arrows inside [footprint], each as long as
  /// the shape lets it be, up to [LevelDrops.maxLength].
  List<ArrowPiece> fill(Set<Cell> footprint) {
    // Long arrows first: for most of its tries a drop only takes an arrow
    // within three cells of its longest, and settles for a short one only
    // once the shape has no room left for a long one.
    final longEnough = max(2, drops.maxLength - 3);
    for (var attempt = 0; attempt < 120 && planned.length < drops.arrows; attempt++) {
      final open = <Cell>[for (final c in footprint) if (!plannedAt.containsKey(c)) c];
      if (open.length < 2) break;
      final body = _walk(open[random.nextInt(open.length)], footprint);
      if (body == null || (attempt < 90 && body.length < longEnough)) continue;
      for (final cells in <List<Cell>>[body, body.reversed.toList()]..shuffle(random)) {
        if (_accept(cells)) break;
      }
    }
    return List<ArrowPiece>.of(planned);
  }

  /// A path from [start] inside [footprint] aiming for close to
  /// [LevelDrops.maxLength] cells, or null when it cannot take a second
  /// step.
  List<Cell>? _walk(Cell start, Set<Cell> footprint) {
    final target = max(2, drops.maxLength - random.nextInt(min(3, drops.maxLength - 1)));
    final body = <Cell>[start];
    var heading = Direction.values[random.nextInt(4)];
    while (body.length < target) {
      Cell? next;
      // Straight on where it can (a long arrow is mostly straight), else
      // any way the shape leaves open.
      for (final d in <Direction>[heading, ...(List<Direction>.of(Direction.values)..shuffle(random))]) {
        if (next != null) break;
        if (d == heading && random.nextDouble() > 0.75) continue;
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

  /// Takes [cells] (tail → head) as a new arrow if its way out — through
  /// the mirrors on the board — leaves, misses its own body, and makes no
  /// arrow wait for itself.
  bool _accept(List<Cell> cells) {
    final heading = cells[cells.length - 2].directionTo(cells.last)!;
    final trace = traceRay(
      head: cells.last,
      heading: heading,
      width: puzzle.width,
      height: puzzle.height,
      mirrorAt: puzzle.mirrorAt,
    );
    if (trace == null || trace.cells.any(cells.contains)) return false;
    final ray = trace.cells;
    final id = puzzle.arrowCount + planned.length;
    final inTheWay = <int>{
      for (final c in ray) ...?_occupantOf(c),
    };
    // Whatever has its way out across the new body waits for it — and a
    // tethered arrow's partner with it, since the two leave together.
    final behind = <int>{
      for (final other in live)
        if (puzzle.rayOf(other).any(cells.contains)) ...<int>[other, ?puzzle.partnerOf(other)],
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

  /// Up to [LevelDrops.mirrors] mirrors, each where it turns the way out of
  /// some arrow on the board (or landing now) — a mirror nobody's path
  /// crosses would only be ornament — and never on a cell any arrow has
  /// ever sat on, off [avoid], clear of the edge and of the other mirrors.
  /// Each is kept only if every arrow still on the board keeps a way out
  /// that leaves, clear of its own body, and the board stays clearable.
  Map<Cell, Mirror> mirrors(List<ArrowPiece> arrows, {Set<Cell> avoid = const <Cell>{}}) {
    final placed = <Cell, Mirror>{};
    if (drops.mirrors == 0) return placed;
    final everSat = <Cell>{for (final a in puzzle.arrows) ...a.cells, for (final a in arrows) ...a.cells};
    final crossed = <Cell>{
      for (final id in live) ...puzzle.rayOf(id),
      for (final r in plannedRays.values) ...r,
    };
    bool clearOfMirrors(Cell c) {
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final n = Cell(c.x + dx, c.y + dy);
          if (puzzle.isMirror(n) || placed.containsKey(n)) return false;
        }
      }
      return true;
    }

    final candidates = <Cell>[
      for (final c in crossed)
        if (c.x >= 1 && c.y >= 1 && c.x < puzzle.width - 1 && c.y < puzzle.height - 1 &&
            !everSat.contains(c) && !avoid.contains(c))
          c,
    ]..shuffle(random);
    final grown = puzzle.grownBy(arrows);
    for (final c in candidates) {
      if (placed.length >= drops.mirrors) break;
      if (!clearOfMirrors(c)) continue;
      for (final m in <Mirror>[Mirror.slash, Mirror.backslash]..shuffle(random)) {
        final trial = <Cell, Mirror>{...placed, c: m};
        if (!_waysOutHold(grown, trial)) continue;
        final board = puzzle.grownBy(arrows, mirrors: trial);
        if (!clearableFrom(board, removed)) continue;
        placed[c] = m;
        break;
      }
    }
    return placed;
  }

  /// Whether, with [extra] mirrors on [board], every arrow still on it has
  /// a way out that leaves and does not come back through its own body.
  bool _waysOutHold(Puzzle board, Map<Cell, Mirror> extra) {
    for (final a in board.arrows) {
      if (removed.contains(a.id)) continue;
      final trace = traceRay(
        head: a.head,
        heading: a.heading,
        width: board.width,
        height: board.height,
        mirrorAt: (c) => extra[c] ?? board.mirrorAt(c),
      );
      if (trace == null || trace.cells.any(a.cells.contains)) return false;
    }
    return true;
  }
}
