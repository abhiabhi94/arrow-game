import 'package:arrow_game/data/audio_credits.dart';
import 'package:arrow_game/screens/credits_screen.dart';
import 'package:arrow_game/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('lists the bundled track with artist and licence', (tester) async {
    await pumpApp(tester, const CreditsScreen());
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('Game'), findsOneWidget);
    expect(find.text('by The_Mountain'), findsOneWidget);
    expect(find.textContaining('Pixabay Content License · pixabay.com'), findsOneWidget);
    expect(audioCredits, hasLength(1));
  });

  testWidgets('renders an injected list', (tester) async {
    await pumpApp(
      tester,
      const CreditsScreen(
        credits: [
          TrackCredit(title: 'Tune', artist: 'Someone', license: 'CC0', sourceUrl: 'x.y'),
        ],
      ),
    );
    expect(find.text('Tune'), findsOneWidget);
    expect(find.text('by Someone'), findsOneWidget);
  });

  testWidgets('a desktop window keeps the cards phone-wide and centred', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, const CreditsScreen());
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.text('Game'));
    expect(title.left, greaterThanOrEqualTo((1440 - kMaxContentWidth) / 2));
    expect(title.left, lessThan(720));
  });
}
