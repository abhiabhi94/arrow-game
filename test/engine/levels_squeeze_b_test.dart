import 'package:flutter_test/flutter_test.dart';

import '../support/dealt_levels.dart';

// The squeeze, second part (181-200).
void main() {
  levelChecks(from: 181, to: 200);

  test('the squeeze is a harder find than the block it follows', () {
    // One way out of a face at a time where the block let two, and more
    // on every face: more arrows to look through for every one that can go.
    double hunt(List<int> levels) =>
        levels.map((l) => dealtLevel(l).arrowsPerOpenMove).reduce((a, b) => a + b) / levels.length;
    expect(hunt(<int>[175, 200]), greaterThan(hunt(<int>[145, 150])));
  });
}
