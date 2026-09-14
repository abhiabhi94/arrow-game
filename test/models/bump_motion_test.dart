import 'package:arrow_game/engine/cell.dart';
import 'package:arrow_game/models/bump_motion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sample_puzzle.dart';

void main() {
  test('runs up to the blocker, stopping just short of its centre', () {
    // Arrow 2's ray is (1,1),(1,0); arrow 0 sits on (1,1): one step away.
    final m = BumpMotion.forTap(samplePuzzle(), 2, const Cell(1, 1));
    expect(m.travel, closeTo(1 - BumpMotion.kStopShort, 1e-9));
    expect(m.forwardMs, 180);
    expect(m.totalMs, m.forwardMs + BumpMotion.backMs);
    expect(m.impactAt, closeTo(180 / 660, 1e-9));
  });

  test('a long run takes longer to arrive, within bounds', () {
    expect(const BumpMotion(travel: 0.4).forwardMs, greaterThanOrEqualTo(180));
    expect(const BumpMotion(travel: 3.4).forwardMs, 378);
    expect(const BumpMotion(travel: 30).forwardMs, 460);
  });

  test('accelerates in, peaks at impact, eases home; the jolt follows', () {
    const m = BumpMotion(travel: 2.4);
    final impact = m.impactAt;
    expect(m.offsetAt(0), 0);
    expect(m.offsetAt(-1), 0);
    expect(m.offsetAt(impact / 2), lessThan(m.travel / 2)); // accelerating
    expect(m.offsetAt(impact), closeTo(m.travel, 1e-9));
    expect(m.offsetAt((1 + impact) / 2), inExclusiveRange(0, m.travel));
    expect(m.offsetAt(1), closeTo(0, 1e-9));
    for (var t = 0.0; t + 0.01 <= impact; t += 0.01) {
      expect(m.offsetAt(t + 0.01), greaterThanOrEqualTo(m.offsetAt(t)));
    }
    expect(m.shoveAt(impact / 2), 0);
    expect(m.flashAt(impact / 2), 0);
    expect(m.shoveAt(impact), 1);
    expect(m.flashAt(impact), 1);
    expect(m.shoveAt(1), closeTo(0, 1e-9));
    expect(m.shoveAt(2), 0);
  });

  test('the screen jolt starts at impact, swings both ways and settles', () {
    const m = BumpMotion(travel: 2.4);
    final impact = m.impactAt;
    expect(m.joltAt(0), 0);
    expect(m.joltAt(impact / 2), 0);
    expect(m.joltAt(impact), closeTo(0, 1e-9));
    final back = 1 - impact;
    // A quarter of the first cycle in: a full swing one way…
    final quarter = impact + back / (BumpMotion.kJoltCycles * 4);
    expect(m.joltAt(quarter), greaterThan(0.5));
    // …three quarters in: the other way, already a little softer.
    final threeQuarters = impact + 3 * back / (BumpMotion.kJoltCycles * 4);
    expect(m.joltAt(threeQuarters), lessThan(-0.3));
    expect(m.joltAt(threeQuarters).abs(), lessThan(m.joltAt(quarter).abs()));
    expect(m.joltAt(1), closeTo(0, 1e-9));
    expect(m.joltAt(2), closeTo(0, 1e-9));
  });
}
