/// The daily board's standing: the salt that makes this install's boards its
/// own, which chapter today's board was dealt in, today's best clear, and
/// the streak of days in a row with a clear. Persisted with `arrow_daily_*`
/// keys.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chapters.dart';
import '../data/daily.dart';
import '../models/level_spec.dart';
import 'app_providers.dart';
import 'progress_provider.dart';

/// What the home screen shows for the daily board.
class DailyStanding {
  const DailyStanding({
    required this.day,
    required this.chapter,
    required this.streak,
    required this.lastClearedDay,
    required this.bestTodayMs,
    required this.starsToday,
  });

  /// Today, as [dayIndexOf] counts it.
  final int day;

  /// The chapter today's board is dealt in — fixed the first time the day's
  /// board is looked at, so clearing a level mid-day does not re-deal it.
  final Chapter chapter;

  /// Days in a row ending today or yesterday with a clear.
  final int streak;
  final int? lastClearedDay;
  final int? bestTodayMs;
  final int starsToday;

  bool get clearedToday => bestTodayMs != null;

  /// The streak as the home screen says it: a run that ended before
  /// yesterday is over.
  int get liveStreak =>
      lastClearedDay != null && lastClearedDay! >= day - 1 ? streak : 0;
}

class DailyRepository {
  DailyRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String saltKey = 'arrow_daily_salt';
  static const String streakKey = 'arrow_daily_streak';
  static const String lastKey = 'arrow_daily_last';
  static String chapterKey(int day) => 'arrow_daily_${day}_chapter';
  static String bestKey(int day) => 'arrow_daily_${day}_best';
  static String starsKey(int day) => 'arrow_daily_${day}_stars';

  /// The install's salt, drawn once and kept.
  int loadSalt(Random random) {
    final stored = _prefs.getInt(saltKey);
    if (stored != null) return stored;
    final salt = random.nextInt(1 << 30);
    _prefs.setInt(saltKey, salt);
    return salt;
  }

  int? chapterFor(int day) => _prefs.getInt(chapterKey(day));
  Future<void> saveChapter(int day, int index) => _prefs.setInt(chapterKey(day), index);

  DailyStanding load(int day, Chapter chapter) => DailyStanding(
        day: day,
        chapter: chapter,
        streak: _prefs.getInt(streakKey) ?? 0,
        lastClearedDay: _prefs.getInt(lastKey),
        bestTodayMs: _prefs.getInt(bestKey(day)),
        starsToday: _prefs.getInt(starsKey(day)) ?? 0,
      );

  Future<void> save(DailyStanding s) async {
    await _prefs.setInt(streakKey, s.streak);
    final last = s.lastClearedDay;
    if (last != null) await _prefs.setInt(lastKey, last);
    final best = s.bestTodayMs;
    if (best != null) await _prefs.setInt(bestKey(s.day), best);
    await _prefs.setInt(starsKey(s.day), s.starsToday);
  }

  /// Wipes the standing (Settings → Reset progress). The salt stays: a reset
  /// is a fresh start, not a new phone.
  Future<void> clear() async {
    for (final key in _prefs.getKeys()) {
      if (key.startsWith('arrow_daily_') && key != saltKey) await _prefs.remove(key);
    }
  }
}

class DailyNotifier extends StateNotifier<DailyStanding> {
  DailyNotifier(
    this._repo, {
    required int Function() levelsCleared,
    DateTime Function()? clock,
    Random? random,
  })  : _levelsCleared = levelsCleared,
        _clock = clock ?? DateTime.now,
        salt = _repo.loadSalt(random ?? Random()),
        super(_load(_repo, levelsCleared, clock ?? DateTime.now));

  final DailyRepository _repo;
  final int Function() _levelsCleared;
  final DateTime Function() _clock;

  /// This install's salt.
  final int salt;

  static DailyStanding _load(DailyRepository repo, int Function() levelsCleared, DateTime Function() clock) {
    final day = dayIndexOf(clock());
    var index = repo.chapterFor(day);
    if (index == null) {
      index = chapterForProgress(levelsCleared()).index;
      repo.saveChapter(day, index);
    }
    return repo.load(day, chapters[index.clamp(1, chapters.length) - 1]);
  }

  /// Rolls the standing over to today if the day has changed since it was
  /// loaded (the app was left open overnight).
  void refresh() {
    if (dayIndexOf(_clock()) != state.day) state = _load(_repo, _levelsCleared, _clock);
  }

  /// Today's board.
  LevelSpec get spec => dailySpec(day: state.day, chapter: state.chapter, salt: salt);

  /// How long until the next board: local midnight.
  Duration get untilNextBoard {
    final now = _clock();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  /// Records a clear of today's board in [timeMs] with [stars]. The streak
  /// grows by one on the first clear of a day that follows a cleared day,
  /// restarts at one after a gap, and is untouched by a second clear.
  Future<void> recordCompletion(int timeMs, int stars) {
    refresh();
    final s = state;
    final first = !s.clearedToday;
    final streak = !first
        ? s.streak
        : (s.lastClearedDay == s.day - 1 ? s.streak + 1 : 1);
    final updated = DailyStanding(
      day: s.day,
      chapter: s.chapter,
      streak: streak,
      lastClearedDay: s.day,
      bestTodayMs: s.bestTodayMs == null ? timeMs : min(s.bestTodayMs!, timeMs),
      starsToday: max(s.starsToday, stars),
    );
    state = updated;
    return _repo.save(updated);
  }

  /// Wipes the standing and deals today again from the current progress.
  Future<void> reset() async {
    await _repo.clear();
    state = _load(_repo, _levelsCleared, _clock);
  }
}

final dailyRepositoryProvider = Provider<DailyRepository>(
  (ref) => DailyRepository(ref.watch(sharedPreferencesProvider)),
);

final dailyProvider = StateNotifierProvider<DailyNotifier, DailyStanding>(
  (ref) => DailyNotifier(
    ref.watch(dailyRepositoryProvider),
    levelsCleared: () => ref.read(progressProvider.notifier).levelsCleared,
  ),
);
