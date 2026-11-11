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
    // Two major versions after the chapters shipped, every such install has
    // had its chance: turn kIntroCatchUp off, delete the catch-up branch of
    // IntroNotifier.due and the tests of it, and this test with them.
    final version = RegExp(r'^version:\s*(\d+)\.', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!;
    final major = int.parse(version.group(1)!);
    expect(
      !kIntroCatchUp || major <= kIntroCatchUpLastMajor,
      isTrue,
      reason: 'version $major.x is past $kIntroCatchUpLastMajor.x: the chapter-card catch-up has had its '
          'two major versions. Remove it (kIntroCatchUp in lib/providers/intro_provider.dart).',
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
    // Each half of the Rush brings its card.
    expect(n.due(level: 101), [ChapterRule.mirrors, ChapterRule.locks, ChapterRule.fog, ChapterRule.pairs, ChapterRule.rush]);
    const throughRush = [
      ChapterRule.mirrors,
      ChapterRule.locks,
      ChapterRule.fog,
      ChapterRule.pairs,
      ChapterRule.rush,
      ChapterRule.rushBlocks,
    ];
    expect(n.due(level: 150), throughRush);
    // The block's card comes with the block, at 151.
    expect(n.due(level: 151), [...throughRush, ChapterRule.cube]);
    expect(n.due(level: 200), [...throughRush, ChapterRule.cube]);
    // The box has none: at level 250 still nothing more.
    expect(n.due(level: 250), [...throughRush, ChapterRule.cube]);
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
