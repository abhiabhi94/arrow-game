import 'package:flutter/material.dart';

import 'game_screen.dart';

/// The first screen of a page opened from a link to a level
/// (`?level=N`, `utils/level_link.dart`): [child] — home, or the
/// walkthrough on a first visit — with the level pushed on top of it at
/// once, so the board is the first thing seen and Back leads into the game
/// rather than out of it.
///
/// A link is an invitation, so the level opens whether or not the player
/// has reached it on their own trail.
class LevelLinkLauncher extends StatefulWidget {
  const LevelLinkLauncher({super.key, required this.level, required this.child});

  final int level;
  final Widget child;

  @override
  State<LevelLinkLauncher> createState() => _LevelLinkLauncherState();
}

class _LevelLinkLauncherState extends State<LevelLinkLauncher> {
  @override
  void initState() {
    super.initState();
    // Once: a rebuild of the app (a setting changed) keeps this state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameScreen(level: widget.level)),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
