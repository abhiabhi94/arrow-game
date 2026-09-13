import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kinds lists plain first, then only the twists with a chance', () {
    const plain = LevelSpec(level: 1, targetHits: 5, timeLimitMs: 1000);
    expect(plain.kinds, [ArrowKind.normal]);
    expect(plain.hasFuse, isFalse);

    const all = LevelSpec(
      level: 2,
      targetHits: 5,
      timeLimitMs: 1000,
      reverseChance: 0.1,
      ghostChance: 0.1,
      decoyChance: 0.1,
      arrowTimeoutMs: 1500,
    );
    expect(all.kinds, ArrowKind.values);
    expect(all.hasFuse, isTrue);
  });

  test('secondsPerArrow and toString', () {
    const s = LevelSpec(level: 3, targetHits: 10, timeLimitMs: 30000);
    expect(s.secondsPerArrow, 3.0);
    expect(s.toString(), 'LevelSpec(3: 10 in 30000ms)');
  });

  test('rejects chances that leave no room for plain arrows', () {
    expect(
      () => LevelSpec(
        level: 1,
        targetHits: 5,
        timeLimitMs: 1000,
        reverseChance: 0.6,
        ghostChance: 0.6,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
