/// Which chapter cards the player has been shown. A card is shown once per
/// install, on the first board the player opens that is at or past the
/// chapter it introduces — so a player who is already deep in the trail
/// when a chapter arrives (the twists landed in an update, with the levels
/// re-dealt) is shown every card they are behind on, one after another,
/// the next time they open a level, rather than never.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapters.dart';
import 'app_providers.dart';

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
  /// [chapter]): every chapter past the first up to and including the one
  /// the level is in, whose card has not been shown, in trail order.
  List<ChapterRule> due({int? level, Chapter? chapter}) {
    final upTo = chapter ?? (level == null ? null : chapterOf(level));
    if (upTo == null) return const <ChapterRule>[];
    return <ChapterRule>[
      for (final c in chapters)
        if (c.index >= 2 && c.index <= upTo.index && !state.contains(c.rule)) c.rule,
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
