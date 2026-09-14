---
name: run
description: Build the app for web and drive it in headless Chromium at a phone viewport to capture screenshots of home/settings/any level's board (and, with --hint, the hint glow), then review the PNGs. Use to visually verify a UI change, check a level's rendering, or run the smoke test. The cloud container has no Android emulator (no KVM); this harness is the stand-in.
---

# Run & screenshot the app (cloud stand-in for the emulator)

The session container has no KVM, so no Android emulator. Instead the app is
built for **web** (debug mode = every level unlocked, same as the "Arrow
Testing" Android build) and rendered in headless Chromium at 390×844 @2x.

## Commands

```bash
flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run   # ~60 s
node tool/screenshot.mjs --levels 1,7,13,20,40 --settings --hint     # -> shots/*.png
node tool/screenshot.mjs --levels 3,16 --dark --hint                 # dark theme
node tool/screenshot.mjs --onboarding                                # first-launch walkthrough
node tool/screenshot.mjs --levels 1,8 --viewport 1440x900 --keys Equal,KeyH  # desktop layout + shortcuts
node tool/screenshot.mjs --levels 1 --crash 2,4                      # a bump mid-crash: screen jolt + red flash
node tool/screenshot.mjs --dump                                      # print reachable buttons/labels
```

`--levels` opens each level and captures its board (`level-NN-*.png`);
`--hint` also taps the toolbar's hint button and captures the glowing arrow
(`level-NN-hint-*.png`). `--viewport WxH` renders the desktop layout (the
web build is public on GitHub Pages and played on laptops too; shots carry
the size in their name) and `--keys` presses keys on each opened level
(`level-NN-keys-*.png`). `--crash x,y` taps that grid cell on the first
level and captures the frame 260 ms in (`level-NN-crash-*.png`) — on level
1, cell 2,4 is a blocked arrow head, so the shot shows the crash: the
screen thrown sideways, the red edge, the flashing blocker (the run drives
the page on a fake clock, since a screenshot takes longer than the bump).
Then `Read` the PNGs in `shots/` to review them.

Rebuild whenever `lib/` changes; the script serves whatever is in `build/web`.
`PATH`/`NODE_PATH` are set by the session-start hook; if `flutter` is missing
run `.claude/hooks/session-start.sh` with `CLAUDE_CODE_REMOTE=true`.

## What it verifies

- Exit code 1 if the app logged a Flutter exception (e.g. a RenderFlex
  overflow) or a JS error while being driven — treat that as a failing test.
  CI runs the same script via `.github/actions/web-smoke` (see `ci.yml`,
  job "Web smoke & screenshots") and uploads `shots/` as an artifact.
- Rendering is faithful: Google Sans Flex ships in `assets/fonts/`, CanvasKit is
  bundled by `--no-web-resources-cdn`, and emoji fallback fonts are mirrored
  through the script's local server (cached in `build/font-cache/`).

## Extending the driver

Flutter web paints to a canvas, so the script enables Flutter's semantics
tree and targets widgets by accessible name: anything in
`Semantics(label: …, button: true)` or an `IconButton(tooltip: …)` is
reachable via `page.getByRole('button', { name: /…/ })`. Use `--dump` to see
what a screen exposes. The accessible name of a level tile is "Level N" *plus*
the tile's digit, and the home "Play" card is "Level N <name>", so anchor
regexes at the start and pick `.last()` for the grid tile.

Preferences are seeded through `localStorage` (`flutter.<pref key>`, JSON
encoded) before boot — that is how the walkthrough is skipped, music and
haptics muted and the theme picked.
Add new prefs there rather than clicking through the UI.

## Gotchas (all already handled in the script — keep them when porting)

- Headless Chromium cannot reach `*.gstatic.com` through the cloud proxy;
  Node and curl can. Hence bundled fonts + the `/__fonts/` mirror.
- The level clock runs in real time from the moment a level opens; the
  screenshot is taken ~1.2 s later.
- `web/index.html` declares the viewport meta tag itself. Without it Chromium's
  mobile emulation lays the page out 980 px wide and snaps to device width
  only when the engine injects the tag during boot; that resize event lands
  inside engine init and the debug engine's keyboard-inset assertion can trip
  on it ("JS error: Error … _computeOnScreenKeyboardInsets"), which made the
  CI smoke job flaky. With the tag in the page the resize happens while the
  HTML is still parsing, before the engine exists.
- Trail nodes off screen are not in the semantics tree yet, so the scroll loop
  probes `boundingBox` with a short timeout; the default 30 s per probe made
  levels 16–20 take 6–10 minutes to reach.
