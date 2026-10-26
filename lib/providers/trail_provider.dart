/// Which chapters of the home trail are folded away. A chapter the player
/// has cleared folds by default — two hundred levels down a page put the
/// next level a long scroll from the top — and every other chapter is open;
/// a tap on a chapter's heading flips it, and that choice is kept.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';

class TrailFoldRepository {
  TrailFoldRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'arrow_trail_folds';

  /// Chapter index → open, for the chapters the player has opened or
  /// folded by hand. Stored as `"index:1"` (open) or `"index:0"` (folded).
  Map<int, bool> load() {
    final entries = _prefs.getStringList(key) ?? const <String>[];
    final folds = <int, bool>{};
    for (final entry in entries) {
      final parts = entry.split(':');
      final index = parts.length == 2 ? int.tryParse(parts[0]) : null;
      if (index != null) folds[index] = parts[1] == '1';
    }
    return folds;
  }

  Future<void> save(Map<int, bool> folds) => _prefs.setStringList(key, <String>[
    for (final e in folds.entries) '${e.key}:${e.value ? 1 : 0}',
  ]);

  Future<void> clear() => _prefs.remove(key);
}

class TrailFoldNotifier extends StateNotifier<Map<int, bool>> {
  TrailFoldNotifier(this._repo) : super(_repo.load());

  final TrailFoldRepository _repo;

  /// Whether chapter [index] shows its levels: as the player left it, or
  /// open unless every one of its levels is cleared.
  bool isOpen(int index, {required bool allCleared}) =>
      state[index] ?? !allCleared;

  /// Opens chapter [index] if it is folded, folds it if it is open.
  void toggle(int index, {required bool allCleared}) {
    state = <int, bool>{
      ...state,
      index: !isOpen(index, allCleared: allCleared),
    };
    _repo.save(state);
  }

  /// Back to the defaults (Reset progress).
  Future<void> reset() {
    state = const <int, bool>{};
    return _repo.clear();
  }
}

final trailFoldProvider =
    StateNotifierProvider<TrailFoldNotifier, Map<int, bool>>(
      (ref) => TrailFoldNotifier(
        TrailFoldRepository(ref.watch(sharedPreferencesProvider)),
      ),
    );
