import 'dart:convert';

import 'package:arrow_game/data/level_specs.dart';
import 'package:arrow_game/providers/game_provider.dart';
import 'package:arrow_game/providers/progress_provider.dart';
import 'package:arrow_game/providers/saved_game_provider.dart';
import 'package:arrow_game/screens/game_screen.dart';
import 'package:arrow_game/screens/home_screen.dart';
import 'package:arrow_game/screens/settings_screen.dart';
import 'package:arrow_game/ui/layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/sample_puzzle.dart';

/// Opening a level from home must not spin up the real generator/timer.
final List<Override> _gameOverride = [
  gameProvider.overrideWith(
    (ref, level) => GameNotifier(
      sampleSpecFor(level),
      puzzle: samplePuzzle(),
      autoTick: false,
    ),
  ),
];

void main() {
  testWidgets('renders title, stars tally, play card and a tile per level', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Arrow'), findsOneWidget);
    expect(find.bySemanticsLabel('0 of ${totalLevels * 3} stars'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget); // the hero card
    expect(find.text('NEXT UP'), findsOneWidget);
    expect(find.text('Your journey'), findsOneWidget);
    for (var level = 1; level <= totalLevels; level++) {
      expect(find.text('$level', skipOffstage: false), findsOneWidget, reason: 'node $level');
    }
  });

  testWidgets('locked levels show a lock and do not open', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      extraOverrides: [
        progressProvider.overrideWith(
          (ref) => ProgressNotifier(
            ref.watch(progressRepositoryProvider),
            unlockAllLevels: false,
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.lock_rounded, skipOffstage: false), findsNWidgets(totalLevels - 1));

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('cleared levels show stars and best time; next unlocks', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        'arrow_level_1_done': true,
        'arrow_level_1_stars': 2,
        'arrow_level_1_best': 21000,
        'arrow_level_1_count': 1,
      },
      extraOverrides: [
        progressProvider.overrideWith(
          (ref) => ProgressNotifier(
            ref.watch(progressRepositoryProvider),
            unlockAllLevels: false,
          ),
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.bySemanticsLabel('2 of ${totalLevels * 3} stars'), findsOneWidget);
    expect(find.text('0:21'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded, skipOffstage: false), findsNWidgets(totalLevels - 2));
    // The hero card points at level 2 now; the node names it too.
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('Two Ways Out'), findsNWidgets(2));
  });

  testWidgets('tapping a tile opens the game; the play card too', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen(), extraOverrides: _gameOverride);
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('Tight Corners'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
  });

  testWidgets('a level left mid-way takes the hero card and opens on tap', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(
      tester,
      const HomeScreen(),
      seed: <String, Object>{
        SavedGameRepository.key: jsonEncode(const {
          'level': 3,
          'removed': [0, 1],
          'mistakes': 0,
          'hintsLeft': 3,
          'elapsedMs': 30000,
        }),
      },
      extraOverrides: _gameOverride,
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('PICK UP WHERE YOU LEFT OFF'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('2 of 12 arrows out · 0:30 on the clock'), findsOneWidget);
    expect(find.text('NEXT UP'), findsNothing);
    expect(find.text('Level 3'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
  });

  testWidgets('with every level cleared the hero offers a replay', (tester) async {
    await usePhoneSurface(tester);
    final seed = <String, Object>{
      for (var l = 1; l <= totalLevels; l++) ...{
        'arrow_level_${l}_done': true,
        'arrow_level_${l}_stars': 3,
      },
    };
    await pumpApp(tester, const HomeScreen(), seed: seed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Every level cleared — legend!'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.bySemanticsLabel('${totalLevels * 3} of ${totalLevels * 3} stars'), findsOneWidget);
  });

  testWidgets('the stars and the gear stay put while the trail scrolls', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen(), seed: <String, Object>{
      'arrow_level_1_done': true,
      'arrow_level_1_stars': 3,
    });
    expect(find.text('Slide every arrow out'), findsOneWidget);
    final gear = find.byTooltip('Settings');
    final stars = find.bySemanticsLabel(RegExp(r'^3 of 180 stars'));
    // Sixty levels down the trail, both are still in the bar at the top —
    // the bar slims and its contents recentre, but nothing scrolls away.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(gear, findsOneWidget);
    expect(stars, findsOneWidget);
    expect(tester.getBottomRight(gear).dy, lessThanOrEqualTo(62));
    expect(tester.getBottomRight(stars).dy, lessThanOrEqualTo(62));
    // The header gave up its tagline to stay slim.
    expect(find.text('Slide every arrow out'), findsNothing);
    // And the trail really did move.
    expect(find.text('Your journey'), findsNothing);
  });

  testWidgets('settings button opens settings', (tester) async {
    await usePhoneSurface(tester);
    await pumpApp(tester, const HomeScreen());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('a desktop window keeps the trail in a centred phone-width column', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, const HomeScreen(), extraOverrides: _gameOverride);
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);

    // The hero card spans the column: its eyebrow starts past the left gutter
    // and its Play chip ends before the right one.
    final eyebrow = tester.getRect(find.text('NEXT UP'));
    final play = tester.getRect(find.text('Play'));
    expect(eyebrow.left, greaterThan((1440 - kMaxContentWidth) / 2));
    expect(play.right, lessThan((1440 + kMaxContentWidth) / 2));
    expect(find.text('Arrow'), findsOneWidget);
    // Every trail node sits inside the column, not out at the window's edges.
    for (var level = 1; level <= 3; level++) {
      final node = tester.getRect(find.text('$level'));
      expect(node.left, greaterThan((1440 - kMaxContentWidth) / 2));
      expect(node.right, lessThan((1440 + kMaxContentWidth) / 2));
    }

    // The wheel scrolls from the gutter, not only over the column.
    final before = tester.getRect(find.text('1')).top;
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(const Offset(100, 500)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 300)));
    await tester.pump();
    expect(tester.getRect(find.text('1')).top, lessThan(before));
  });
}
