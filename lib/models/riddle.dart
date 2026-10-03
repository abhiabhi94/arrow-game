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

/// What cracking the riddle buys. The card's words change with it; the
/// riddle, the judging and the jokes do not.
enum RiddlePrize {
  /// One more life, from the "Out of lives" card.
  life,

  /// One more hint, from the toolbar once the free ones are spent.
  hint,
}

/// The riddle on the table for a level, kept so that leaving the level with
/// the card up (back to the levels, or closing the app) brings the same card
/// back rather than the "Out of lives" card in front of it — and the same
/// riddle, so walking away is not a way to swap a hard one for another.
class OpenRiddle {
  const OpenRiddle({
    required this.level,
    required this.prize,
    required this.id,
    required this.language,
  });

  final int level;
  final RiddlePrize prize;
  final int id;

  /// The bank [id] belongs to. The banks share ids but not riddles (7 is a
  /// mirror in English and a peacock in Hindi), so without it a change of
  /// language between leaving and coming back would be a swap.
  final String language;

  /// `level:prize:id:language`, the form it is stored in.
  String encode() => '$level:${prize.name}:$id:$language';

  /// Reads [encode]'s form back; null when [raw] is not one.
  static OpenRiddle? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 4 || parts[3].isEmpty) return null;
    final level = int.tryParse(parts[0]);
    final id = int.tryParse(parts[2]);
    final prize = RiddlePrize.values.where((p) => p.name == parts[1]).firstOrNull;
    if (level == null || id == null || prize == null) return null;
    return OpenRiddle(level: level, prize: prize, id: id, language: parts[3]);
  }

  @override
  bool operator ==(Object other) =>
      other is OpenRiddle &&
      other.level == level &&
      other.prize == prize &&
      other.id == id &&
      other.language == language;

  @override
  int get hashCode => Object.hash(level, prize, id, language);
}
