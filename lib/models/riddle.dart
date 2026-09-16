/// One riddle: the question, what counts as the answer, and the nudge that
/// helps when it doesn't come. Pure Dart (no Flutter) — the banks in
/// `data/riddle_bank.dart` are const lists of these.
library;

class Riddle {
  const Riddle({
    required this.id,
    required this.emoji,
    required this.question,
    required this.answer,
    required this.hint,
    this.alternates = const <String>[],
  });

  /// Stable within its bank, 1..kRiddleCount. The deck shuffles ids, so an
  /// id must never be reused for a different riddle in the same language.
  final int id;

  /// A picture of the answer, shown only once the answer is in: on the card
  /// while the riddle is still being asked it would simply give it away.
  final String emoji;

  final String question;

  /// The answer as it is revealed to the player.
  final String answer;

  /// Other words that are just as right (synonyms, spellings). Near misses
  /// — plurals, tenses, typos — are handled by the matcher, not listed here.
  final List<String> alternates;

  /// The nudge behind the 💡, in the spirit of a sudoku hint: it narrows the
  /// riddle down without ever spelling the answer out.
  final String hint;

  /// Everything a typed answer may be measured against.
  List<String> get accepted => <String>[answer, ...alternates];
}
