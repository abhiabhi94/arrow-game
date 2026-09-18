/// The riddle gate: the card that stands between a spent allowance and one
/// more life.
///
/// The point is that it should be *fun* rather than a tax. So the question
/// gets the big type, a wrong guess costs nothing but a wobble, the 💡 gives
/// a real nudge and then the first letter, and an answer that is merely
/// close — a plural, a tense, a slipped finger — is waved through with a
/// grin rather than rejected on a technicality.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/riddle_bank.dart';
import '../engine/answer_match.dart';
import '../l10n/app_localizations.dart';
import '../models/riddle.dart';
import '../services/haptics_service.dart';
import '../services/sfx_service.dart';
import '../ui/colors.dart';
import 'result_card.dart';

/// How many ways the card has of saying "no". They are jokes at the guess's
/// expense rather than the player's — the gate is meant to be the fun part
/// of losing, not a second punishment — and none of them mention the 💡 or
/// count the misses, because they come up in a shuffled order.
const int kRiddleQuips = 30;

/// Every one of them, in the language the app is speaking.
@visibleForTesting
List<String> riddleQuips(AppLocalizations l10n) => <String>[
  l10n.riddleWrong1,
  l10n.riddleWrong2,
  l10n.riddleWrong3,
  l10n.riddleWrong4,
  l10n.riddleWrong5,
  l10n.riddleWrong6,
  l10n.riddleWrong7,
  l10n.riddleWrong8,
  l10n.riddleWrong9,
  l10n.riddleWrong10,
  l10n.riddleWrong11,
  l10n.riddleWrong12,
  l10n.riddleWrong13,
  l10n.riddleWrong14,
  l10n.riddleWrong15,
  l10n.riddleWrong16,
  l10n.riddleWrong17,
  l10n.riddleWrong18,
  l10n.riddleWrong19,
  l10n.riddleWrong20,
  l10n.riddleWrong21,
  l10n.riddleWrong22,
  l10n.riddleWrong23,
  l10n.riddleWrong24,
  l10n.riddleWrong25,
  l10n.riddleWrong26,
  l10n.riddleWrong27,
  l10n.riddleWrong28,
  l10n.riddleWrong29,
  l10n.riddleWrong30,
];

/// The face the card wears while the riddle is still being asked. It has to
/// be a blank one: every riddle's emoji is a picture of its answer, and a 🥭
/// over "फलों का राजा कहलाता हूँ" is not a riddle, it is a caption.
const String kRiddleAskingEmoji = '🧩';

/// How many wrong guesses before the card offers a different riddle. Two is
/// enough to have tried; a third dead end should never feel like a wall.
const int kSwapAfterMisses = 2;

class RiddleChallenge extends ConsumerStatefulWidget {
  const RiddleChallenge({
    super.key,
    required this.riddleId,
    required this.solvedCount,
    required this.onSolved,
    required this.onSwap,
    required this.onDismiss,
  });

  /// Which riddle, in the bank of the language the app is speaking.
  final int riddleId;

  /// Riddles cracked before this one — the card wears it as a badge.
  final int solvedCount;

  /// Answered right: the caller hands back the life.
  final VoidCallback onSolved;

  /// Deal a different riddle.
  final VoidCallback onSwap;

  /// Back out to the ending card without an answer.
  final VoidCallback onDismiss;

  @override
  ConsumerState<RiddleChallenge> createState() => _RiddleChallengeState();
}

class _RiddleChallengeState extends ConsumerState<RiddleChallenge> {
  final TextEditingController _typed = TextEditingController();

  /// The answer field keeps the keyboard: with accessibility on, tapping a
  /// chip or button on this card takes the focus with it in a browser, and
  /// the next thing typed would go nowhere. See [_keepTyping].
  final FocusNode _field = FocusNode();

  /// Wrong guesses so far — they cost nothing but they do change the tone.
  int _misses = 0;

  /// Bumped on every wrong answer to re-run the wobble.
  int _wobble = 0;

  bool _hintShown = false;
  bool _letterShown = false;

  /// The order this card's quips come in — see [_missMessage].
  final List<int> _quipOrder = List<int>.generate(kRiddleQuips, (i) => i)..shuffle();

  /// Null until an answer is judged; [AnswerVerdict.wrong] keeps the card
  /// open, the other two open the gate.
  AnswerVerdict? _verdict;

  bool get _solved => _verdict != null && _verdict!.accepted;

  @override
  void initState() {
    super.initState();
    // Not `autofocus`: that only applies while nothing in the scope has ever
    // held the focus, and the game screen's own `Focus` (the keyboard
    // shortcuts) always has, so when the "Solve a riddle" button goes the
    // focus falls back to that rather than forward to the field. The card
    // asks outright.
    _focusField();
  }

