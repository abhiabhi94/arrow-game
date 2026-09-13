/// Deals arrows for a level according to its [LevelSpec] mix. Pure Dart.
library;

import 'dart:math';

import '../models/level_spec.dart';
import 'arrow.dart';
import 'direction.dart';

/// How often the next arrow is allowed to point the same way as the last one.
/// Pure randomness produces dull runs of four "up"s; this keeps things lively
/// while still letting the occasional repeat catch an autopilot player.
const double kRepeatDirectionChance = 0.2;

class ArrowFactory {
  ArrowFactory(this.spec, {Random? random}) : _random = random ?? Random();

  final LevelSpec spec;
  final Random _random;
  int _nextId = 0;
  Direction? _lastDirection;

  /// Deals the next arrow. Kinds are rolled from the spec's chances (whatever
  /// is left over is a plain arrow); the direction avoids repeating the
  /// previous one most of the time.
  Arrow next() {
    final direction = _rollDirection();
    final kind = _rollKind();
    _lastDirection = direction;
    return Arrow(
      id: _nextId++,
      direction: direction,
      kind: kind,
      decoyLabel: kind == ArrowKind.decoy ? _otherDirection(direction) : null,
    );
  }

  /// Forget the last direction (used when a level restarts).
  void reset() {
    _nextId = 0;
    _lastDirection = null;
  }

  Direction _rollDirection() {
    final last = _lastDirection;
    if (last == null || _random.nextDouble() < kRepeatDirectionChance) {
      return Direction.values[_random.nextInt(4)];
    }
    return _otherDirection(last);
  }

  /// A uniformly random direction that is not [avoid].
  Direction _otherDirection(Direction avoid) {
    final choices = Direction.values.where((d) => d != avoid).toList();
    return choices[_random.nextInt(choices.length)];
  }

  ArrowKind _rollKind() {
    final r = _random.nextDouble();
    var edge = spec.reverseChance;
    if (r < edge) return ArrowKind.reverse;
    edge += spec.ghostChance;
    if (r < edge) return ArrowKind.ghost;
    edge += spec.decoyChance;
    if (r < edge) return ArrowKind.decoy;
    return ArrowKind.normal;
  }
}
