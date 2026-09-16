/// Judging a typed riddle answer. Pure Dart, no Flutter.
///
/// The point is to be *generous*: a player who knows the answer but typed
/// "shadows", "candel" or "परछाई" has solved the riddle, and a gate that
/// says no to them is a gate that feels broken. So a guess is measured three
/// ways — the word itself, the word with its inflections peeled off, and the
/// word a typo or two away — and anything but the first is reported as
/// [AnswerVerdict.close] so the card can say "close enough" and let them
/// through.
library;

/// How a typed guess measured up.
enum AnswerVerdict {
  /// The answer, on the nose (spacing, case and punctuation aside).
  exact,

  /// Near enough to let through: a plural or a tense, or a small misspelling.
  close,

  /// Not this riddle's answer.
  wrong;

  /// Whether the guess opens the gate.
  bool get accepted => this != AnswerVerdict.wrong;
}

/// Judges [typed] against [accepted] (the answer and its synonyms).
AnswerVerdict judgeAnswer(String typed, Iterable<String> accepted) {
  final guess = normalizeAnswer(typed);
  if (guess.isEmpty) return AnswerVerdict.wrong;
  final candidates = accepted.map(normalizeAnswer).where((a) => a.isNotEmpty).toList();
  for (final answer in candidates) {
    // "ice cream" and "icecream" are the same word typed two ways.
    if (guess == answer || _squash(guess) == _squash(answer)) return AnswerVerdict.exact;
  }
  final guessForms = _forms(guess);
  for (final answer in candidates) {
    if (guessForms.intersection(_forms(answer)).isNotEmpty) return AnswerVerdict.close;
    if (_withinTypos(guess, answer)) return AnswerVerdict.close;
  }
  return AnswerVerdict.wrong;
}

/// Lower-cases, strips accents, nukta dots and punctuation, drops a leading
/// article and collapses whitespace, so only the word itself is compared.
String normalizeAnswer(String raw) {
  final buffer = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    // Invisible in pasted Devanagari, and never part of an answer.
    if (rune == 0x200c || rune == 0x200d || rune == 0x093c) continue;
    final devanagari = _devanagariFold[rune];
    if (devanagari != null) {
      buffer.writeCharCode(devanagari);
      continue;
    }
    final ch = String.fromCharCode(rune);
    final latin = _latinFold[ch];
    if (latin != null) {
      buffer.write(latin);
    } else if (_isWordChar(rune)) {
      buffer.write(ch);
    } else {
      buffer.write(' ');
    }
  }
  var out = buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
  for (final article in _articles) {
    if (out.startsWith(article)) {
      out = out.substring(article.length);
      break;
    }
  }
  return out.trim();
}

/// Letters, digits and Devanagari; everything else is a separator.
bool _isWordChar(int rune) =>
    (rune >= 0x61 && rune <= 0x7a) || // a-z (already lower-cased)
    (rune >= 0x30 && rune <= 0x39) || // 0-9
    (rune >= 0x0900 && rune <= 0x097f); // Devanagari

/// Accents: cafe and café are the same answer.
const Map<String, String> _latinFold = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

/// The dotted (nukta) letters Hindi is typed both ways, folded onto their
/// plain form, plus chandrabindu onto anusvara: ज़ल and जल, ँ and ं, are not
/// different guesses. Keyed by code point, so a pre-composed क़ and a
/// क + nukta pair both land on क.
const Map<int, int> _devanagariFold = <int, int>{
  0x0958: 0x0915, // क़
  0x0959: 0x0916, // ख़
  0x095a: 0x0917, // ग़
  0x095b: 0x091c, // ज़
  0x095c: 0x0921, // ड़
  0x095d: 0x0922, // ढ़
  0x095e: 0x092b, // फ़
  0x095f: 0x092f, // य़
  0x0901: 0x0902, // ँ -> ं
};

/// Leading words that carry no meaning in an answer.
const List<String> _articles = <String>['the ', 'a ', 'an ', 'एक '];

String _squash(String s) => s.replaceAll(' ', '').replaceAll('-', '');

