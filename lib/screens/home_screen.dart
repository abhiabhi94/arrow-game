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

/// The home screen: a stars tally, a jump-in "Play" card for the furthest open
/// level, and the 20-level grid with lock/star state.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final nextLevel = notifier.highestUnlocked;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: p.textInk,
                                ),
                          ),
                          Text(
                            l10n.appTagline,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: _StarsPill(
                  stars: notifier.totalStars,
                  total: totalLevels * 3,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                child: _PlayCard(
                  level: nextLevel,
                  onPlay: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(level: nextLevel),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeLevels,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: p.textInk,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeLevelsHint,
                      style: TextStyle(color: p.textFaint, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final level = i + 1;
                    return _LevelTile(
                      level: level,
                      progress: progress[level] ?? LevelProgress.empty(level),
                      unlocked: notifier.isUnlocked(level),
                    );
                  },
                  childCount: totalLevels,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: p.star, size: 30),
          const SizedBox(width: 10),
          Text(
            l10n.homeStars(stars, total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: p.textInk,
                ),
          ),
        ],
      ),
    );
  }
}

/// The jump-in card for the furthest level open by progress.
class _PlayCard extends StatelessWidget {
  const _PlayCard({required this.level, required this.onPlay});
  final int level;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: '${l10n.levelNumber(level)} ${levelName(l10n, level)}',
      button: true,
      child: Material(
        color: p.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.levelNumber(level),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        levelName(l10n, level),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1);
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.progress,
    required this.unlocked,
  });

  final int level;
  final LevelProgress progress;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context)!;
    final cleared = progress.completed;
    return Semantics(
      label: unlocked ? l10n.levelNumber(level) : '${l10n.levelNumber(level)} ${l10n.levelLocked}',
      button: unlocked,
      child: Material(
        color: unlocked ? p.surface : p.backgroundSoft,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(level: level),
                    ),
                  )
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cleared ? p.accentMint : p.outlineSoft,
                width: cleared ? 2 : 1,
              ),
            ),
            child: Center(
              child: unlocked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$level',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cleared ? p.accentMint : p.textInk,
                          ),
                        ),
                        if (cleared)
                          _TinyStars(stars: progress.stars)
                        else
                          const SizedBox(height: 14),
                        if (cleared && progress.bestTimeMs != null)
                          Text(
                            formatDurationMs(progress.bestTimeMs!),
                            style: TextStyle(fontSize: 10, color: p.textMuted),
                          ),
                      ],
                    )
                  : Icon(Icons.lock_rounded, color: p.textFaint, size: 20),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _TinyStars extends StatelessWidget {
  const _TinyStars({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        3,
        (i) => Icon(
          Icons.star_rounded,
          size: 12,
          color: i < stars ? p.star : p.starEmpty,
        ),
      ),
    );
  }
}
