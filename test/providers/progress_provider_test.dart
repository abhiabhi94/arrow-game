import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressRepository', () {
    test('loads empty progress for every level', () async {
      final repo = ProgressRepository(await _prefs());
      final all = repo.loadAll();
      expect(all, hasLength(totalLevels));
      expect(all[1]!.completed, isFalse);
      expect(all[20]!.stars, 0);
    });

    test('round-trips a completion and can wipe it', () async {
      final prefs = await _prefs();
      final repo = ProgressRepository(prefs);
      await repo.save(repo.load(3).withCompletion(12345, 2));
      final loaded = ProgressRepository(prefs).load(3);
      expect(loaded.completed, isTrue);
      expect(loaded.stars, 2);
      expect(loaded.bestTimeMs, 12345);
      expect(loaded.timesCompleted, 1);

      await repo.clearAll();
      expect(ProgressRepository(prefs).load(3).completed, isFalse);
      expect(prefs.getKeys(), isEmpty);
    });
  });

  group('ProgressNotifier', () {
    test('locked progression: level 1 open, others need the previous cleared',
        () async {
      final n = ProgressNotifier(ProgressRepository(await _prefs()), unlockAllLevels: false);
      expect(n.isUnlocked(1), isTrue);
      expect(n.isUnlocked(2), isFalse);
      expect(n.isUnlocked(20), isFalse);
      expect(n.highestUnlocked, 1);

      n.recordCompletion(1, 20000, 3);
      expect(n.isUnlocked(2), isTrue);
      expect(n.isUnlocked(3), isFalse);
      expect(n.highestUnlocked, 2);
      expect(n.totalStars, 3);
      expect(n.levelsCleared, 1);
      n.dispose();
    });

    test('the testing build unlocks everything but keeps the pure rule',
        () async {
      final n = ProgressNotifier(ProgressRepository(await _prefs()), unlockAllLevels: true);
      expect(n.isUnlocked(20), isTrue);
      expect(n.unlockedByProgress(20), isFalse);
      expect(n.highestUnlocked, 1);
      n.dispose();
    });

    test('default unlock policy follows the build mode flag', () async {
      final n = ProgressNotifier(ProgressRepository(await _prefs()));
      expect(n.isUnlocked(20), testingUnlocksAllLevels);
      n.dispose();
    });

    test('records and persists completions, keeping the best', () async {
      final prefs = await _prefs();
      final n = ProgressNotifier(ProgressRepository(prefs), unlockAllLevels: false);
      await n.recordCompletion(1, 30000, 1);
      await n.recordCompletion(1, 20000, 3);
      final p = n.progressFor(1);
      expect(p.stars, 3);
      expect(p.bestTimeMs, 20000);
      expect(p.timesCompleted, 2);
      expect(prefs.getInt('arrow_level_1_best'), 20000);
      expect(prefs.getInt('arrow_level_1_stars'), 3);
      n.dispose();
    });

    test('resetAll wipes state and storage', () async {
      final prefs = await _prefs();
      final n = ProgressNotifier(ProgressRepository(prefs), unlockAllLevels: false);
      await n.recordCompletion(1, 30000, 3);
      await n.recordCompletion(2, 30000, 3);
      final wiped = n.resetAll();
      expect(n.totalStars, 0);
      expect(n.isUnlocked(2), isFalse);
      expect(n.state, hasLength(totalLevels));
      await wiped;
      expect(prefs.getKeys(), isEmpty);
      n.dispose();
    });

    test('the provider reads through the injected prefs', () async {
      final prefs = await _prefs(<String, Object>{
        'arrow_level_1_done': true,
        'arrow_level_1_stars': 2,
      });
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      expect(container.read(progressProvider)[1]!.stars, 2);
      expect(container.read(progressProvider.notifier).totalStars, 2);
    });
  });
}
