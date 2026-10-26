import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapters.dart';
import '../data/daily.dart';
import '../data/level_specs.dart';
import '../l10n/app_localizations.dart';
import '../models/level_progress.dart';
import '../models/level_spec.dart';
import '../providers/daily_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/saved_game_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Vertical distance between trail nodes.
const double kTrailSpacing = 90;

/// The room a chapter heading takes on the trail, above its first level.
const double kChapterBandHeight = 104;

/// The home screen: a stars tally, a "next up" hero card, and the journey — a
/// winding trail of every level node (locked ones numbered too) with lock / stars / current state.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final nextLevel = notifier.highestUnlocked;
    final allCleared = notifier.levelsCleared == totalLevels;
    // A level left mid-way takes the hero card: it is where the player was.
    // A daily board left mid-way is the daily card's to offer.
    final saved = ref.watch(savedGameProvider);
    final savedLevel = saved != null && saved.level != LevelSpec.dailyLevel ? saved : null;
    // With time limits removed a level has no clock to report.
    final untimed = ref.watch(settingsProvider.select((s) => s.noTimeLimit));
    final heroLevel = savedLevel?.level ?? nextLevel;
    final daily = ref.watch(dailyProvider);
    final dailyNotifier = ref.read(dailyProvider.notifier)..refresh();
    final dailySaved = saved != null &&
        saved.level == LevelSpec.dailyLevel &&
        saved.seed == dailyNotifier.spec.seed;

    return Scaffold(
      body: SafeArea(
        // Full-width scroll view, phone-width content: in a desktop browser
        // the trail would otherwise meander across the whole window. The
        // gutter (not a centred column) keeps the wheel and a mouse drag
        // scrolling from anywhere over the page.
        child: LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            slivers: [
              // The header is a sliver of the scroll view itself, not one of
              // the group below: a pinned header inside a SliverMainAxisGroup
              // paints less than it lays out, which trips the geometry assert.
              SliverPadding(
                padding: contentGutter(constraints.maxWidth),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeHeader(
                    title: l10n.appTitle,
                    tagline: l10n.appTagline,
                    stars: notifier.totalStars,
                    palette: p,
                    textScaler: MediaQuery.textScalerOf(context),
                    settingsTooltip: l10n.homeSettings,
                    onSettings: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: contentGutter(constraints.maxWidth),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                        child: _NextUpCard(
                          level: heroLevel,
                          allCleared: allCleared,
                          resume: savedLevel == null
                              ? null
                              : untimed
                                  ? l10n.homeResumeProgressUntimed(
                                      savedLevel.arrowsOut,
                                      specForLevel(savedLevel.level).arrows,
                                    )
                                  : l10n.homeResumeProgress(
                                      savedLevel.arrowsOut,
                                      specForLevel(savedLevel.level).arrows,
                                      formatDurationMs(savedLevel.elapsedMs),
                                    ),
                          onPlay: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameScreen(level: heroLevel),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                        child: _DailyCard(
                          standing: daily,
                          arrows: dailyNotifier.spec.arrows,
                          untilNext: dailyNotifier.untilNextBoard,
                          resuming: dailySaved,
                          onPlay: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const GameScreen.daily()),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  l10n.homeJourney,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: p.textInk,
                                  ),
                                ),
                              ),
                            ),
                            // Flexible so a large system font wraps the count
                            // rather than running off the row.
                            Flexible(
                              child: Text(
                                l10n.homeLevelsCleared(notifier.levelsCleared, totalLevels),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: _Trail(
                          progress: progress,
                          isUnlocked: notifier.isUnlocked,
                          current: nextLevel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The home screen's header, pinned to the top of the trail: the trail is
/// a hundred levels long, and the star count and the way into Settings should not
/// be a hundred levels back up the page. It shrinks as the page scrolls — the
/// title comes down to a heading and the tagline folds away — while the stars
/// and the gear stay put, and stay the same size.
class _HomeHeader extends SliverPersistentHeaderDelegate {
  const _HomeHeader({
    required this.title,
    required this.tagline,
    required this.stars,
    required this.palette,
    required this.textScaler,
    required this.settingsTooltip,
    required this.onSettings,
  });

  final String title;
  final String tagline;
  final int stars;
  final ArrowPalette palette;

  /// The system font size: the header has to make room for the title and
  /// tagline it draws, or a large setting overflows the extent.
  final TextScaler textScaler;
  final String settingsTooltip;
  final VoidCallback onSettings;

  /// The title's and tagline's line heights at 1x (generous: a typeface's
  /// line is taller than its size), plus the vertical padding.
  static const double _titleLine = 36 * 1.6;
  static const double _headingLine = 24 * 1.6;
  static const double _taglineLine = 15 * 1.6;
  static const double _padding = 16;

  @override
  double get maxExtent => max(96, textScaler.scale(_titleLine + _taglineLine) + _padding);

  @override
  double get minExtent => max(62, textScaler.scale(_headingLine) + _padding);

  @override
  bool shouldRebuild(_HomeHeader old) =>
      old.stars != stars ||
      old.palette != palette ||
      old.title != title ||
      old.tagline != tagline ||
      old.textScaler != textScaler;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    // Filling the extent is not optional: a child that measures shorter than
    // the extent leaves the sliver painting less than it lays out, which is
    // an assert rather than a gap.
    return SizedBox.expand(
      // Opaque, because the trail scrolls underneath it.
      child: Material(
        color: palette.backgroundSoft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                // Scales the lettering down rather than overflowing if a
                // font's metrics outgrow the extent's estimate.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: lerpDouble(36, 24, t),
                            fontWeight: FontWeight.w800,
                            color: palette.textInk,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      // heightFactor folds the line away rather than cutting
                      // it; once folded it leaves the tree altogether, so a
                      // screen reader is not still reading it out.
                      if (t < 1)
                        Align(
                          alignment: Alignment.topLeft,
                          heightFactor: 1 - t,
                          child: Opacity(
                            opacity: 1 - t,
                            child: Text(
                              tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: palette.textMuted, fontSize: 15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _StarsPill(stars: stars, total: totalLevels * 3),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: settingsTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarsPill extends StatelessWidget {
  const _StarsPill({required this.stars, required this.total});
  final int stars;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.homeStars(stars, total),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: p.star, size: 22),
            const SizedBox(width: 4),
            Text(
              '$stars',
              style: TextStyle(fontWeight: FontWeight.w800, color: p.textInk, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hero: a gradient card for the furthest level open by progress.
class _NextUpCard extends StatelessWidget {
  const _NextUpCard({
    required this.level,
    required this.allCleared,
    required this.resume,
    required this.onPlay,
  });
  final int level;
  final bool allCleared;

  /// A one-line summary of the saved game when [level] is one left mid-way.
  final String? resume;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final eyebrow = resume != null
        ? l10n.homeResumeEyebrow
        : allCleared
            ? l10n.homeAllCleared
            : l10n.homeNextUp;
    final action = resume != null
        ? l10n.homeContinue
        : allCleared
            ? l10n.homeReplay
            : l10n.homePlay;
    // One button to a screen reader, saying everything the card shows, in
    // the order it shows it; the pieces inside are not read a second time.
    final card = Semantics(
      label: [
        eyebrow,
        '${l10n.levelNumber(level)}, ${levelName(l10n, level)}',
        ?resume,
        action,
      ].join('. '),
      button: true,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPlay,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.primary, p.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full-strength white: at 70% the 12 px eyebrow sat
                        // at 3.2:1 on the gradient.
                        Text(
                          allCleared && resume == null ? eyebrow : eyebrow.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.levelNumber(level),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          levelName(l10n, level),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (resume != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              resume!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // The pill is white in both themes, so its ink is the
                    // deep primary in both: the dark theme's primary on
                    // white was 4.1:1.
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: p.primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          action,
                          style: TextStyle(
                            color: p.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (reduceMotionOf(context)) return card;
    return card.animate().fadeIn(duration: 250.ms).slideY(begin: -0.08);
  }
}

/// The journey: a section per chapter — its heading, blurb and progress —
/// and under it the chapter's levels on a soft ribbon of road that winds
/// down the page, mint behind the player and faint ahead, with the next
/// level marked by a bubble beside its node. The first cut was a thin
/// dotted line from node to node down a lot of empty page, and a caption
/// under every node: a list.
class _Trail extends StatelessWidget {
  const _Trail({
    required this.progress,
    required this.isUnlocked,
    required this.current,
  });

  final Map<int, LevelProgress> progress;
  final bool Function(int level) isUnlocked;
  final int current;

  /// Where across the width [level]'s node sits: a slow sine that starts
  /// over at every chapter, so each section opens at the centre and winds
  /// twice down to its twentieth level.
  static double fractionFor(int level) =>
      0.5 + 0.38 * sin(((level - 1) % kChapterLength) * 0.62);

  /// How far down the trail [level]'s node sits: its place in the line plus
  /// a band of [bandHeight] for every chapter heading above it.
  static double topOf(int level, double bandHeight) =>
      (level - 1) * kTrailSpacing + chapterOf(level).index * bandHeight;

  static const double nodeSize = 60;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The band holds two lines of text and a bar, so it grows with the
    // system font.
    final bandHeight = MediaQuery.textScalerOf(
      context,
    ).scale(kChapterBandHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final points = <Offset>[
          for (var level = 1; level <= totalLevels; level++)
            Offset(
              (width - nodeSize) * fractionFor(level) + nodeSize / 2,
              topOf(level, bandHeight) + nodeSize / 2 + 8,
            ),
        ];
        // One road per chapter: it starts under the chapter's heading and
        // ends at its last level, rather than running on behind the next
        // heading.
        final roads = <_Road>[
          for (final chapter in chapters)
            _Road(
              firstLevel: chapter.firstLevel,
              points: points.sublist(chapter.firstLevel - 1, chapter.lastLevel),
            ),
        ];
        final height = topOf(totalLevels, bandHeight) + nodeSize + 48;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    roads: roads,
                    clearedUpTo: _clearedPrefix(),
                    color: p.outlineSoft,
                    doneColor: p.accentMint,
                  ),
                ),
              ),
              for (final chapter in chapters)
                Positioned(
                  left: 0,
                  right: 0,
                  top: topOf(chapter.firstLevel, bandHeight) - bandHeight + 8,
                  height: bandHeight - 8,
                  child: _ChapterBand(
                    chapter: chapter,
                    reached: isUnlocked(chapter.firstLevel),
                    cleared: _clearedIn(chapter),
                  ),
                ),
              for (var level = 1; level <= totalLevels; level++)
                Positioned(
                  left: points[level - 1].dx - nodeSize / 2,
                  top: points[level - 1].dy - nodeSize / 2,
                  child: _LevelNode(
                    level: level,
                    size: nodeSize,
                    progress: progress[level] ?? LevelProgress.empty(level),
                    unlocked: isUnlocked(level),
                    isCurrent:
                        level == current &&
                        !(progress[level]?.completed ?? false),
                  ),
                ),
              if (current >= 1 &&
                  current <= totalLevels &&
                  !(progress[current]?.completed ?? false))
                _NextUpBubble(
                  level: current,
                  node: points[current - 1],
                  nodeSize: nodeSize,
                  // Beside the node, on the side with the room.
                  onRight: fractionFor(current) < 0.5,
                  width: width,
                ),
            ],
          ),
        );
      },
    );
  }

  /// How many levels from the start are cleared in a row (the road is
  /// painted "walked" that far).
  int _clearedPrefix() {
    var n = 0;
    while (n < totalLevels && (progress[n + 1]?.completed ?? false)) {
      n++;
    }
    return n;
  }

  int _clearedIn(Chapter chapter) {
    var n = 0;
    for (var level = chapter.firstLevel; level <= chapter.lastLevel; level++) {
      if (progress[level]?.completed ?? false) n++;
    }
    return n;
  }
}

/// A chapter's stretch of the road: its nodes' centres, in order.
class _Road {
  const _Road({required this.firstLevel, required this.points});

  final int firstLevel;
  final List<Offset> points;
}

/// The road under the nodes: one smooth ribbon per chapter through its
/// nodes (a Catmull-Rom spline, so the line arrives at a node on the
/// tangent it leaves on), wide and soft, in the mint as far as the player
/// has walked and faint ahead. The nodes sit on top of it, so the joins
/// are under them.
class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.roads,
    required this.clearedUpTo,
    required this.color,
    required this.doneColor,
  });

  final List<_Road> roads;
  final int clearedUpTo;
  final Color color;
  final Color doneColor;

  static const double kRoadWidth = 18;

  /// The cubic from node [i] to node [i + 1] of [points], its tangents
  /// taken from the neighbours either side, appended to [path].
  static void _stretch(Path path, List<Offset> points, int i) {
    final a = points[i];
    final b = points[i + 1];
    final before = i == 0 ? a : points[i - 1];
    final after = i + 2 >= points.length ? b : points[i + 2];
    final ta = (b - before) / 2;
    final tb = (after - a) / 2;
    path.cubicTo(
      a.dx + ta.dx / 3,
      a.dy + ta.dy / 3,
      b.dx - tb.dx / 3,
      b.dy - tb.dy / 3,
      b.dx,
      b.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ahead = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = kRoadWidth
      ..strokeCap = StrokeCap.round;
    final walked = Paint.from(ahead)..color = doneColor.withValues(alpha: 0.45);
    for (final road in roads) {
      // One path per shade, each stroked once, so nothing stacks where
      // the stretches meet.
      final done = Path();
      final todo = Path();
      final started = <Path>{};
      for (var i = 0; i + 1 < road.points.length; i++) {
        final level = road.firstLevel + i;
        final path = level <= clearedUpTo ? done : todo;
        if (started.add(path)) {
          path.moveTo(road.points[i].dx, road.points[i].dy);
        }
        _stretch(path, road.points, i);
      }
      canvas.drawPath(todo, ahead);
      canvas.drawPath(done, walked);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.clearedUpTo != clearedUpTo ||
      old.color != color ||
      old.doneColor != doneColor ||
      old.roads.length != roads.length ||
      (old.roads.isNotEmpty &&
          old.roads.first.points.first != roads.first.points.first) ||
      (old.roads.isNotEmpty &&
          old.roads.last.points.last != roads.last.points.last);
}

/// The marker on the next level: a small card beside its node with the
/// level's name, and a pointer to the node. It is the one caption on the
/// trail, so the eye finds where to go next without reading every node.
class _NextUpBubble extends StatelessWidget {
  const _NextUpBubble({
    required this.level,
    required this.node,
    required this.nodeSize,
    required this.onRight,
    required this.width,
  });

  final int level;
  final Offset node;
  final double nodeSize;
  final bool onRight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    const gap = 14.0;
    const pointer = 8.0;
    final room = onRight
        ? width - (node.dx + nodeSize / 2) - gap - 12
        : node.dx - nodeSize / 2 - gap - 12;
    final card = Container(
      constraints: BoxConstraints(maxWidth: max(96, room)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.levelUpNext.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Text(
            levelName(l10n, level),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    final tip = CustomPaint(
      size: const Size(pointer, pointer * 2),
      painter: _PointerPainter(color: p.primary, toRight: !onRight),
    );
    final bubble = Row(
      mainAxisSize: MainAxisSize.min,
      children: onRight ? [tip, card] : [card, tip],
    );
    // The node is the button; the bubble is a picture of its state.
    final body = ExcludeSemantics(
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)),
        ),
        child: bubble,
      ),
    );
    final child = reduceMotionOf(context)
        ? body
        : body
              .animate(delay: 500.ms)
              .fadeIn(duration: 250.ms)
              .slideX(
                begin: onRight ? -0.15 : 0.15,
                curve: Curves.easeOutCubic,
              );
    return Positioned(
      top: node.dy - 24,
      left: onRight ? node.dx + nodeSize / 2 + gap - pointer : null,
      right: onRight ? null : width - (node.dx - nodeSize / 2 - gap + pointer),
      child: child,
    );
  }
}

/// The bubble's pointer: a small triangle on the side facing the node.
class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.color, required this.toRight});

  final Color color;
  final bool toRight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = toRight
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, size.height / 2)
            ..lineTo(0, size.height)
            ..close())
        : (Path()
            ..moveTo(size.width, 0)
            ..lineTo(0, size.height / 2)
            ..lineTo(size.width, size.height)
            ..close());
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.color != color || old.toRight != toRight;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.size,
    required this.progress,
    required this.unlocked,
    required this.isCurrent,
  });

  final int level;
  final double size;
  final LevelProgress progress;
  final bool unlocked;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final cleared = progress.completed;
    final Color fill;
    final Color fg;
    if (cleared) {
      // Dark ink on the mint: white on it read at 1.9:1.
      fill = p.accentMint;
      fg = p.onAccent;
    } else if (isCurrent) {
      fill = p.primary;
      fg = Colors.white;
    } else if (unlocked) {
      fill = p.surface;
      fg = p.textInk;
    } else {
      // A locked level is still a number to read, so muted rather than faint
      // (2.5:1 on the light surface).
      fill = p.surface;
      fg = p.textMuted;
    }

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent
              ? p.primaryLight
              : (cleared ? p.accentMint : p.outlineSoft),
          width: isCurrent ? 4 : 2,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: p.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            )
          else if (cleared)
            BoxShadow(
              color: p.accentMint.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
    // A locked level still shows its number — the player can see what is
    // ahead and how far the trail goes — with a small lock tucked on it.
    final node = unlocked
        ? circle
        : Stack(
            clipBehavior: Clip.none,
            children: [
              circle,
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.outlineSoft, width: 1.5),
                  ),
                  child: Icon(Icons.lock_rounded, color: p.textMuted, size: 13),
                ),
              ),
            ],
          );

    // Everything the node shows, in one label: the number, the name and its
    // state — locked, up next, or cleared with its stars and best time.
    final best = progress.bestTimeMs;
    final label = [
      '${l10n.levelNumber(level)}, ${levelName(l10n, level)}',
      if (!unlocked) l10n.levelLocked,
      if (isCurrent) l10n.levelUpNext,
      if (cleared) l10n.levelCleared,
      if (cleared) l10n.starsOfThree(progress.stars),
      if (cleared && best != null) l10n.levelBestTime(formatDurationMs(best)),
    ].join(', ');
    final tile = Semantics(
      label: label,
      button: unlocked,
      enabled: unlocked,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: unlocked
              ? () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(level: level),
                  ),
                )
              : null,
          // No fixed height: the stars under a cleared node grow with the
          // system font size, and the node is positioned by its top.
          child: SizedBox(
            width: size + 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                node,
                // The stars are the one thing under a node: the next
                // level's name is in its bubble, and the rest are numbers.
                if (cleared) ...[
                  const SizedBox(height: 2),
                  // On a small pill, since the row sits over the road.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: i < progress.stars ? p.star : p.starEmpty,
                          ),
                        if (best != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            formatDurationMs(best),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: p.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (reduceMotionOf(context)) return tile;
    return tile
        .animate(delay: (min(level, 12) * 30).ms)
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.85, 0.85));
  }
}

