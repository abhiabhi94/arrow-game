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

  test("a chapter's first level owes its card until it is dismissed", () async {
    final n = await _notifier();
    expect(n.due(level: 1), isEmpty);
    expect(n.due(level: 20), isEmpty);
    expect(n.due(level: 21), [ChapterRule.mirrors]);
    expect(n.due(level: 41), [ChapterRule.locks]);
    expect(n.due(level: 101), [ChapterRule.cube]);
    // Only a chapter's first level: a player past it is not caught up.
    expect(n.due(level: 46), isEmpty);
    expect(n.due(level: 150), isEmpty);
    // The squeeze and the box have no card.
    expect(n.due(level: 151), isEmpty);
    expect(n.due(level: 201), isEmpty);
    // The daily board brings the card of the chapter it borrows from.
    expect(n.due(chapter: chapters[1]), [ChapterRule.mirrors]);
    expect(n.due(chapter: chapters[2]), [ChapterRule.locks]);
    expect(n.due(chapter: chapters[0]), isEmpty);
    expect(n.due(), isEmpty);
    n.markSeen(ChapterRule.mirrors);
    expect(n.due(level: 21), isEmpty);
    expect(n.due(chapter: chapters[1]), isEmpty);
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
