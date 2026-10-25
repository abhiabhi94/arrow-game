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

    test('the grid-lines toggle is earned by clearing level 4', () async {
      final n = ProgressNotifier(ProgressRepository(await _prefs()), unlockAllLevels: false);
      expect(kGridLinesUnlockAfterLevel, 4);
      expect(n.gridLinesUnlocked, isFalse);
      await n.recordCompletion(3, 1000, 3);
      expect(n.gridLinesUnlocked, isFalse);
      await n.recordCompletion(4, 1000, 1);
      expect(n.gridLinesUnlocked, isTrue);
      final testing = ProgressNotifier(ProgressRepository(await _prefs()), unlockAllLevels: true);
      expect(testing.gridLinesUnlocked, isTrue);
      n.dispose();
      testing.dispose();
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

  group('moving to the new trail', () {
    /// Old-trail progress: levels 1..[upTo] cleared, two stars each and a
    /// best time of a minute.
    Map<String, Object> oldTrail(int upTo) => <String, Object>{
          for (var level = 1; level <= upTo; level++) ...{
            'arrow_level_${level}_done': true,
            'arrow_level_${level}_stars': level.isEven ? 3 : 2,
            'arrow_level_${level}_best': 60000 + level,
            'arrow_level_${level}_count': 1,
          },
        };

    test('each new level stands in for an old one', () {
      expect(ProgressRepository.oldLevelFor(1), 1);
      expect(ProgressRepository.oldLevelFor(7), 7);
      expect(ProgressRepository.oldLevelFor(8), 9);
      expect(ProgressRepository.oldLevelFor(10), 15);
      // Mirrors: its teaching board, then every other level of the climb.
      expect(ProgressRepository.oldLevelFor(11), 21);
      expect(ProgressRepository.oldLevelFor(12), 24);
      expect(ProgressRepository.oldLevelFor(20), 40);
      expect(ProgressRepository.oldLevelFor(41), 81);
      expect(ProgressRepository.oldLevelFor(50), 100);
    });

    test('a player keeps their place: halfway through the old Mirrors is halfway through the new', () async {
      final prefs = await _prefs(oldTrail(30));
      final repo = ProgressRepository(prefs);
      await repo.migrateLayout();
      final n = ProgressNotifier(repo, unlockAllLevels: false);
      // Old 1..20 (Lines) → new 1..10; old 21..30 → new 11..15.
      expect(n.levelsCleared, 15);
      expect(n.highestUnlocked, 16);
      expect(n.progressFor(16).completed, isFalse);
      // Stars come across; a best time only where the board did.
      expect(n.progressFor(12).stars, 3); // old 24
      expect(n.progressFor(3).bestTimeMs, 60003);
      expect(n.progressFor(9).bestTimeMs, isNull);
      expect(n.progressFor(9).timesCompleted, 1);
      // Nothing old carries onto the block.
      expect(prefs.getBool('arrow_level_30_done'), isNull);
      expect(prefs.getInt(ProgressRepository.layoutKey), ProgressRepository.kTrailLayout);
      n.dispose();
    });

    test('runs once, and a fresh install only notes the layout', () async {
      final prefs = await _prefs(oldTrail(20));
      final repo = ProgressRepository(prefs);
      await repo.migrateLayout();
      // Played on the new trail since: level 11 cleared.
      await repo.save(repo.load(11).withCompletion(1000, 3));
      await repo.migrateLayout();
      expect(repo.load(10).completed, isTrue);
      expect(repo.load(11).completed, isTrue);

      final fresh = await _prefs();
      await ProgressRepository(fresh).migrateLayout();
      expect(fresh.getKeys(), {ProgressRepository.layoutKey});
    });

    test('a level left half-played on a board that has moved is dropped, one that has not is kept', () async {
      final moved = await _prefs(<String, Object>{
        ...oldTrail(12),
        'arrow_saved_game': '{"level":13,"seed":102964,"removed":[0],"mistakes":0,"hintsLeft":3,"elapsedMs":100}',
        'arrow_riddle_open': '13:life:4:en',
      });
      await ProgressRepository(moved).migrateLayout();
      expect(moved.getString('arrow_saved_game'), isNull);
      expect(moved.getString('arrow_riddle_open'), isNull);

      final kept = await _prefs(<String, Object>{
        ...oldTrail(4),
        'arrow_saved_game': '{"level":5,"seed":39612,"removed":[0],"mistakes":0,"hintsLeft":3,"elapsedMs":100}',
        'arrow_riddle_open': '5:life:4:en',
      });
      await ProgressRepository(kept).migrateLayout();
      expect(kept.getString('arrow_saved_game'), isNotNull);
      expect(kept.getString('arrow_riddle_open'), isNotNull);
    });
  });
}
