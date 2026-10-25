import 'package:flutter/material.dart';

import '../ui/colors.dart';

/// How tall a keycap stands off the page, in logical pixels.
const double kKeycapDepth = 4;

/// A button that stands up off the page like a key on a keyboard: a top in
/// [color] over a side in a deeper shade of it, [kKeycapDepth] tall, that
/// sinks as the finger presses it and springs back as it lifts. Disabled
/// (no [onPressed]), it lies flat. The toolbar and the block's turn buttons
/// wear it, so the game's controls read as things in space like the block.
class Keycap extends StatefulWidget {
  const Keycap({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
    required this.borderColor,
    this.width = 58,
    this.height = 54,
    this.radius = 16,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;
  final double width;
  final double height;
  final double radius;

  @override
  State<Keycap> createState() => _KeycapState();
}

class _KeycapState extends State<Keycap> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onPressed == null || down == _down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onPressed != null;
    final raised = enabled && !_down ? kKeycapDepth : (enabled ? 1.0 : 0.0);
    final side = Color.lerp(widget.borderColor, p.arrowInk, 0.25)!;
    final radius = BorderRadius.circular(widget.radius);
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: SizedBox(
        width: widget.width,
        height: widget.height + kKeycapDepth,
        child: Stack(
          children: [
            // The key's side, showing below its top.
            Positioned(
              left: 0,
              right: 0,
              top: kKeycapDepth,
              height: widget.height,
              child: DecoratedBox(decoration: BoxDecoration(color: side, borderRadius: radius)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: kKeycapDepth - raised,
              height: widget.height,
              child: Material(
                color: widget.color,
                shape: RoundedRectangleBorder(
                  borderRadius: radius,
                  side: BorderSide(color: widget.borderColor),
                ),
                child: InkWell(borderRadius: radius, onTap: widget.onPressed, child: Center(child: widget.child)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
