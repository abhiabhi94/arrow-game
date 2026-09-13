import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('there are 20 levels, numbered 1..20 in order', () {
    expect(totalLevels, 20);
    expect(levelSpecs, hasLength(totalLevels));
    for (var i = 0; i < levelSpecs.length; i++) {
      expect(levelSpecs[i].level, i + 1);
      expect(specForLevel(i + 1), same(levelSpecs[i]));
    }
    expect(() => specForLevel(0), throwsRangeError);
    expect(() => specForLevel(21), throwsRangeError);
  });

  test('every level leaves at least 15% plain arrows', () {
    for (final s in levelSpecs) {
      expect(
        s.reverseChance + s.ghostChance + s.decoyChance,
        lessThanOrEqualTo(0.85 + 1e-9),
        reason: 'level ${s.level}',
      );
    }
  });

  test('the clock is reasonable: 30–45 s, and at least 0.9 s per arrow', () {
    for (final s in levelSpecs) {
      expect(s.timeLimitMs, inInclusiveRange(30000, 45000), reason: 'level ${s.level}');
      expect(s.secondsPerArrow, greaterThanOrEqualTo(0.9), reason: 'level ${s.level}');
    }
    expect(levelSpecs.first.secondsPerArrow, greaterThanOrEqualTo(2.5));
  });

  test('twists arrive in chapters and never leave', () {
    ArrowKind? firstKindAt(int level, ArrowKind kind) =>
        specForLevel(level).kinds.contains(kind) ? kind : null;
    expect(specForLevel(3).kinds, [ArrowKind.normal]);
    expect(firstKindAt(4, ArrowKind.reverse), ArrowKind.reverse);
    expect(specForLevel(6).hasFuse, isFalse);
    expect(specForLevel(7).hasFuse, isTrue);
    expect(specForLevel(9).kinds, isNot(contains(ArrowKind.ghost)));
    expect(firstKindAt(10, ArrowKind.ghost), ArrowKind.ghost);
    expect(specForLevel(12).kinds, isNot(contains(ArrowKind.decoy)));
    expect(firstKindAt(13, ArrowKind.decoy), ArrowKind.decoy);
    expect(specForLevel(20).kinds, ArrowKind.values);

    // Once a twist is in, it stays in for every later level.
    for (var level = 4; level <= totalLevels; level++) {
      expect(specForLevel(level).reverseChance, greaterThan(0), reason: 'level $level');
    }
    for (var level = 7; level <= totalLevels; level++) {
      expect(specForLevel(level).hasFuse, isTrue, reason: 'level $level');
    }
    for (var level = 10; level <= totalLevels; level++) {
      expect(specForLevel(level).ghostChance, greaterThan(0), reason: 'level $level');
    }
    for (var level = 13; level <= totalLevels; level++) {
      expect(specForLevel(level).decoyChance, greaterThan(0), reason: 'level $level');
    }
  });

  test('within a chapter the target climbs and the fuse tightens', () {
    const chapters = [[1, 3], [4, 6], [7, 9], [10, 12], [13, 15], [16, 20]];
    for (final c in chapters) {
      for (var level = c[0] + 1; level <= c[1]; level++) {
        final prev = specForLevel(level - 1);
        final cur = specForLevel(level);
        expect(cur.targetHits, greaterThan(prev.targetHits), reason: 'level $level');
        if (prev.hasFuse) {
          expect(cur.arrowTimeoutMs, lessThan(prev.arrowTimeoutMs), reason: 'level $level');
        }
      }
    }
  });

  test('a new twist arrives with a gentler pace than the level before it', () {
    for (final level in [7, 10, 13]) {
      expect(
        specForLevel(level).secondsPerArrow,
        greaterThan(specForLevel(level - 1).secondsPerArrow),
        reason: 'level $level',
      );
    }
  });

  test('a fuse always outlasts a ghost by a fair margin', () {
    for (final s in levelSpecs.where((s) => s.hasFuse && s.ghostChance > 0)) {
      expect(s.arrowTimeoutMs, greaterThanOrEqualTo(kGhostVisibleMs + 700), reason: 'level ${s.level}');
    }
  });

  test('the finale is the hardest on every axis', () {
    final first = specForLevel(1);
    final last = specForLevel(totalLevels);
    expect(last.targetHits, greaterThan(first.targetHits));
    expect(last.secondsPerArrow, lessThan(first.secondsPerArrow));
    expect(last.arrowTimeoutMs, lessThanOrEqualTo(levelSpecs.where((s) => s.hasFuse).map((s) => s.arrowTimeoutMs).reduce((a, b) => a < b ? a : b)));
  });
}
