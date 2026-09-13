# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A fast, playful cross-platform (Android + iOS) **swipe-the-arrow** reflex game
built with Flutter. An arrow appears; the player swipes the arena (or taps the
direction pad) the way it points. 20 levels with a hand-tuned difficulty curve,
3 lives per level (a wrong swipe or a burnt fuse costs one; losing all three
resets the level behind a "Retry" screen), a clock on every level ("Time's up"
→ replay the same level), 1–3 stars per clear, local progress, light/dark
theme, haptics.

## Build & Development Commands

```bash
flutter pub get                 # deps
flutter gen-l10n                # regenerate localizations after editing lib/l10n/*.arb
flutter analyze --fatal-infos   # static analysis (must be clean; CI fails on infos)
flutter test                    # full test suite
tool/coverage.sh 92             # coverage gate (fails under threshold)

flutter build web --debug --no-web-resources-cdn --no-wasm-dry-run  # web build (debug = all levels unlocked)
node tool/screenshot.mjs --levels 1,7,20 --settings --play          # phone-viewport screenshots -> shots/

flutter run                     # debug build = "Arrow Testing", all levels unlocked
flutter run --release           # release build = "Arrow", locked progression
flutter build apk --debug       # -> build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release     # -> app-release.apk (upload-key signed if key.properties present)
flutter build appbundle --release  # -> build/app/outputs/bundle/release/app-release.aab (for Play Store)
```

## Cloud sessions & visual verification

Claude Code on the web has no Android emulator (no KVM). The stand-in is the
**web build + headless Chromium**: `tool/screenshot.mjs` serves `build/web`,
drives the app (home, settings, any level's intro and — with `--play` — the
live arena, light/dark) at 390×844 and writes PNGs to `shots/`; it exits 1 on
any Flutter exception, so it doubles as the CI smoke test
(`.github/actions/web-smoke`, job "Web smoke & screenshots"). See
`.claude/skills/run/SKILL.md` and `docs/cloud-dev.md`. The SessionStart hook
in `.claude/hooks/session-start.sh` installs the SDK pinned in
`.flutter-version`.

The web target is a verification/preview target; the shipped platforms are
Android + iOS. Nunito is bundled in `assets/fonts/` (google_fonts resolves it
from assets, no runtime fetch).

## Build types (no flavors)

Identity is tied to the **build type**, not a product flavor:

| Build   | App name       | Application id               | Levels                        |
|---------|----------------|------------------------------|-------------------------------|
| debug   | Arrow Testing  | `app.curious.arrow.testing`  | all unlocked (for testing)    |
| release | Arrow          | `app.curious.arrow`          | locked until previous cleared |

- The debug `.testing` app-id suffix lets both install side-by-side.
- "Unlock all levels" keys off `kDebugMode` (`testingUnlocksAllLevels` in
  `lib/providers/progress_provider.dart`). Namespace is `app.curious.arrow`.
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
    direction.dart       Direction enum, opposite, swipe-delta -> direction
    arrow.dart           Arrow (direction, kind: normal/reverse/ghost/decoy) + expected answer
    arrow_factory.dart   deals arrows from a LevelSpec's chances (seedable Random)
  data/level_specs.dart  the 20 levels (target hits, clock, twist chances, fuse)
  models/              level_spec, level_progress (stars), settings, game_state (phases)
  providers/           app_providers (DI root), settings_provider, progress_provider, game_provider
  services/            haptics_service (injectable HapticEngine)
  screens/             home (level grid), game (arena + overlays), settings
  ui/                  colors.dart (light+dark ArrowPalette), theme.dart (Material 3 + Nunito)
  widgets/             arrow_view, direction_pad, lives_indicator, timer_bar, streak_badge,
                       stars_row, result_card, level_intro
  utils/               format.dart, labels.dart (l10n lookups for engine values)
  l10n/                app_en.arb (+ generated app_localizations*.dart)
```

Key patterns:
- **DI:** `sharedPreferencesProvider` throws until overridden in `main()`; all
  repositories/providers read prefs through it. Tests override it with a mock.
- **Persistence:** `shared_preferences` only, keys prefixed `arrow_*`.
- **Game loop:** `GameNotifier` owns the phase machine
  (`ready → playing ⇄ paused → cleared | outOfLives | timeUp`). A 100 ms
  `Timer.periodic` drives `tick()` when `autoTick` is true; tests pass
  `autoTick: false` and call `tick()` themselves. The notifier is an
  `autoDispose.family` keyed by level, so leaving the screen discards the attempt.
- **Difficulty:** every knob is in `data/level_specs.dart`; the tests in
  `test/data/level_specs_test.dart` pin the curve's shape (chapters, pace,
  fuse ≥ ghost window). Tune numbers there, keep the tests honest.
- **Lives / stars:** `maxLives = 3` and `starsForMistakes` live in
  `models/level_progress.dart`.

## Testing

- `flutter test` + `tool/coverage.sh`. The gate excludes generated l10n,
  `main.dart`, and glue marked `// coverage:ignore` (the real periodic timer).
  Don't add `coverage:ignore` to hide untested logic — only true glue.
- Widget tests override `gameProvider` with `autoTick: false` and a seeded
  `Random`. `flutter_animate` schedules a zero-delay start on every mount, so
  tests pump a frame before advancing the clock (see `_settle` in
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
- **Audio:** no music/sfx yet. The sudoku app's `AudioService` pattern
  (injectable backend, `.mp3` only) is the template if it's wanted.
- **App icon:** still the default Flutter icon.
- **iOS:** code is iOS-ready; the matching iOS scheme needs Xcode (not set up here).
