import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/utils/perf_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a page opened at ?level=N opens level N, when allowed and N is a level', () {
    Uri page(String query) => Uri.parse('https://example.org/arrow/?$query');
    expect(startLevelFrom(page('perf&level=250'), allowed: true), 250);
    expect(startLevelFrom(page('level=1'), allowed: true), 1);
    // Not in the store build, and never a level that does not exist.
    expect(startLevelFrom(page('perf&level=250'), allowed: false), isNull);
    expect(startLevelFrom(page('level=0'), allowed: true), isNull);
    expect(startLevelFrom(page('level=${totalLevels + 1}'), allowed: true), isNull);
    expect(startLevelFrom(page('level=two'), allowed: true), isNull);
    expect(startLevelFrom(page('perf'), allowed: true), isNull);
  });

  test('the hooks are off off the web', () {
    expect(perfHooksOn, isFalse);
    perfMark('nothing'); // prints nothing, throws nothing
    reportFrameTimings(); // registers nothing
  });
}
