import 'package:arrow_game/models/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stars: flawless 3, one slip 2, two slips 1', () {
    expect(starsForMistakes(0), 3);
    expect(starsForMistakes(1), 2);
    expect(starsForMistakes(2), 1);
    expect(starsForMistakes(3), 0);
    expect(starsForMistakes(9), 0);
  });

  test('empty progress', () {
    final p = LevelProgress.empty(4);
    expect(p.level, 4);
    expect(p.completed, isFalse);
    expect(p.stars, 0);
    expect(p.bestTimeMs, isNull);
    expect(p.timesCompleted, 0);
    expect(p.isNewBest(1), isTrue);
  });

  test('withCompletion keeps the best time and the most stars', () {
    final first = LevelProgress.empty(1).withCompletion(20000, 2);
    expect(first.completed, isTrue);
    expect(first.stars, 2);
    expect(first.bestTimeMs, 20000);
    expect(first.timesCompleted, 1);

    final worse = first.withCompletion(25000, 1);
    expect(worse.stars, 2);
    expect(worse.bestTimeMs, 20000);
    expect(worse.timesCompleted, 2);

    final better = worse.withCompletion(15000, 3);
    expect(better.stars, 3);
    expect(better.bestTimeMs, 15000);
    expect(better.isNewBest(15000), isFalse);
    expect(better.isNewBest(14999), isTrue);
  });

  test('value equality', () {
    final a = LevelProgress.empty(2).withCompletion(1000, 3);
    final b = LevelProgress.empty(2).withCompletion(1000, 3);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(LevelProgress.empty(2)));
  });
}
