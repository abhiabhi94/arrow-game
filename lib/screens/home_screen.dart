import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level_specs.dart';
import '../l10n/app_localizations.dart';
import '../models/level_progress.dart';
import '../providers/progress_provider.dart';
import '../ui/colors.dart';
import '../utils/format.dart';
import '../utils/labels.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Vertical distance between trail nodes.
const double kTrailSpacing = 104;

/// The home screen: a stars tally, a "next up" hero card, and the journey — a
/// winding trail of 20 level nodes with lock / stars / current state.
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

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: p.textInk,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n.appTagline,
                            style: TextStyle(color: p.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    _StarsPill(stars: notifier.totalStars, total: totalLevels * 3),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: l10n.homeSettings,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: _NextUpCard(
                  level: nextLevel,
                  allCleared: allCleared,
                  onPlay: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(level: nextLevel),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              sliver: SliverToBoxAdapter(
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
    required this.onPlay,
  });
  final int level;
  final bool allCleared;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: '${l10n.levelNumber(level)} ${levelName(l10n, level)}',
      button: true,
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
                        Text(
                          allCleared ? l10n.homeAllCleared : l10n.homeNextUp.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
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
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: p.primary),
                        const SizedBox(width: 4),
                        Text(
                          allCleared ? l10n.homeReplay : l10n.homePlay,
                          style: TextStyle(
                            color: p.primary,
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
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.08);
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const nodeSize = 62.0;
        final points = <Offset>[
          for (var level = 1; level <= totalLevels; level++)
            Offset(
              (width - nodeSize) * fractionFor(level) + nodeSize / 2,
              (level - 1) * kTrailSpacing + nodeSize / 2 + 8,
            ),
        ];
        final height = (totalLevels - 1) * kTrailSpacing + nodeSize + 48;
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
      fill = p.accentMint;
      fg = Colors.white;
    } else if (isCurrent) {
      fill = p.primary;
      fg = Colors.white;
    } else if (unlocked) {
      fill = p.surface;
      fg = p.textInk;
    } else {
      fill = p.surface;
      fg = p.textFaint;
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
        child: unlocked
            ? Text(
                '$level',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: fg),
              )
            : Icon(Icons.lock_rounded, color: fg, size: 22),
      ),
    );

    return Semantics(
      label: unlocked ? l10n.levelNumber(level) : '${l10n.levelNumber(level)} ${l10n.levelLocked}',
      button: unlocked,
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
          child: SizedBox(
            width: size + 40,
            height: size + 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                circle,
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
                      if (progress.bestTimeMs != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          formatDurationMs(progress.bestTimeMs!),
                          style: TextStyle(fontSize: 10, color: p.textMuted),
                        ),
                      ],
                    ],
                  )
                else if (unlocked)
                  Text(
                    levelName(l10n, level),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCurrent ? p.primary : p.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (min(level, 12) * 30).ms).fadeIn(duration: 200.ms).scale(begin: const Offset(0.85, 0.85));
  }
}
