import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/arrow_piece.dart';
import '../engine/cell.dart';
import '../engine/direction.dart';
import '../engine/puzzle.dart';
import '../l10n/app_localizations.dart';
import '../models/game_state.dart';
import '../models/level_spec.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../ui/colors.dart';
import '../ui/layout.dart';
import '../widgets/puzzle_board.dart';

/// A tiny board with one free arrow: "tap it".
Puzzle tutorialPuzzleOne() => Puzzle(
      width: 4,
      height: 3,
      arrows: [
        ArrowPiece(
          id: 0,
          cells: const [Cell(0, 1), Cell(1, 1), Cell(2, 1)],
          heading: Direction.right,
        ),
      ],
    );

/// A tiny board where the upward arrow is blocked by the top one.
Puzzle tutorialPuzzleTwo() => Puzzle(
      width: 4,
      height: 3,
      arrows: [
        ArrowPiece(
          id: 0,
          cells: const [Cell(0, 0), Cell(1, 0), Cell(2, 0)],
          heading: Direction.right,
        ),
        ArrowPiece(
          id: 1,
          cells: const [Cell(2, 2), Cell(2, 1)],
          heading: Direction.up,
        ),
      ],
    );

const LevelSpec _tutorialSpec = LevelSpec(
  level: 1,
  width: 4,
  height: 3,
  arrows: 2,
  minLength: 2,
  maxLength: 3,
  timeLimitMs: 60000,
);

/// The one-time walkthrough: three steps, the first two played for real on
/// tiny boards (tap an arrow out; feel a blocked one bump), the third a
/// glance at lives, clock, hints and zoom. Minimal, and hard to get wrong.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});

  /// True when opened again from Settings: finishing pops back instead of
  /// relying on the app switching to the home screen.
  final bool replay;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  late final GameNotifier _one =
      GameNotifier(_tutorialSpec, puzzle: tutorialPuzzleOne(), autoTick: false);
  late final GameNotifier _two =
      GameNotifier(_tutorialSpec, puzzle: tutorialPuzzleTwo(), autoTick: false);
  late final List<void Function()> _unsubscribe;
  late GameState _oneState;
  late GameState _twoState;
  bool _bumped = false;

  @override
  void initState() {
    super.initState();
    // StateNotifier.state is protected; mirror it through the listeners
    // (fired immediately, so the first build has a board).
    _unsubscribe = [
      _one.addListener((s) => setState(() => _oneState = s)),
      _two.addListener(_onTwo),
    ];
  }

  void _onTwo(GameState s) {
    if (s.lastOutcome == MoveOutcome.blocked) _bumped = true;
    // The demo has no stakes: never let it end on lives.
    if (s.phase == GamePhase.outOfLives) {
      _two.restart();
      return; // the restart fires this listener again with the fresh state
    }
    setState(() => _twoState = s);
  }

  @override
  void dispose() {
    for (final u in _unsubscribe) {
      u();
    }
    _one.dispose();
    _two.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).completeOnboarding();
    if (widget.replay) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oneDone = _oneState.phase == GamePhase.cleared;
    final twoDone = _twoState.phase == GamePhase.cleared;
    final canNext = switch (_step) { 0 => oneDone, 1 => twoDone, _ => true };

    return Scaffold(
      body: SafeArea(
        // A phone-width column, centred, so the walkthrough reads the same in
        // a desktop browser.
        child: ContentColumn(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _StepDots(step: _step),
                    const Spacer(),
                    TextButton(onPressed: _finish, child: Text(l10n.onboardSkip)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      0 => _DemoStep(
                          key: const ValueKey(0),
                          title: l10n.onboardTitle1,
                          body: oneDone ? l10n.onboardDone1 : l10n.onboardBody1,
                          done: oneDone,
                          state: _oneState,
                          onTapArrow: _one.tapArrow,
                        ),
                      1 => _DemoStep(
                          key: const ValueKey(1),
                          title: l10n.onboardTitle2,
                          body: twoDone
                              ? l10n.onboardDone2
                              : _bumped
                                  ? l10n.onboardBumped2
                                  : l10n.onboardBody2,
                          done: twoDone,
                          state: _twoState,
                          onTapArrow: _two.tapArrow,
                        ),
                      _ => _SummaryStep(key: const ValueKey(2)),
                    },
                  ),
                ),
                FilledButton(
                  onPressed: canNext
                      ? () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            _finish();
                          }
                        }
                      : null,
                  child: Text(_step < 2 ? l10n.onboardNext : l10n.onboardStart),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: List<Widget>.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: i == step ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= step ? p.primary : p.outlineSoft,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _DemoStep extends StatelessWidget {
  const _DemoStep({
    super.key,
    required this.title,
    required this.body,
    required this.done,
    required this.state,
    required this.onTapArrow,
  });

  final String title;
  final String body;
  final bool done;
  final GameState state;
  final ValueChanged<int> onTapArrow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.textInk),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            body,
            key: ValueKey(body),
            style: TextStyle(fontSize: 16, color: p.textMuted, height: 1.4),
          ),
        ),
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              width: 240,
              height: 180,
              child: PuzzleBoard(state: state, showGrid: true, onTapArrow: onTapArrow),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: done
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.accentMint.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: p.accentMint, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.onboardNext,
                          style: TextStyle(color: p.accentMint, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack, duration: 300.ms),
                )
              : null,
        ),
        const Spacer(),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final rules = <(String, String)>[
      ('❤️', l10n.onboardRuleLives),
      ('⏱️', l10n.onboardRuleClock),
      ('💡', l10n.onboardRuleHints),
      ('🔍', l10n.onboardRuleZoom),
      ('🧩', l10n.onboardRuleRiddle),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          l10n.onboardTitle3,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: p.textInk),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < rules.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(rules[i].$1, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    rules[i].$2,
                    style: TextStyle(fontSize: 15, color: p.textInk, height: 1.3),
                  ),
                ),
              ],
            ),
          ).animate(delay: (80 * i).ms).fadeIn(duration: 250.ms).slideY(begin: 0.15),
      ],
    );
  }
}
