import 'package:arrow_game/engine/arrow.dart';
import 'package:arrow_game/engine/direction.dart';
import 'package:arrow_game/models/game_state.dart';
import 'package:arrow_game/models/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

const _spec = LevelSpec(
  level: 7,
  targetHits: 20,
  timeLimitMs: 30000,
  arrowTimeoutMs: 2000,
);

void main() {
  test('ready state', () {
    final s = GameState.ready(_spec);
    expect(s.level, 7);
    expect(s.phase, GamePhase.ready);
    expect(s.livesLeft, 3);
    expect(s.remainingMs, 30000);
    expect(s.timeFraction, 1.0);
    expect(s.progress, 0);
    expect(s.arrow, isNull);
    expect(s.arrowVisible, isFalse);
    expect(s.isPlaying, isFalse);
    expect(s.isOver, isFalse);
    expect(s.stars, 0);
  });

  test('derived values', () {
    final s = GameState.ready(_spec).copyWith(
      phase: GamePhase.playing,
      hits: 5,
      mistakes: 1,
      elapsedMs: 12000,
      arrow: const Arrow(id: 0, direction: Direction.up),
      arrowAgeMs: 500,
    );
    expect(s.livesLeft, 2);
    expect(s.remainingMs, 18000);
    expect(s.timeFraction, closeTo(0.6, 1e-9));
    expect(s.progress, 0.25);
    expect(s.fuseFraction, closeTo(0.75, 1e-9));
    expect(s.arrowVisible, isTrue);
    expect(s.isPlaying, isTrue);
  });

  test('remaining time and fuse clamp at zero', () {
    final s = GameState.ready(_spec).copyWith(elapsedMs: 99999, arrowAgeMs: 9999);
    expect(s.remainingMs, 0);
    expect(s.fuseFraction, 0);
  });

  test('no fuse means a null fuse fraction', () {
    const noFuse = LevelSpec(level: 1, targetHits: 5, timeLimitMs: 1000);
    expect(GameState.ready(noFuse).fuseFraction, isNull);
  });

  test('ghosts hide after kGhostVisibleMs, other kinds never do', () {
    const ghost = Arrow(id: 0, direction: Direction.up, kind: ArrowKind.ghost);
    const plain = Arrow(id: 1, direction: Direction.up);
    final base = GameState.ready(_spec);
    expect(base.copyWith(arrow: ghost, arrowAgeMs: 0).arrowVisible, isTrue);
    expect(base.copyWith(arrow: ghost, arrowAgeMs: kGhostVisibleMs - 1).arrowVisible, isTrue);
    expect(base.copyWith(arrow: ghost, arrowAgeMs: kGhostVisibleMs).arrowVisible, isFalse);
    expect(base.copyWith(arrow: plain, arrowAgeMs: 99999).arrowVisible, isTrue);
  });

  test('stars only count once cleared; terminal phases are over', () {
    final base = GameState.ready(_spec).copyWith(mistakes: 1);
    expect(base.stars, 0);
    expect(base.copyWith(phase: GamePhase.cleared).stars, 2);
    for (final p in [GamePhase.cleared, GamePhase.outOfLives, GamePhase.timeUp]) {
      expect(base.copyWith(phase: p).isOver, isTrue);
    }
    for (final p in [GamePhase.ready, GamePhase.playing, GamePhase.paused]) {
      expect(base.copyWith(phase: p).isOver, isFalse);
    }
  });
}