  @override
  void dispose() {
    _typed.dispose();
    _field.dispose();
    super.dispose();
  }

  Riddle get _riddle =>
      riddleFor(Localizations.localeOf(context).languageCode, widget.riddleId);

  /// Puts the keyboard back in the answer field after something else on the
  /// card has been pressed.
  ///
  /// Off the web a chip never takes the focus and this is a no-op, so the
  /// soft keyboard never blinks. The shape of it is dictated by the web with
  /// accessibility on (a screen reader, or the screenshot harness, which
  /// turns semantics on to find widgets by name). There a chip is a DOM
  /// element that takes the browser's focus on mousedown: the field's DOM
  /// input blurs, the engine shuts its text-editing strategy down and
  /// *schedules a deferred blur* of that input on a zero-delay timer of its
  /// own, and the framework's focus follows to the chip. The engine only
  /// wakes the field again on a semantics update in which its focus has
  /// changed to on, and that has to land *after* the engine's timer: a
  /// refocus that lands first is undone by it, and the typing goes nowhere.
  ///
  /// So two things. The refocus is asked for from [_focusField]'s own
  /// zero-delay timer, queued from the tap, which sits behind the engine's
  /// in the same queue. And nothing may hand the field the focus sooner:
  /// a chip that vanishes on the press (the 💡 after the first letter)
  /// would, because a removed focus node passes the focus to the scope's
  /// previously focused child — the field — inside the frame that removes
  /// it, ahead of the timer. So whatever has the focus is first parked on the
  /// enclosing `Focus` (the game screen's shortcuts, which has no semantics
  /// node and so moves nothing in the browser), and the chip goes without
  /// having anything to hand on. The chips and buttons keep their focus
  /// nodes: a chip that could not take the focus would still steal the
  /// browser's, and with nothing changing on the framework's side the field
  /// would look focused to Flutter and be dead to the browser.
  void _keepTyping() {
    final FocusNode? holder = FocusManager.instance.primaryFocus;
    if (holder != null && holder != _field) {
      // Asking a *scope* for the focus would only hand it back to the chip,
      // so with no enclosing `Focus` the holder is unfocused instead.
      final FocusNode? parking = Focus.maybeOf(context);
      if (parking != null) {
        parking.requestFocus();
      } else {
        holder.unfocus();
      }
    }
    _focusField();
  }

  /// Asks for the field's focus from a zero-delay timer — behind whatever the
  /// engine has already queued (see [_keepTyping]), and after the first
  /// frame when the card opens.
  void _focusField() {
    Timer.run(() {
      if (mounted) _field.requestFocus();
    });
  }

  void _check() {
    if (_solved) return;
    final verdict = judgeAnswer(_typed.text, _riddle.accepted);
    setState(() {
      _verdict = verdict;
      if (verdict == AnswerVerdict.wrong) {
        _misses++;
        _wobble++;
      }
    });
    if (verdict == AnswerVerdict.wrong) {
      ref.read(sfxProvider).bump();
      ref.read(hapticsProvider).tap();
      _keepTyping();
    } else {
      ref.read(sfxProvider).win();
      ref.read(hapticsProvider).victory();
    }
  }

  void _nudge() {
    ref.read(hapticsProvider).tap();
    _keepTyping();
    setState(() {
      if (!_hintShown) {
        _hintShown = true;
      } else {
        _letterShown = true;
      }
    });
  }

  /// The quip for this miss, from a pack shuffled when the card was built:
  /// a random pick would repeat itself within a handful of guesses, and the
  /// same line twice reads as a bug rather than as ribbing.
  String _missMessage(AppLocalizations l10n) =>
      riddleQuips(l10n)[_quipOrder[(_misses - 1) % kRiddleQuips]];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = context.palette;
    final riddle = _riddle;
    final answer = riddle.answer;

