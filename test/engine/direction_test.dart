import 'package:arrow_game/engine/direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opposite is 180° away and involutive', () {
    expect(Direction.up.opposite, Direction.down);
    expect(Direction.down.opposite, Direction.up);
    expect(Direction.left.opposite, Direction.right);
    expect(Direction.right.opposite, Direction.left);
    for (final d in Direction.values) {
      expect(d.opposite.opposite, d);
    }
  });

  test('quarter turns and vectors follow screen coordinates', () {
    expect(Direction.up.quarterTurns, 0);
    expect(Direction.right.quarterTurns, 1);
    expect(Direction.down.quarterTurns, 2);
    expect(Direction.left.quarterTurns, 3);
    expect(Direction.up.vector, (0, -1));
    expect(Direction.right.vector, (1, 0));
    expect(Direction.down.vector, (0, 1));
    expect(Direction.left.vector, (-1, 0));
  });

  group('directionFromSwipe', () {
    test('ignores movement shorter than the minimum distance', () {
      expect(directionFromSwipe(10, 5), isNull);
      expect(directionFromSwipe(-23, 23), isNull);
      expect(directionFromSwipe(0, 0), isNull);
    });

    test('picks the dominant axis', () {
      expect(directionFromSwipe(50, 10), Direction.right);
      expect(directionFromSwipe(-50, 10), Direction.left);
      expect(directionFromSwipe(5, 60), Direction.down);
      expect(directionFromSwipe(5, -60), Direction.up);
    });

    test('honours a custom minimum distance', () {
      expect(directionFromSwipe(30, 0, minDistance: 40), isNull);
      expect(directionFromSwipe(30, 0, minDistance: 20), Direction.right);
    });
  });
}
