import 'package:arrow_game/data/riddle_bank.dart';
import 'package:arrow_game/engine/answer_match.dart';
import 'package:arrow_game/models/riddle.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every bank the app can deal from, by the language code that picks it.
const Map<String, List<Riddle>> _banks = <String, List<Riddle>>{
  'en': englishRiddles,
  'hi': hindiRiddles,
};

void main() {
  _banks.forEach((language, bank) {
    group('the $language bank', () {
      test('holds $kRiddleCount riddles with ids 1..$kRiddleCount', () {
        expect(bank, hasLength(kRiddleCount));
        expect(
          bank.map((r) => r.id).toList()..sort(),
          <int>[for (var i = 1; i <= kRiddleCount; i++) i],
        );
      });

      test('every riddle asks something, answers it, and carries a hint', () {
        for (final riddle in bank) {
          expect(riddle.question.trim(), isNotEmpty, reason: 'riddle ${riddle.id}');
          expect(riddle.question.trim(), endsWith('?'), reason: 'riddle ${riddle.id}');
          expect(riddle.hint.trim(), isNotEmpty, reason: 'riddle ${riddle.id}');
          expect(riddle.emoji.trim(), isNotEmpty, reason: 'riddle ${riddle.id}');
          expect(riddle.answer.trim(), isNotEmpty, reason: 'riddle ${riddle.id}');
          // An everyday word or two, not a sentence: this is a five-second
          // gate, and the card shows how many words to expect.
          expect(riddle.answer.split(' '), hasLength(lessThanOrEqualTo(3)));
          // The hint narrows the riddle down; it never spells the answer out.
          expect(
            riddle.hint.toLowerCase(),
            isNot(contains(riddle.answer.toLowerCase())),
            reason: 'riddle ${riddle.id}',
          );
        }
      });

      test('the answer and every alternate are accepted', () {
        for (final riddle in bank) {
          for (final word in riddle.accepted) {
            expect(
              judgeAnswer(word, riddle.accepted),
              AnswerVerdict.exact,
              reason: 'riddle ${riddle.id} should accept "$word"',
            );
          }
        }
      });

      test('no riddle accepts another riddle\'s answer', () {
        for (final riddle in bank) {
          for (final other in bank) {
            if (other.id == riddle.id) continue;
            expect(
              judgeAnswer(other.answer, riddle.accepted),
              AnswerVerdict.wrong,
              reason: '"${other.answer}" (${other.id}) is taken for ${riddle.id}',
            );
          }
        }
      });
    });
  });

  test('the Hindi bank is written in Devanagari', () {
    for (final riddle in hindiRiddles) {
      expect(
        riddle.answer.runes.every((r) => r >= 0x0900 && r <= 0x097f),
        isTrue,
        reason: 'riddle ${riddle.id}: ${riddle.answer}',
      );
    }
  });

  test('every Hindi answer can also be typed in roman letters', () {
    // A phone set to Hindi very often has no Devanagari keyboard on it.
    for (final riddle in hindiRiddles) {
      final roman = riddle.alternates.where(
        (w) => w.runes.every((r) => r < 0x0080),
      );
      expect(roman, isNotEmpty, reason: 'riddle ${riddle.id} has no roman spelling');
      for (final word in roman) {
        expect(judgeAnswer(word, riddle.accepted), AnswerVerdict.exact);
      }
    }
  });

  test('a riddle is not a translation of the one with the same id', () {
    // The banks are two sets of riddles, not one set said twice, so nothing
    // guarantees more than the shape — but the questions must at least be
    // their own language's.
    for (var i = 0; i < kRiddleCount; i++) {
      expect(englishRiddles[i].question, isNot(hindiRiddles[i].question));
    }
  });

  group('picking a riddle', () {
    test('the language picks the bank, with English as the fallback', () {
      expect(riddleBankFor('hi'), same(hindiRiddles));
      expect(riddleBankFor('en'), same(englishRiddles));
      expect(riddleBankFor('fr'), same(englishRiddles));
    });

    test('by id, within the language', () {
      expect(riddleFor('en', 7).answer, englishRiddles[6].answer);
      expect(riddleFor('hi', 7).answer, hindiRiddles[6].answer);
    });

    test('an id the bank does not have falls back to the first', () {
      expect(riddleFor('en', kRiddleCount + 99).id, englishRiddles.first.id);
    });
  });
}
