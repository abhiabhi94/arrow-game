import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain, ghost and decoy arrows want the direction they point', () {
    const plain = Arrow(id: 1, direction: Direction.left);
    const ghost = Arrow(id: 2, direction: Direction.up, kind: ArrowKind.ghost);
    const decoy = Arrow(
      id: 3,
      direction: Direction.down,
      kind: ArrowKind.decoy,
      decoyLabel: Direction.left,
    );
    expect(plain.answer, Direction.left);
    expect(ghost.answer, Direction.up);
    expect(decoy.answer, Direction.down);
    expect(decoy.accepts(Direction.down), isTrue);
    expect(decoy.accepts(Direction.left), isFalse);
  });

  test('reverse arrows want the opposite direction', () {
    const r = Arrow(id: 1, direction: Direction.right, kind: ArrowKind.reverse);
    expect(r.answer, Direction.left);
    expect(r.accepts(Direction.left), isTrue);
    expect(r.accepts(Direction.right), isFalse);
  });

  test('only decoys carry a label', () {
    expect(
      () => Arrow(
        id: 1,
        direction: Direction.up,
        decoyLabel: Direction.down,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => Arrow(id: 1, direction: Direction.up, kind: ArrowKind.decoy),
      throwsA(isA<AssertionError>()),
    );
  });

  test('value equality and a readable toString', () {
    const a = Arrow(id: 7, direction: Direction.up, kind: ArrowKind.reverse);
    const b = Arrow(id: 7, direction: Direction.up, kind: ArrowKind.reverse);
    const c = Arrow(id: 8, direction: Direction.up, kind: ArrowKind.reverse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
    expect(a.toString(), 'Arrow#7(up, reverse)');
    const d = Arrow(
      id: 9,
      direction: Direction.up,
      kind: ArrowKind.decoy,
      decoyLabel: Direction.left,
    );
    expect(d.toString(), 'Arrow#9(up, decoy, says left)');
  });
}
