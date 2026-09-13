import 'dart:math';

import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/engine/arrow_factory.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

const _plain = LevelSpec(level: 1, targetHits: 10, timeLimitMs: 30000);
const _mixed = LevelSpec(
  level: 9,
  targetHits: 10,
  timeLimitMs: 30000,
  reverseChance: 0.3,
  ghostChance: 0.3,
  decoyChance: 0.3,
);

void main() {
  test('ids are sequential and reset on demand', () {
    final f = ArrowFactory(_plain, random: Random(1));
    expect(f.next().id, 0);
    expect(f.next().id, 1);
    expect(f.next().id, 2);
    f.reset();
    expect(f.next().id, 0);
  });

  test('a plain spec only deals plain arrows', () {
    final f = ArrowFactory(_plain, random: Random(2));
    for (var i = 0; i < 200; i++) {
      expect(f.next().kind, ArrowKind.normal);
    }
  });

  test('a mixed spec deals every kind at roughly its chance', () {
    final f = ArrowFactory(_mixed, random: Random(3));
    final counts = <ArrowKind, int>{};
    const n = 4000;
    for (var i = 0; i < n; i++) {
      final a = f.next();
      counts[a.kind] = (counts[a.kind] ?? 0) + 1;
      if (a.kind == ArrowKind.decoy) {
        expect(a.decoyLabel, isNotNull);
        expect(a.decoyLabel, isNot(a.direction));
      } else {
        expect(a.decoyLabel, isNull);
      }
    }
    for (final kind in [ArrowKind.reverse, ArrowKind.ghost, ArrowKind.decoy]) {
      expect(counts[kind]! / n, closeTo(0.3, 0.04), reason: '$kind');
    }
    expect(counts[ArrowKind.normal]! / n, closeTo(0.1, 0.03));
  });

  test('mostly avoids repeating the previous direction', () {
    final f = ArrowFactory(_plain, random: Random(4));
    var repeats = 0;
    Direction? last;
    const n = 2000;
    for (var i = 0; i < n; i++) {
      final d = f.next().direction;
      if (d == last) repeats++;
      last = d;
    }
    // Repeats happen only on the kRepeatDirectionChance roll, and then only
    // 1 in 4 of those land on the same direction again.
    expect(repeats / n, closeTo(kRepeatDirectionChance / 4, 0.03));
  });

  test('every direction shows up', () {
    final f = ArrowFactory(_plain, random: Random(5));
    final seen = <Direction>{for (var i = 0; i < 100; i++) f.next().direction};
    expect(seen, Direction.values.toSet());
  });
}
