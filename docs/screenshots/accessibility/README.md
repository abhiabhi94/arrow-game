# Accessibility: before / after

Side-by-side captures for the accessibility pass (pull request #24): the
left half of each image is `main` before it, the right half the branch.

Both halves come from the web build driven by `tool/screenshot.mjs` in
headless Chromium — the cloud session has no Android emulator — at the two
viewports CI uses:

- `phone-*.png`: 390×844, the phone viewport. The Flutter UI is the same
  one the Android/iOS app draws, so these stand in for the app; only the
  platform chrome differs.
- `web-*.png`: 1440×900, the desktop browser layout played on GitHub
  Pages. `web-level-01-keys-*` is captured after pressing ArrowDown twice,
  so the keyboard cursor ring is on the second arrow (there is no cursor
  on `main`).

Regenerate with `flutter build web --debug --no-web-resources-cdn
--no-wasm-dry-run` on each commit, then (`--scale 1 --out <dir>`):

```
--levels 1,20 --settings --hint
--levels 16 --dark --hint --grid
--levels 1 --riddle 2,4,2,3,2,2
--levels 1 --viewport 1440x900 --keys ArrowDown,ArrowDown
--onboarding
```

What a screen reader or a large system font changes is not visible in a
still: see the **Accessibility** section of `CLAUDE.md` and
`test/widgets/accessibility_test.dart` for those.
