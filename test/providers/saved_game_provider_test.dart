import 'dart:convert';

import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/saved_game.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/sample_puzzle.dart';

Future<ProviderContainer> _container(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

const _saved = SavedGame(level: 3, removed: [1], mistakes: 0, hintsLeft: 3, elapsedMs: 4000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('repository saves, loads and clears the slot; junk reads as empty', () async {
    final container = await _container({});
    final repo = container.read(savedGameRepositoryProvider);
    expect(repo.load(), isNull);
    await repo.save(_saved);
    expect(repo.load(), _saved);
    final prefs = container.read(sharedPreferencesProvider);
    expect(jsonDecode(prefs.getString(SavedGameRepository.key)!), _saved.toJson());
    await repo.clear();
    expect(repo.load(), isNull);
    await prefs.setString(SavedGameRepository.key, '[1, 2]');
    expect(repo.load(), isNull);
  });

  test('the notifier starts from storage and answers for its level only', () async {
    final container = await _container({SavedGameRepository.key: jsonEncode(_saved.toJson())});
    final notifier = container.read(savedGameProvider.notifier);
    expect(container.read(savedGameProvider), _saved);
    expect(notifier.forLevel(3), _saved);
    expect(notifier.forLevel(4), isNull);
  });

  test('record: progress saves, an ending clears, an untouched other level is left alone', () async {
    final container = await _container({SavedGameRepository.key: jsonEncode(_saved.toJson())});
    final notifier = container.read(savedGameProvider.notifier);
    final repo = container.read(savedGameRepositoryProvider);

    // Level 1 opened and left untouched: level 3's game stays.
    await notifier.record(GameState.fresh(sampleSpecFor(1), samplePuzzle()));
    expect(repo.load(), _saved);
    // Nothing to record while loading.
    await notifier.record(GameState.loading(sampleSpecFor(1)));
    expect(repo.load(), _saved);

    // A move on level 1 takes the slot.
    final moved = GameState.fresh(sampleSpecFor(1), samplePuzzle()).copyWith(removed: const {0}, elapsedMs: 900);
    await notifier.record(moved);
    expect(repo.load(), SavedGame.fromState(moved));
    expect(container.read(savedGameProvider)?.level, 1);

    // Level 1 restarted (fresh again): the stale slot for level 1 goes.
    await notifier.record(GameState.fresh(sampleSpecFor(1), samplePuzzle()));
    expect(repo.load(), isNull);

    // An ending clears too.
    await notifier.record(moved);
    await notifier.record(moved.copyWith(phase: GamePhase.cleared));
    expect(repo.load(), isNull);
    expect(container.read(savedGameProvider), isNull);
  });
}
