#!/usr/bin/env python3
"""Generate the Arrow app icon from code (no external design tool).

Produces, from one drawing routine rendered at high resolution:
  assets/icon/icon.png             1024x1024 full-bleed (launcher source / iOS / Play)
  assets/icon/icon_foreground.png  1024x1024 transparent, glyph centred in the
                                   adaptive-icon safe zone (~66%)

Design: a soft indigo gradient tile with one bold white bent arrow — the
game piece itself — sliding up and out. Matches lib/ui/colors.dart.
Run: python3 tool/make_icon.py && dart run flutter_launcher_icons
"""
from PIL import Image, ImageDraw, ImageFilter

INDIGO = (108, 92, 231)
INDIGO_DEEP = (74, 60, 200)
WHITE = (255, 255, 255)
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


def draw_arrow(img, cx, cy, span, stroke):
    """A bent arrow: runs right along the bottom, turns up, ends in a head."""
    d = ImageDraw.Draw(img)
    half = span / 2
    x0, x1 = cx - half, cx + half * 0.55
    y0, y1 = cy - half, cy + half * 0.75
    # Body: bottom-left → bottom-right corner → up towards the head.
    d.line([(x0, y1), (x1, y1), (x1, y0 + span * 0.32)], fill=WHITE, width=int(stroke), joint="curve")
    r = stroke / 2
    for (px, py) in [(x0, y1)]:
        d.ellipse([px - r, py - r, px + r, py + r], fill=WHITE)
    # Head: a filled triangle pointing up.
    hw = stroke * 1.55
    tip = (x1, y0)
    d.polygon([tip, (x1 - hw, y0 + span * 0.36), (x1 + hw, y0 + span * 0.36)], fill=WHITE)


def make_full(path):
    s = SIZE * SS
    img = gradient(s, INDIGO, INDIGO_DEEP)
    # Soft highlight blob top-left for a little depth.
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([-s * 0.2, -s * 0.35, s * 0.75, s * 0.55], fill=(255, 255, 255, 46))
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.12))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    draw_arrow(img, s / 2, s / 2, s * 0.58, s * 0.115)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    mask = rounded_mask(SIZE, int(SIZE * 0.22))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    out.save(path)


def make_foreground(path):
    s = SIZE * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw_arrow(img, s / 2, s / 2, s * 0.42, s * 0.085)
    img.resize((SIZE, SIZE), Image.LANCZOS).save(path)


if __name__ == "__main__":
    make_full("assets/icon/icon.png")
    make_foreground("assets/icon/icon_foreground.png")
    print("wrote assets/icon/icon.png and icon_foreground.png")
