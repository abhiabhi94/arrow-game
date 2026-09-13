import 'package:arrow_game/data/audio_credits.dart';
import 'package:arrow_game/screens/credits_screen.dart';
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
}
