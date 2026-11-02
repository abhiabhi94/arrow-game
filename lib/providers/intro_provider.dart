/// Which chapter cards the player has been shown. A card is shown once per
/// install, on a chapter's first level.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

  /// The cards still owed to a player opening [level]: the card of the
  /// chapter [level] is the first of, if it has not been shown.
  List<ChapterRule> due({required int level}) {
    final rule = ruleTaughtAt(level);
    return rule == null || !rule.hasCard || state.contains(rule) ? const <ChapterRule>[] : <ChapterRule>[rule];
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
