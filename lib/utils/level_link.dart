import 'package:flutter/foundation.dart';

import '../data/level_specs.dart';
import '../providers/progress_provider.dart' show testingUnlocksAllLevels;

/// Level links are a reviewer's tool: they live only in a browser build
/// with every level open — the PR previews (`UNLOCK_ALL=true`) and a debug
/// build — where "open level 140" is what a review needs. The public site
/// and the store app have no link button and ignore `?level=N`: a player
/// there earns their way along the trail.
bool get levelLinksOn => (kIsWeb || debugLevelLinksAnywhere) && testingUnlocksAllLevels;

/// Lets a widget test, which is not a browser, see the link button.
@visibleForTesting
bool debugLevelLinksAnywhere = false;

/// Where the game is played in a browser: the web build on GitHub Pages.
/// A link to a level is a page of it with `?level=N`.
const String kPublicSite = 'https://abhiabhi94.github.io/arrow-game/';

/// The link that opens [level] straight onto its board.
///
/// [here] is the page the app is running on, when it runs in a browser: a
/// link copied from a PR preview opens the same preview. Without a page
/// (a test) the link is to [kPublicSite].
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
