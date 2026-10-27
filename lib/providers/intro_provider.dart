/// Which chapter cards the player has been shown. A card is shown once per
/// install, on a chapter's first level — and, while [kIntroCatchUp] is on,
/// on the first board the player opens that is at or past the chapter, so
/// a player who was already deep in the trail when the chapters arrived
/// (they landed in an update, with the levels re-dealt) is shown every
/// card they are behind on, one after another, rather than never.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapters.dart';
import 'app_providers.dart';

/// Whether cards are caught up on: the bridge for installs that were past
/// level 20 when the chapters landed. It is a one-time thing, not the
/// game: once every such install has had its four releases to open a
/// level, turn it off and delete the catch-up branch of [IntroNotifier.due]
/// (and the tests of it). `test/providers/intro_provider_test.dart` fails
/// the build that comes after [kIntroCatchUpLastBuild] until that is done.
const bool kIntroCatchUp = true;

/// The last release build (`pubspec.yaml`'s `+N`) to carry the catch-up:
/// the chapters shipped in build 15, and four releases on is 18.
const int kIntroCatchUpLastBuild = 18;

class IntroRepository {
  IntroRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'arrow_intros_seen';

  Set<ChapterRule> load() {
    final names = _prefs.getStringList(key) ?? const <String>[];
    return <ChapterRule>{
      for (final rule in ChapterRule.values)
        if (names.contains(rule.name)) rule,
    };
  }

  Future<void> save(Set<ChapterRule> seen) =>
      _prefs.setStringList(key, <String>[for (final r in seen) r.name]);

  Future<void> clear() => _prefs.remove(key);
}

class IntroNotifier extends StateNotifier<Set<ChapterRule>> {
  IntroNotifier(this._repo) : super(_repo.load());

  final IntroRepository _repo;

  /// The cards still owed to a player opening [level] (or the daily board of
  /// [chapter]): the card of the chapter [level] is the first of, if it has
  /// not been shown — and, with [kIntroCatchUp], every chapter past the
  /// first up to and including the one the level (or the daily) is in,
  /// whose card has not been shown, in trail order.
  List<ChapterRule> due({int? level, Chapter? chapter}) {
    if (!kIntroCatchUp) {
      final rule = level == null ? null : ruleTaughtAt(level);
      return rule == null || !rule.hasCard || state.contains(rule) ? const <ChapterRule>[] : <ChapterRule>[rule];
    }
    final upTo = chapter ?? (level == null ? null : chapterOf(level));
    if (upTo == null) return const <ChapterRule>[];
    return <ChapterRule>[
      for (final c in chapters)
        if (c.index >= 2 && c.index <= upTo.index && c.rule.hasCard && !state.contains(c.rule)) c.rule,
    ];
  }

  /// The card for [rule] has been dismissed.
  void markSeen(ChapterRule rule) {
    if (state.contains(rule)) return;
    state = <ChapterRule>{...state, rule};
    _repo.save(state);
  }

  /// Every card will be shown again (a progress reset).
  void reset() {
    state = const <ChapterRule>{};
    _repo.clear();
  }
}

final introRepositoryProvider = Provider<IntroRepository>(
  (ref) => IntroRepository(ref.watch(sharedPreferencesProvider)),
);

final introProvider = StateNotifierProvider<IntroNotifier, Set<ChapterRule>>(
  (ref) => IntroNotifier(ref.watch(introRepositoryProvider)),
);
