# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A playful cross-platform (Android + iOS) **arrow exit puzzle** built with
Flutter (in the spirit of "Arrow Exit Puzzle"). Bent arrow pieces sit on a
grid; tapping one slides it along its own path, the way its head points, until
it leaves the board. An arrow whose exit path runs into another arrow bumps
back and costs a life. 80 fixed, procedurally generated levels on a steep
curve (5 arrows on 5×6 → 59 on 19×26 by level 8 → 144 on 32×50 by level
20 → 224 on 42×63 by level 40 → 304 on 47×73 by level 60 → 384 on 52×84), drawn in a
single ink like a printed puzzle, 3 lives per level (spend them all and a
card asks for a riddle: crack it and the level carries on for one more
mistake, then asks again — or start fresh), a clock on every level ("Time's
up" → replay the same level), 3 hints per level, zoom in/out, a grid-lines
toggle earned after level 4 and on by default from there, 1–3 stars per
clear, local progress, light/dark theme, English and हिन्दी (following the
device by default), haptic feedback.

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
node tool/screenshot.mjs --levels 1 --riddle 2,4,2,3,2,2            # spend all 3 lives -> Out of lives, the riddle, its hint, solved
node tool/screenshot.mjs --lang hi --settings --levels 1 --riddle 2,4,2,3,2,2 --riddle-answer aam  # the same in Hindi
node tool/screenshot.mjs --levels 1 --riddle-hint 2,4                # spend the 3 hints -> the riddle button, its riddle, the hint it buys

flutter run                     # debug build = "Arrow Testing", all levels unlocked
flutter run --release           # release build = "Arrow", locked progression
flutter build apk --debug       # -> build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release     # -> app-release.apk (upload-key signed if key.properties present)
flutter build appbundle --release  # -> build/app/outputs/bundle/release/app-release.aab (for Play Store)

tool/bump_version.sh [patch|minor|major|build|X.Y.Z] [--push]  # bump pubspec, commit, tag (+ push: cuts a release)
```

## Cloud sessions & visual verification

Claude Code on the web has no Android emulator (no KVM). The stand-in is the
**web build + headless Chromium**: `tool/screenshot.mjs` serves `build/web`,
drives the app (home, settings, any level's board and — with `--hint` — the
hint glow, light/dark) at 390×844 and writes PNGs to `shots/`; `--viewport
WxH` renders the desktop layout instead and `--keys` presses keys on each
opened level (both exercised in CI, since the web build is also played on a
laptop via GitHub Pages); `--crash x,y` taps a grid cell on the first level
and captures the bump 260 ms in on Playwright's fake clock (a screenshot
takes longer than the bump), with the semantics layer made pointer-transparent
for the tap — a click on the board's accessibility node would otherwise be a
semantic tap at the board's centre. `--riddle x,y,…` spends every life on
three different blocked heads (level 1: `2,4,2,3,2,2`) and captures the
"Out of lives" card, the riddle behind it, the riddle with its hint out and
the answer accepted — it seeds an unshuffled pack so the riddle is always the
first in the bank (`--riddle-answer`, default `shadow`). `--lang en|hi` seeds
the language setting; the driver finds widgets by their accessible name, so
it keeps a small table of those names per language. It exits 1 on any Flutter exception, so it doubles
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
  Dart symbols) as an artifact and a GitHub Release. Cloud sessions
  have no key, so a bundle built here is debug-signed and only proves the
  build compiles. Guide: `docs/release.md`.
- **Cutting a release** is `tool/bump_version.sh` from an up-to-date `main`:
  it rewrites `version:` in `pubspec.yaml`, commits, makes an annotated
  `v<name>+<code>` tag — `v` plus the whole version, one shape always, which
  `release.yml` refuses to build if it disagrees with pubspec — and prints
  the commit as a patch. **The current version name
  comes from the newest `v*` tag, not from `pubspec.yaml`** — v1.0.0, v1.1.0
  and v1.2.0 all shipped while pubspec's name stayed `1.0.0` and only its
  `+N` moved, so the script takes the name from whichever is further along
  (tag or pubspec) and the code from the highest of pubspec now, the code the
  newest tag spells out, and pubspec at that tag, which also drags pubspec
  back in line. The three tags cut before this (`v1.0.0`, `v1.1.0`, `v1.2.0`)
  carry only a name and are still read correctly. The argument
  (`patch` default, `minor`, `major`, `build`, or an explicit `X.Y.Z`) moves
  the name; the `+N` code always increments, because Play needs it strictly
  higher than any uploaded build. **Pushing is always offered, never assumed** — it
  asks separately for the branch and for the tag (the tag push is what runs
  the workflow), and declining prints the push and undo commands. `--push`
  only answers those two questions for a run with nobody to ask (`-y`, or no
  terminal), so an unattended run without it commits and tags but publishes
  nothing. It prints the plan and asks before the commit
  too, and refuses a dirty tree, a non-`main` branch, a branch behind
  `origin` or an existing tag (`--dry-run`, `-y`, `--check`, `--no-tag`,
  `--tag NAME`, `--any-branch`, `--no-fetch`).

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
    answer_match.dart    judging a typed riddle answer (exact / close / wrong)
  data/level_specs.dart  the 60 levels (board size, arrow count, length range, clock)
  data/riddle_bank.dart  100 riddles in English + 100 पहेलियाँ in Hindi
  models/              level_spec, level_progress (stars), settings, game_state (phases, moves),
                       bump_motion (the blocked-tap animation), saved_game (resume snapshot),
                       riddle (question, answers, hint)
  providers/           app_providers (DI root), settings_provider, progress_provider, game_provider,
                       saved_game_provider (the one level in progress), riddle_provider (the deck)
  services/            haptics_service (injectable HapticEngine), sfx_service (whoosh + bump),
                       audio_service (looping music)
  data/audio_credits.dart  attribution for the bundled track
  screens/             onboarding (interactive 3-step walkthrough), home (journey trail),
                       game (board + toolbar + overlays), settings, credits
  ui/                  colors.dart (light+dark ArrowPalette), theme.dart (Material 3 + Google Sans Flex),
                       layout.dart (phone-width column + mouse-drag scrolling for the desktop browser)
  widgets/             puzzle_board (painter + slide/bump animations), board_toolbar,
                       lives_indicator, timer_bar, stars_row, result_card, riddle_card
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
  it runs inline (~0.4 s for level 20, about 2.5 s for level 60 and ~4 s for
  the 52×84 finale, which takes 1.7× level 60's time in the VM). `dart run tool/level_report.dart
  [level] [extraSeeds]` prints arrows placed vs asked, fill, depth,
  free-at-start, open moves (mean/max vs the cap), `Puzzle.openTapRisk` and
  timing — run it after touching the table or the generator.
- **`Puzzle.openTapRisk`** is the fat-finger number: the share of a playable
  arrow's own cells that touch an arrow which cannot move yet, averaged over
  a greedy solve. It sits near 0.49 from level 12 on — half the cells of the
  arrow you want are one slipped finger from a lost life. It is measured but
  deliberately *not* selected on. Candidates vary (0.41–0.60 at level 18),
  but the kind boards are the loose, shallow ones: picking the lowest risk
  outright took level 1 from depth 5 to 3, level 10 from 41 to 28 and level
  18's opening from 2 free arrows to 5, while choosing only among boards the
  curve cannot tell apart won nothing (level 18 came back identical), and on
  levels 20 and 40 the lowest-risk candidate is already the one the existing
  keys pick. Playable arrows also already average ~8 free cells of margin
  (~40% of their perimeter), so an "apron" pass has nothing to add. Density
  is the wrong lever for mis-taps; input handling is.
- **Game loop:** `GameNotifier` owns the phase machine
  (`loading → playing ⇄ paused → cleared | outOfLives | timeUp`). `tapArrow` updates
  state instantly; `PuzzleBoard` animates the slide-out / bump purely
  visually, keyed on `GameState.moveToken`. A 100 ms `Timer.periodic` drives
  `tick()` when `autoTick` is true; tests pass `autoTick: false`.
- **Bump:** `models/bump_motion.dart` (pure Dart) describes the blocked
  tap — the arrow accelerates up to the arrow in its way (stopping
  `kStopShort` of a cell before its centre, 180–460 ms by distance) and
  eases back over 480 ms; the blocker flashes and is shoved a touch at
  impact. The board draws `offsetAt/shoveAt/flashAt`. The game screen runs
  the same motion in its own controller to throw the whole screen sideways
  (`joltAt` × `kCrashJoltPx`) and bloom a red edge over it (`flashAt` on a
  radial gradient of `blockedFlash`), so a lost life registers even when
  the eye was nowhere near the arrow. **The ending waits for all of it:**
  `_endingHeld` on the game screen holds the "Out of lives" card back until
  the crash animation completes — a scrim dropping in the same frame as the
  tap means the player never sees the bump that cost them the level — and
  `PuzzleBoard._syncSlump` holds the slump the same way, so the board droops
  after the arrow has visibly hit rather than around it in mid-air.
  The provider fires the crash sound
  and `HapticsService.miss` (`HapticEngine.crash`: a hard hit plus a
  rumble — an Android waveform, heavy + vibrate elsewhere) on a `Timer` at
  `forwardMs` so they land on impact (a light tick answers the finger at
  once). Tests use `fakeAsync` for that timer.
- **Saved game:** one slot (`models/saved_game.dart`, prefs key
  `arrow_saved_game`, JSON: level, the board's seed, arrows out, slips,
  hints, clock — the board itself is rebuilt from the seed, and the seed is
  stored because a level can be re-dealt (`LevelSpec.variant`): a snapshot
  from another board, or one without a seed, is not resumed). `GameNotifier.onSnapshot` fires
  after every move/hint/pause/restart/ending and in `dispose` (back, quit,
  next level); `SavedGameNotifier.record` saves a level with progress,
  clears on an ending, and clears an untouched/restarted visit of the same
  level only (peeking at another level keeps the slot). `gameProvider`
  passes `savedGame: forLevel(level)`; a fitting one comes back paused with
  `GameState.resumeOffered` and the "Welcome back" card (Continue / Start
  over / Home). Home's hero card becomes "Pick up where you left off ·
  Continue" for that level. Reset progress clears the slot too.
- **Hints:** `maxHints = 3` per attempt; `Puzzle.hintFor` picks the removable
  arrow that frees the most others; any tap clears the highlight. The
  button never goes dead: once `hintsLeft` is zero it wears
  `kRiddleHintIcon` (a head with a question mark) and a "?" badge, and a
  press pauses the level and puts a riddle over the board
  (`RiddlePrize.hint` on `RiddleChallenge`; the game screen's `_onHint`,
  also behind the **H** key). Cracked, it resumes and calls
  `GameNotifier.earnHint`, which lights an arrow without touching
  `hintsLeft`, so the next one costs a riddle too; "Never mind" just
  resumes. The clock is paused under the riddle because a level-1 clock
  is 26 s and a riddle takes longer than that.
- **Grid lines:** drawn through the cell centres (the lattice the arrows lie
  on), not between cells, so every arrow body sits on a line. They are a
  1 px hairline, so `gridLine` keeps ≥ 40 levels of contrast to the page in
  both palettes (`test/ui/theme_test.dart` pins it) — fainter and it
  disappears on a laptop screen.
  `Settings.gridLinesOn` (persisted) but the toggle is earned:
  `ProgressNotifier.gridLinesUnlocked` (clear level `kGridLinesUnlockAfterLevel`
  = 4; always on in the testing build).
- **Zoom:** `InteractiveViewer` (pinch) + toolbar buttons, from `kMinZoom` to
  `maxZoomFor(cellPx)` — `kMaxZoom` (4×), or as much more as it takes to bring
  a cell up to `kFingerCellPx` (46). A flat 4× left a level-40 cell at 33 px,
  so the last levels had no zoom at which a target was finger-sized.
- **Taps the player didn't mean** (`widgets/puzzle_board.dart`): a tap is
  dropped while the board is still moving from the last one (the whole bump,
  the first `kSettleFraction` of a slide — keyed off the animation
  controllers, so the engine stays pure), and when the gesture had more than
  one finger down (a pinch below the pan slop used to end as a tap). A tap on
  an empty cell takes the nearest arrow within `kTouchSlopPx` on screen,
  capped at 1.5 cells; an occupied cell always wins, so slop never overrides
  a deliberate hit. The board's `zoom` keeps the slop a fixed size on screen.
  The HUD and toolbar keep the side gutter and the board runs edge to edge,
  which is ~9% more cell on the dense levels.
- **Endings react** (`models/reaction_motion.dart`, pure Dart like
  `bump_motion.dart`): a cleared level makes the whole play column **hop**
  (`hopScaleX/Y` — a squash, a spring past normal, a settle; the board itself
  is empty by then, so the celebration has to be the screen), and a spent
  allowance or a run-out clock makes every arrow left on the board **slump**
  (`slumpDropFor`/`slumpTiltFor` droop and tilt each arrow by its own amount,
  jittered from its id so the board sags raggedly rather than sliding as one
  block). `ResultCard.mood` gives the card's emoji the matching manner:
  `cheer` over-spins and boings in, `sulk` flops down and shakes its head.
- **Board look:** one ink (`palette.arrowInk`), thin strokes (≤5 px), small
  heads, no frame — the arrows sit straight on the page. The hint glow and
  the blocked flash are the only colour on the board. Slide-out and bump are
  animated in `PuzzleBoard` (240–600 ms slide, ease-in; the bump 180–460 ms
  in and 480 ms back). Strokes cap at
  3 px and heads at 8 px so the small early boards read as pen lines.
- **Sound effects:** `SfxService` (`services/sfx_service.dart`, injectable
  `SfxBackend`, a pool of low-latency players built once behind a single
  `_building` future — `play` is fire-and-forget, so an unguarded
  `if (_pool.isEmpty)` let two quick taps each fill the pool — and warmed up
  from `main.dart` at launch, never while effects are off) plays `assets/audio/whoosh.wav`
  on every exit — the pitch climbs a notch per quick successive exit and
  resets after 1.5 s — and `assets/audio/bump.wav` (a knock) on a blocked
  tap, which also ends the streak. Both WAVs are synthesised by
  `tool/make_sfx.py` (pure Python, no deps): the whoosh is swept band-passed
  noise (no tone — a chirp reads as a laser), the bump a sharp crack over a
  sagging thump and a low rumble with a lighter rebound knock — half a
  second and near full scale, since it announces a lost life.
  It also plays `assets/audio/win.wav` when a level is cleared (four plucked
  notes up a major triad — the one moment the game sings) and
  `assets/audio/lose.wav` on a spent allowance or a run-out clock (a comic
  deflation: a note sagging a minor sixth with a wobble, onto a small flat
  thud). On a life-losing bump the sting waits `kEndingStingMs` after the
  knock so the two read as two things. `Settings.sfxOn` gates all four (on by
  default).
- **Audio:** `AudioService` (injectable `AudioBackend`, audioplayers) loops
  "Game" by The_Mountain (Pixabay Content License, `assets/audio/game.mp3`), credited on
  the Credits screen (`data/audio_credits.dart`). `main.dart` applies the
  settings once on launch, on every change, and pauses on background.
  **Audio focus:** every audioplayers player carries its own Android focus
  request, and the default is `AUDIOFOCUS_GAIN` — which Android grants by
  taking focus *off the music player in the same app*, whereupon the plugin
  pauses it (`WrappedPlayer.onLoss`). That is why the music died on the first
  arrow of a level. The effect players are therefore built with
  `AndroidAudioFocus.none`, which `FocusManager` grants without asking
  anyone. Music keeps `gain` so it still yields to calls and other apps.
  `AudioBackend.interruptions` reports any stop the service did not ask for,
  and `AudioService._recover` restarts the loop (via `loop`, not `resume` —
  a *stopped* player cannot resume), capped at `kMaxMusicRecoveries` per
  settings/foreground change so a platform that is refusing to play is not
  asked forever. Without that feedback the service's `_playing` flag drifted
  from reality and one lost focus meant silence for the rest of the session.
- **Autoplay on the web:** a browser will not start audio before the page has
  been touched — `audioplayers_web` builds an `AudioContext` that is created
  `suspended` — and it refuses *quietly*: the call to play resolves normally,
  or never completes at all, and the plugin's own `AudioPlayer.state` is
  intent rather than evidence. So `main.dart` wraps the app in a `Listener`
  whose `onPointerDown` calls `AudioService.nudge()`, and `nudge` asks
  `AudioBackend.isPlaying` — implemented as "has the playhead moved",
  the only honest signal — before deciding there is nothing to do. It then
  goes back through `loop`, because a player that never started cannot be
  resumed. Nothing may latch for the duration of a start attempt: the web
  plugin's future can hang forever, and a flag held across it blocked every
  retry for the whole visit (a regression test in
  `test/services/audio_service_test.dart` pins that). Verified in headless
  Chromium with `--autoplay-policy=document-user-activation-required`: the
  context starts suspended, and the first tap takes it to `running` with the
  track playing.
- **Onboarding:** `OnboardingScreen` — two tiny boards played for real
  (`tutorialPuzzleOne/Two`) plus a summary; `Settings.onboardingDone` gates
  it in `main.dart`; Settings → "How to play" replays it (`replay: true`).
- **Home:** a gradient "Next up" hero card and a winding trail of level
  nodes (`_Trail` + `_TrailPainter`), locked/current/cleared states with
  stars and best time. The header (`_HomeHeader`, a
  `SliverPersistentHeaderDelegate`) is **pinned**: the trail is eighty levels
  long, and the star count and the way into Settings should not be eighty
  levels back up the page. It shrinks 96 → 62 as the page scrolls — the
  title comes down to a heading and the tagline folds away, and out of the
  widget tree, so it is not read out either — while the pill and the gear
  stay put. Two things it has to get right: the delegate fills its extent
  (`SizedBox.expand`; a child that measures shorter paints less than it lays
  out, which asserts), and it is a sliver of the scroll view itself rather
  than one of the `SliverMainAxisGroup` below, where a pinned header hits
  that same assert.
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
  guarantees a level is playable. The clock is brisk: ~1.7 s an arrow on
  levels 1–4, 2.1 s on 5–9 and 2.5 s from 10 (plus ~17 s) — 26 s on level
  1, 9½ minutes on level 40, about 11½ on level 60, 12¾ on the finale — so
  a level is a sprint of quick reads. Those are the numbers the curve was drawn with,
  less 5%: every level's clock was tightened by that much in one pass, so
  the shape is unchanged and the whole game is that much brisker.
  **Levels 41–60** keep climbing four arrows a level (228 → 304) while the
  board barely grows (42×64 → 47×73), and the count is not the only thing
  that climbs — it was, once, and the last twenty levels felt like one
  level played twenty times. Three more things move: the shortest arrow is
  4 cells rather than 3 (the generator cannot place the full count at 5 on
  those boards, and `openMoves: 1` makes boards *looser*, since every closer
  it places is itself a new open arrow), the clock tightens from ~2.54 s an
  arrow at level 41 to 2.30 s at 60 (the limits still grow, just slower
  than the arrow count), and each level is dealt from the **variant**
  (`LevelSpec.variant`, folded into the seed) whose board is the tightest
  the generator offered, chosen so the moves open at a typical moment fall
  level by level (about 2.5 at 41 to about 2.1 at 60, against 2.4–3.0 on
  levels 20–40) and no level opens with more than three arrows to tap. The
  generator's own tightness plateaus from about level 20 — its candidate
  pool is only `kMinCandidates` boards on the big levels, and among them
  the mean open moves scatter between ~2.1 and ~3.2 — so re-dealing is
  where the endgame's tightness comes from; `dart run
  tool/level_report.dart <level> <n>` prints a level's next n variants.
  `test/engine/puzzle_generator_test.dart` pins the descent, so a generator
  change that loosens a late level means re-picking its variant, not
  loosening the test. The saved game records the board's seed and a
  snapshot from another board (a re-dealt level, or one written before the
  seed was stored) is not resumed. The last levels are long only because
  there are 300–400 arrows to read, and the saved-game slot means such a
  board can be put down and picked up.
  **Levels 61–80** are the last act and the clock is what makes it one.
  The count climbs on four a level (308 → 384), the board keeps pace with
  it (47×74 → 52×84, ~11.2–11.4 cells an arrow throughout so the fill
  stays ~0.9), the longest run stretches to 16 cells, and every level is
  dealt from its tightest variant under the same hunt-never-eases test.
  What is new is that the pace per arrow keeps falling past the endgame's
  2.30 s — 2.29 s at 61 to 2.00 s at 80 — so the limit grows from 11:40
  at level 60 to only 12:48 on the finale for eighty more arrows
  (`test/data/level_specs_test.dart` pins the 2.00 s floor and that the
  last act's clock grows by under a tenth while its count grows by a
  quarter). The arrows-per-open-move hunt keeps climbing through 80
  because the count does even where the variants' mean open moves plateau;
  the generator's own tightness does not improve past level 20.
- **Lives / stars:** `models/level_progress.dart`. `maxLives` is 3 on every
  level and `starsForMistakes(mistakes)` is the plain rule (flawless three,
  one slip two, two slips one). Spending the allowance is not the end of the
  level: the "Out of lives" card offers to carry on — but only through a
  **riddle** (see below), which is what calls `GameNotifier.keepGoing`. It
  plays on from where the board stood with the clock where it was. The reprieve is **one mistake long** — the next
  fresh bump ends the attempt and asks again — and `GameState.continues`
  counts how many times it was taken. `GameState.stars` floors a clear at one
  star, so a zero there only ever means "not cleared". A second run at an
  arrow already in `GameState.bumped` is free: that lesson is paid for, and a
  200-arrow board is too big to hold every dead end in your head. Both
  `bumped` and `continues` travel in the saved game.
- **The riddle gate** (`data/riddle_bank.dart`, `engine/answer_match.dart`,
  `providers/riddle_provider.dart`, `widgets/riddle_card.dart`): carrying on
  past a spent allowance is earned rather than tapped through, so lives are
  never spent thoughtlessly and a 300-arrow board is still never lost to one
  slipped finger; the same card, with `RiddlePrize.hint`, sells a fourth
  hint and every one after it (see **Hints**). Each language has its own bank of `kRiddleCount` (100)
  riddles — ids 51–100 a shade more lateral than the first fifty, since the
  first fifty read as too easy, though the answer is still one everyday word
  and the gate is still not a crossword — the Hindi ones are written as पहेलियाँ, not translated, since a
  pun rarely survives the crossing — and `RiddleDeckNotifier` deals a
  *shuffled pack* rather than rolling a die: every riddle comes up before any
  repeats, the order and position are persisted (`arrow_riddle_order`,
  `arrow_riddle_cursor`, `arrow_riddles_solved`), and a reshuffle never opens
  on the riddle the last pack closed with. `judgeAnswer` is deliberately
  generous — it compares the typed word, the word with its inflections peeled
  off (English plurals/tenses, Hindi case endings) and the word within a typo
  or two (Damerau, so a transposition costs one, not two) — and reports
  anything but a direct hit as `AnswerVerdict.close`, which the card
  celebrates ("close enough") and lets through. The 💡 gives a clue on the
  first press and the first letter on the second, and it is a **chip in the
  row that already says how long the answer is**, not a button (filled with
  `accentSun` and lettered in `onAccent`, the pairing the toolbar's hint badge
  uses and `test/ui/theme_test.dart` pins at 4.5:1). **A wash never carries
  its own tint as text** — that is how both pills first shipped and why their
  labels all but vanished, amber on pale amber in the light theme and the
  primary at 3.4:1 on its own wash in the dark one. The quiet pills take
  `ArrowPalette.chipInk`, which steps away from the wash in each palette
  (darker on light, lighter on dark): a card with a
  column of buttons at its foot should not have a second one loose in its
  middle, and the hint opens directly under the chip that gave it. A
  different riddle is offered after two misses; a wrong answer costs nothing
  but a wobble and a joke at the guess's expense — `kRiddleQuips` (30) of
  them per language, dealt from a pack shuffled when the card is built
  rather than sampled at random, because a random pick repeats itself within
  a handful of guesses and the same line twice reads as a bug rather than as
  ribbing. They never mention the 💡 (it may be spent) or count the misses
  (they arrive in a shuffled order), and they are at the guess's expense,
  never the player's: the gate is meant to be the fun part of losing, not a
  second punishment. The
  card wears `kRiddleAskingEmoji` while it asks: **every riddle's emoji is a
  picture of its answer**, so the riddle's own emoji is held back and arrives
  as the reveal on the solved card. The card asks for the answer field's
  focus outright — from `initState`, not `autofocus`, which only applies
  while nothing in the scope has ever held the focus, and the game screen's
  keyboard-shortcut `Focus` always has — and `_keepTyping` puts the keyboard
  back after anything else on the card is pressed. Off the web a chip never
  takes the focus and that is a no-op; the shape of it is dictated by the web
  with accessibility on (a screen reader, or the screenshot harness, which
  enables semantics to find widgets by name). There a chip is a DOM element
  that takes the browser's focus on mousedown: the field's DOM input blurs,
  the engine shuts its text-editing strategy down and *schedules a deferred
  blur* of that input on a zero-delay timer of its own, and the framework's
  focus follows to the chip. The engine wakes the field again only on a
  semantics update in which its focus has changed to on, and that has to land
  **after the engine's timer**: a refocus that lands first is undone by it
  (the stale blur finds the input focused and moves the focus to the view
  root), and the typing goes nowhere. What shipped first was a post-frame
  callback, which ran inside the frame — and Chromium runs frames ahead of
  pending timers, so on a slow build it always lost. Two things fix it. The
  refocus is asked for from a zero-delay `Timer` queued from the tap, which
  sits behind the engine's in the same queue. And nothing may hand the field
  the focus sooner: a chip that vanishes on the press (the 💡 after the
  first letter) would, because a removed focus node passes the focus to the
  scope's previously focused child — the field — inside the frame that
  removes it, ahead of the timer; so `_keepTyping` first parks whatever
  holds the focus on the enclosing `Focus` (the game screen's shortcuts,
  which has no semantics node and so moves nothing in the browser). The
  chips and buttons **keep their focus nodes**: a chip that could not take
  the focus would still steal the browser's, and with nothing changing on
  the framework's side the field would look focused to Flutter and be dead
  to the browser. (An unfocus-and-refocus toggle does not work either: the
  engine also defers the `SemanticsAction.focus` it induces during a frame,
  so a stale one lands right after the unfocus and the toggle completes
  within one frame, invisible to semantics.)
  `test/widgets/riddle_card_test.dart` pins the open-time focus and that a
  vanishing chip hands nothing back; the harness is the regression test for
  the rest: `--riddle` types the answer with the real keyboard and exits 1
  unless the solved card's button (`riddleBackToBoard`) appears. Every Hindi
  answer also lists its **romanized** spellings ('paani', 'jal'), because a
  phone set to Hindi very often has no Devanagari keyboard on it, and the
  field says so; `test/data/riddle_bank_test.dart` pins that every one of
  them has at least one.
  `test/data/riddle_bank_test.dart` pins that no riddle in a bank accepts
  another riddle's answer, which is what keeps that generosity honest; when
  two words collide (धुआँ is one letter from कुआँ), the bank gives way rather
  than the matcher getting stricter. The banks also barely share a *subject*:
  the Hindi one is about गन्ना, मेहँदी, कुआँ and रेलगाड़ी, not about whatever
  the English riddle with the same id happens to be. The gate is UI-level state
  (`_riddleId` on the game screen): the engine and `GameState` know nothing
  about riddles.
- **Language:** `Settings.languageChoice` (`arrow_language`, default
  `LanguageChoice.system`) → `localeFor` in `main.dart` →
  `MaterialApp.locale`, where **null is the point**: it hands the choice back
  to Flutter, which resolves the device locale against `supportedLocales`, so
  a phone set to Hindi opens in Hindi. Settings → Language pins one instead.
  The riddle card reads `Localizations.localeOf(context).languageCode` to
  pick its bank, so the riddles follow the app's language rather than a
  stored copy of it.

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

- **Localization:** English and Hindi are authored (`lib/l10n/app_en.arb`,
  `app_hi.arb`) and Settings has the picker, so a third language is a third
  `.arb` file, a `LanguageChoice` value, and a bank of 100 riddles in
  `data/riddle_bank.dart` (plus whatever `engine/answer_match.dart` needs to
  peel that language's endings off — it handles English and Devanagari today,
  and falls back to plain typo distance for anything else).
- **Sound effects:** exit whoosh and blocked bump exist; any further sound
  is another synth in `tool/make_sfx.py` (never `.ogg` — iOS can't decode
  Vorbis via audioplayers) and a method on `SfxService`.
- **iOS:** code is iOS-ready; the matching iOS scheme needs Xcode (not set up here).
