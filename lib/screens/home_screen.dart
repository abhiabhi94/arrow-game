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
import '../ui/colors.dart';
import '../ui/layout.dart';
import '../ui/motion.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Vertical distance between trail nodes.
const double kTrailSpacing = 104;

/// The room a chapter heading takes on the trail, above its first level.
const double kChapterBandHeight = 108;

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

/// A winding path of level nodes. Node `i` sits at a horizontal offset that
/// follows a gentle sine wave, so the trail meanders down the screen.
class _Trail extends StatelessWidget {
  const _Trail({
    required this.progress,
    required this.isUnlocked,
    required this.current,
  });

  final Map<int, LevelProgress> progress;
  final bool Function(int level) isUnlocked;
  final int current;

  static double fractionFor(int level) => 0.5 + 0.36 * sin((level - 1) * 1.05);

  /// How far down the trail [level]'s node sits: its place in the line plus
  /// a band of [bandHeight] for every chapter heading above it.
  static double topOf(int level, double bandHeight) =>
      (level - 1) * kTrailSpacing + chapterOf(level).index * bandHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // The band holds two lines of text, so it grows with the system font.
    final bandHeight = MediaQuery.textScalerOf(context).scale(kChapterBandHeight);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const nodeSize = 62.0;
        final points = <Offset>[
          for (var level = 1; level <= totalLevels; level++)
            Offset(
              (width - nodeSize) * fractionFor(level) + nodeSize / 2,
              topOf(level, bandHeight) + nodeSize / 2 + 8,
            ),
        ];
        final height = topOf(totalLevels, bandHeight) + nodeSize + 48;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    points: points,
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
                    isCurrent: level == current && !(progress[level]?.completed ?? false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// How many levels from the start are cleared in a row (the trail is
  /// painted "done" that far).
  int _clearedPrefix() {
    var n = 0;
    while (n < totalLevels && (progress[n + 1]?.completed ?? false)) {
      n++;
    }
    return n;
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.points,
    required this.clearedUpTo,
    required this.color,
    required this.doneColor,
  });

  final List<Offset> points;
  final int clearedUpTo;
  final Color color;
  final Color doneColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      final midY = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
      final paint = Paint()
        ..color = i < clearedUpTo ? doneColor : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      _drawDashed(canvas, path, paint);
    }
  }

  static void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 10.0;
    const gap = 9.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.clearedUpTo != clearedUpTo ||
      old.color != color ||
      old.doneColor != doneColor ||
      old.points.length != points.length ||
      (old.points.isNotEmpty && old.points.first != points.first);
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
          color: isCurrent ? p.primaryLight : (cleared ? p.accentMint : p.outlineSoft),
          width: isCurrent ? 4 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: p.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg),
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
          // No fixed height: the caption under the node grows with the system
          // font size, and the node is positioned by its top on the trail.
          child: SizedBox(
            width: size + 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                node,
                const SizedBox(height: 4),
                if (cleared)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: i < progress.stars ? p.star : p.starEmpty,
                        ),
                      if (best != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          formatDurationMs(best),
                          style: TextStyle(fontSize: 10, color: p.textMuted),
                        ),
                      ],
                    ],
                  )
                else if (unlocked)
                  Text(
                    levelName(l10n, level),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? p.primaryInk : p.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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


/// A chapter heading on the trail: its number and name, the levels it
/// spans and a line on the twist it brings, over its first level. Muted
/// until the chapter is reached.
class _ChapterBand extends StatelessWidget {
  const _ChapterBand({required this.chapter, required this.reached});

  final Chapter chapter;
  final bool reached;

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
      ChapterRule.shapes => Icons.crop_square_rounded,
      ChapterRule.locks => Icons.vpn_key_rounded,
      ChapterRule.fog => Icons.blur_on_rounded,
      ChapterRule.pairs => Icons.link_rounded,
    };
    final ink = reached ? p.textInk : p.textMuted;
    return Semantics(
      header: true,
      label: '$heading. $levels. $blurb',
      excludeSemantics: true,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: reached ? p.primaryLight : p.outlineSoft, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: reached ? p.primary : p.cardTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: reached ? Colors.white : p.textMuted, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
                    ),
                    Text(
                      '$levels · $blurb',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textMuted, height: 1.3),
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

/// The daily board's card: today's deal in the chapter the player has
/// reached, the streak, today's best, and the way in. One button to a
/// screen reader.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.standing,
    required this.arrows,
    required this.resuming,
    required this.onPlay,
  });

  final DailyStanding standing;
  final int arrows;

  /// Today's board was left mid-way: the button says Continue.
  final bool resuming;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final chapter = chapterName(l10n, standing.chapter.index);
    final body = l10n.dailyBody(kDailyMinutes, arrows, chapter);
    final streak = l10n.dailyStreak(standing.liveStreak);
    final best = standing.bestTodayMs;
    final status = best == null
        ? streak
        : '${l10n.dailyClearedToday} · ${l10n.dailyBestToday(formatDurationMs(best))} · $streak';
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
