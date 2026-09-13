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
node tool/screenshot.mjs --levels 1,7,13,20 --settings --hint        # -> shots/*.png
node tool/screenshot.mjs --levels 3,16 --dark --hint                 # dark theme
node tool/screenshot.mjs --dump                                      # print reachable buttons/labels
```

`--levels` opens each level and captures its board (`level-NN-*.png`);
`--hint` also taps the toolbar's hint button and captures the glowing arrow
(`level-NN-hint-*.png`). Then `Read` the PNGs in `shots/` to review them.

Rebuild whenever `lib/` changes; the script serves whatever is in `build/web`.
`PATH`/`NODE_PATH` are set by the session-start hook; if `flutter` is missing
run `.claude/hooks/session-start.sh` with `CLAUDE_CODE_REMOTE=true`.

## What it verifies

- Exit code 1 if the app logged a Flutter exception (e.g. a RenderFlex
  overflow) or a JS error while being driven — treat that as a failing test.
  CI runs the same script via `.github/actions/web-smoke` (see `ci.yml`,
  job "Web smoke & screenshots") and uploads `shots/` as an artifact.
- Rendering is faithful: Nunito ships in `assets/fonts/`, CanvasKit is
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
encoded) before boot — that is how the theme is picked and haptics muted.
Add new prefs there rather than clicking through the UI.

## Gotchas (all already handled in the script — keep them when porting)

- Headless Chromium cannot reach `*.gstatic.com` through the cloud proxy;
  Node and curl can. Hence bundled fonts + the `/__fonts/` mirror.
- The level clock runs in real time from the moment a level opens; the
  screenshot is taken ~1.2 s later.
