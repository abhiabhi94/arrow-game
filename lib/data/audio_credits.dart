/// Attribution entries for bundled background music.
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

/// The bundled tracks and their attributions.
const List<TrackCredit> audioCredits = <TrackCredit>[
  TrackCredit(
    title: 'Game',
    artist: 'The_Mountain',
    license: 'Pixabay Content License',
    sourceUrl: 'pixabay.com/music/beats-game-179496',
  ),
];
