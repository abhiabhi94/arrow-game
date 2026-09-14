# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A playful cross-platform (Android + iOS) **arrow exit puzzle** built with
Flutter (in the spirit of "Arrow Exit Puzzle"). Bent arrow pieces sit on a
grid; tapping one slides it along its own path, the way its head points, until
it leaves the board. An arrow whose exit path runs into another arrow bumps
back and costs a life. 40 fixed, procedurally generated levels on a steep
curve (5 arrows on 5×6 → 59 on 19×26 by level 8 → 144 on 32×50 by level
20 → 224 on 42×63), drawn in a
single ink like a printed puzzle, 3 lives per level (losing all three resets the level behind a
"Retry" screen), a clock on every level ("Time's up" → replay the same level),
3 hints per level, zoom in/out, an earned grid-lines toggle (after level 4),
1–3 stars per clear, local progress, light/dark theme, haptic feedback.

## Build & Development Commands

```bash
flutter pub get                 # deps
flutter gen-l10n                # regenerate localizations after editing lib/l10n/*.arb
flutter analyze --fatal-infos   # static analysis (must be clean; CI fails on infos)
flutter test                    # full test suite
tool/coverage.sh 92             # coverage gate (fails under threshold)

flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run  # web build (debug = all levels unlocked)
node tool/screenshot.mjs --levels 1,7,20,40 --settings --hint       # phone-viewport screenshots -> shots/
node tool/screenshot.mjs --levels 3 --resume                        # + a saved game: Continue card, Welcome back
node tool/screenshot.mjs --levels 1 --viewport 1440x900 --keys Equal,KeyH  # desktop layout + keyboard
node tool/screenshot.mjs --levels 1 --crash 2,4                     # a bump mid-crash (fake clock): jolt + red flash

flutter run                     # debug build = "Arrow Testing", all levels unlocked
flutter run --release           # release build = "Arrow", locked progression
flutter build apk --debug       # -> build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release     # -> app-release.apk (upload-key signed if key.properties present)
flutter build appbundle --release  # -> build/app/outputs/bundle/release/app-release.aab (for Play Store)
```

## Cloud sessions & visual verification

