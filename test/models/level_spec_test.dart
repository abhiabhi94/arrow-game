import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derived values', () {
    const s = LevelSpec(level: 3, width: 5, height: 6, arrows: 4, minLength: 2, maxLength: 4, timeLimitMs: 90000);
    expect(s.cellCount, 30);
    expect(s.seed, 3 * 7919 + 17);
    expect(s.toString(), 'LevelSpec(3: 5x6, 4 arrows, 90000ms)');
  });

  test('rejects nonsense', () {
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
