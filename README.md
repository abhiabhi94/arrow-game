# Arrow

A playful cross-platform (Android + iOS) **arrow exit puzzle** built with
Flutter.

**Play in the browser:** https://abhiabhi94.github.io/arrow-game/ (release
build, deployed from `main` by GitHub Actions; installable as a PWA). Every
pull request gets its own playable preview and a debug APK — see
[Reviewing a pull request](#reviewing-a-pull-request). On a
laptop the keyboard helps: **H** hint, **+ / -** zoom, **G** grid lines,
**Space** pause.

## How it plays

Bent arrow pieces sit on a grid. Tap one and it slides along its own path,
the way its head points, until it leaves the board. Get every arrow out.

- **Blocked arrows cost a life.** If an arrow's exit path runs into another
  arrow it bumps back. **3 lives per level** — spend all three and the
  "Out of lives" card asks for a riddle before it lets you carry on.
- **Carrying on is earned, not free.** Out of lives, you can pick the level
  up exactly where it stands — for a single star — by cracking a riddle
  ("I follow you all day long and vanish when the lights go out"). Every
  riddle has a 💡 that gives a clue and then the first letter, and the
  answer only has to be *close*: a plural, a tense or a typo is waved
  through with a "close enough". **100 riddles per language** — the second
  fifty a shade more lateral than the first, still one everyday word each —
  dealt in a shuffled order so the whole pack comes round before any of
  them repeats.
  The next fresh mistake asks again, so lives are never spent thoughtlessly.
- **A clock on every level** (26 seconds to learn on, up to about twelve
  and three-quarter minutes for the finale, growing with the board — brisk
  on purpose, and brisker per arrow through the last forty levels: the
  final twenty get eighty more arrows for barely a minute more).
  Run out and it's "Time's up" — replay the same level.
- **80 levels**, each a fixed, procedurally generated board that is solvable
  by construction. The curve is steep: 5 arrows on a 5×6 board to learn on,
  59 arrows on 19×26 by level 8, 144 arrows on 32×50 by level 20,
  224 arrows on 42×63 by level 40, 304 arrows on 47×73 by level 60,
  384 arrows on 52×84 for the finale — and the "who must go before whom"
  chains get longer all the way. Levels 41–60 pack more arrows onto a board
  that hardly grows, with longer arrows, fewer playable at any moment and a
  little less time per arrow, so the endgame gets tighter level by level,
  not just wider. Levels 61–80 keep all of that and turn the clock into the
  difficulty: the time per arrow falls from 2.3 s to 2.0 s, so the last act
  is a longer read on less time.
- **3 hints per level** light up an arrow that can go right now. Spent
  them? The bulb turns into a riddle: crack one and you get another hint,
  with the clock stopped while you think.
- **Zoom** in/out (buttons or pinch, up to 4×) — the late boards need it.
- **One ink.** Arrows are thin dark lines like a printed puzzle; only the
  hint glow and a blocked bump add colour.
- **Grid lines** are an earned toggle: clear level 4 to unlock them.
- **Stars**: three for a flawless run, two for one slip, one for two. Best
  stars and best time are kept per level.
- **A bump is a bump:** the arrow runs into the one in its way, jolts it,
  and springs back — and the whole screen shakes, flashes red at the edges,
  cracks and buzzes, so a lost life is never missed.
- **Pick up where you left off:** close the app, switch away or back out
  mid-level and the level is saved; Home offers Continue, and the level
  opens on a "Welcome back" card with Continue or Start over.
- **First launch** walks you through on two tiny boards you actually play.
- **Home** is a winding journey trail of levels with a "Next up" card.
- Background music ("Game" by The_Mountain, Pixabay Content License, credited
  in-app), sound effects (a whoosh on every exit, a crash on a bump) and
  haptics, all on by default and configurable; confetti; pause
  (also on backgrounding); light/dark/system theme; **English and हिन्दी**
  (Settings → Language, following the device by default — riddles and all);
  locked progression (all levels open in the debug build); Google Sans Flex
  throughout.

## Architecture

Pure-Dart, zero-Flutter **engine** (`lib/engine/`) — cells, arrow pieces, the
puzzle rules (exit rays, blockers, solvability, hints) and a generator that
only ever produces solvable boards and keeps the number of playable arrows
at any moment down to a handful, so the late levels are found, not raced
(run on a background isolate) — plus an immutable
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
flutter build apk --debug   # -> app-debug.apk   ("Arrow Testing", ~150 MB, all ABIs)
flutter build apk --release # -> app-release.apk  ("Arrow")
flutter build apk --release --split-per-abi --dart-define=UNLOCK_ALL=true
                            # -> small per-ABI tester APKs, every level open, installs
                            #    alongside as "Arrow Testing" (.testing id)

flutter build web --debug --no-web-resources-cdn      # web preview build (all levels open)
node tool/screenshot.mjs --levels 1,7,20,40 --settings --hint  # phone-size screenshots -> shots/
node tool/screenshot.mjs --levels 1 --viewport 1440x900 --keys Equal,KeyH  # desktop + keyboard
```

The web build is played for real in the browser (the GitHub Pages site
above, phone or laptop) and doubles as the verification target CI and cloud
dev sessions use to screenshot every screen — see `docs/cloud-dev.md`. The
store platforms are Android and iOS.

## Publishing (web)

`.github/workflows/pages.yml` builds the release web app with
`--base-href /<repo>/` and commits it to the root of the `gh-pages` branch on
every push to `main` (or manually from the Actions tab). One-time repo
setting: Settings → Pages → Build and deployment → Source: **Deploy from a
branch**, Branch: **`gh-pages` / (root)** — the branch shows up in that
dropdown only after the workflow has run once.

## Reviewing a pull request

Every PR gets both builds of itself, without anyone checking it out:

- **Play it in the browser.** `.github/workflows/pr-preview.yml` deploys the
  PR's web build to `…/arrow-game/pr-preview/pr-<number>/` (a release build
  with `UNLOCK_ALL=true`, so every level is reachable) and keeps a comment on
  the PR with the link. The preview and its comment are deleted when the PR
  closes.
- **Install it on a phone.** The `Debug APK` job in `ci.yml` builds
  `app-debug.apk` ("Arrow Testing", all levels open) and comments the
  download link, refreshed on every push.

Both run only for branches in this repo — a PR from a fork has no token to
write `gh-pages`.

## Publishing (Play Store)

The upload bundle comes from the **Release** workflow
(`.github/workflows/release.yml`): push a `v*` tag (or run it manually from
the Actions tab) and it builds a signed `.aab` + `.apk`, uploads them as an
artifact and attaches them to a GitHub Release. The upload key lives in
repository secrets — full setup and the step-by-step in `docs/release.md`.

Cutting one is a single command from an up-to-date `main` — it bumps
`version:` in `pubspec.yaml`, commits, tags, and prints the commit for review:

```bash
tool/bump_version.sh                  # v1.2.0 -> 1.2.1+4, tag v1.2.1+4, local only
tool/bump_version.sh --push           # ... and let an unattended run (-y) push too
tool/bump_version.sh minor --dry-run  # also major | build | an explicit X.Y.Z
```

The current version name comes from the **newest `v*` tag**, not from
`pubspec.yaml` — the releases through v1.2.0 left pubspec's name at `1.0.0`
and moved only the `+N` code, so the tag is the honest source. The code
always increments, since Play needs it strictly higher than any build
already uploaded. A new tag is `v` + the whole version, code included
(`v1.3.0+4`), so tag and pubspec mirror each other exactly; the Release
workflow refuses a tag that disagrees.

Pushing is always offered and asked for a piece at a time — once for the
branch, once for the tag — and declining prints the commands and the undo.
`--push` matters only when there is nobody to ask: under `-y` or with no
terminal it answers those questions, so a script never publishes by
accident. `--help` lists the rest
(`--check`, `--no-tag`, `--tag NAME`, `--any-branch`, `-y`).

Locally, release builds are signed with the same upload key read from a
gitignored `android/key.properties` (copy `android/key.properties.example`):

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
screenshots" (web build driven in headless Chromium at phone and desktop
viewports, keyboard included; fails on any Flutter exception; uploads
`shots/`). Flutter is pinned in `.flutter-version`.
