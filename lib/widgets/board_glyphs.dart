import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/mirror.dart';

/// The small marks the board draws for the chapter twists, in one place so
/// the game board and the chapter-intro illustrations draw them the same
/// way: a padlock on a locked arrow, a numbered key badge on its key, a
/// question mark on a hidden head, a link at either end of a tether (over
/// a wash under both halves), and the diagonal of a mirror. All are sized from the cell and
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
    required this.mirrorWash,
    required this.pairWash,
    required this.textDirection,
  });

  final Color ink;
  final Color paper;
  final Color badge;
  final Color onBadge;
  final Color mirrorWash;
  final Color pairWash;
  final TextDirection textDirection;

  /// The size of a glyph on a cell [cs] across: most of the cell, never a
  /// speck.
  static double glyphSize(double cs) => max(10.0, min(cs * 0.95, 26.0));

  /// A mirror in [cell]: a pane of glass across the diagonal — a soft wash
  /// over the cell so it reads as a *thing* on the board even at a dozen
  /// pixels, and the diagonal itself as a bar of ink with a hairline of
  /// paper along it for the shine. Which way it lies is the whole message,
  /// so the bar is the thickest line on the board.
  void mirror(Canvas canvas, Rect cell, Mirror kind) {
    final cs = cell.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(cell.deflate(cs * 0.08), Radius.circular(cs * 0.2)),
      Paint()..color = mirrorWash,
    );
    final (a, b) = _diagonal(cell, kind);
    final stroke = max(2.5, min(cs * 0.2, 6.0));
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = ink
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    // The shine: a thin line of paper just off the bar, on its upper side.
    final along = (b - a) / (b - a).distance;
    final normal = Offset(along.dy, -along.dx) * (stroke * 0.55);
    canvas.drawLine(
      a + normal + along * (stroke * 0.6),
      b + normal - along * (stroke * 0.6),
      Paint()
        ..color = paper
        ..strokeWidth = max(0.8, stroke * 0.22)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The diagonal of the mirror in [cell] lit up in [glow]: drawn over the
  /// mirror as an arrow turns at it.
  void mirrorFlash(Canvas canvas, Rect cell, Mirror kind, Color glow) {
    final (a, b) = _diagonal(cell, kind);
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = glow
        ..strokeWidth = max(2.5, min(cell.width * 0.2, 6.0)) * 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The two ends of a mirror's diagonal across [cell].
  static (Offset, Offset) _diagonal(Rect cell, Mirror kind) {
    final inset = cell.width * 0.2;
    return switch (kind) {
      Mirror.slash => (Offset(cell.left + inset, cell.bottom - inset), Offset(cell.right - inset, cell.top + inset)),
      Mirror.backslash => (Offset(cell.left + inset, cell.top + inset), Offset(cell.right - inset, cell.bottom - inset)),
    };
  }

  /// A padlock centred on [c]: [openness] 0 is shut, 1 is open (the
  /// shackle swung up and out, the whole thing faded: the key has gone),
  /// and in between it is on its way. [number] sits in a badge at its
  /// corner while it is shut, so the matching key can be found.
  void padlock(Canvas canvas, Offset c, double g, {required double openness, int? number}) {
    final body = Rect.fromCenter(center: c + Offset(0, g * 0.14), width: g * 0.62, height: g * 0.46);
    final color = ink.withValues(alpha: 1 - 0.55 * openness.clamp(0, 1));
    final stroke = max(1.2, g * 0.09);
    final r = g * 0.19;
    final top = body.top - r;
    // The shackle: an arc over the body. Opening, its right leg lifts out
    // of the body and swings up, pivoting on the left leg.
    final lift = g * 0.22 * openness;
    final shackle = Path()
      ..moveTo(c.dx - r, body.top)
      ..lineTo(c.dx - r, top - lift * 0.3)
      ..arcToPoint(Offset(c.dx + r, top - lift * 0.3), radius: Radius.circular(r))
      ..lineTo(c.dx + r, body.top - lift);
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
    if (openness < 0.5 && number != null) {
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

  /// The wash under a tethered pair: every one of [cells] (the cells of
  /// both halves) tinted, so on a dense board the two arrows read as one
  /// piece before the tether between them is even found.
  void washPair(Canvas canvas, Iterable<Rect> cells) {
    final path = Path()..fillType = PathFillType.nonZero;
    // Each cell a touch larger than itself, so neighbours overlap and the
    // wash is one blob with no pinholes where four corners meet.
    for (final cell in cells) {
      path.addRRect(RRect.fromRectAndRadius(cell.inflate(cell.width * 0.07), Radius.circular(cell.width * 0.2)));
    }
    canvas.drawPath(path, Paint()..color = pairWash);
  }

  /// A tether between two cells of a pair: a dotted line with a ring at
  /// each end. In [colour] (the glow, say) while the pair is on the move,
  /// so what pulls the second half along is seen; the ink otherwise.
  void tether(Canvas canvas, Offset a, Offset b, double cs, {Color? colour}) {
    final stroke = max(1.5, min(cs * 0.14, 3.5)) * (colour == null ? 1 : 1.4);
    final paint = Paint()
      ..color = colour ?? ink
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