/// A chapter's section heading on the trail: its icon, number and name,
/// the levels it spans and a line on the twist it brings, and a bar of
/// how much of it is cleared. Muted until the chapter is reached.
class _ChapterBand extends StatelessWidget {
  const _ChapterBand({
    required this.chapter,
    required this.reached,
    required this.cleared,
  });

  final Chapter chapter;
  final bool reached;
  final int cleared;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final name = chapterName(l10n, chapter.index);
    final heading = l10n.chapterHeading(chapter.index, name);
    final levels = l10n.chapterLevels(chapter.firstLevel, chapter.lastLevel);
    final blurb = chapterBlurb(l10n, chapter.index);
    final icon = switch (chapter.rule) {
      ChapterRule.lines => Icons.east_rounded,
      ChapterRule.mirrors => Icons.flip_rounded,
      ChapterRule.locks => Icons.vpn_key_rounded,
      ChapterRule.fog => Icons.blur_on_rounded,
      ChapterRule.pairs => Icons.link_rounded,
    };
    final ink = reached ? p.textInk : p.textMuted;
    final share = cleared / kChapterLength;
    return Semantics(
      header: true,
      label: '$heading. $levels. $blurb',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: reached ? p.primary : p.cardTint,
                shape: BoxShape.circle,
                border: reached
                    ? null
                    : Border.all(color: p.outlineSoft, width: 1.5),
              ),
              child: Icon(
                icon,
                color: reached ? Colors.white : p.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$cleared/$kChapterLength',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cleared == kChapterLength
                              ? p.successInk
                              : p.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$levels · $blurb',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 5,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: p.outlineSoft),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: share,
                            child: ColoredBox(color: p.accentMint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The daily board's card: today's deal in the chapter the player has
/// reached, the streak, today's best, and the way in. One button to a
/// screen reader.
class _DailyCard extends StatefulWidget {
  const _DailyCard({
    required this.standing,
    required this.arrows,
    required this.untilNext,
    required this.resuming,
    required this.onPlay,
  });

  final DailyStanding standing;
  final int arrows;

  /// Time to the next board when the card was built; the card counts it
  /// down a minute at a time.
  final Duration untilNext;

  /// Today's board was left mid-way: the button says Continue.
  final bool resuming;
  final VoidCallback onPlay;

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard> {
  Timer? _ticker;
  late DateTime _builtAt;

  @override
  void initState() {
    super.initState();
    _builtAt = DateTime.now();
    // Once a minute is as fine as the countdown reads.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void didUpdateWidget(_DailyCard old) {
    super.didUpdateWidget(old);
    if (old.untilNext != widget.untilNext) _builtAt = DateTime.now();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// The countdown as "5h 12m" (or "12m" under an hour).
  String _countdown(AppLocalizations l10n) {
    final left = widget.untilNext - DateTime.now().difference(_builtAt);
    // Rounded up: "1m" until the minute is really over.
    final minutes = max(0, (left.inSeconds + 59) ~/ 60);
    return minutes >= 60 ? l10n.dailyNextInHours(minutes ~/ 60, minutes % 60) : l10n.dailyNextInMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final standing = widget.standing;
    final resuming = widget.resuming;
    final onPlay = widget.onPlay;
    final chapter = chapterName(l10n, standing.chapter.index);
    final body = l10n.dailyBody(kDailyMinutes, widget.arrows, chapter);
    final streak = l10n.dailyStreak(standing.liveStreak);
    final best = standing.bestTodayMs;
    final next = _countdown(l10n);
    final status = best == null
        ? '$streak · $next'
        : '${l10n.dailyClearedToday} · ${l10n.dailyBestToday(formatDurationMs(best))} · $streak · $next';
    final action = resuming
        ? l10n.homeContinue
        : standing.clearedToday
            ? l10n.dailyReplay
            : l10n.dailyPlay;
    return Semantics(
      label: [l10n.dailyEyebrow, l10n.dailyTitle, body, status, action].join('. '),
      button: true,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPlay,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.outlineSoft, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: p.cardTint, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.today_rounded, color: p.primaryInk, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dailyEyebrow.toUpperCase(),
                        style: TextStyle(
                          color: p.primaryInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: TextStyle(color: p.textInk, fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: standing.clearedToday ? p.successInk : p.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Under the text rather than beside it, so a large
                      // system font wraps the card taller instead of wider.
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                action,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
