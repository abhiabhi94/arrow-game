import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The small marks the board draws for the chapter twists, in one place so
/// the game board and the chapter-intro illustrations draw them the same
/// way: a padlock on a locked arrow, a numbered key badge on its key, a
/// question mark on a hidden head, a link at either end of a tether, and
/// the hole a wall makes in the page. All are sized from the cell and
/// floored in pixels so they stay legible on a dense board, where a cell is
/// a dozen pixels and the player zooms in to read them.
///
/// The badges are the one place colour sits on the board besides the hint
/// glow and the blocked flash: a key and its lock's number wear the sun, so
/// the pair can be found among two hundred arrows in one ink. Everything
/// else is the arrow ink on the page.
class BoardGlyphs {
  const BoardGlyphs({
    required this.ink,
    required this.paper,
    required this.badge,
    required this.onBadge,
    required this.wall,
    required this.wallEdge,
    required this.textDirection,
  });

  final Color ink;
  final Color paper;
  final Color badge;
  final Color onBadge;
  final Color wall;
  final Color wallEdge;
  final TextDirection textDirection;

  /// The size of a glyph on a cell [cs] across: most of the cell, never a
  /// speck.
  static double glyphSize(double cs) => max(10.0, min(cs * 0.95, 26.0));

  /// A wall cell: a sunken square, a hole in the page.
  void wallCell(Canvas canvas, Rect cell) {
    final r = RRect.fromRectAndRadius(cell.deflate(cell.width * 0.06), Radius.circular(cell.width * 0.18));
    canvas.drawRRect(r, Paint()..color = wall);
    canvas.drawRRect(
      r,
      Paint()
        ..color = wallEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, cell.width * 0.05),
    );
  }

  /// A padlock centred on [c], shut or [open] (the shackle swung up and the
  /// whole thing faded: the key has gone). [number] sits in a badge at its
  /// corner while it is shut, so the matching key can be found.
  void padlock(Canvas canvas, Offset c, double g, {required bool open, int? number}) {
    final body = Rect.fromCenter(center: c + Offset(0, g * 0.14), width: g * 0.62, height: g * 0.46);
    final color = open ? ink.withValues(alpha: 0.45) : ink;
    final stroke = max(1.2, g * 0.09);
    // The shackle: an arc over the body, lifted off one side when open.
    final shackle = Path();
    final r = g * 0.19;
    final top = body.top - r;
    if (open) {
      shackle.moveTo(body.left + g * 0.12, body.top);
      shackle.lineTo(body.left + g * 0.12, top - g * 0.08);
      shackle.arcToPoint(Offset(body.left + g * 0.12 + 2 * r, top - g * 0.08), radius: Radius.circular(r));
      shackle.lineTo(body.left + g * 0.12 + 2 * r, top + g * 0.02);
    } else {
      shackle.moveTo(c.dx - r, body.top);
      shackle.lineTo(c.dx - r, top);
      shackle.arcToPoint(Offset(c.dx + r, top), radius: Radius.circular(r));
      shackle.lineTo(c.dx + r, body.top);
    }
    canvas.drawPath(
      shackle,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(g * 0.08)),
      Paint()..color = color,
    );
    // The keyhole, in the paper's colour.
    canvas.drawCircle(body.center - Offset(0, g * 0.04), g * 0.07, Paint()..color = paper);
    canvas.drawRect(
      Rect.fromCenter(center: body.center + Offset(0, g * 0.06), width: g * 0.07, height: g * 0.16),
      Paint()..color = paper,
    );
    if (!open && number != null) {
      numberBadge(canvas, Offset(body.right, body.bottom), g * 0.5, number);
    }
  }

  /// A key: a ring with a toothed stem, in the badge colour, with its
  /// [number] beside it.
  void key(Canvas canvas, Offset c, double g, int number) {
    final stroke = max(1.4, g * 0.11);
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final bow = c + Offset(-g * 0.2, 0);
    canvas.drawCircle(bow, g * 0.17, Paint()..color = badge);
    canvas.drawCircle(bow, g * 0.17, paint);
    // The stem runs to the right, with two teeth hanging off it.
    final stemEnd = c + Offset(g * 0.36, 0);
    canvas.drawLine(bow + Offset(g * 0.17, 0), stemEnd, paint);
    canvas.drawLine(stemEnd, stemEnd + Offset(0, g * 0.14), paint);
    canvas.drawLine(stemEnd - Offset(g * 0.14, 0), stemEnd + Offset(-g * 0.14, g * 0.1), paint);
    numberBadge(canvas, c + Offset(g * 0.3, -g * 0.3), g * 0.5, number);
  }

  /// A sun-coloured disc with [number] on it.
  void numberBadge(Canvas canvas, Offset c, double d, int number) {
    canvas.drawCircle(c, d / 2, Paint()..color = badge);
    canvas.drawCircle(
      c,
      d / 2,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, d * 0.07),
    );
    _text(canvas, '$number', c, d * 0.72, onBadge, bold: true);
  }

  /// The mark on a hidden head: a disc with a question mark, over the
  /// middle of the arrow.
  void question(Canvas canvas, Offset c, double g) {
    canvas.drawCircle(c, g * 0.36, Paint()..color = paper);
    canvas.drawCircle(
      c,
      g * 0.36,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, g * 0.09),
    );
    _text(canvas, '?', c, g * 0.56, ink, bold: true);
  }

  /// A tether between two cells of a pair: a dotted line with a ring at
  /// each end.
  void tether(Canvas canvas, Offset a, Offset b, double cs) {
    final stroke = max(1.5, min(cs * 0.14, 3.5));
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final line = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(dashed(line, stroke * 0.6, stroke * 1.8), paint);
    final r = max(2.5, min(cs * 0.22, 6.0));
    for (final end in <Offset>[a, b]) {
      canvas.drawCircle(end, r, Paint()..color = paper);
      canvas.drawCircle(end, r, paint);
    }
  }

  /// [path] as dashes of [dash] with [gap] between them.
  static Path dashed(Path path, double dash, double gap) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = min(d + dash, metric.length);
        out.addPath(metric.extractPath(d, end), Offset.zero);
        d += dash + gap;
      }
    }
    return out;
  }

  void _text(Canvas canvas, String text, Offset c, double size, Color color, {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          height: 1,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, c - Offset(painter.width / 2, painter.height / 2));
  }
}
