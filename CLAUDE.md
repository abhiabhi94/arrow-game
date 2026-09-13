# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A playful cross-platform (Android + iOS) **arrow exit puzzle** built with
Flutter (in the spirit of "Arrow Exit Puzzle"). Bent arrow pieces sit on a
grid; tapping one slides it along its own path, the way its head points, until
it leaves the board. An arrow whose exit path runs into another arrow bumps
back and costs a life. 20 fixed, procedurally generated levels on a steep
curve (5 arrows on 5×6 → 59 on 19×26 by level 8 → 144 on 32×50), drawn in a
single ink like a printed puzzle, 3 lives per level (losing all three resets the level behind a
"Retry" screen), a clock on every level ("Time's up" → replay the same level),
3 hints per level, zoom in/out, an earned grid-lines toggle (after level 4),
1–3 stars per clear, local progress, light/dark theme, haptics.

## Build & Development Commands

```bash
flutter pub get                 # deps
flutter gen-l10n                # regenerate localizations after editing lib/l10n/*.arb
flutter analyze --fatal-infos   # static analysis (must be clean; CI fails on infos)
flutter test                    # full test suite
tool/coverage.sh 92             # coverage gate (fails under threshold)

flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run  # web build (debug = all levels unlocked)
node tool/screenshot.mjs --levels 1,7,20 --settings --hint          # phone-viewport screenshots -> shots/

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
hint glow, light/dark) at 390×844 and writes PNGs to `shots/`; it exits 1 on
any Flutter exception, so it doubles as the CI smoke test
(`.github/actions/web-smoke`, job "Web smoke & screenshots"). See
`.claude/skills/run/SKILL.md` and `docs/cloud-dev.md`. The SessionStart hook
in `.claude/hooks/session-start.sh` installs the SDK pinned in
`.flutter-version`.

The web target is a verification/preview target; the shipped platforms are
Android + iOS. The typeface (Google Sans Flex, OFL, static weights 400–800)
is bundled in `assets/fonts/` and declared under `flutter: fonts:` as
`GoogleSansFlex` — no `google_fonts`, no runtime fetch.

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
  with all ABIs). Namespace is `app.curious.arrow`.
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
    puzzle_generator.dart reverse-order generator (solvable by construction), best-of-N candidates
  data/level_specs.dart  the 20 levels (board size, arrow count, length range, clock)
  models/              level_spec, level_progress (stars), settings, game_state (phases, moves)
  providers/           app_providers (DI root), settings_provider, progress_provider, game_provider
  services/            haptics_service (injectable HapticEngine), audio_service (looping music)
  data/audio_credits.dart  CC-BY attribution for the bundled track
  screens/             onboarding (interactive 3-step walkthrough), home (journey trail),
                       game (board + toolbar + overlays), settings, credits
  ui/                  colors.dart (light+dark ArrowPalette), theme.dart (Material 3 + Google Sans Flex)
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
- **Generation:** `puzzle_generator.dart` places arrows in reverse solving
  order on a flat byte grid: it enumerates every (head, heading) whose exit
  ray is clear, samples deep heads first (inside-out fill keeps the free area
  an outer ring), grows bodies step by step scoring straightness, hugging
  (arrows/border) and existing rays, with a length ramp (inner short, outer
  long — nested rings), keeps the best of `kPlacementChoices` bodies per
  arrow, then a gap pass grows tails into leftover cells (safe: a tail may
  only land on rays of arrows placed *earlier*), and finally keeps the
  fullest/most tangled of `candidatesFor(arrows)` boards. Fill is ~90%+;
  the level table is sized at roughly ten cells per arrow so every level
  gets its full count. `puzzleForLevel(spec)` seeds `Random`
  from `LevelSpec.seed`, so each level is a fixed puzzle. It runs on a
  background isolate (`defaultPuzzleBuilder` → `compute`) behind
  `GamePhase.loading`; on web it runs inline (~1 s for the finale).
  `dart run tool/level_report.dart [level] [extraSeeds]` prints arrows placed
  vs asked, fill, depth, free-at-start and timing — run it after touching the
  table or the generator.
- **Game loop:** `GameNotifier` owns the phase machine
  (`loading → playing ⇄ paused → cleared | outOfLives | timeUp`). `tapArrow` updates
  state instantly; `PuzzleBoard` animates the slide-out / bump purely
  visually, keyed on `GameState.moveToken`. A 100 ms `Timer.periodic` drives
  `tick()` when `autoTick` is true; tests pass `autoTick: false`.
- **Hints:** `maxHints = 3` per attempt; `Puzzle.hintFor` picks the removable
  arrow that frees the most others; any tap clears the highlight.
- **Grid lines:** `Settings.gridLinesOn` (persisted) but the toggle is earned:
  `ProgressNotifier.gridLinesUnlocked` (clear level `kGridLinesUnlockAfterLevel`
  = 4; always on in the testing build).
- **Zoom:** `InteractiveViewer` (pinch) + toolbar buttons, `kMinZoom`..`kMaxZoom`
  (1×–4×; the late boards are 30+ cells wide, so zoom is how you tap them).
- **Board look:** one ink (`palette.arrowInk`), thin strokes (≤5 px), small
  heads, no frame — the arrows sit straight on the page. The hint glow and
  the blocked flash are the only colour on the board. Slide-out and bump are
  animated in `PuzzleBoard` (450–1300 ms slide, ease-in).
- **Audio:** `AudioService` (injectable `AudioBackend`, audioplayers) loops
  "Permafrost" by Scott Buckley (CC-BY 4.0, `assets/audio/`), credited on
  the Credits screen (`data/audio_credits.dart`). `main.dart` applies the
  settings once on launch, on every change, and pauses on background.
- **Onboarding:** `OnboardingScreen` — two tiny boards played for real
  (`tutorialPuzzleOne/Two`) plus a summary; `Settings.onboardingDone` gates
  it in `main.dart`; Settings → "How to play" replays it (`replay: true`).
- **Home:** a gradient "Next up" hero card and a winding trail of level
  nodes (`_Trail` + `_TrailPainter`), locked/current/cleared states with
  stars and best time.
- **Icon:** `tool/make_icon.py` (Pillow) renders `assets/icon/*.png`; then
  `dart run flutter_launcher_icons`.
- **Difficulty:** every knob is in `data/level_specs.dart`; the tests in
  `test/data/level_specs_test.dart` and `test/engine/puzzle_generator_test.dart`
  pin the curve (sizes never shrink, every level generates its full arrow
  count, solvable, later levels more tangled). Tune numbers there; keep the
  generator test green — it is what guarantees a level is playable.
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

## Continuous Integration

GitHub Actions runs on every push to `main` and every PR targeting `main`
(`.github/workflows/ci.yml`). Flutter is pinned in **`.flutter-version`**
(3.44.8 / stable — match `.metadata`; bump both together; the session-start
hook reads the same file). Job "Analyze & test" runs `flutter analyze
--fatal-infos` and `bash tool/coverage.sh 92`. Job "Web smoke & screenshots"
builds the web app, drives it in headless Chromium (`tool/screenshot.mjs`),
fails on any Flutter exception, and uploads `shots/`.

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
- **Sound effects:** music only; a slide/bump sfx would need new assets
  (`.mp3`/AAC, never `.ogg` — iOS can't decode Vorbis via audioplayers).
- **iOS:** code is iOS-ready; the matching iOS scheme needs Xcode (not set up here).
