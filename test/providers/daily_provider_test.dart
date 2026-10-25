import 'dart:math';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/data/daily.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/daily_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

final _day = DateTime(2026, 10, 22, 9);
int get _today => dayIndexOf(_day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the salt is drawn once and kept', () async {
    final prefs = await _prefs();
    final repo = DailyRepository(prefs);
    final salt = repo.loadSalt(Random(1));
    expect(prefs.getInt(DailyRepository.saltKey), salt);
    expect(DailyRepository(prefs).loadSalt(Random(2)), salt);
    expect(DailyRepository(await _prefs()).loadSalt(Random(1)), salt);
  });

  test('today\'s chapter follows the levels cleared and is then fixed for the day', () async {
    final prefs = await _prefs();
    var cleared = 15;
    final n = DailyNotifier(
      DailyRepository(prefs),
      levelsCleared: () => cleared,
      clock: () => _day,
      random: Random(1),
    );
    expect(n.state.day, _today);
    expect(n.state.chapter.index, 2);
    expect(n.state.streak, 0);
    expect(n.state.liveStreak, 0);
    expect(n.state.clearedToday, isFalse);
    expect(n.spec.seed, dailySeed(_today, n.salt));
    expect(n.spec.features.mirrors, greaterThan(0));
    // More levels cleared later in the day do not re-deal the board.
    cleared = 35;
    n.refresh();
    expect(n.state.chapter.index, 2);
    final again = DailyNotifier(
      DailyRepository(prefs),
      levelsCleared: () => cleared,
      clock: () => _day,
    );
    expect(again.state.chapter.index, 2);
    expect(again.salt, n.salt);
    n.dispose();
    again.dispose();
  });

  test('on the block the daily board stays flat, with the last flat chapter\'s twists', () async {
    final prefs = await _prefs();
    final n = DailyNotifier(DailyRepository(prefs), levelsCleared: () => 80, clock: () => _day, random: Random(1));
    expect(n.state.chapter.index, 5);
    expect(n.spec.isCube, isFalse);
    expect(n.spec.features.pairs, greaterThan(0));
    n.dispose();
  });

  test('a clear records the best time and stars and grows the streak day by day', () async {
    final prefs = await _prefs();
    var now = _day;
    final n = DailyNotifier(
      DailyRepository(prefs),
      levelsCleared: () => 0,
      clock: () => now,
      random: Random(1),
    );
    await n.recordCompletion(200000, 2);
    expect(n.state.bestTodayMs, 200000);
    expect(n.state.starsToday, 2);
    expect(n.state.streak, 1);
    expect(n.state.liveStreak, 1);
    expect(n.state.lastClearedDay, _today);
    // A second clear the same day keeps the best of each, not the streak.
    await n.recordCompletion(250000, 3);
    expect(n.state.bestTodayMs, 200000);
    expect(n.state.starsToday, 3);
    expect(n.state.streak, 1);
    // The next day: a new board, the streak still alive, nothing cleared yet.
    now = _day.add(const Duration(days: 1));
    n.refresh();
    expect(n.state.day, _today + 1);
    expect(n.state.clearedToday, isFalse);
    expect(n.state.liveStreak, 1);
    await n.recordCompletion(180000, 1);
    expect(n.state.streak, 2);
    // Skip a day: the run is over, and a clear starts a new one.
    now = _day.add(const Duration(days: 3));
    n.refresh();
    expect(n.state.liveStreak, 0);
    expect(n.state.streak, 2);
    await n.recordCompletion(100000, 3);
    expect(n.state.streak, 1);
    // Reloading sees the same standing.
    final m = DailyNotifier(DailyRepository(prefs), levelsCleared: () => 0, clock: () => now);
    expect(m.state.streak, 1);
    expect(m.state.bestTodayMs, 100000);
    expect(m.state.starsToday, 3);
    n.dispose();
    m.dispose();
  });

  test('the time to the next board runs to local midnight', () async {
    var now = DateTime(2026, 10, 22, 9, 30);
    final n = DailyNotifier(
      DailyRepository(await _prefs()),
      levelsCleared: () => 0,
      clock: () => now,
      random: Random(1),
    );
    expect(n.untilNextBoard, const Duration(hours: 14, minutes: 30));
    now = DateTime(2026, 10, 22, 23, 59, 30);
    expect(n.untilNextBoard, const Duration(seconds: 30));
    n.dispose();
  });

  test('a clear after midnight counts for the new day', () async {
    var now = _day;
    final n = DailyNotifier(
      DailyRepository(await _prefs()),
      levelsCleared: () => 0,
      clock: () => now,
      random: Random(1),
    );
    now = _day.add(const Duration(days: 1));
    await n.recordCompletion(1000, 3);
    expect(n.state.day, _today + 1);
    expect(n.state.streak, 1);
    n.dispose();
  });

  test('reset wipes the standing but keeps the salt', () async {
    final prefs = await _prefs();
    final n = DailyNotifier(
      DailyRepository(prefs),
      levelsCleared: () => 50,
      clock: () => _day,
      random: Random(1),
    );
    await n.recordCompletion(1000, 3);
    final salt = n.salt;
    await n.reset();
    expect(n.state.streak, 0);
    expect(n.state.clearedToday, isFalse);
    expect(prefs.getInt(DailyRepository.saltKey), salt);
    expect(prefs.getKeys().where((k) => k.startsWith('arrow_daily_')), {DailyRepository.saltKey, DailyRepository.chapterKey(_today)});
    n.dispose();
  });

  test('dailyProvider reads the chapter off the progress', () async {
    final prefs = await _prefs({'arrow_level_1_done': true});
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(progressProvider.notifier).levelsCleared, 1);
    expect(container.read(dailyProvider).chapter, chapters.first);
    expect(container.read(dailyProvider.notifier).spec.isDaily, isTrue);
  });
}
