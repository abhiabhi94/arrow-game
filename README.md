# Arrow

A playful cross-platform (Android + iOS) **arrow exit puzzle** built with
Flutter.

## How it plays

Bent arrow pieces sit on a grid. Tap one and it slides along its own path,
the way its head points, until it leaves the board. Get every arrow out.

- **Blocked arrows cost a life.** If an arrow's exit path runs into another
  arrow it bumps back. **3 lives per level** — lose all three and the level
  resets behind an "Out of lives / Retry" screen.
- **A clock on every level** (1–5 minutes, growing with the board). Run out
  and it's "Time's up" — replay the same level.
- **20 levels**, each a fixed, procedurally generated board that is solvable
  by construction. Boards grow from 4×4 with 3 arrows to 10×11 with 16, and
  the "who must go before whom" chains get longer.
- **3 hints per level** light up an arrow that can go right now.
- **Zoom** in/out (buttons or pinch) for the big boards.
- **Grid lines** are an earned toggle: clear level 4 to unlock them.
- **Stars**: three for a flawless run, two for one slip, one for two. Best
  stars and best time are kept per level. Confetti, pause (also on
  backgrounding), light/dark theme, haptics, locked progression (all levels
  open in the debug build).

## Architecture

Pure-Dart, zero-Flutter **engine** (`lib/engine/`) — cells, arrow pieces, the
puzzle rules (exit rays, blockers, solvability, hints) and a reverse-order
generator that only ever produces solvable boards — plus an immutable
`GameState` driven by a Riverpod `StateNotifier`
(`lib/providers/game_provider.dart`). The level table lives in
`lib/data/level_specs.dart`; the board is a `CustomPainter` that also
animates slide-outs and bumps. Persistence is
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
node tool/screenshot.mjs --levels 1,7,20 --settings --hint  # phone-size screenshots -> shots/
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
