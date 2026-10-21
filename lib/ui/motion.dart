/// Whether the screen should keep still.
///
/// The game moves a lot on purpose — a bump throws the whole screen sideways,
/// a clear makes it hop under a burst of confetti, a lost level sags — and
/// for a player with a vestibular disorder that is not fun, it is nausea.
/// Every such motion asks [reduceMotionOf] first. It is true when the player
/// has asked the OS to calm things down (Android "Remove animations", iOS
/// "Reduce Motion", `prefers-reduced-motion` on the web), which Flutter
/// reports as [MediaQuery.disableAnimations], or has turned "Reduce motion"
/// on in Settings, which `main.dart` folds into the same flag so every widget
/// has one thing to ask.
///
/// What "reduced" means here: nothing moves that does not carry information.
/// An arrow still leaves the board and a blocked one still flashes where it
/// hit, because that is the game; the jolt, the hop, the confetti, the slump,
/// the shakes and the entrance animations go, and the hint glow holds still
/// instead of pulsing.
library;

import 'package:flutter/widgets.dart';

/// True when motion should be kept to the informative minimum.
bool reduceMotionOf(BuildContext context) => MediaQuery.disableAnimationsOf(context);
