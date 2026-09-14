/// Layout rules shared by every screen so this phone-first design also behaves
/// in a desktop browser — the web build is public on GitHub Pages, where it is
/// played in a window several times wider than a phone.
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Widest the content column ever gets, in logical pixels.
///
/// Stretched edge to edge on a laptop the home trail meanders across a
/// 1400px-wide page and the clock, toolbar and result cards sit metres apart,
/// so content stays a phone-ish column and is centred instead. The board
/// itself loses nothing: the levels are taller than they are wide, so on a
/// laptop-shaped window the height, not this width, is what sizes them.
const double kMaxContentWidth = 480;

/// Symmetric horizontal padding that keeps a full-width scroll view's content
/// within [kMaxContentWidth]. The viewport itself stays full-width, so the
/// wheel scrolls anywhere over the window rather than only over the column.
EdgeInsets contentGutter(double viewportWidth, {double minimum = 0}) =>
    EdgeInsets.symmetric(
      horizontal: math.max(minimum, (viewportWidth - kMaxContentWidth) / 2),
    );

/// Centres [child] in a column no wider than [kMaxContentWidth]. For screens
/// whose whole body is one block; a long scrolling list is better served by
/// [contentGutter], which keeps the scrollable area full-width.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: child,
        ),
      );
}

/// Scroll behaviour for the app.
///
/// Flutter's desktop/web default only scrolls from the wheel or a trackpad;
/// this layout is touch-first, so a mouse *drag* — what people reach for when a
/// page looks like a phone screen — scrolls it too.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
