import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// The block, second part (181-200).
void main() {
  levelChecks(from: 181, to: 200);

  test('the block ends a harder find than it starts', () {
    // More on every face as the chapter climbs: more arrows to look through
    // for every one that can go.
    double hunt(List<int> levels) =>
        levels.map((l) => dealtLevel(l).arrowsPerOpenMove).reduce((a, b) => a + b) / levels.length;
    expect(hunt(<int>[195, 200]), greaterThan(hunt(<int>[155, 160])));
  });
}
