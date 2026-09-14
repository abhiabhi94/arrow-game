# Developing in Claude Code on the web (cloud sessions)

How this repo is set up so a cloud session (no Android emulator, no KVM) can
build, test, and **visually verify** the app. Ported from the sudoku repo's
`docs/cloud-dev.md`; the workflow is identical.

## What the cloud container can and cannot do

| Capability                         | Status | Notes |
|------------------------------------|--------|-------|
| Flutter SDK (pinned)               | ✅     | Installed by the session-start hook into `/opt/flutter` |
| `flutter analyze` / `flutter test` | ✅     | Same gates as CI, incl. `tool/coverage.sh` |
| Web build + headless Chromium      | ✅     | `tool/screenshot.mjs` — phone *and* desktop (`--viewport`) screenshots, keyboard (`--keys`) + smoke test |
| Android emulator                   | ❌     | No `/dev/kvm`; an emulator would not boot usably |
| Android APK build                  | ⚠️     | Works after a ~2 GB SDK install (see CLAUDE.md, "Android SDK in cloud sessions"); not done by the hook |
| iOS build                          | ❌     | Needs macOS/Xcode |

So the loop is: change code → `flutter build web --debug --no-web-resources-cdn`
→ `node tool/screenshot.mjs --levels … --hint` → read the PNGs. CI runs the
same script and uploads the screenshots as an artifact.

## Files that make this work

| File | Role |
|------|------|
| `.flutter-version` | Single pin for the SDK (hook + both CI jobs read it). Keep in sync with `.metadata`. |
| `.claude/hooks/session-start.sh` + `.claude/settings.json` | Cloud-only SessionStart hook: installs Flutter, `pub get`, `gen-l10n`, ensures Playwright/Chromium, exports `PATH`/`NODE_PATH`. |
| `.claude/skills/run/SKILL.md` | Tells Claude how to build/screenshot/review in a session. |
| `tool/screenshot.mjs` | The driver: static server + font mirror + Playwright script + smoke gate. |
| `.github/actions/web-smoke/action.yml` | Composite action: build web, run the driver (phone + desktop runs), upload `shots/`. Used by the `smoke` job in `ci.yml`. |
| `.github/workflows/pages.yml` | Deploys the release web build to GitHub Pages on every push to `main` (base href derived from the repo name). |
| `lib/ui/layout.dart` | Phone-width content column + mouse-drag scrolling so the Pages build works in a laptop-sized window. |
| `assets/fonts/` + `pubspec.yaml` `fonts:` entry | Google Sans Flex bundled as a regular font family — nothing fetched at runtime. |
| `web/` | Web platform scaffold (`flutter create --platforms=web .`). |

## App-specific parts of the driver

- **Prefs** seeded into `localStorage` before boot (`flutter.<key>`, JSON
  encoded): `arrow_onboarding_done` (false with `--onboarding`),
  `arrow_music_on` (false — no audio device), `arrow_sfx_on` (false), `arrow_haptics_on`,
  `arrow_theme` (`"light"`/`"dark"`).
- **Navigation**: home → trail node "Level N" (`.last()`, because the
  "Next up" card is also named "Level N …") → the board → `--hint` taps the
  "Hint" toolbar button → the AppBar "Back" button returns home. Settings
  via the "Settings" tooltip; `--onboarding` captures the walkthrough.
- Add new screens by giving their entry widget a `Semantics(label: …,
  button: true)` or a `tooltip:`; run `--dump` to list what a screen exposes.

## Gotchas worth remembering

- **Chromium vs proxy:** in cloud sessions headless Chromium's TLS through
  the egress proxy fails for `*.gstatic.com` (curl/Node succeed). Everything
  the browser needs must come from `localhost`: `--no-web-resources-cdn`
  bundles CanvasKit, fonts are bundled, and the engine's fallback fonts
  (emoji) are mirrored by the script's server via `fontFallbackBaseUrl`
  (injected into `flutter_bootstrap.js` on the fly).
- **Debug web build** ≙ "testing" build: `kDebugMode` is true, so the
  unlock-everything switch applies. Release web builds (what GitHub Pages
  serves) keep progression.
- **Desktop viewport:** `--viewport 1440x900` turns Playwright's mobile
  emulation off (mouse instead of touch), so what it captures is the
  laptop layout — the centred phone-width column from `lib/ui/layout.dart`.
  `--keys Equal,KeyH` presses keys on the opened level (Playwright key
  names) and captures the result, which is how the shortcuts are smoke
  tested.
- **Semantics on web** are off until the hidden "Enable accessibility"
  placeholder is clicked; the script does that. The accessible name of a
  widget concatenates its label and child text.
- The first layout runs before the bundled font is registered; a
  `RenderFlex overflow` seen only on the very first frame is that transient.
  The script waits ~1.5 s after boot before screenshotting so the gate only
  catches real overflows.
- The game clock runs in real time on the web build; a level screenshot is
  taken ~1.2 s after opening, so the clock reads a second under its limit.