/// Tolerated typos for an answer of [length] characters: none in a very
/// short word (where one letter is a different word), one in a short word,
/// two once there is enough word left to still be recognisable.
int typoBudget(int length) => switch (length) {
  <= 3 => 0,
  <= 6 => 1,
  _ => 2,
};

bool _withinTypos(String a, String b) {
  final budget = typoBudget(b.length);
  if (budget == 0) return false;
  if ((a.length - b.length).abs() > budget) return false;
  return _editDistance(a, b, budget) <= budget;
}

/// The word plus the base forms it could be an inflection of — plurals and
/// tenses in English, the common case endings in Hindi. Both the guess and
/// the answer are reduced, so either one may be the inflected one.
Set<String> _forms(String word) {
  final forms = <String>{word};
  for (final part in <String>{word, _squash(word)}) {
    forms.add(part);
    forms.addAll(_englishStems(part));
    forms.addAll(_hindiStems(part));
  }
  // A one- or two-letter "stem" is noise, not a word.
  return forms.where((f) => f.length >= 3).toSet();
}

Set<String> _englishStems(String w) {
  final stems = <String>{};
  void add(String s) {
    if (s.length >= 3) stems.add(s);
  }

  String drop(int n) => w.substring(0, w.length - n);

  if (w.endsWith('ies')) add('${drop(3)}y');
  if (w.endsWith('ves')) add('${drop(3)}f');
  if (w.endsWith('es')) {
    add(drop(2));
    add(drop(1));
  } else if (w.endsWith('s') && !w.endsWith('ss')) {
    add(drop(1));
  }
  if (w.endsWith('ed')) {
    add(drop(2));
    add(drop(1));
    add(_undouble(drop(2)));
  }
  if (w.endsWith('ing')) {
    add(drop(3));
    add('${drop(3)}e');
    add(_undouble(drop(3)));
  }
  if (w.endsWith('er') || w.endsWith('en')) {
    add(drop(2));
    add(drop(1));
  }
  return stems;
}

/// "stopp" -> "stop": English doubles the last consonant before -ed/-ing.
String _undouble(String w) =>
    w.length > 2 && w[w.length - 1] == w[w.length - 2] ? w.substring(0, w.length - 1) : w;

/// Hindi answers arrive with whatever ending the sentence in the player's
/// head had — परछाईं for परछाई, बच्चों for बच्चा — so the common endings come
/// off the same way English plurals do.
Set<String> _hindiStems(String w) {
  const endings = <String>[
    'याँ', 'ियाँ', 'ाएँ', 'ओं', 'ों', 'ें', 'ाओं', 'ीं',
    'ा', 'े', 'ी', 'ू', 'ो', 'ं', 'ई',
  ];
  final stems = <String>{};
  for (final ending in endings) {
    if (w.length > ending.length + 1 && w.endsWith(ending)) {
      stems.add(w.substring(0, w.length - ending.length));
    }
  }
  return stems.where((s) => s.length >= 2).toSet();
}

/// Edit distance with transpositions (optimal string alignment), given up
/// on once it passes [budget]. Swapping two letters — "candel" for "candle"
/// — is the typo people actually make, and plain Levenshtein charges two for
/// it, which is exactly the guess a gate should not be turning away.
int _editDistance(String a, String b, int budget) {
  final cols = b.length + 1;
  var twoBack = List<int>.filled(cols, 0);
  var previous = List<int>.generate(cols, (i) => i);
  var current = List<int>.filled(cols, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var best = i;
    for (var j = 1; j < cols; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var value = previous[j] + 1;
      if (current[j - 1] + 1 < value) value = current[j - 1] + 1;
      if (previous[j - 1] + cost < value) value = previous[j - 1] + cost;
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        final swapped = twoBack[j - 2] + 1;
        if (swapped < value) value = swapped;
      }
      current[j] = value;
      if (value < best) best = value;
    }
    if (best > budget) return budget + 1;
    final spent = twoBack;
    twoBack = previous;
    previous = current;
    current = spent;
  }
  return previous[cols - 1];
}
