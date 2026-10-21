#!/usr/bin/env python3
"""Before/after screenshot pairs for a pull request.

    tool/compare_shots.py BEFORE_DIR AFTER_DIR OUT_DIR [--log HEAD_LOG] [--url BASE_URL]

Takes two runs of tool/screenshot.mjs (the base branch's build and the PR's,
same flags, --scale 1) and writes, for every screen whose pixels differ, one
image with the base on the left, the PR on the right and numbered red boxes
on the right half around the regions that changed; plus summary.md, the PR
comment: a line per screen (changed / unchanged / only on one side), the
images (linked under --url) and, from --log, every problem the harness
reported on the PR's build, with its failure.png.

Pure Pillow, no other dependency. Regions smaller than kMinArea are ignored
so the level clock's digits, which differ between any two runs, do not count
as a change on their own.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

RED = (229, 49, 43)
BLOCK = 8          # the diff is clustered on an 8 px grid
THRESH = 40        # per-channel difference that counts as a change
kMinArea = 1500    # px²: a cluster's bounding box has to be at least this


def changed_regions(a, b):
    """Bounding boxes of the clusters of changed pixels between a and b."""
    d = ImageChops.difference(a, b).convert('L')
    d = d.point(lambda v: 255 if v > THRESH else 0).filter(ImageFilter.MaxFilter(9))
    w, h = d.size
    small = d.resize((w // BLOCK + 1, h // BLOCK + 1), Image.Resampling.BOX)
    bw, bh = small.size
    px = small.load()
    grid = [[1 if px[x, y] > 8 else 0 for x in range(bw)] for y in range(bh)]
    seen = [[False] * bw for _ in range(bh)]
    boxes = []
    for y in range(bh):
        for x in range(bw):
            if not grid[y][x] or seen[y][x]:
                continue
            stack, cells = [(y, x)], []
            seen[y][x] = True
            while stack:
                cy, cx = stack.pop()
                cells.append((cy, cx))
                for ny in (cy - 1, cy, cy + 1):
                    for nx in (cx - 1, cx, cx + 1):
                        if 0 <= ny < bh and 0 <= nx < bw and grid[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            stack.append((ny, nx))
            ys = [c[0] for c in cells]
            xs = [c[1] for c in cells]
            box = (min(xs) * BLOCK, min(ys) * BLOCK, (max(xs) + 1) * BLOCK, (max(ys) + 1) * BLOCK)
            if (box[2] - box[0]) * (box[3] - box[1]) >= kMinArea:
                boxes.append(box)
    boxes.sort(key=lambda b: (b[1], b[0]))
    return boxes


def compose(a, b, boxes, title, path):
    font = ImageFont.load_default(size=18)
    badge = ImageFont.load_default(size=15)
    gap, head = 24, 40
    img = Image.new('RGB', (a.width + b.width + gap, max(a.height, b.height) + head), (246, 246, 250))
    d = ImageDraw.Draw(img)
    d.text((12, 10), f'Before (base)  ·  {title}', fill=(40, 40, 60), font=font)
    d.text((a.width + gap + 12, 10), f'After (this PR)  ·  {len(boxes)} changed region(s) in red', fill=RED, font=font)
    img.paste(a, (0, head))
    img.paste(b, (a.width + gap, head))
    for i, (x0, y0, x1, y1) in enumerate(boxes, 1):
        x0, x1 = x0 + a.width + gap, x1 + a.width + gap
        y0, y1 = y0 + head, y1 + head
        d.rounded_rectangle((x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=8, outline=RED, width=3)
        bx, by = x0 - 10, y0 - 16
        d.ellipse((bx, by, bx + 22, by + 22), fill=RED)
        tw = d.textlength(str(i), font=badge)
        d.text((bx + 11 - tw / 2, by + 2), str(i), fill='white', font=badge)
    img.save(path, optimize=True)


def harness_problems(log_path):
    """The problem lines tool/screenshot.mjs printed, if any."""
    if not log_path or not os.path.exists(log_path):
        return []
    lines = open(log_path, encoding='utf-8', errors='replace').read().splitlines()
    out, grab = [], False
    for line in lines:
        if 'problem(s) while driving the app' in line:
            grab = True
            continue
        if grab:
            if line.startswith(' - '):
                out.append(line[3:].strip())
            elif line.startswith('   '):
                out[-1] += '\n' + line.strip()
            else:
                grab = False
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('before')
    ap.add_argument('after')
    ap.add_argument('out')
    ap.add_argument('--log', help="the harness's output for the PR's build")
    ap.add_argument('--url', default='', help='where OUT_DIR will be served from')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    url = args.url.rstrip('/')

    names = sorted(set(os.listdir(args.before)) | set(os.listdir(args.after)))
    names = [n for n in names if n.endswith('.png') and n != 'failure.png']
    changed, same, only_before, only_after = [], [], [], []
    for n in names:
        pa, pb = os.path.join(args.before, n), os.path.join(args.after, n)
        if not os.path.exists(pa):
            only_after.append(n)
            continue
        if not os.path.exists(pb):
            only_before.append(n)
            continue
        a, b = Image.open(pa).convert('RGB'), Image.open(pb).convert('RGB')
        if a.size != b.size:
            b = b.resize(a.size)
        boxes = changed_regions(a, b)
        if not boxes:
            same.append(n)
            continue
        title = os.path.splitext(n)[0]
        compose(a, b, boxes, title, os.path.join(args.out, n))
        changed.append((n, len(boxes)))

    problems = harness_problems(args.log)
    failure = os.path.join(args.after, 'failure.png')
    if problems and os.path.exists(failure):
        Image.open(failure).save(os.path.join(args.out, 'failure.png'), optimize=True)

    md = []
    if problems:
        md.append(f'### ❌ {len(problems)} problem(s) driving the PR build\n')
        for p in problems:
            md.append('```\n' + p + '\n```')
        if os.path.exists(failure):
            md.append(f'The screen when it failed:\n\n![failure]({url}/failure.png)\n')
    md.append(f'**{len(changed)} screen(s) changed**, {len(same)} unchanged'
              + (f', {len(only_after)} new' if only_after else '')
              + (f', {len(only_before)} gone' if only_before else '') + '.\n')
    for n, k in changed:
        title = os.path.splitext(n)[0]
        md.append(f'<details><summary><b>{title}</b> — {k} changed region(s)</summary>\n\n'
                  f'![{title}]({url}/{n})\n\n</details>\n')
    for n in only_after:
        md.append(f'- `{n}`: new in this PR (no counterpart on the base branch)')
    for n in only_before:
        md.append(f'- `{n}`: on the base branch but not in this PR')
    if same:
        md.append('<details><summary>Unchanged</summary>\n\n' + '\n'.join(f'- `{n}`' for n in same) + '\n\n</details>')
    open(os.path.join(args.out, 'summary.md'), 'w').write('\n'.join(md) + '\n')
    json.dump({'changed': changed, 'same': same, 'only_after': only_after,
               'only_before': only_before, 'problems': problems},
              open(os.path.join(args.out, 'summary.json'), 'w'), indent=1)
    print(f'{len(changed)} changed, {len(same)} unchanged, {len(problems)} problem(s)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
