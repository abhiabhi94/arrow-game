import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/settings.dart';
import '../providers/progress_provider.dart';
import '../providers/riddle_provider.dart';
import '../providers/saved_game_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import 'credits_screen.dart';
import 'onboarding_screen.dart';

/// Settings: music (on/off + volume), sound effects, haptic feedback,
/// language, theme, the walkthrough again, music credits, and a progress
/// reset.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsResetConfirmTitle),
        content: Text(l10n.settingsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonReset),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(progressProvider.notifier).resetAll();
      ref.read(savedGameProvider.notifier).clear();
      ref.read(riddleDeckProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      // Full-width list, phone-width content: on a desktop browser the cards
      // would otherwise stretch across the whole window.
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.all(20) + contentGutter(constraints.maxWidth),
          children: [
            _SettingCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.musicOn,
                    onChanged: notifier.setMusic,
                    secondary: const Text('🎵', style: TextStyle(fontSize: 24)),
                    title: Text(l10n.settingsMusic),
                    subtitle: Text(l10n.settingsMusicSubtitle),
                  ),
                  if (settings.musicOn)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: p.textMuted),
                          Expanded(
                            child: Slider(
                              value: settings.musicVolume,
                              onChanged: notifier.setMusicVolume,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${(settings.musicVolume * 100).round()}%',
                              textAlign: TextAlign.end,
                              style: TextStyle(color: p.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: SwitchListTile(
                value: settings.sfxOn,
                onChanged: notifier.setSfx,
                secondary: const Text('💨', style: TextStyle(fontSize: 24)),
                title: Text(l10n.settingsSfx),
                subtitle: Text(l10n.settingsSfxSubtitle),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: SwitchListTile(
                value: settings.hapticsOn,
                onChanged: notifier.setHaptics,
                secondary: const Text('📳', style: TextStyle(fontSize: 24)),
                title: Text(l10n.settingsHaptics),
                subtitle: Text(l10n.settingsHapticsSubtitle),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: _ChoiceCard(
                emoji: '🌐',
                title: l10n.settingsLanguage,
                child: SegmentedButton<LanguageChoice>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<LanguageChoice>>[
                    ButtonSegment(
                      value: LanguageChoice.system,
                      label: Text(l10n.languageSystem),
                    ),
                    ButtonSegment(
                      value: LanguageChoice.english,
                      label: Text(l10n.languageEnglish),
                    ),
                    ButtonSegment(
                      value: LanguageChoice.hindi,
                      label: Text(l10n.languageHindi),
                    ),
                  ],
                  selected: {settings.languageChoice},
                  onSelectionChanged: (sel) => notifier.setLanguageChoice(sel.first),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: _ChoiceCard(
                emoji: '🌗',
                title: l10n.settingsTheme,
                child: SegmentedButton<ThemeChoice>(
                  showSelectedIcon: false,
                  segments: <ButtonSegment<ThemeChoice>>[
                    ButtonSegment(value: ThemeChoice.system, label: Text(l10n.themeSystem)),
                    ButtonSegment(value: ThemeChoice.light, label: Text(l10n.themeLight)),
                    ButtonSegment(value: ThemeChoice.dark, label: Text(l10n.themeDark)),
                  ],
                  selected: {settings.themeChoice},
                  onSelectionChanged: (sel) => notifier.setThemeChoice(sel.first),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: ListTile(
                leading: const Text('🎯', style: TextStyle(fontSize: 24)),
                title: Text(l10n.settingsHowToPlay),
                subtitle: Text(l10n.howToPlayBody),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingScreen(replay: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: ListTile(
                leading: const Text('🎼', style: TextStyle(fontSize: 24)),
                title: Text(l10n.settingsCredits),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const CreditsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: ListTile(
                leading: const Text('🧹', style: TextStyle(fontSize: 24)),
                title: Text(l10n.settingsResetProgress),
                subtitle: Text(l10n.settingsResetProgressSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _confirmReset(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A setting that is a choice rather than a switch: an emoji, a heading and
/// the row of options under it (language, theme).
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.emoji, required this.title, required this.child});

  final String emoji;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.child});
  final Widget child;

  // A Material (not a decorated Container) so ListTile/SwitchListTile can
  // paint their background and ink on a Material ancestor.
  @override
  Widget build(BuildContext context) => Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
