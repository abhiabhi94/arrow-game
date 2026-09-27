import 'dart:math';

import 'package:arrow_game/data/riddle_bank.dart';
import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/riddle_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return SharedPreferences.getInstance();
}

RiddleDeckNotifier _deck(SharedPreferences prefs, {int seed = 7}) =>
    RiddleDeckNotifier(RiddleDeckRepository(prefs), random: Random(seed));

void main() {
  test('deals the whole bank before dealing any riddle twice', () async {
    final deck = _deck(await _prefs());
    final dealt = <int>[for (var i = 0; i < kRiddleCount; i++) deck.draw()];
    expect(dealt.toSet(), hasLength(kRiddleCount));
    expect(deck.state.remaining, 0);
  });

  test('reshuffles when the pack runs out, never twice in a row', () async {
    final deck = _deck(await _prefs());
    var last = 0;
    for (var i = 0; i < kRiddleCount; i++) {
      last = deck.draw();
    }
    final first = deck.draw();
    expect(first, isNot(last));
    expect(deck.state.remaining, kRiddleCount - 1);
  });

  test('picks up where it left off after a restart', () async {
    final prefs = await _prefs();
    final deck = _deck(prefs);
    final dealt = <int>[deck.draw(), deck.draw(), deck.draw()];
    await Future<void>.delayed(Duration.zero);

    final reopened = _deck(prefs, seed: 99);
    expect(reopened.state.cursor, 3);
    expect(reopened.state.order.take(3), dealt);
    // And carries on down the same pack rather than re-dealing.
    expect(dealt, isNot(contains(reopened.draw())));
  });

  test('a stored pack that is not the bank is thrown away', () async {
    for (final stored in <List<String>>[
      <String>['1', '2', '4'], // a hole in it
      <String>[for (var i = 0; i <= kRiddleCount; i++) '${i + 1}'], // a longer bank
      <String>[for (var i = 0; i < kRiddleCount; i++) '1'], // not a permutation
      <String>[for (var i = 0; i < kRiddleCount; i++) 'seven'], // not even ids
    ]) {
      final prefs = await _prefs(<String, Object>{RiddleDeckRepository.orderKey: stored});
      final deck = _deck(prefs);
      expect(deck.state.order.toSet(), hasLength(kRiddleCount));
      expect(deck.state.order.toSet(), contains(kRiddleCount));
    }
  });

  test('a pack from a smaller bank keeps its dealt riddles and shuffles the new ones in', () async {
    final prefs = await _prefs(<String, Object>{
      RiddleDeckRepository.orderKey: <String>[for (var i = 100; i >= 1; i--) '$i'],
      RiddleDeckRepository.cursorKey: 40,
    });
    final deck = _deck(prefs);
    // The same forty are behind the cursor, in the order they were dealt…
    expect(deck.state.cursor, 40);
    expect(deck.state.order.take(40), <int>[for (var i = 100; i > 60; i--) i]);
    // …and the rest of the pack is every riddle not yet seen, the new ones
    // mixed in rather than tacked onto the end.
    final rest = <int>[
      for (var i = 0; i < kRiddleCount - 40; i++) deck.draw(),
    ];
    expect(rest.toSet(), <int>{for (var i = 1; i <= 60; i++) i, for (var i = 101; i <= kRiddleCount; i++) i});
    expect(rest.take(60).where((id) => id > 100), isNotEmpty);
    expect(deck.state.remaining, 0);
  });

  test('a cursor past the end of the pack still deals', () async {
    final prefs = await _prefs(<String, Object>{RiddleDeckRepository.cursorKey: 9999});
    final deck = _deck(prefs);
    expect(deck.state.cursor, lessThanOrEqualTo(kRiddleCount));
    expect(deck.draw(), inInclusiveRange(1, kRiddleCount));
  });

  test('counts the riddles cracked, and remembers the tally', () async {
    final prefs = await _prefs();
    final deck = _deck(prefs);
    expect(deck.state.solved, 0);
    deck
      ..recordSolved()
      ..recordSolved();
    await Future<void>.delayed(Duration.zero);
    expect(deck.state.solved, 2);
    expect(_deck(prefs).state.solved, 2);
  });

  test('a reset deals a fresh pack and forgets the tally', () async {
    final prefs = await _prefs();
    final deck = _deck(prefs)
      ..draw()
      ..draw()
      ..recordSolved();
    await Future<void>.delayed(Duration.zero);

    deck.reset();
    await Future<void>.delayed(Duration.zero);
    expect(deck.state.cursor, 0);
    expect(deck.state.solved, 0);
    expect(prefs.getStringList(RiddleDeckRepository.orderKey), isNull);
    expect(prefs.getInt(RiddleDeckRepository.solvedKey), isNull);
  });

  test('the provider wires the deck to shared preferences', () async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(await _prefs())],
    );
    addTearDown(container.dispose);
    expect(container.read(riddleDeckProvider).order, hasLength(kRiddleCount));
    expect(container.read(riddleDeckProvider.notifier).draw(), inInclusiveRange(1, kRiddleCount));
    expect(container.read(riddleDeckProvider).cursor, 1);
  });
}