Claude Code on the web has no Android emulator (no KVM). The stand-in is the
**web build + headless Chromium**: `tool/screenshot.mjs` serves `build/web`,
drives the app (home, settings, any level's board and — with `--hint` — the
hint glow, light/dark) at 390×844 and writes PNGs to `shots/`; `--viewport
WxH` renders the desktop layout instead and `--keys` presses keys on each
opened level (both exercised in CI, since the web build is also played on a
laptop via GitHub Pages); `--crash x,y` taps a grid cell on the first level
and captures the bump 230 ms in on Playwright's fake clock (a screenshot
takes longer than the bump), with the semantics layer made pointer-transparent
for the tap — a click on the board's accessibility node would otherwise be a
semantic tap at the board's centre. It exits 1 on any Flutter exception, so it doubles
as the CI smoke test (`.github/actions/web-smoke`, job "Web smoke &
screenshots"). See `.claude/skills/run/SKILL.md` and `docs/cloud-dev.md`.
The SessionStart hook in `.claude/hooks/session-start.sh` installs the SDK
pinned in `.flutter-version`.

The web target doubles as a public build: `.github/workflows/pages.yml`
deploys the release web app to GitHub Pages
(https://abhiabhi94.github.io/arrow-game/) on every push to `main`, and
`pr-preview.yml` deploys every PR to `…/pr-preview/pr-<number>/`. The
shipped store platforms are Android + iOS. The typeface (Google Sans Flex,
OFL, static weights 400–800) is bundled in `assets/fonts/` and declared
under `flutter: fonts:` as `GoogleSansFlex` — no `google_fonts`, no runtime
fetch.

**Desktop browser (`lib/ui/layout.dart`):** the design is phone-first, so
every screen keeps its content in a centred column no wider than
`kMaxContentWidth` (480) — `ContentColumn` for one-block screens (game,
onboarding), `contentGutter` as extra padding for the scrolling ones (home,
settings, credits), which keeps the scroll viewport full-width so the wheel
works anywhere over the page. `AppScrollBehavior` (set on the `MaterialApp`)
lets a mouse drag scroll too. The game screen's `Focus` handles keyboard
shortcuts: **H** hint, **+ / =** and **-** zoom, **G** grid lines (once
earned), **Space / P** pause and resume (`shortcutFor` maps the keys);
modifier-held keys are left to the browser. Taps stay on the mouse — the
arrows are canvas drawings.

## Build types (no flavors)

Identity is tied to the **build type**, not a product flavor:

| Build   | App name       | Application id               | Levels                        |
|---------|----------------|------------------------------|-------------------------------|
| debug   | Arrow Testing  | `app.curious.arrow.testing`  | all unlocked (for testing)    |
| release | Arrow          | `app.curious.arrow`          | locked until previous cleared |

- The debug `.testing` app-id suffix lets both install side-by-side.
- "Unlock all levels" keys off `kDebugMode` (`testingUnlocksAllLevels` in
  `lib/providers/progress_provider.dart`), or off
  `--dart-define=UNLOCK_ALL=true` for a small release-mode tester build:
  `flutter build apk --release --split-per-abi --dart-define=UNLOCK_ALL=true`
  gives a ~20 MB arm64 APK with every level open (the debug APK is ~150 MB
  with all ABIs). `build.gradle.kts` decodes the `dart-defines` Gradle
  property (base64, comma-separated) and, when it sees `UNLOCK_ALL=true`,
  gives that release build the debug identity (`.testing` suffix, "Arrow
  Testing", debug signing) so it installs alongside the real app instead of
  replacing it. Namespace is `app.curious.arrow`.
- **Haptics on Android** go through `MainActivity.kt` (channel
  `app.curious.arrow/haptics`, `VIBRATE` permission) straight to the
  Vibrator service: Flutter's `HapticFeedback` uses
  `View.performHapticFeedback`, which the OS mutes whenever the user's
  system "touch feedback" is off. iOS keeps `HapticFeedback`.
- **Android SDK in cloud sessions:** not installed by the hook. To build an
  APK: unzip the command-line tools into `/opt/android-sdk/cmdline-tools/latest`,
  `sdkmanager 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358'`,
  `flutter config --android-sdk /opt/android-sdk`. The first Gradle run
  takes ~6 minutes.
- Do NOT name an Android flavor starting with `test` (Gradle reserves it), and
  `android.buildFeatures.resValues` must stay enabled for the per-build app name.

## Release signing / publishing

- Release is signed with an upload key read from `android/key.properties`
  (**gitignored**); falls back to debug signing when that file is absent.
  Template: `android/key.properties.example`. Keystore lives OUTSIDE the repo.
- Never commit `key.properties`, `*.jks`, `*.keystore`, or anything under
  `build/`.
- **Play Store bundle:** `.github/workflows/release.yml` (tag `v*` or manual
  dispatch) restores the upload key from the `ANDROID_UPLOAD_*` secrets,
  runs analyze + tests, builds the signed `.aab`/`.apk` with
  `--obfuscate --split-debug-info`, and uploads them (plus R8 mapping and
  Dart symbols) as an artifact and a GitHub Release. Bump `version:` in
  `pubspec.yaml` (the `+N` code must increase) before tagging. Cloud sessions
  have no key, so a bundle built here is debug-signed and only proves the
  build compiles. Guide: `docs/release.md`.

## Architecture

**Pure-Dart engine + Riverpod StateNotifier + shared_preferences.** Layered
`lib/` (by type):

```
lib/
  main.dart            # prefs awaited once, ProviderScope override, MaterialApp + l10n
  engine/              # PURE DART, zero Flutter imports
    direction.dart       Direction enum (opposite, vector)
    cell.dart            grid coordinate
    arrow_piece.dart     ArrowPiece: cells tail→head + heading; exitRay()
    puzzle.dart          Puzzle: occupancy, blockers, canExit, solvingOrder, hintFor, difficultyScore
    puzzle_generator.dart DAG-checked generator (solvable by construction), tight, best-of-N
  data/level_specs.dart  the 40 levels (board size, arrow count, length range, clock)
  models/              level_spec, level_progress (stars), settings, game_state (phases, moves),
                       bump_motion (the blocked-tap animation), saved_game (resume snapshot)
  providers/           app_providers (DI root), settings_provider, progress_provider, game_provider,
                       saved_game_provider (the one level in progress)
  services/            haptics_service (injectable HapticEngine), sfx_service (whoosh + bump),
                       audio_service (looping music)
  data/audio_credits.dart  attribution for the bundled track
  screens/             onboarding (interactive 3-step walkthrough), home (journey trail),
                       game (board + toolbar + overlays), settings, credits
  ui/                  colors.dart (light+dark ArrowPalette), theme.dart (Material 3 + Google Sans Flex),
                       layout.dart (phone-width column + mouse-drag scrolling for the desktop browser)
  widgets/             puzzle_board (painter + slide/bump animations), board_toolbar,
                       lives_indicator, timer_bar, stars_row, result_card
  utils/               format.dart, labels.dart (level names)
  l10n/                app_en.arb (+ generated app_localizations*.dart)
```

Key patterns:
- **DI:** `sharedPreferencesProvider` throws until overridden in `main()`; all
  repositories/providers read prefs through it. Tests override it with a mock.
- **Persistence:** `shared_preferences` only, keys prefixed `arrow_*`.
- **Rules:** an arrow can exit iff every cell of its `exitRay` (head → board
  edge, in its heading) is free of other arrows still on the board. Arrows
  leave entirely, so "who blocks whom" is fixed; solvable ⇔ acyclic.
- **Generation:** `puzzle_generator.dart` places arrows one by one on flat
  typed-data grids, roughly inside-out (deep heads sampled first so the free
  area stays an outer ring). A head may face free cells *or point straight
  at an existing arrow*; the only rule is that the "waits for" graph stays
  a DAG (`_acyclic`: nothing the newcomer waits for may already wait for an
  arrow whose ray the newcomer's body crosses). Bodies grow step by step
  scoring straightness, hugging (arrows/border) and existing rays, with a
  length ramp (inner short, outer long — nested rings); the best of
  `kPlacementChoices` bodies per arrow wins. **Tightness:** an arrow that
  waits for nobody is *open* — a tap the player will have. Whenever more
  than `LevelSpec.openMoves` are open, placement switches to closing mode:
  heads near open rays weigh more, bodies are pulled onto open rays
  (`kCloseBonus`, `kCloseStepBias`) and a second strategy grows a body *out
  from a cell on an open ray* and picks the head end afterwards
  (`_placeClosing`). Then a gap pass grows tails into leftover cells under
  the same DAG rule, and the fullest, then (`holdsChoice`) one within
  `startSlack`/`widestSlack` of `openMoves` at the first move and at its
  widest, then lowest-`meanOpenMoves`, of `candidatesFor(arrows)` boards
  is kept (`kMinCandidates` = 5 on the big boards). Fill is ~85–95%; the level table
  is sized at roughly ten cells per arrow so every level gets its full
  count, and the levels open with ≤ 5 free arrows and offer ~2 taps at a
  typical moment (`test/engine/puzzle_generator_test.dart` pins that).
  `puzzleForLevel(spec)` seeds `Random` from `LevelSpec.seed`, so each
  level is a fixed puzzle. It runs on a background isolate
  (`defaultPuzzleBuilder` → `compute`) behind `GamePhase.loading`; on web
  it runs inline (~0.4 s for level 20, about 2 s for the finale). `dart run tool/level_report.dart
  [level] [extraSeeds]` prints arrows placed vs asked, fill, depth,
  free-at-start, open moves (mean/max vs the cap) and timing — run it after
  touching the table or the generator.
- **Game loop:** `GameNotifier` owns the phase machine
  (`loading → playing ⇄ paused → cleared | outOfLives | timeUp`). `tapArrow` updates
  state instantly; `PuzzleBoard` animates the slide-out / bump purely
  visually, keyed on `GameState.moveToken`. A 100 ms `Timer.periodic` drives
  `tick()` when `autoTick` is true; tests pass `autoTick: false`.
- **Bump:** `models/bump_motion.dart` (pure Dart) describes the blocked
  tap — the arrow accelerates up to the arrow in its way (stopping
  `kStopShort` of a cell before its centre, 140–380 ms by distance) and
  eases back over 360 ms; the blocker flashes and is shoved a touch at
  impact. The board draws `offsetAt/shoveAt/flashAt`. The game screen runs
  the same motion in its own controller to throw the whole screen sideways
  (`joltAt` × `kCrashJoltPx`) and bloom a red edge over it (`flashAt` on a
  radial gradient of `blockedFlash`), so a lost life registers even when
  the eye was nowhere near the arrow. The provider fires the crash sound
  and `HapticsService.miss` (`HapticEngine.crash`: a hard hit plus a
  rumble — an Android waveform, heavy + vibrate elsewhere) on a `Timer` at
  `forwardMs` so they land on impact (a light tick answers the finger at
  once). Tests use `fakeAsync` for that timer.
- **Saved game:** one slot (`models/saved_game.dart`, prefs key
  `arrow_saved_game`, JSON: level, arrows out, slips, hints, clock — the
  board itself is rebuilt from the seed). `GameNotifier.onSnapshot` fires
  after every move/hint/pause/restart/ending and in `dispose` (back, quit,
  next level); `SavedGameNotifier.record` saves a level with progress,
  clears on an ending, and clears an untouched/restarted visit of the same
  level only (peeking at another level keeps the slot). `gameProvider`
  passes `savedGame: forLevel(level)`; a fitting one comes back paused with
  `GameState.resumeOffered` and the "Welcome back" card (Continue / Start
  over / Home). Home's hero card becomes "Pick up where you left off ·
  Continue" for that level. Reset progress clears the slot too.
- **Hints:** `maxHints = 3` per attempt; `Puzzle.hintFor` picks the removable
  arrow that frees the most others; any tap clears the highlight.
- **Grid lines:** drawn through the cell centres (the lattice the arrows lie
  on), not between cells, so every arrow body sits on a line. They are a
  1 px hairline, so `gridLine` keeps ≥ 40 levels of contrast to the page in
  both palettes (`test/ui/theme_test.dart` pins it) — fainter and it
  disappears on a laptop screen.
  `Settings.gridLinesOn` (persisted) but the toggle is earned:
  `ProgressNotifier.gridLinesUnlocked` (clear level `kGridLinesUnlockAfterLevel`
  = 4; always on in the testing build).
- **Zoom:** `InteractiveViewer` (pinch) + toolbar buttons, `kMinZoom`..`kMaxZoom`
  (1×–4×; the late boards are 30+ cells wide, so zoom is how you tap them).
- **Board look:** one ink (`palette.arrowInk`), thin strokes (≤5 px), small
  heads, no frame — the arrows sit straight on the page. The hint glow and
  the blocked flash are the only colour on the board. Slide-out and bump are
  animated in `PuzzleBoard` (240–600 ms slide, ease-in; the bump 140–380 ms
  in and 360 ms back). Strokes cap at
  3 px and heads at 8 px so the small early boards read as pen lines.
- **Sound effects:** `SfxService` (`services/sfx_service.dart`, injectable
  `SfxBackend`, a pool of low-latency players) plays `assets/audio/whoosh.wav`
  on every exit — the pitch climbs a notch per quick successive exit and
  resets after 1.5 s — and `assets/audio/bump.wav` (a knock) on a blocked
  tap, which also ends the streak. Both WAVs are synthesised by
  `tool/make_sfx.py` (pure Python, no deps): the whoosh is swept band-passed
  noise (no tone — a chirp reads as a laser), the bump a sharp crack over a
  sagging thump and a low rumble with a lighter rebound knock — half a
  second and near full scale, since it announces a lost life.
  `Settings.sfxOn` gates both (on by default).
- **Audio:** `AudioService` (injectable `AudioBackend`, audioplayers) loops
  "Game" by The_Mountain (Pixabay Content License, `assets/audio/game.mp3`), credited on
  the Credits screen (`data/audio_credits.dart`). `main.dart` applies the
  settings once on launch, on every change, and pauses on background.
- **Onboarding:** `OnboardingScreen` — two tiny boards played for real
  (`tutorialPuzzleOne/Two`) plus a summary; `Settings.onboardingDone` gates
  it in `main.dart`; Settings → "How to play" replays it (`replay: true`).
- **Home:** a gradient "Next up" hero card and a winding trail of level
  nodes (`_Trail` + `_TrailPainter`), locked/current/cleared states with
  stars and best time.
- **Icon:** `tool/make_icon.py` (Pillow) renders `assets/icon/*.png` and
  the web icons (`web/favicon.png`, `web/icons/*.png` — flutter_launcher_icons
  is Android + iOS only); then `dart run flutter_launcher_icons`.
- **Difficulty:** every knob is in `data/level_specs.dart` — size, arrow
  count, lengths, clock and `openMoves` (3 on levels 1–3, 2 from level 4:
  how many taps the generator leaves available at once); the tests in
  `test/data/level_specs_test.dart` and `test/engine/puzzle_generator_test.dart`
  pin the curve (sizes never shrink, the cap never widens, every level
  generates its full arrow count, solvable, tight, later levels more
  tangled). Tune numbers there; keep the generator test green — it is what
  guarantees a level is playable. The clock is brisk: ~1.8 s an arrow on
  levels 1–4, 2.2 s on 5–9 and 2.6 s from 10 (plus ~18 s) — 27 s on level
  1, ten minutes on the finale — so a level is a sprint of quick reads.
- **Lives / stars:** `maxLives = 3` and `starsForMistakes` live in
  `models/level_progress.dart`.

## Testing

- `flutter test` + `tool/coverage.sh`. The gate excludes generated l10n,
  `main.dart`, and glue marked `// coverage:ignore` (the real periodic timer).
  Don't add `coverage:ignore` to hide untested logic — only true glue.
- `test/widgets/onboarding_test.dart` plays the walkthrough boards for real
  by tapping grid cells.
- Widget tests override `gameProvider` with `autoTick: false` and the tiny
  hand-built board in `test/support/sample_puzzle.dart` (taps are aimed at
  grid cells); pass `puzzle:` to skip the loading phase, or a `builder:`
  returning a `Completer` future to test it. `flutter_animate` schedules a zero-delay start on every mount,
  so tests pump a frame before advancing the clock (see `_settle` in
  `test/widgets/game_screen_test.dart`).
- Screenshot driver finds widgets by accessible name: give tappable widgets a
  `Semantics(label: …, button: true)` or a `tooltip:`.

## Branching

`main` is the default branch and the only long-lived one. Every piece of
work starts on a branch cut from the latest `main` and comes back through a
pull request into `main`; never build on another feature branch, and never
let a feature branch become the repository's HEAD.

## Continuous Integration

GitHub Actions runs on every push to `main` and every PR targeting `main`
(`.github/workflows/ci.yml`). Flutter is pinned in **`.flutter-version`**
(3.47.4 / stable — match `.metadata`; bump both together; the session-start
hook reads the same file). Job "Analyze & test" runs `flutter analyze
--fatal-infos` and `bash tool/coverage.sh 92`. Job "Web smoke & screenshots"
builds the web app, drives it in headless Chromium (`tool/screenshot.mjs`)
at a phone viewport and at 1440×900 with keyboard presses, fails on any
Flutter exception, and uploads `shots/`.

Job "Debug APK" builds `flutter build apk --debug` ("Arrow Testing", every
level unlocked), uploads it as the `arrow-debug-apk` artifact and, on a PR,
keeps a sticky comment with the download link — an installable build of every
change without checking it out.

Two more workflows publish the web build to the **`gh-pages` branch**, which
GitHub Pages serves (Settings → Pages → Source = "Deploy from a branch",
Branch = `gh-pages` / (root), set once):

- `.github/workflows/pages.yml` — on every push to `main` (and manually via
  workflow_dispatch): the release web app with `--base-href /<repo>/`,
  committed to the branch root. Release = locked progression, same as the
  store build. It deploys with `clean-exclude: pr-preview/` and `force:
  false`, so it rebases onto concurrent preview deploys instead of wiping
  them.
- `.github/workflows/pr-preview.yml` — on every PR event: the release web app
  built with `--dart-define=UNLOCK_ALL=true` (so a reviewer can reach any
  level) and a base href of `/<repo>/pr-preview/pr-<number>/`, deployed to
  `pr-preview/pr-<number>/` on the same branch with `target-folder` + `clean`
  (which wipes only that folder), plus a sticky link comment. Its `remove` job
  deletes the folder and the comment when the PR closes, re-fetching `gh-pages`
  before each of 3 push attempts so a concurrent deploy is merged, not
  overwritten. This is `rossjrw/pr-preview-action` spelled out — that action is
  a composite that still pins node20 builds of the two actions it wraps.

Both base hrefs are derived from the repo name, so the workflows port to
other repos unchanged. Both skip PRs from forks (no token to write
`gh-pages`); the repo needs Settings → Actions → General → Workflow
permissions = "Read and write permissions" for the branch push and the
comments.

Every action is pinned to its **major** tag, and every major in use resolves
to a `node24` (or composite) release — node20 is deprecated on GitHub-hosted
runners. When adding a third-party action, check its `runs.using`, and for a
composite action check the `uses:` inside it too.

## Conventions

- Dart `^3.12.2`, Material 3, `useMaterial3: true`; stock `flutter_lints` (no overrides).
- **Theming:** light + dark via `ThemeMode` (default `system`, set in Settings). Widgets read colours through `context.palette` (an `ArrowPalette` chosen by brightness) — never hardcode a `Color`. Add new tokens as fields on `ArrowPalette` with both light/dark values in `ui/colors.dart`.
- `snake_case` filenames; const-heavy; trailing commas; imports at the top.
- Immutable state with `copyWith`; Riverpod **StateNotifier** style (not codegen).
- **No `try/except`** unless explicitly required.
- Prefer "allowedlist/blocklist" over black/white; format large numbers as `10_000`.

## Pending follow-ups

- **Localization:** only English is authored (`lib/l10n/app_en.arb`); the
  l10n pipeline is wired, so adding a language is a second `.arb` file plus a
  language picker in Settings.
- **Sound effects:** exit whoosh and blocked bump exist; any further sound
  is another synth in `tool/make_sfx.py` (never `.ogg` — iOS can't decode
  Vorbis via audioplayers) and a method on `SfxService`.
- **iOS:** code is iOS-ready; the matching iOS scheme needs Xcode (not set up here).
