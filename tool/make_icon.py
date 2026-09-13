#!/usr/bin/env python3
"""Generate the Arrow app icon from code (no external design tool).

Produces, from one drawing routine rendered at high resolution:
  assets/icon/icon.png             1024x1024 full-bleed (launcher source / iOS / Play)
  assets/icon/icon_foreground.png  1024x1024 transparent, the card centred in the
                                   adaptive-icon safe zone (~66%)

Design (same family as the Sudoku icon): an indigo gradient tile carrying a
white puzzle card with an extruded lower edge. On the card sits a tiny board —
a faint lattice, two bent arrows in the game's ink, and one coral arrow that
is sliding up and out past the card's edge: the move the whole game is about.
Colours match lib/ui/colors.dart.
Run: python3 tool/make_icon.py && dart run flutter_launcher_icons
"""
from PIL import Image, ImageDraw, ImageFilter

INDIGO = (108, 92, 231)        # primary
INDIGO_DEEP = (86, 71, 196)    # primaryDark
WHITE = (255, 255, 255)
CARD_EDGE = (214, 210, 242)    # outlineSoft, the card's extruded side
GRID = (228, 224, 255)         # gridLine
INK = (45, 42, 74)             # textInk, the arrows' single ink
CORAL = (255, 107, 107)        # accentCoral, the arrow on its way out
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
    for (x, y) in points[:1]:
        d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
    hx, hy = points[-1]
    dx, dy = heading
    px, py = -dy, dx  # perpendicular
    length, half = stroke * 1.7, stroke * 1.2
    tip = (hx + dx * length, hy + dy * length)
    base_l = (hx + px * half, hy + py * half)
    base_r = (hx - px * half, hy - py * half)
    d.polygon([tip, base_l, base_r], fill=colour)


def draw_card(img, cx, cy, span):
    """The white puzzle card with its board, centred at (cx, cy), `span` wide."""
    half = span / 2
    x0, y0, x1, y1 = cx - half, cy - half, cx + half, cy + half
    radius = span * 0.16
    lift = span * 0.05  # how far the card's lower edge is extruded

    # Soft shadow under the card.
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x0, y0 + lift * 1.6, x1, y1 + lift * 1.6], radius=radius, fill=(30, 20, 90, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(span * 0.05))
    img.alpha_composite(shadow)

    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x0, y0 + lift, x1, y1 + lift], radius=radius, fill=CARD_EDGE)
    d.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=WHITE)

    # A 4x4 lattice through the cell centres — the lines the arrows lie on.
    inset = span * 0.15
    bx0, by0, bx1, by1 = x0 + inset, y0 + inset, x1 - inset, y1 - inset
    board = bx1 - bx0
    cell = board / 4
    centres = [bx0 + cell * (i + 0.5) for i in range(4)]
    grid_w = max(1, int(span * 0.012))
    for c in centres:
        d.line([(c, by0), (c, by1)], fill=GRID, width=grid_w)
        d.line([(bx0, c), (bx1, c)], fill=GRID, width=grid_w)

    stroke = span * 0.052
    c = centres
    # Two arrows still on the board, in ink.
    arrow(d, [(c[0], c[0]), (c[0], c[2]), (c[1], c[2])], (1, 0), stroke, INK)
    arrow(d, [(c[3], c[3]), (c[3], c[1])], (0, -1), stroke, INK)
    # The coral arrow: its head is already clear of the card's top edge.
    exit_y = y0 - span * 0.10
    arrow(d, [(c[1], c[3]), (c[2], c[3]), (c[2], exit_y)], (0, -1), stroke, CORAL)


def make_full(path):
    s = SIZE * SS
    img = gradient(s, INDIGO, INDIGO_DEEP).convert("RGBA")
    # Soft highlight top-left for a little depth.
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([-s * 0.2, -s * 0.35, s * 0.75, s * 0.55], fill=(255, 255, 255, 40))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(s * 0.12)))
    draw_card(img, s / 2, s * 0.53, s * 0.62)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    mask = rounded_mask(SIZE, int(SIZE * 0.22))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    out.save(path)


def make_foreground(path):
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw_card(img, s / 2, s * 0.53, s * 0.50)
    img.resize((SIZE, SIZE), Image.LANCZOS).save(path)


if __name__ == "__main__":
    make_full("assets/icon/icon.png")
    make_foreground("assets/icon/icon_foreground.png")
