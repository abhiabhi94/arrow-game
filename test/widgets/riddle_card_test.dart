import 'package:arrow_game/data/riddle_bank.dart';
import 'package:arrow_game/l10n/app_localizations.dart';
import 'package:arrow_game/ui/colors.dart';
import 'package:arrow_game/widgets/riddle_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Riddle 1 in each bank, the one every test here is asked.
final _en = riddleFor('en', 1);
final _hi = riddleFor('hi', 1);

class _Calls {
  int solved = 0;
  int swapped = 0;
  int dismissed = 0;
}

Future<_Calls> _pumpRiddle(
  WidgetTester tester, {
  int id = 1,
  int solvedCount = 0,
  Locale? locale,
}) async {
  final calls = _Calls();
  await usePhoneSurface(tester);
  await pumpApp(
    tester,
    Scaffold(
      body: Stack(
        children: [
          RiddleChallenge(
            riddleId: id,
            solvedCount: solvedCount,
            onSolved: () => calls.solved++,
            onSwap: () => calls.swapped++,
            onDismiss: () => calls.dismissed++,
          ),
        ],
      ),
    ),
    locale: locale,
    extraOverrides: silentFeedback(),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return calls;
}

/// Mounts whatever the tap revealed, then lets its entrance play out:
/// flutter_animate starts on a zero-delay timer, so the frame has to be
/// pumped before the clock is advanced.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Whatever the card said about the last guess: the one line drawn in the
/// error colour. Null when it is not saying anything.
String? _ribbing(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .where((t) => t.style?.color == ArrowPalette.light.errorRed)
    .map((t) => t.data)
    .firstOrNull;

/// Types [guess] and submits it, then lets the wobble finish.
Future<void> _answer(WidgetTester tester, String guess) async {
  await tester.enterText(find.byType(TextField), guess);
  await tester.tap(find.text("That's my answer"));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('asks the riddle, and says how long the answer is', (tester) async {
    await _pumpRiddle(tester);
    expect(find.text('Riddle me this'), findsOneWidget);
    expect(find.text(_en.question), findsOneWidget);
    // The riddle's own emoji is a picture of its answer, so the card wears a
    // blank face while it is still asking.
    expect(find.text(kRiddleAskingEmoji), findsOneWidget);
    expect(find.text(_en.emoji), findsNothing);
    expect(find.text('${_en.answer.length} letters'), findsOneWidget);
    // The hint stays behind its button until it is asked for.
    expect(find.text(_en.hint), findsNothing);
    expect(find.text('Give me a hint'), findsOneWidget);
  });

  testWidgets('a wrong answer costs nothing but a nudge in the ribs', (tester) async {
    final calls = await _pumpRiddle(tester);
    await _answer(tester, 'banana');
    expect(_ribbing(tester), isNotNull);
    expect(calls.solved, 0);
    // Still the same riddle, still answerable.
    expect(find.text(_en.question), findsOneWidget);

    // Typing again clears the telling-off.
    await tester.enterText(find.byType(TextField), 'b');
    await tester.pump();
    expect(_ribbing(tester), isNull);
  });

  testWidgets('the hint comes in two nudges: the clue, then the first letter', (tester) async {
    await _pumpRiddle(tester);
    await tester.tap(find.text('Give me a hint'));
    await _settle(tester);
    expect(find.text(_en.hint), findsOneWidget);

    await tester.tap(find.text('One more nudge'));
    await _settle(tester);
    expect(find.text('It starts with “${_en.answer[0].toUpperCase()}”'), findsOneWidget);
    // Nothing left to give.
    expect(find.text('One more nudge'), findsNothing);
  });

  testWidgets('the hint chip is readable: accent ink on the solid accent', (tester) async {
    // Amber on pale amber is what it looked like first, and the label all
    // but disappeared. onAccent on accentSun is the pairing theme_test pins
    // at 4.5:1 in both palettes.
    await _pumpRiddle(tester);
    final label = tester.widget<Text>(find.text('Give me a hint'));
    expect(label.style?.color, ArrowPalette.light.onAccent);
    final pill = tester.widget<Material>(
      find.ancestor(of: find.text('Give me a hint'), matching: find.byType(Material)).first,
    );
    expect(pill.color, ArrowPalette.light.accentSun);

    // The chip that only states a fact stays a quiet wash.
    final fact = tester.widget<Text>(find.text('6 letters'));
    expect(fact.style?.color, ArrowPalette.light.chipInk);
  });

  testWidgets('the answer field keeps the keyboard when a button is tapped', (tester) async {
    await _pumpRiddle(tester);
    bool focused() => tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;
    expect(focused(), isTrue);

    // On a desktop browser a button takes the focus with it, and the next
    // thing typed would go nowhere.
    await tester.tap(find.text('Give me a hint'));
    await _settle(tester);
    expect(focused(), isTrue);

    await _answer(tester, 'banana');
    expect(focused(), isTrue);
  });

  testWidgets('the ribbing keeps changing, and never repeats itself', (tester) async {
    await _pumpRiddle(tester);
    final seen = <String>{};
    for (var i = 0; i < 12; i++) {
      await _answer(tester, 'nope $i');
      final line = _ribbing(tester);
      expect(line, isNotNull, reason: 'miss ${i + 1} said nothing');
      seen.add(line!);
    }
    // A dozen misses, a dozen different jokes: the pack is shuffled, not
    // sampled, so nothing comes round twice until all thirty have had a turn.
    expect(seen, hasLength(12));
  });

  testWidgets('every quip is its own, in both languages', (tester) async {
    for (final locale in <Locale>[const Locale('en'), const Locale('hi')]) {
      late List<String> quips;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            quips = riddleQuips(AppLocalizations.of(context)!);
            return const SizedBox();
          },
        ),
        locale: locale,
      );
      expect(quips, hasLength(kRiddleQuips));
      expect(quips.toSet(), hasLength(kRiddleQuips), reason: '$locale repeats itself');
      for (final quip in quips) {
        expect(quip.trim(), isNotEmpty);
      }
    }
  });

  testWidgets('two misses in and a different riddle is on offer', (tester) async {
    final calls = await _pumpRiddle(tester);
    expect(find.text('Try a different riddle'), findsNothing);
    await _answer(tester, 'banana');
    expect(find.text('Try a different riddle'), findsNothing);
    await _answer(tester, 'mango');
    expect(_ribbing(tester), isNotNull);

    await tester.tap(find.text('Try a different riddle'));
    await tester.pump();
    expect(calls.swapped, 1);
  });

  testWidgets('the right answer hands the life back', (tester) async {
    final calls = await _pumpRiddle(tester, solvedCount: 4);
    await _answer(tester, _en.answer.toUpperCase());
    expect(find.text('Spot on!'), findsOneWidget);
    // Now the emoji can come out: it is the answer, drawn.
    expect(find.text(_en.emoji), findsOneWidget);
    expect(find.text(kRiddleAskingEmoji), findsNothing);
    expect(find.textContaining(_en.answer), findsWidgets);
    expect(find.text('5 riddles cracked so far'), findsOneWidget);

    expect(calls.solved, 0);
    await tester.tap(find.text('Back to the arrows'));
    await tester.pump();
    expect(calls.solved, 1);
  });

  testWidgets('close enough is good enough', (tester) async {
    await _pumpRiddle(tester);
    // A plural of the answer: right word, wrong ending.
    await _answer(tester, '${_en.answer}s');
    expect(find.text('Close enough!'), findsOneWidget);
    expect(find.text('Spot on!'), findsNothing);
    expect(find.textContaining('it was ${_en.answer}'), findsOneWidget);
    expect(find.text('Your first riddle'), findsNothing);
    expect(find.text('1 riddle cracked so far'), findsOneWidget);
  });

  testWidgets('backing out leaves the riddle unanswered', (tester) async {
    final calls = await _pumpRiddle(tester);
    await tester.tap(find.text('Never mind'));
    await tester.pump();
    expect(calls.dismissed, 1);
    expect(calls.solved, 0);
  });

  testWidgets('a Hindi answer can be typed in roman letters', (tester) async {
    // A phone set to Hindi often has no Devanagari keyboard on it.
    await _pumpRiddle(tester, locale: const Locale('hi'));
    await tester.enterText(find.byType(TextField), _hi.alternates.last);
    await tester.tap(find.text('यही मेरा जवाब है'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('एकदम सही!'), findsOneWidget);
  });

  testWidgets('a Hindi app asks a Hindi riddle', (tester) async {
    await _pumpRiddle(tester, locale: const Locale('hi'));
    expect(find.text('बूझो तो जानें'), findsOneWidget);
    expect(find.text(_hi.question), findsOneWidget);
    // A matra rides on the letter before it, so the count is of letters as
    // a reader counts them, not of runes.
    expect(find.text('${answerLength(_hi.answer)} अक्षर'), findsOneWidget);
    expect(answerLength('परछाई'), 4);

    await tester.enterText(find.byType(TextField), _hi.answer);
    await tester.tap(find.text('यही मेरा जवाब है'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('एकदम सही!'), findsOneWidget);
  });
}
