/// Level progress state: completion, stars, best times, unlock progression.
/// Persisted via shared_preferences with app-prefixed keys.
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapters.dart';
import '../data/level_specs.dart';
import '../models/level_progress.dart';
import '../models/riddle.dart';
import 'app_providers.dart';
import 'riddle_provider.dart';
import 'saved_game_provider.dart';

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

  /// Which layout of the trail the stored progress is for: absent for the
  /// first (five chapters of twenty), [kTrailLayout] once moved over.
  static const String layoutKey = 'arrow_trail_layout';

  /// The trail's current layout: five flat chapters of ten, then the block.
  static const int kTrailLayout = 2;

  /// Moves progress recorded on the old trail — five chapters of twenty
  /// levels — onto the new one, once. Each new level takes the standing of
  /// the old level it stands in for ([oldLevelFor]), so a player keeps their
  /// place: halfway through the old Mirrors is halfway through the new. The
  /// block (51–100) is new, so nothing carries onto it. Stars and clear
  /// counts come across; a best time only where the board did (levels 1–7,
  /// dealt as before), since a time on another board says nothing here. A
  /// game left half-played on a level whose board has moved is dropped, and
  /// so is a riddle left open on one. Takes effect in memory at once; run
  /// from `main()` before anything reads the progress or the saved game.
  Future<void> migrateLayout() async {
    if (_prefs.getInt(layoutKey) == kTrailLayout) return;
    final old = <int, LevelProgress>{
      for (var level = 1; level <= totalLevels; level++) level: load(level),
    };
    final moved = <LevelProgress>[
      for (var level = 1; level < kFirstCubeLevel; level++)
        if (old[oldLevelFor(level)]! case final was when was.completed)
          LevelProgress(
            level: level,
            completed: true,
            stars: was.stars,
            bestTimeMs: level <= kUnmovedLevels ? was.bestTimeMs : null,
            timesCompleted: was.timesCompleted,
          ),
    ];
    await _prefs.setInt(layoutKey, kTrailLayout);
    if (old.values.every((p) => !p.completed)) return;
    await clearAll();
    for (final p in moved) {
      await save(p);
    }
    final saved = SavedGameRepository(_prefs).load();
    if (saved != null && saved.level > kUnmovedLevels) await SavedGameRepository(_prefs).clear();
    final riddle = _prefs.getString(RiddleDeckRepository.openKey);
    if (riddle != null && (OpenRiddle.decode(riddle)?.level ?? totalLevels) > kUnmovedLevels) {
      await _prefs.remove(RiddleDeckRepository.openKey);
    }
  }

  /// The levels whose boards did not move with the new layout.
  static const int kUnmovedLevels = 7;

  /// The level of the old trail (five chapters of twenty) that new [level]
  /// (1..50) stands in for: the same level for 1–7, then old 9, 12 and 15
  /// for the rest of Lines; in each later chapter its teaching board, and
  /// for the climb every other level (the new chapter's 2nd level is the
  /// old one's 4th, its 10th the old 20th).
  static int oldLevelFor(int level) {
    if (level <= kUnmovedLevels) return level;
    if (level <= 10) return const <int>[9, 12, 15][level - 8];
    final chapter = (level - 1) ~/ 10; // 1..4
    final i = (level - 1) % 10 + 1; // 1..10
    return chapter * 20 + (i == 1 ? 1 : 2 * i);
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
