#!/usr/bin/env python3
"""Generate the Arrow app icon from code (no external design tool).

Produces, from one drawing routine rendered at high resolution:
  assets/icon/icon.png             1024x1024 full-bleed (launcher source / iOS / Play)
  assets/icon/icon_foreground.png  1024x1024 transparent, the board centred in the
                                   adaptive-icon safe zone (~66%)
  web/favicon.png                  64x64 of the full tile
  web/icons/Icon-{192,512}.png     the full tile (PWA "any" icons)
  web/icons/Icon-maskable-*.png    square, paper edge to edge with the board in
                                   the maskable safe zone (like the adaptive icon)

Design: the tile *is* the page. A sheet of soft paper with the faint
lattice the arrows lie on, two bent arrows in the game's single ink and one
coral arrow sliding up and off the top edge — the move the whole game is
about. Colours match lib/ui/colors.dart (light palette).
Run: python3 tool/make_icon.py && dart run flutter_launcher_icons
(flutter_launcher_icons only covers Android and iOS; the web files are written
here so the site and the store builds share one icon.)
The adaptive background colour in pubspec.yaml must match PAPER_BOTTOM.
"""
from PIL import Image, ImageDraw

PAPER_TOP = (255, 255, 255)
PAPER_BOTTOM = (244, 243, 255)   # backgroundSoft
GRID = (228, 224, 255)           # the lattice, a shade fainter than gridLine
INK = (45, 42, 74)               # arrowInk, the arrows' single ink
CORAL = (255, 107, 107)          # accentCoral, the arrow on its way out
SS = 4  # supersample for crisp anti-aliasing
SIZE = 1024


def gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        row = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(size):
            px[x, y] = row
    return img


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def arrow(d, points, heading, stroke, colour):
    """A bent arrow: a round-capped polyline ending in a small filled head.

    `points` run tail → head cell; `heading` is the unit step the head faces.
    The head is a triangle a touch wider than the stroke, like the board's.
    """
    d.line(points, fill=colour, width=int(stroke), joint="curve")
    r = stroke / 2
    (x, y) = points[0]
    d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
    hx, hy = points[-1]
    dx, dy = heading
    px, py = -dy, dx  # perpendicular
    length, half = stroke * 1.7, stroke * 1.2
    tip = (hx + dx * length, hy + dy * length)
    d.polygon([tip, (hx + px * half, hy + py * half), (hx - px * half, hy - py * half)], fill=colour)


def draw_board(img, cx, cy, span, exit_to, paper=True):
    """A 6x6 board centred at (cx, cy), `span` wide. With `paper`, the lattice
    runs edge to edge like graph paper; the coral arrow's head reaches up to
    `exit_to` (a y coordinate)."""
    d = ImageDraw.Draw(img)
    w, h = img.size
    cell = span / 6
    xs = [cx - span / 2 + cell * (i + 0.5) for i in range(6)]
    ys = [cy - span / 2 + cell * (i + 0.5) for i in range(6)]
    grid_w = max(1, int(span * 0.006))
    if paper:
        for x in xs:
            d.line([(x, 0), (x, h)], fill=GRID, width=grid_w)
        for y in ys:
            d.line([(0, y), (w, y)], fill=GRID, width=grid_w)

    stroke = span * 0.062
    # Two arrows still on the board, in ink.
    arrow(d, [(xs[1], ys[1]), (xs[1], ys[3]), (xs[2], ys[3])], (1, 0), stroke, INK)
    arrow(d, [(xs[4], ys[4]), (xs[4], ys[2])], (0, -1), stroke, INK)
    # The coral arrow, on its way out past the top edge.
    head = exit_to + stroke * 1.7
    arrow(d, [(xs[1], ys[4]), (xs[3], ys[4]), (xs[3], head)], (0, -1), stroke, CORAL)


def make_full(path):
    s = SIZE * SS
    img = gradient(s, PAPER_TOP, PAPER_BOTTOM).convert("RGBA")
    draw_board(img, s / 2, s * 0.53, s * 1.0, s * 0.05)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    mask = rounded_mask(SIZE, int(SIZE * 0.22))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    out.save(path)


def make_foreground(path):
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw_board(img, s / 2, s * 0.52, s * 0.66, s * 0.19, paper=False)
    img.resize((SIZE, SIZE), Image.LANCZOS).save(path)


def make_maskable(size):
    """A square tile for PWA maskable icons: the paper runs edge to edge and
    the board sits in the centre ~66%, which is what survives a circle mask."""
    s = SIZE * SS
    img = gradient(s, PAPER_TOP, PAPER_BOTTOM).convert("RGBA")
    draw_board(img, s / 2, s * 0.52, s * 0.66, s * 0.19)
    return img.resize((size, size), Image.LANCZOS)


def make_web(full_path):
    full = Image.open(full_path)
    full.resize((64, 64), Image.LANCZOS).save("web/favicon.png")
    for size in (192, 512):
        full.resize((size, size), Image.LANCZOS).save(f"web/icons/Icon-{size}.png")
        make_maskable(size).save(f"web/icons/Icon-maskable-{size}.png")


if __name__ == "__main__":
    make_full("assets/icon/icon.png")
    make_foreground("assets/icon/icon_foreground.png")
    make_web("assets/icon/icon.png")
