import 'dart:io';

import 'package:arrow_game/data/chapters.dart';
import 'package:arrow_game/providers/intro_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<IntroNotifier> _notifier([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return IntroNotifier(IntroRepository(await SharedPreferences.getInstance()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the catch-up is a bridge for installs from before the chapters, with a sunset', () {
    // Four releases after the chapters shipped, every such install has had
    // its chance: turn kIntroCatchUp off, delete the catch-up branch of
    // IntroNotifier.due and the tests of it, and this test with them.
    final version = RegExp(r'^version:\s*\S+\+(\d+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!;
    final build = int.parse(version.group(1)!);
    expect(
      !kIntroCatchUp || build <= kIntroCatchUpLastBuild,
      isTrue,
      reason: 'build $build is past $kIntroCatchUpLastBuild: the chapter-card catch-up has had its '
          'four releases. Remove it (kIntroCatchUp in lib/providers/intro_provider.dart).',
    );
  });

  test('every card at or before the level is owed, in trail order, until dismissed', () async {
    final n = await _notifier();
    expect(n.due(level: 1), isEmpty);
    expect(n.due(level: 20), isEmpty);
    expect(n.due(level: 21), [ChapterRule.mirrors]);
    expect(n.due(level: 46), [ChapterRule.mirrors, ChapterRule.locks]);
    expect(n.due(level: 65), [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog]);
    expect(n.due(level: 100), [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog, ChapterRule.pairs]);
    expect(
      n.due(level: 150),
      [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog, ChapterRule.pairs, ChapterRule.cube],
    );
    // The squeeze has no card: past level 150 nothing more is owed.
    expect(
      n.due(level: 200),
      [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog, ChapterRule.pairs, ChapterRule.cube],
    );
    // Nor has the box: at level 250 still nothing more.
    expect(
      n.due(level: 250),
      [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog, ChapterRule.pairs, ChapterRule.cube],
    );
    expect(n.due(chapter: chapters[2]), [ChapterRule.mirrors, ChapterRule.locks]);
    expect(n.due(), isEmpty);
    // A player who met Mirrors at 21 is shown only Locks at 41.
    n.markSeen(ChapterRule.mirrors);
    expect(n.due(level: 41), [ChapterRule.locks]);
    expect(n.due(level: 22), isEmpty);
    n.markSeen(ChapterRule.mirrors); // again: nothing changes
    expect(n.state, {ChapterRule.mirrors});
    n.dispose();
  });

  test('what was dismissed is kept, and a reset forgets it', () async {
    final n = await _notifier();
    n.markSeen(ChapterRule.locks);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(IntroRepository.key), ['locks']);
    final again = IntroNotifier(IntroRepository(prefs));
    expect(again.state, {ChapterRule.locks});
    again.reset();
    expect(again.state, isEmpty);
    expect(prefs.getStringList(IntroRepository.key), isNull);
    // An unknown name in the list is ignored.
    final odd = await _notifier({IntroRepository.key: ['fog', 'walls']});
    expect(odd.state, {ChapterRule.fog});
    n.dispose();
    again.dispose();
    odd.dispose();
  });
}