    if (_solved) {
      // A near miss is let through with a grin rather than a lecture: the
      // player knew the answer, their thumb (or their grammar) disagreed.
      final close = _verdict == AnswerVerdict.close;
      return ResultCard(
        // The riddle's own emoji, at last: it is a picture of the answer,
        // so this is the first moment it can be shown without giving the
        // game away. It arrives as the reveal rather than as decoration.
        emoji: riddle.emoji,
        mood: EmojiMood.cheer,
        title: close ? l10n.riddleCloseTitle : l10n.riddleCorrect,
        body: close ? l10n.riddleClose(answer) : l10n.riddleCorrectBody(answer),
        scrollable: true,
        content: Text(
          l10n.riddleSolvedCount(widget.solvedCount + 1),
          style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700),
        ),
        actions: [
          FilledButton(onPressed: widget.onSolved, child: Text(l10n.riddleBackToBoard)),
        ],
      );
    }

    final letters = answerLength(answer);
    final words = answer.split(' ').where((w) => w.isNotEmpty).length;

    return ResultCard(
      emoji: kRiddleAskingEmoji,
      title: l10n.riddleTitle,
      body: l10n.riddleIntro,
      scrollable: true,
      content:
          Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: p.cardTint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      riddle.question,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: p.textInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Everything about the answer lives in one row of pills:
                  // how long it is, and — while there is one left to give —
                  // the nudge. A card with one column of buttons at its foot
                  // does not want a second button loose in its middle, so the
                  // hint is not a button at all; it is a chip that turns into
                  // the hint under it.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(
                        label: l10n.riddleLetters(letters),
                        tint: p.primary,
                        ink: p.chipInk,
                      ),
                      if (words > 1)
                        _Chip(
                          label: l10n.riddleWords(words),
                          tint: p.primary,
                          ink: p.chipInk,
                        ),
                      if (!_letterShown)
                        _Chip(
                          emoji: '💡',
                          label: _hintShown ? l10n.riddleHintMore : l10n.riddleHintAction,
                          tint: p.accentSun,
                          ink: p.onAccent,
                          onTap: _nudge,
                        ),
                    ],
                  ),
                  if (_hintShown) ...[
                    const SizedBox(height: 10),
                    _Banner(emoji: '🔍', text: riddle.hint, tint: p.accentSun),
                  ],
                  if (_letterShown) ...[
                    const SizedBox(height: 8),
                    _Banner(
                      emoji: '🔤',
                      text: l10n.riddleFirstLetter(_firstLetter(answer)),
                      tint: p.accentSun,
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _typed,
                    focusNode: _field,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) => _check(),
                    onChanged: (_) {
                      // A fresh guess deserves a clean slate under it.
                      if (_verdict != null) setState(() => _verdict = null);
                    },
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: l10n.riddleField,
                      filled: true,
                      fillColor: p.backgroundSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_verdict == AnswerVerdict.wrong) ...[
                    const SizedBox(height: 10),
                    Text(
                      _missMessage(l10n),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.errorRed, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              )
              // The card shrugs off a wrong answer rather than scolding.
              .animate(key: ValueKey<int>(_wobble), autoPlay: _misses > 0)
              .shake(hz: 4, offset: const Offset(6, 0), duration: 380.ms),
      actions: [
        FilledButton(onPressed: _check, child: Text(l10n.riddleSubmit)),
        if (_misses >= kSwapAfterMisses)
          TextButton(onPressed: widget.onSwap, child: Text(l10n.riddleSwap)),
        TextButton(onPressed: widget.onDismiss, child: Text(l10n.riddleGiveUp)),
      ],
    );
  }
}

/// How many letters the answer has, as a reader would count them: a
/// Devanagari matra rides on the letter before it (परछाई is four, not five),
/// so the combining marks do not count.
@visibleForTesting
int answerLength(String answer) => answer
    .replaceAll(' ', '')
    .runes
    .where(
      (r) => !(r >= 0x0900 && r <= 0x0903) &&
          !(r >= 0x093a && r <= 0x094f) &&
          !(r >= 0x0951 && r <= 0x0957) &&
          !(r >= 0x0962 && r <= 0x0963),
    )
    .length;

/// The answer's first letter — the base character, so a Devanagari answer
/// gives away its consonant and not its vowel sign. Capitalised, because it
/// is being shown as a letter rather than as part of the word (a no-op for
/// a script that has no capitals).
String _firstLetter(String answer) =>
    String.fromCharCode(answer.runes.first).toUpperCase();

/// A small pill: how long the answer is, and — with [onTap] — the nudge,
/// which is a pill rather than a button so the card keeps a single column of
/// buttons at its foot.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tint, this.ink, this.emoji, this.onTap});

  final String label;

  /// The chip's colour: a wash behind the label on a chip that only states a
  /// fact, the fill itself on one that can be tapped.
  final Color tint;

  /// The label's colour, which is never [tint] itself: a wash cannot carry
  /// its own tint as text. A pill that states a fact takes
  /// [ArrowPalette.chipInk], a tappable one is filled and takes
  /// [ArrowPalette.onAccent] — the pairing the toolbar's hint badge uses.
  /// `test/ui/theme_test.dart` pins both at 4.5:1 in both palettes.
  final Color? ink;

  final String? emoji;
  final VoidCallback? onTap;

  bool get _filled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: _filled ? 9 : 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: ink ?? tint,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: _filled ? tint : tint.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: _filled ? InkWell(onTap: onTap, child: content) : content,
    );
  }
}

/// The hint, and the "close enough" pat on the back: an emoji and a line in
/// a tinted box.
class _Banner extends StatelessWidget {
  const _Banner({required this.emoji, required this.text, required this.tint});

  final String emoji;
  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.palette.textInk,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.15, end: 0, duration: 220.ms);
}
