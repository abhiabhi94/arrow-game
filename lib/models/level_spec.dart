/// The knobs that define one level's board. Pure Dart (no Flutter).
library;

/// The chapter twists a board is dealt with: how many mirrors stand on it
/// and how many of its arrows are locked, hidden or tethered. The plain
/// board with none of them is every level before the Mirrors chapter.
class LevelFeatures {
  const LevelFeatures({
    this.mirrors = 0,
    this.locks = 0,
    this.hidden = 0,
    this.pairs = 0,
  })  : assert(mirrors >= 0),
        assert(locks >= 0),
        assert(hidden >= 0),
        assert(pairs >= 0);

  static const LevelFeatures none = LevelFeatures();

  /// Mirror cells, each turning the arrows that slide into it.
  final int mirrors;

  /// Locked arrows, each with its own key arrow elsewhere on the board.
  final int locks;

  /// Arrows dealt with their head hidden.
  final int hidden;

  /// Tethered pairs that leave on one tap.
  final int pairs;

  bool get isPlain => mirrors == 0 && locks == 0 && hidden == 0 && pairs == 0;

  @override
  bool operator ==(Object other) =>
      other is LevelFeatures &&
      other.mirrors == mirrors &&
      other.locks == locks &&
      other.hidden == hidden &&
      other.pairs == pairs;

  @override
  int get hashCode => Object.hash(mirrors, locks, hidden, pairs);

  @override
  String toString() => 'LevelFeatures(mirrors $mirrors, locks $locks, hidden $hidden, pairs $pairs)';
}

class LevelSpec {
  const LevelSpec({
    required this.level,
    required this.width,
    required this.height,
    required this.arrows,
    required this.minLength,
    required this.maxLength,
    required this.timeLimitMs,
    this.openMoves = 2,
    this.variant = 0,
    this.features = LevelFeatures.none,
    this.faces = 0,
    this.depth = 0,
    this.timed = true,
    this._seed,
  })  : assert(level >= 0),
        assert(faces == 0 || (faces == 6 && (depth > 0 || width == height))),
        assert(depth == 0 || faces == 6),
        assert(openMoves >= 1),
        assert(variant >= 0),
        assert(width >= 3 && height >= 3),
        assert(arrows >= 1),
        assert(minLength >= 2 && maxLength >= minLength),
        assert(timeLimitMs > 0);

  /// 1-based level number on the trail, or [dailyLevel] for a daily board.
  final int level;

  /// The level number a daily board carries: it is on no trail.
  static const int dailyLevel = 0;

  /// Board size in cells — on a cube level, the size of one face.
  final int width;
  final int height;

  /// Arrows on the board (all must exit to clear the level) — on a cube
  /// level, on all its faces together.
  final int arrows;

  /// Arrow length range in cells.
  final int minLength;
  final int maxLength;

  /// The level clock: run out and the level is failed — unless [timed] is
  /// off, when it is only the level's nominal pace.
  final int timeLimitMs;

  /// Whether the clock can run out. Off with the "no time limit" setting
  /// ([untimed]): the time played is still counted, but never ends the level.
  final bool timed;

  /// How many arrows the generator tries to keep playable at any moment.
  /// Small numbers mean the player has to hunt for the next move; big ones
  /// leave plenty of obvious taps. A soft target, not a guarantee.
  final int openMoves;

  /// Which of the level's boards is dealt. The generator is seeded from the
  /// level and this, so a level can be re-dealt — when its first board came
  /// out looser than the curve wants — without moving any other level's.
  /// `tool/level_report.dart <level> <extra>` shows how the variants compare.
  final int variant;

  /// The chapter twists the board is dealt with — on a cube level, on all
  /// its faces together.
  final LevelFeatures features;

  /// How many faces a cube level has (six), or 0 for a flat board. Each
  /// face is a board of its own ([faceSpecs]); the player plays one at a
  /// time and turns the block to reach the next.
  final int faces;

  /// The block's depth in cells, front to back, when it is a box rather
  /// than a cube; 0 for a cube ([width] deep) or a flat board. A box is
  /// [width] wide, [height] tall and [depth] deep: its front and back are
  /// [width]×[height], its sides [depth]×[height] and its top and bottom
  /// [width]×[depth].
  final int depth;

  bool get isCube => faces > 0;

  /// Whether the block is a box with faces of different sizes.
  bool get isBox => depth > 0 && (depth != width || width != height);

  /// The block's depth in cells: [depth], or [width] on a cube.
  int get blockDepth => depth > 0 ? depth : width;

  /// The size of [face] of the block (faces numbered as `engine/cube.dart`
  /// numbers them: 0 front, 1 right, 2 back, 3 left, 4 top, 5 bottom).
  (int, int) faceSizeOf(int face) => switch (face) {
        0 || 2 => (width, height),
        1 || 3 => (blockDepth, height),
        _ => (width, blockDepth),
      };

  final int? _seed;

  /// Seed for the level's fixed puzzle. Variant 0 is the seed the levels were
  /// first cut with, so a level keeps its board unless it is re-dealt. A
  /// daily board carries its own seed instead.
  int get seed => _seed ?? level * 7919 + 17 + variant * 1_000_003;

