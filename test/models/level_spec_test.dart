import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derived values', () {
    const s = LevelSpec(level: 3, width: 5, height: 6, arrows: 4, minLength: 2, maxLength: 4, timeLimitMs: 90000);
    expect(s.cellCount, 30);
    expect(s.seed, 3 * 7919 + 17);
    expect(s.toString(), 'LevelSpec(3: 5x6, 4 arrows, 90000ms)');
  });

  test('a variant re-deals the level without moving any other', () {
    const first = LevelSpec(level: 3, width: 5, height: 6, arrows: 4, minLength: 2, maxLength: 4, timeLimitMs: 90000);
    const again = LevelSpec(level: 3, width: 5, height: 6, arrows: 4, minLength: 2, maxLength: 4, timeLimitMs: 90000, variant: 2);
    expect(first.variant, 0);
    expect(again.seed, isNot(first.seed));
    // Far outside the range the level numbers reach, so no level's variant
    // lands on another level's board.
    expect((again.seed - first.seed).abs(), greaterThan(100 * 7919));
  });

  test('rejects nonsense', () {
    expect(
      () => LevelSpec(level: 1, width: 4, height: 4, arrows: 1, minLength: 2, maxLength: 2, timeLimitMs: 1000, variant: -1),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => LevelSpec(level: 1, width: 2, height: 4, arrows: 1, minLength: 2, maxLength: 2, timeLimitMs: 1000),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => LevelSpec(level: 1, width: 4, height: 4, arrows: 1, minLength: 3, maxLength: 2, timeLimitMs: 1000),
      throwsA(isA<AssertionError>()),
    );
  });
}
