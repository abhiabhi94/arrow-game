/// Attribution entries for bundled background music (CC-BY requires crediting
/// each track).
library;

class TrackCredit {
  const TrackCredit({
    required this.title,
    required this.artist,
    required this.license,
    required this.sourceUrl,
  });

  final String title;
  final String artist;
  final String license;
  final String sourceUrl;
}

/// The bundled tracks and their attributions. The artist's required credit line
/// is: "'Permafrost' by Scott Buckley - released under CC-BY 4.0.
/// www.scottbuckley.com.au".
const List<TrackCredit> audioCredits = <TrackCredit>[
  TrackCredit(
    title: 'Permafrost',
    artist: 'Scott Buckley',
    license: 'CC BY 4.0',
    sourceUrl: 'www.scottbuckley.com.au',
  ),
];
