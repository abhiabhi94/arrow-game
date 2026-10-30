import 'package:arrow_game/data/chapters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// The five flat chapters, 1-100. The block, the squeeze and the box are in
// levels_*_test.dart beside this file, split so the deals run in parallel.
void main() {
  levelChecks(from: 1, to: 100);

  test('each chapter is a harder find than the one before, taken as a whole', () {
    // The hunt — arrows on the board for every one that can go at a typical
    // moment — climbs chapter by chapter over the climb levels, even as the
    // count no longer runs away: the twists tangle the graph as much as
    // more arrows did.
    double hunt(Chapter c) {
      var sum = 0.0;
      var n = 0;
      for (var level = c.firstLevel + 1; level <= c.lastLevel - 1; level++) {
        final i = (level - 1) % kChapterLength + 1;
        if (i == 5 || i == 15 || i == 10) continue;
        sum += dealtLevel(level).arrowsPerOpenMove;
        n++;
      }
      return sum / n;
    }

    final first = hunt(chapters[0]);
    var before = hunt(chapters[1]);
    expect(before, greaterThan(first));
    for (final chapter in chapters.skip(2).where((c) => !c.rule.onBlock)) {
      final now = hunt(chapter);
      expect(now, greaterThan(before * 0.9), reason: 'chapter ${chapter.index}');
      before = now;
    }
  });
}
