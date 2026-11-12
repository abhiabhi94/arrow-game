import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/utils/level_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a link to a level is the public site with ?level=N off the web', () {
    expect('${levelLinkFor(42)}', 'https://abhiabhi94.github.io/arrow-game/?level=42');
  });

  test('in a browser the link keeps the page it was copied from', () {
    final here = Uri.parse('https://abhiabhi94.github.io/arrow-game/pr-preview/pr-41/?perf#/');
    expect('${levelLinkFor(7, here: here)}', 'https://abhiabhi94.github.io/arrow-game/pr-preview/pr-41/?level=7');
    expect('${levelLinkFor(3, here: Uri.parse('http://localhost:8080/'))}', 'http://localhost:8080/?level=3');
    // Not a page (a test, a file): the public site.
    expect('${levelLinkFor(3, here: Uri.parse('file:///tmp/x'))}', 'https://abhiabhi94.github.io/arrow-game/?level=3');
  });

  test('a link reads back to its level, before or after the #', () {
    expect(levelFromLink(levelLinkFor(150)), 150);
    expect(levelFromLink(Uri.parse('https://x.test/arrow-game/#/?level=12')), 12);
    expect(levelFromLink(Uri.parse('https://x.test/?level=$totalLevels')), totalLevels);
  });

  test('anything else is no level', () {
    for (final uri in [
      'https://x.test/',
      'https://x.test/?level=0',
      'https://x.test/?level=${totalLevels + 1}',
      'https://x.test/?level=abc',
      'https://x.test/#/home',
    ]) {
      expect(levelFromLink(Uri.parse(uri)), isNull, reason: uri);
    }
  });
}
