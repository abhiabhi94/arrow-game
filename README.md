# Arrow

A fast, playful cross-platform (Android + iOS) **swipe-the-arrow** reflex game
built with Flutter.

## How it plays

An arrow pops up in the arena. Swipe (or tap the direction pad) the way it
points. Clear the level's arrow quota before the clock runs out.

- **20 levels** with a hand-tuned difficulty curve. Twists arrive in chapters:
  plain arrows (1–3) → **coral arrows** that mean the *opposite* way (4–6) →
  a **per-arrow fuse** (7–9) → **ghost arrows** that vanish after a moment
  (10–12) → **decoy arrows** wearing a misleading word (13–15) → everything,
  faster and faster (16–20).
- **3 lives per level.** A wrong swipe or a burnt fuse costs one. Lose all
  three and the level resets — an "Out of lives" screen offers a retry.
- **A clock on every level** (30–42 s). Run out and it's "Time's up" — replay
  the same level.
- **Stars**: three for a flawless run, two for one slip, one for two. Best
  stars and best time are kept per level.
- Streak badge with cheers, confetti wins, pause (also on backgrounding),
  light/dark theme, haptics, locked progression (all levels open in the debug
  build).

## Architecture

Pure-Dart, zero-Flutter **engine** (`lib/engine/`) — directions, arrows and
the arrow factory that deals a level's mix — plus an immutable `GameState`
driven by a Riverpod `StateNotifier` (`lib/providers/game_provider.dart`).
The level table lives in `lib/data/level_specs.dart`. Persistence is
`shared_preferences`. Layout follows a layered `lib/` structure (`engine`,
`models`, `data`, `providers`, `services`, `screens`, `widgets`, `ui`,
`utils`, `l10n`).

## Running

Two build types install side-by-side:

- **Debug → "Arrow Testing"** (`app.curious.arrow.testing`): every level
  unlocked, for testing.
- **Release → "Arrow"** (`app.curious.arrow`): levels locked until the
  previous one is cleared.

```bash
flutter run                 # debug — "Arrow Testing", all levels open
flutter run --release       # release — "Arrow", locked progression
flutter build apk --debug   # -> app-debug.apk   ("Arrow Testing")
flutter build apk --release # -> app-release.apk  ("Arrow")

flutter build web --debug --no-web-resources-cdn      # web preview build (all levels open)
node tool/screenshot.mjs --levels 1,7,20 --settings --play  # phone-size screenshots -> shots/
```

The web build is a preview/verification target (used by CI and cloud dev
sessions to screenshot every screen — see `docs/cloud-dev.md`); the shipped
platforms are Android and iOS.

## Publishing (Play Store)

Release builds are signed with your **upload key**, read from a gitignored
`android/key.properties`. Copy `android/key.properties.example` to
`android/key.properties`, generate an upload keystore, then:

```bash
flutter build appbundle --release   # -> build/app/outputs/bundle/release/app-release.aab
```

Without `key.properties`, release falls back to debug signing (fine for local
runs, not for the Play Store).

## Tests & coverage

```bash
flutter analyze --fatal-infos   # must be clean
flutter test                    # full suite
tool/coverage.sh 92             # coverage gate (fails under 92%)
```

## Continuous Integration

`.github/workflows/ci.yml` runs on every push to `main` and every PR:
"Analyze & test" (analyze, tests, coverage gate) and "Web smoke &
screenshots" (web build driven in headless Chromium; fails on any Flutter
exception; uploads `shots/`). Flutter is pinned in `.flutter-version`.
