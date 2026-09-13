/// The one level in progress, persisted so it survives closing the app,
/// switching away or backing out of the level. A single slot: starting to
/// play another level replaces it.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';
import '../models/saved_game.dart';
import 'app_providers.dart';

class SavedGameRepository {
  SavedGameRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String key = 'arrow_saved_game';

  SavedGame? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? SavedGame.fromJson(decoded) : null;
  }

  Future<void> save(SavedGame game) => _prefs.setString(key, jsonEncode(game.toJson()));

  Future<void> clear() => _prefs.remove(key);
}

class SavedGameNotifier extends StateNotifier<SavedGame?> {
  SavedGameNotifier(this._repo) : super(_repo.load());

  final SavedGameRepository _repo;

  /// The saved game for [level], if that is the one in the slot.
  SavedGame? forLevel(int level) => state?.level == level ? state : null;

  /// Records where [state] stands. A finished level clears the slot; a level
  /// with something done is saved; a level with nothing done yet clears the
  /// slot only if the slot was this same level (a restart, or an untouched
  /// visit), so peeking at another level never throws a saved one away.
  Future<void> record(GameState state) {
    // A game screen torn down with the whole app may report after this
    // notifier is gone; storage already has the last snapshot.
    if (!mounted || state.puzzle == null) return Future<void>.value();
    if (state.isOver) return clear();
    final snapshot = SavedGame.fromState(state);
    if (snapshot.hasProgress) {
      this.state = snapshot;
      return _repo.save(snapshot);
    }
    if (this.state?.level == state.level) return clear();
    return Future<void>.value();
  }

  Future<void> clear() {
    if (!mounted) return Future<void>.value();
    state = null;
    return _repo.clear();
  }
}

final savedGameRepositoryProvider = Provider<SavedGameRepository>(
  (ref) => SavedGameRepository(ref.watch(sharedPreferencesProvider)),
);

final savedGameProvider = StateNotifierProvider<SavedGameNotifier, SavedGame?>(
  (ref) => SavedGameNotifier(ref.watch(savedGameRepositoryProvider)),
);
