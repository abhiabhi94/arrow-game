import 'package:arrow_game/providers/app_providers.dart';
import 'package:arrow_game/providers/trail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('a chapter is open until it is cleared, unless the player says otherwise', () async {
    final c = await _container();
    final n = c.read(trailFoldProvider.notifier);
    expect(n.isOpen(1, allCleared: false), isTrue);
    expect(n.isOpen(1, allCleared: true), isFalse);
    n.toggle(1, allCleared: true);
    expect(n.isOpen(1, allCleared: true), isTrue);
    n.toggle(2, allCleared: false);
    expect(n.isOpen(2, allCleared: false), isFalse);
    expect(c.read(trailFoldProvider), {1: true, 2: false});
  });

  test('the folds are kept, and Reset progress puts them back', () async {
    final c = await _container(<String, Object>{
      TrailFoldRepository.key: <String>['3:1', '4:0', 'junk', 'x:1'],
    });
    final n = c.read(trailFoldProvider.notifier);
    expect(c.read(trailFoldProvider), {3: true, 4: false});
    n.toggle(4, allCleared: false);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getStringList(TrailFoldRepository.key), ['3:1', '4:1']);
    await n.reset();
    expect(c.read(trailFoldProvider), isEmpty);
    expect(prefs.getStringList(TrailFoldRepository.key), isNull);
  });
}
