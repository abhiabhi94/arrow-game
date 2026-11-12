import '../data/level_specs.dart';

/// Where the game is played in a browser: the release web build on GitHub
/// Pages. A link to a level is this with `?level=N`.
const String kPublicSite = 'https://abhiabhi94.github.io/arrow-game/';

/// The link that opens [level] straight onto its board.
///
/// [here] is the page the app is running on, when it runs in a browser: a
/// link copied from a PR preview opens the same preview, and one copied
/// from the public site opens the public site. Off the web (the phone app)
/// the link is to [kPublicSite], which anyone can open.
Uri levelLinkFor(int level, {Uri? here}) {
  final site = here != null && (here.scheme == 'http' || here.scheme == 'https') ? here : Uri.parse(kPublicSite);
  return Uri(
    scheme: site.scheme,
    host: site.host,
    port: site.hasPort ? site.port : null,
    path: site.path,
    queryParameters: {'level': '$level'},
  );
}

/// The level a page's address asks for — `?level=N`, also read after a `#`
/// (the app's URLs carry one) — when N is a level; otherwise null.
int? levelFromLink(Uri uri) {
  final asked = uri.queryParameters['level'] ?? _fragmentQuery(uri.fragment)['level'];
  final level = int.tryParse(asked ?? '');
  return level != null && level >= 1 && level <= totalLevels ? level : null;
}

Map<String, String> _fragmentQuery(String fragment) {
  final at = fragment.indexOf('?');
  return at < 0 ? const {} : Uri.splitQueryString(fragment.substring(at + 1));
}
