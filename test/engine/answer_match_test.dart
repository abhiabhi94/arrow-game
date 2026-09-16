import 'package:arrow_game/engine/answer_match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the answer itself', () {
    test('case, spacing and punctuation do not matter', () {
      expect(judgeAnswer('  Shadow! ', const ['shadow']), AnswerVerdict.exact);
      expect(judgeAnswer('ICE CREAM', const ['icecream']), AnswerVerdict.exact);
      expect(judgeAnswer('ice-cream', const ['ice cream']), AnswerVerdict.exact);
    });

    test('a leading article is not part of the answer', () {
      expect(judgeAnswer('the moon', const ['moon']), AnswerVerdict.exact);
      expect(judgeAnswer('an onion', const ['onion']), AnswerVerdict.exact);
      expect(judgeAnswer('एक पतंग', const ['पतंग']), AnswerVerdict.exact);
    });

    test('any of the accepted words counts', () {
      expect(judgeAnswer('watch', const ['clock', 'watch']), AnswerVerdict.exact);
    });

    test('an accent is a keyboard, not a mistake', () {
      expect(judgeAnswer('café', const ['cafe']), AnswerVerdict.exact);
    });
  });

  group('close enough', () {
    test('a plural, or a singular for a plural answer', () {
      expect(judgeAnswer('shadows', const ['shadow']), AnswerVerdict.close);
      expect(judgeAnswer('footstep', const ['footsteps']), AnswerVerdict.close);
      expect(judgeAnswer('candies', const ['candy']), AnswerVerdict.close);
    });

    test('a tense the riddle did not ask for', () {
      expect(judgeAnswer('dreaming', const ['dream']), AnswerVerdict.close);
      expect(judgeAnswer('promised', const ['promise']), AnswerVerdict.close);
      expect(judgeAnswer('stopped', const ['stop']), AnswerVerdict.close);
      expect(judgeAnswer('running', const ['run']), AnswerVerdict.close);
    });

    test('a common misspelling', () {
      expect(judgeAnswer('candel', const ['candle']), AnswerVerdict.close);
      expect(judgeAnswer('elefant', const ['elephant']), AnswerVerdict.close);
      expect(judgeAnswer('umbrela', const ['umbrella']), AnswerVerdict.close);
      expect(judgeAnswer('rainbo', const ['rainbow']), AnswerVerdict.close);
    });
  });

  group('wrong', () {
    test('an empty guess is not an answer', () {
      expect(judgeAnswer('   ', const ['shadow']), AnswerVerdict.wrong);
      expect(judgeAnswer('', const ['shadow']), AnswerVerdict.wrong);
    });

    test('a different word', () {
      expect(judgeAnswer('banana', const ['shadow']), AnswerVerdict.wrong);
      expect(judgeAnswer('mirror', const ['window']), AnswerVerdict.wrong);
    });

    test('short words hold the line: one letter apart is a different word', () {
      expect(judgeAnswer('cat', const ['bat']), AnswerVerdict.wrong);
      expect(judgeAnswer('bee', const ['bed']), AnswerVerdict.wrong);
      expect(typoBudget(3), 0);
      expect(typoBudget(6), 1);
      expect(typoBudget(9), 2);
    });
  });

  group('Hindi', () {
    test('a nukta is optional, and so is a chandrabindu', () {
      expect(judgeAnswer('जुबान', const ['ज़ुबान']), AnswerVerdict.exact);
      expect(judgeAnswer('प्याज', const ['प्याज़']), AnswerVerdict.exact);
      expect(judgeAnswer('गूंज', const ['गूँज']), AnswerVerdict.exact);
    });

    test('the ending the sentence in your head had', () {
      expect(judgeAnswer('सपने', const ['सपना']), AnswerVerdict.close);
      expect(judgeAnswer('तारों', const ['तारा']), AnswerVerdict.close);
    });

    test('a slipped matra', () {
      expect(judgeAnswer('मोमबती', const ['मोमबत्ती']), AnswerVerdict.close);
      expect(judgeAnswer('भुलभुलैया', const ['भूलभुलैया']), AnswerVerdict.close);
    });

    test('a different word is still wrong', () {
      expect(judgeAnswer('पानी', const ['पतंग']), AnswerVerdict.wrong);
      expect(judgeAnswer('घड़ा', const ['घड़ी']), AnswerVerdict.wrong);
    });
  });

  test('a verdict knows whether it opens the gate', () {
    expect(AnswerVerdict.exact.accepted, isTrue);
    expect(AnswerVerdict.close.accepted, isTrue);
    expect(AnswerVerdict.wrong.accepted, isFalse);
  });

  test('normalizing is idempotent and strips the noise', () {
    expect(normalizeAnswer('  The  Moon!! '), 'moon');
    expect(normalizeAnswer(normalizeAnswer('A Shadow?')), 'shadow');
  });
}
