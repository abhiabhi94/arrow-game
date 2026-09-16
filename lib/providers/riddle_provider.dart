/// The riddle deck: which riddle comes up next when a player spends their
/// last life and asks to carry on.
///
/// A deck rather than a dice roll — the ids are shuffled once and dealt in
/// order, so every riddle in the bank comes up before any of them comes up
/// twice. The order and the position in it are persisted, so closing the app
/// mid-run does not reshuffle the pack and hand back the riddle just seen.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/riddle_bank.dart';
import 'app_providers.dart';

/// A shuffled pack of riddle ids, a position in it, and the tally of riddles
/// cracked so far (the card wears it as a badge). Immutable.
class RiddleDeck {
  const RiddleDeck({required this.order, required this.cursor, required this.solved});

  final List<int> order;

  /// How many of [order] have been dealt.
  final int cursor;

  /// Riddles answered right, ever. Bragging rights only.
  final int solved;

  /// How many are left before the pack is reshuffled.
  int get remaining => order.length - cursor;

  RiddleDeck copyWith({List<int>? order, int? cursor, int? solved}) => RiddleDeck(
    order: order ?? this.order,
    cursor: cursor ?? this.cursor,
    solved: solved ?? this.solved,
  );
}

class RiddleDeckRepository {
  RiddleDeckRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String orderKey = 'arrow_riddle_order';
  static const String cursorKey = 'arrow_riddle_cursor';
  static const String solvedKey = 'arrow_riddles_solved';

  /// The stored pack, or null when there isn't a usable one. A pack that is
  /// not a permutation of the bank (an older, shorter bank; a hand-edited
  /// preference) is thrown away rather than patched.
  List<int>? loadOrder() {
    final raw = _prefs.getStringList(orderKey);
    if (raw == null || raw.length != kRiddleCount) return null;
    final ids = <int>[];
    for (final entry in raw) {
      final id = int.tryParse(entry);
      if (id == null) return null;
      ids.add(id);
    }
    final expected = <int>{for (var i = 1; i <= kRiddleCount; i++) i};
    return ids.toSet().containsAll(expected) ? ids : null;
  }

  int loadCursor() => _prefs.getInt(cursorKey) ?? 0;

  int loadSolved() => _prefs.getInt(solvedKey) ?? 0;

  Future<void> save(RiddleDeck deck) async {
    await _prefs.setStringList(orderKey, deck.order.map((id) => '$id').toList());
    await _prefs.setInt(cursorKey, deck.cursor);
    await _prefs.setInt(solvedKey, deck.solved);
  }

  Future<void> clear() async {
    await _prefs.remove(orderKey);
    await _prefs.remove(cursorKey);
    await _prefs.remove(solvedKey);
  }
}

class RiddleDeckNotifier extends StateNotifier<RiddleDeck> {
  factory RiddleDeckNotifier(RiddleDeckRepository repo, {Random? random}) {
    final rng = random ?? Random();
    final order = repo.loadOrder() ?? _shuffled(rng);
    return RiddleDeckNotifier._(
      repo,
      rng,
      RiddleDeck(
        order: order,
        // A cursor from a pack that is no longer there would deal nothing.
        cursor: repo.loadCursor().clamp(0, order.length),
        solved: repo.loadSolved(),
      ),
    );
  }

  RiddleDeckNotifier._(this._repo, this._random, RiddleDeck initial) : super(initial);

  final RiddleDeckRepository _repo;
  final Random _random;

  static List<int> _shuffled(Random random) =>
      <int>[for (var i = 1; i <= kRiddleCount; i++) i]..shuffle(random);

  /// Deals the next riddle id, reshuffling when the pack runs out. The new
  /// pack never opens with the riddle the old one closed on.
  int draw() {
    var order = state.order;
    var cursor = state.cursor;
    if (cursor >= order.length) {
      final last = order.last;
      order = _shuffled(_random);
      if (order.first == last && order.length > 1) {
        order = <int>[...order.skip(1), order.first];
      }
      cursor = 0;
    }
    final id = order[cursor];
    _update(state.copyWith(order: order, cursor: cursor + 1));
    return id;
  }

  /// One more riddle cracked.
  void recordSolved() => _update(state.copyWith(solved: state.solved + 1));

  /// Back to a fresh pack and a zero tally (a progress reset).
  void reset() {
    state = RiddleDeck(order: _shuffled(_random), cursor: 0, solved: 0);
    _repo.clear();
  }

  void _update(RiddleDeck next) {
    state = next;
    _repo.save(next);
  }
}

final riddleDeckRepositoryProvider = Provider<RiddleDeckRepository>(
  (ref) => RiddleDeckRepository(ref.watch(sharedPreferencesProvider)),
);

final riddleDeckProvider = StateNotifierProvider<RiddleDeckNotifier, RiddleDeck>(
  (ref) => RiddleDeckNotifier(ref.watch(riddleDeckRepositoryProvider)),
);
