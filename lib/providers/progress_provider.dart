/// Level progress state: completion, stars, best times, unlock progression.
/// Persisted via shared_preferences with app-prefixed keys.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/level_specs.dart';
import '../models/level_progress.dart';
import 'app_providers.dart';

class ProgressRepository {
  ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _doneKey(int level) => 'arrow_level_${level}_done';
  static String _starsKey(int level) => 'arrow_level_${level}_stars';
  static String _bestKey(int level) => 'arrow_level_${level}_best';
  static String _countKey(int level) => 'arrow_level_${level}_count';

  LevelProgress load(int level) => LevelProgress(
        level: level,
        completed: _prefs.getBool(_doneKey(level)) ?? false,
        stars: _prefs.getInt(_starsKey(level)) ?? 0,
        bestTimeMs: _prefs.getInt(_bestKey(level)),
        timesCompleted: _prefs.getInt(_countKey(level)) ?? 0,
      );

  Map<int, LevelProgress> loadAll() => <int, LevelProgress>{
        for (var level = 1; level <= totalLevels; level++) level: load(level),
      };

  Future<void> save(LevelProgress p) async {
    await _prefs.setBool(_doneKey(p.level), p.completed);
    await _prefs.setInt(_starsKey(p.level), p.stars);
    await _prefs.setInt(_countKey(p.level), p.timesCompleted);
    final best = p.bestTimeMs;
    if (best != null) await _prefs.setInt(_bestKey(p.level), best);
  }

  /// Wipes every level's progress.
  Future<void> clearAll() async {
    for (var level = 1; level <= totalLevels; level++) {
      await _prefs.remove(_doneKey(level));
      await _prefs.remove(_starsKey(level));
      await _prefs.remove(_bestKey(level));
      await _prefs.remove(_countKey(level));
    }
  }
}

/// The grid-lines toggle is earned: it appears once this level is cleared.
const int kGridLinesUnlockAfterLevel = 4;

/// Whether the running build unlocks every level regardless of progress. True
/// for the debug ("Arrow Testing") build so testers can reach any level, or
/// for any build compiled with `--dart-define=UNLOCK_ALL=true` (a small
/// release-mode tester build); the plain release ("Arrow") build enforces
/// the locked progression.
bool get testingUnlocksAllLevels =>
    kDebugMode || const bool.fromEnvironment('UNLOCK_ALL');

class ProgressNotifier extends StateNotifier<Map<int, LevelProgress>> {
  ProgressNotifier(this._repo, {bool? unlockAllLevels})
      : _unlockAll = unlockAllLevels ?? testingUnlocksAllLevels,
        super(_repo.loadAll());

  final ProgressRepository _repo;
  final bool _unlockAll;

  LevelProgress progressFor(int level) =>
      state[level] ?? LevelProgress.empty(level);

  /// Records a clear of [level] in [timeMs] with [stars]. State updates at
  /// once; the returned future completes when it is persisted.
  Future<void> recordCompletion(int level, int timeMs, int stars) {
    final updated = progressFor(level).withCompletion(timeMs, stars);
    state = <int, LevelProgress>{...state, level: updated};
    return _repo.save(updated);
  }

  /// Wipes all progress (settings screen "Reset progress"). State updates at
  /// once; the returned future completes when storage is cleared.
  Future<void> resetAll() {
    state = <int, LevelProgress>{
      for (var level = 1; level <= totalLevels; level++)
        level: LevelProgress.empty(level),
    };
    return _repo.clearAll();
  }

  /// Stars earned across all levels (out of [totalLevels] × 3).
  int get totalStars => state.values.fold(0, (sum, p) => sum + p.stars);

  /// Levels cleared at least once.
  int get levelsCleared => state.values.where((p) => p.completed).length;

  /// Level 1 is always open; each later level unlocks once the previous is
  /// cleared. The debug ("Arrow Testing") build unlocks everything.
  bool isUnlocked(int level) => _unlockAll || unlockedByProgress(level);

  /// Whether the board's grid-lines toggle has been earned (clearing level
  /// [kGridLinesUnlockAfterLevel]); always true in the testing build.
  bool get gridLinesUnlocked =>
      _unlockAll || progressFor(kGridLinesUnlockAfterLevel).completed;

  /// The pure unlock rule (ignores debug-mode overrides).
  bool unlockedByProgress(int level) =>
      level <= 1 || progressFor(level - 1).completed;

  /// The furthest level open by linear progress (a "Continue" target).
  int get highestUnlocked {
    var highest = 1;
    for (var level = 2; level <= totalLevels; level++) {
      if (progressFor(level - 1).completed) highest = level;
    }
    return highest;
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final progressProvider =
    StateNotifierProvider<ProgressNotifier, Map<int, LevelProgress>>(
  (ref) => ProgressNotifier(ref.watch(progressRepositoryProvider)),
);