  bool get isDaily => level == dailyLevel;

  /// Cells on the board, every face of a block counted.
  int get cellCount {
    if (!isCube) return width * height;
    var n = 0;
    for (var f = 0; f < faces; f++) {
      final (w, h) = faceSizeOf(f);
      n += w * h;
    }
    return n;
  }

  /// [total] shared out over the faces by their area — evenly on a cube —
  /// the odd ones going to the faces with the biggest leftover share, ties
  /// spread round the block from [offset] rather than heaped on the first
  /// face.
  ///
  /// When there are enough to go round, every face gets one first, so a
  /// small face of a box is never left without a twist the level has.
  List<int> _shareByArea(int total, int offset) {
    final areas = <int>[
      for (var f = 0; f < faces; f++) faceSizeOf(f).$1 * faceSizeOf(f).$2,
    ];
    final sum = areas.fold<int>(0, (a, b) => a + b);
    final base = total >= faces ? 1 : 0;
    final rest = total - base * faces;
    final out = <int>[for (final a in areas) base + rest * a ~/ sum];
    final order = List<int>.generate(faces, (f) => f)
      ..sort((a, b) {
        final ra = rest * areas[a] % sum, rb = rest * areas[b] % sum;
        if (ra != rb) return rb.compareTo(ra);
        return ((a + offset) % faces).compareTo((b + offset) % faces);
      });
    var left = total - out.fold<int>(0, (a, b) => a + b);
    for (final f in order) {
      if (left == 0) break;
      out[f]++;
      left--;
    }
    return out;
  }

  /// A block's faces as boards of their own: the arrows and the twists
  /// shared out between them by area — evenly on a cube, the odd ones
  /// spread round the block rather than heaped on the first face — each
  /// face its own size and seeded from the level's seed and its number.
  /// Empty for a flat board.
  List<LevelSpec> get faceSpecs {
    if (!isCube) return const <LevelSpec>[];
    final arrowShare = _shareByArea(arrows, 0);
    final mirrorShare = _shareByArea(features.mirrors, 1);
    final lockShare = _shareByArea(features.locks, 3);
    final hiddenShare = _shareByArea(features.hidden, 5);
    final pairShare = _shareByArea(features.pairs, 2);
    return <LevelSpec>[
      for (var f = 0; f < faces; f++)
        LevelSpec(
          level: level,
          width: faceSizeOf(f).$1,
          height: faceSizeOf(f).$2,
          arrows: arrowShare[f],
          minLength: minLength,
          maxLength: maxLength,
          timeLimitMs: timeLimitMs,
          openMoves: openMoves,
          features: LevelFeatures(
            mirrors: mirrorShare[f],
            locks: lockShare[f],
            hidden: hiddenShare[f],
            pairs: pairShare[f],
          ),
          seed: seed * 31 + (f + 1) * 104_729,
        ),
    ];
  }

  /// Cells an arrow may use: the board less its mirrors.
  int get freeCellCount => cellCount - features.mirrors;

  /// The same level with its clock multiplied by [factor] — the "extra time"
  /// accessibility setting. The board (and so [seed]) is untouched, so a
  /// saved game still fits and a cleared level is still that level. A factor
  /// of 1 is this very spec.
  LevelSpec withClockFactor(int factor) {
    assert(factor >= 1);
    if (factor == 1) return this;
    return LevelSpec(
      level: level,
      width: width,
      height: height,
      arrows: arrows,
      minLength: minLength,
      maxLength: maxLength,
      timeLimitMs: timeLimitMs * factor,
      openMoves: openMoves,
      variant: variant,
      features: features,
      faces: faces,
      depth: depth,
      timed: timed,
      seed: _seed,
    );
  }

  /// The same level with no clock at all — the "Remove time limits" setting.
  /// Like [withClockFactor], the board and [seed] are untouched.
  LevelSpec untimed() {
    if (!timed) return this;
    return LevelSpec(
      level: level,
      width: width,
      height: height,
      arrows: arrows,
      minLength: minLength,
      maxLength: maxLength,
      timeLimitMs: timeLimitMs,
      openMoves: openMoves,
      variant: variant,
      features: features,
      faces: faces,
      depth: depth,
      timed: false,
      seed: _seed,
    );
  }

  /// The same level dealt from another [variant].
  LevelSpec withVariant(int variant) => LevelSpec(
        level: level,
        width: width,
        height: height,
        arrows: arrows,
        minLength: minLength,
        maxLength: maxLength,
        timeLimitMs: timeLimitMs,
        openMoves: openMoves,
        variant: variant,
        features: features,
        faces: faces,
        depth: depth,
        timed: timed,
        seed: _seed,
      );

  @override
  String toString() => isBox
      ? 'LevelSpec($level: a ${width}x${height}x$depth box, $arrows arrows, ${timeLimitMs}ms)'
      : isCube
      ? 'LevelSpec($level: $faces faces of ${width}x$height, $arrows arrows, ${timeLimitMs}ms)'
      : 'LevelSpec($level: ${width}x$height, $arrows arrows, ${timeLimitMs}ms)';
}
