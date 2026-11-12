import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/settings.dart';
import '../providers/daily_provider.dart';
import '../providers/intro_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/riddle_provider.dart';
import '../providers/saved_game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/trail_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import 'credits_screen.dart';
import 'onboarding_screen.dart';

/// Settings, in five cards: the level clock (one choice: standard, extra
/// time or none), sound and touch (music and its volume, sound effects,
/// haptics), language and theme, accessibility (reduce motion), and the
/// rest (the walkthrough again, music credits, a progress reset).
///
/// The emoji on each row are decoration and kept from the screen reader; the
/// volume slider carries its own name and reads its value as a percentage.
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
      ref.read(dailyProvider.notifier).reset();
      ref.read(riddleDeckProvider.notifier).reset();
      ref.read(introProvider.notifier).reset();
      ref.read(trailFoldProvider.notifier).reset();
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
      // An explicit padding turns off ListView's own system-inset padding, so
      // the insets are added back: the app draws edge to edge, and the last
      // card would otherwise scroll to a stop under the navigation bar.
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.all(20) +
              contentGutter(constraints.maxWidth) +
              MediaQuery.paddingOf(context),
          children: [
            // How the game plays: the clock is one choice, not two switches
            // that only made sense together.
            _SettingCard(
              child: Column(
                children: [
                  _CardHeading(emoji: '⏱️', title: l10n.settingsClock),
                  // Three options, each saying what it does: a row of
                  // segments overflowed with the system font at 2×.
                  RadioGroup<ClockChoice>(
                    groupValue: settings.clock,
                    onChanged: (choice) => notifier.setClock(choice!),
                    child: Column(
                      children: [
                        RadioListTile<ClockChoice>(
                          value: ClockChoice.standard,
                          title: Text(l10n.clockStandard),
                          subtitle: Text(l10n.clockStandardBody),
                        ),
                        RadioListTile<ClockChoice>(
                          value: ClockChoice.extra,
                          title: Text(l10n.clockExtra),
                          subtitle: Text(l10n.settingsExtraTimeSubtitle),
                        ),
                        RadioListTile<ClockChoice>(
                          value: ClockChoice.off,
                          title: Text(l10n.clockOff),
                          subtitle: Text(l10n.settingsRemoveTimeLimitsSubtitle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // What the game sounds and feels like, in one card.
            _SettingCard(
              child: Column(
                children: [
                  _CardHeading(emoji: '🔊', title: l10n.settingsSoundAndTouch),
                  SwitchListTile(
                    value: settings.musicOn,
                    onChanged: notifier.setMusic,
                    secondary: const _Emoji('🎵'),
                    title: Text(l10n.settingsMusic),
                    subtitle: Text(l10n.settingsMusicSubtitle),
                  ),
                  if (settings.musicOn)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(Icons.volume_up_rounded, color: p.textMuted),
                          ),
                          // One node — "Music volume, 60%" with the slider's
                          // own increase and decrease.
                          Expanded(
                            child: MergeSemantics(
                              child: Semantics(
                                label: l10n.settingsMusicVolume,
                                child: Slider(
                                  value: settings.musicVolume,
                                  onChanged: notifier.setMusicVolume,
                                  semanticFormatterCallback: (value) => '${(value * 100).round()}%',
                                ),
                              ),
                            ),
                          ),
                          // The slider already speaks its value.
                          ExcludeSemantics(
                            child: SizedBox(
                              width: MediaQuery.textScalerOf(context).scale(40),
                              child: Text(
                                '${(settings.musicVolume * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: TextStyle(color: p.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SwitchListTile(
                    value: settings.sfxOn,
                    onChanged: notifier.setSfx,
                    secondary: const _Emoji('💨'),
                    title: Text(l10n.settingsSfx),
                    subtitle: Text(l10n.settingsSfxSubtitle),
                  ),
                  SwitchListTile(
                    value: settings.hapticsOn,
                    onChanged: notifier.setHaptics,
                    secondary: const _Emoji('📳'),
                    title: Text(l10n.settingsHaptics),
                    subtitle: Text(l10n.settingsHapticsSubtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // How it reads: the language and the theme together.
            _SettingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChoiceCard(
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
                  _ChoiceCard(
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingCard(
              child: Column(
                children: [
                  _CardHeading(emoji: '♿', title: l10n.settingsAccessibility),
                  SwitchListTile(
                    value: settings.reduceMotion,
                    onChanged: notifier.setReduceMotion,
                    title: Text(l10n.settingsReduceMotion),
                    subtitle: Text(l10n.settingsReduceMotionSubtitle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Help, credits and the reset: what is not a setting.
            _SettingCard(
              child: Column(
                children: [
                  _CardHeading(emoji: '📋', title: l10n.settingsMore),
                  ListTile(
                    leading: const _Emoji('🎯'),
                    title: Text(l10n.settingsHowToPlay),
                    subtitle: Text(l10n.howToPlayBody),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OnboardingScreen(replay: true),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const _Emoji('🎼'),
                    title: Text(l10n.settingsCredits),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreditsScreen()),
                    ),
                  ),
                  ListTile(
                    leading: const _Emoji('🧹'),
                    title: Text(l10n.settingsResetProgress),
                    subtitle: Text(l10n.settingsResetProgressSubtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _confirmReset(context, ref),
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
                _Emoji(emoji),
                const SizedBox(width: 12),
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

/// A row's emoji: decoration, so a screen reader skips it rather than
/// announcing "musical note" before every setting.
class _Emoji extends StatelessWidget {
  const _Emoji(this.emoji);
  final String emoji;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: Text(emoji, style: const TextStyle(fontSize: 24)));
}

/// The emoji and spoken heading at the top of a card that groups switches.
class _CardHeading extends StatelessWidget {
  const _CardHeading({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            _Emoji(emoji),
            const SizedBox(width: 12),
            // Wraps rather than overflows with a large system font.
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
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
