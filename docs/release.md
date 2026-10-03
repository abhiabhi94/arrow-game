# Releasing to the Play Store

The upload bundle is built by the **Release** workflow
(`.github/workflows/release.yml`), signed with the upload key stored in
repository secrets. Nothing secret is ever committed: `android/key.properties`
and the keystore are written on the runner from secrets and deleted at the end
of the job.

## One-time setup

### 1. Create the upload keystore

```bash
keytool -genkey -v -keystore ~/keys/arrow-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep the `.jks` and both passwords somewhere safe and backed up (a password
manager). With Play App Signing, Google holds the *app* signing key and this
is only the *upload* key, so it can be reset through Play Console support if
lost — but that is a slow process, so treat it as precious.

### 2. Store it in the `release` environment's secrets

The workflow's job runs in the GitHub environment named **`release`**, so
the secrets go there (not in the repository-wide list): GitHub → repository
→ Settings → Environments → `release` (create it if missing) → Environment
secrets → Add secret. Or with the `gh` CLI:

```bash
gh secret set --env release ANDROID_UPLOAD_KEYSTORE_BASE64 --body "$(base64 -w0 ~/keys/arrow-upload.jks)"
gh secret set --env release ANDROID_UPLOAD_KEYSTORE_PASSWORD   # prompts for the value
gh secret set --env release ANDROID_UPLOAD_KEY_ALIAS --body upload     # optional, defaults to "upload"
gh secret set --env release ANDROID_UPLOAD_KEY_PASSWORD                # optional, see below
```

`ANDROID_UPLOAD_KEY_PASSWORD` is only needed when the key's password differs
from the keystore's. `keytool` creates PKCS12 keystores by default, and those
have a single password for both, so most setups can skip it.

An environment also lets you add protection rules (Settings → Environments
→ release): "Required reviewers" makes every release build wait for an
approval click, and "Deployment branches and tags" can restrict it to
`main` and `v*` tags.

(On macOS `base64` takes no `-w0`; use `base64 -i ~/keys/arrow-upload.jks`.)

The workflow fails fast with a clear message if a required secret is missing,
and it opens the keystore before building, so a wrong password, a bad alias
or a mangled base64 upload fails in a second rather than after the compile.
That step prints the certificate's SHA-256 fingerprint; compare it with

```bash
keytool -list -v -keystore ~/keys/arrow-upload.jks -alias upload
```

on the machine that holds the keystore. If the workflow reports "keystore
password was incorrect" but the command above accepts the password, the
secret value differs from what you typed (a stray trailing space or newline
when pasting is the usual culprit) or the base64 was truncated when pasted:
re-set `ANDROID_UPLOAD_KEYSTORE_BASE64` and `ANDROID_UPLOAD_KEYSTORE_PASSWORD`.

### 3. Play Console

- Create the app (`app.curious.arrow`, "Arrow"). Accept **Play App Signing**
  when prompted on the first upload; the key you sign the first bundle with
  becomes the registered upload key.
- Privacy policy URL: publish `docs/privacy-policy.md` (GitHub Pages or the
  raw file link works) and paste it into App content → Privacy policy.
- Store listing screenshots: the phone-viewport PNGs from
  `node tool/screenshot.mjs --levels 1,7,20 --settings --hint` (390×844;
  Play accepts any 16:9–9:16 PNG from 320 px up).

### 4. Google Play API access (automatic uploads)

The workflows publish to Play themselves through the Play Developer API,
signed in as a **service account**. Once:

1. **Google Cloud Console** (any project; one made for this is tidiest):
   APIs & Services → Library → enable **Google Play Android Developer API**.
2. IAM & Admin → Service accounts → **Create service account** (no roles
   needed) → Keys → Add key → JSON. Keep the downloaded file safe; it is a
   credential.
3. **Play Console** → Users and permissions → **Invite new users** → the
   service account's email (`…@….iam.gserviceaccount.com`) → App
   permissions → Arrow → tick **Release apps to testing tracks** and
   **Release to production, exclude devices, and use Play App Signing**.
   (Access can take a few minutes to start working.)
4. **GitHub** → Settings → Environments:
   - `release` → add secret `PLAY_SERVICE_ACCOUNT_JSON` = the whole JSON file.
   - `production` (create it) → the same secret again (environment secrets
     are per environment), and under **Required reviewers** add yourself, so
     every production release waits for an approval click.

   ```bash
   gh secret set --env release    PLAY_SERVICE_ACCOUNT_JSON < ~/keys/arrow-play.json
   gh secret set --env production PLAY_SERVICE_ACCOUNT_JSON < ~/keys/arrow-play.json
   ```

The API cannot create the app or its first release, so the very first
bundle goes up by hand (already done for Arrow). Without the secret the
Release workflow still builds and attaches the bundle, and only warns that it
uploaded nothing.

## Cutting a release

From an up-to-date `main`, one command does the whole thing:

```bash
tool/bump_version.sh            # 1.2.1+4 -> 1.2.2+5, commit, tag v1.2.2+5, offer to push
tool/bump_version.sh --push     # the same, but unattended runs push too
```

It rewrites `version:` in `pubspec.yaml`, commits ("Bump version to
1.0.1+4"), makes an annotated `v1.0.1` tag — and then **prints the commit,
patch and all**, so the change can be read before it goes anywhere.

Pushing is always offered, never assumed, and asked for a piece at a time:
once for the branch, then again for the tag — the tag being the one that
actually starts a release. Declining either stops there and prints what is
left to run, alongside the one-line undo, so the bump can sit until it looks
right.

`--push` is for the runs with nobody to ask. Under `-y`, or with no
terminal, the two questions cannot be put to anyone, so `--push` answers
them: without it such a run commits and tags but publishes nothing. That is
the only thing the flag does — interactively you are still asked either way.

| Invocation                     | What it pushes                          |
|--------------------------------|-----------------------------------------|
| `tool/bump_version.sh`         | asks for each; whatever you say yes to  |
| `tool/bump_version.sh --push`  | same — you are still asked              |
| `… -y`                         | nothing                                 |
| `… -y --push`                  | branch and tag, no prompts              |

`--dry-run` prints the plan and stops before even the commit.

### Where "the current version" comes from

**The released version name lives in the newest `v*` tag, not in
`pubspec.yaml`.** Through v1.2.0 this repo tagged `v1.0.0`, `v1.1.0` and
`v1.2.0` while pubspec's name sat at `1.0.0` the whole time — only the `+N`
code was ever bumped there (`+1`, `+2`, `+3`), because the workflow's
`build_name` input supplied the name. Reading pubspec alone would propose
`1.0.1` when the shipped version is `1.2.0`.

So the script takes:

- the **name** from whichever is further along, the newest `v*` tag or
  pubspec (and says so in the plan when the tag wins);
- the **code** from the highest of three: pubspec now, the code the newest
  tag spells out, and the code the pubspec at that tag carried (all a bare
  legacy tag can tell us) — it has to clear every build ever uploaded.

Bumping then also drags pubspec's name back in line with reality, so after
the first run the two agree.

### What each argument does

The version code always increments, because Play requires it **strictly
higher** than any previously uploaded build. Against today's `v1.2.0` and
pubspec `1.0.0+3`:

| Argument            | Becomes  | Tag        |
|---------------------|----------|------------|
| `patch` *(default)* | 1.2.1+4  | `v1.2.1+4` |
| `minor`             | 1.3.0+4  | `v1.3.0+4` |
| `major`             | 2.0.0+4  | `v2.0.0+4` |
| `build`             | 1.2.0+4  | `v1.2.0+4` |
| `2.5.1`             | 2.5.1+4  | `v2.5.1+4` |

**A tag is `v` + the whole version, code included.** One shape, always, so a
tag and pubspec mirror each other exactly and there is no reading to do.
It is unique by construction too — the code strictly increments — so `build`
can re-upload under the same name (`v1.3.0+4`, then `v1.3.0+5`) without a
special case. `--tag NAME` overrides it. An explicit `X.Y.Z` must be higher
than the current name: `1.0.1` is refused today, not silently accepted.

The three tags cut before this scheme (`v1.0.0`, `v1.1.0`, `v1.2.0`) carry
only a name. They are still read correctly — that is how the table above
gets `1.2.0` — but no new tag looks like that.

Because the tags decide the version, the script fetches them first
(`--no-fetch` skips that, and then only local tags are consulted). Before it
changes anything it refuses to run on a dirty tree, off `main`
(`--any-branch` overrides), on a branch behind `origin`, or onto a tag that
already exists. `--check` runs `flutter analyze --fatal-infos` and
`flutter test` first, and `--no-tag` commits the bump alone.
`tool/bump_version.sh --help` lists them all.

Doing it by hand is the same three steps:

1. Bump `version:` in `pubspec.yaml` and commit.
2. Merge that to `main` through a PR as usual.
3. Tag and push:

   ```bash
   git checkout main && git pull
   git tag v1.0.0 && git push origin v1.0.0
   ```

Either way, the tag push runs the Release workflow: analyze + tests, then a
signed `.aab` and `.apk`, uploaded as the workflow artifact
`arrow-<name>-<code>` and attached to a GitHub Release named
"Arrow 1.0.0 (1)".

To build without tagging (a dry run, or a one-off alpha upload), use
**Actions → Release → Run workflow**; the optional inputs override the
version name/code for that build only.

Then download the artifact. It contains:

| File                         | Use                                             |
|------------------------------|-------------------------------------------------|
| `arrow-<v>.aab`              | Upload this to Play Console                     |
| `arrow-<v>.apk`              | Same signed build as an APK, for a device check |
| `arrow-<v>-mapping.txt`      | R8 mapping — upload under App bundle explorer → Downloads → "Upload ReTrace mapping file" so native/Kotlin crash reports are readable |
| `arrow-<v>-dart-symbols.zip` | Dart obfuscation symbols; keep with the release (`flutter symbolize -d`) |

## Google Play: alpha, then production

Only two tracks are used, both at a 100% rollout:

| Track | What puts a build there |
|-------|-------------------------|
| **alpha** (closed testing) | every `v*` tag — the Release workflow uploads the `.aab` and its R8 mapping after building it (a manual run does too when **upload_to_alpha** is ticked) |
| **production** | **Actions → Promote to production → Run workflow**, then approve it |

Promoting rebuilds nothing: it puts the version code that is on alpha onto
production, so the public gets exactly the build the testers ran. Leave
**version_code** blank for alpha's newest, or name an older one that is
still on alpha. Both go through `tool/play_publish.mjs` (Node's own `fetch`
and `crypto`, no dependencies).

So a release is:

1. `tool/bump_version.sh --push` → the build lands on alpha.
2. Try it from the Play Store as a tester.
3. Promote to production → approve → Google's review → live.

Play still reviews releases on both tracks; the API only saves the clicks.
A personal developer account opened after November 2023 also has to run a
closed test (12 testers for 14 days) before production is unlocked at all.

To do it by hand instead: Play Console → Testing → Closed testing (alpha)
or Production → Create new release → upload the `.aab` → review → roll out.

## Building locally instead

`flutter build appbundle --release` works on any machine that has
`android/key.properties` (copy `android/key.properties.example`, point
`storeFile` at the `.jks`). Without that file the build silently falls back
to **debug signing**, which Play rejects — so the workflow above is the
recommended path. Cloud (Claude Code on the web) sessions never have the key
and can only verify that the release build compiles.

## The tag and pubspec must agree

A tag is `v` + the whole pubspec version — `v1.3.0+4` for `1.3.0+4` — and
the Release workflow enforces it: a tag-triggered run fails in its first
seconds unless `${tag#v}` equals pubspec's `version:` exactly. Requiring the
code as well as the name is what keeps it to one tag shape; otherwise
`v1.3.0` and `v1.3.0+5` end up side by side meaning different things.
`tool/bump_version.sh` keeps them in step by construction — it writes the
version into pubspec and tags that same commit.

This is a guard against a real drift. `v1.0.0`, `v1.1.0` and `v1.2.0` were
all cut by tagging alone, while pubspec's name sat at `1.0.0` and only its
`+N` moved. The build reads pubspec, so every bundle those releases carry is
`versionName 1.0.0` — `arrow-1.0.0-1.aab`, `arrow-1.0.0-2.aab`,
`arrow-1.0.0-3.aab` — under tags claiming three different versions. Nothing
downstream could catch it: the tag is only a label on a commit.

If the check fires, do not re-point the tag at a new commit — that gives a
release whose artifacts do not match the source it names. Bump pubspec
properly, delete the bad tag (`git tag -d <tag> && git push origin
:refs/tags/<tag>`), and tag the bump commit, which is what
`tool/bump_version.sh` does on its own.

## Permissions in the Play Console

The bundle ships exactly two permissions, and both are expected:

| Permission | Declared by |
|------------|-------------|
| `android.permission.VIBRATE` | `android/app/src/main/AndroidManifest.xml` — the haptics channel in `MainActivity.kt` |
| `<applicationId>.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `androidx.core:core`, pulled in by `io.flutter:flutter_embedding_release`. Signature-level, used when androidx registers a non-exported dynamic broadcast receiver on Android 13+. Invisible to users. |

Play Console's **App bundle** page lists a third, `com.android.vending.CHECK_LICENSE`.
It is **not** in the uploaded artifact — Google Play injects it when it
processes the bundle and generates the delivered APKs. Verified on the
`1.0.0+2` bundle: the manifest-merger blame report names only the two above,
and neither `aapt2 dump permissions app-release.apk` nor `bundletool dump
manifest --bundle=app-release.aab` mentions it. There is nothing to remove on
our side (a `tools:node="remove"` rule would be a no-op), and the permission
is `normal` protection level, so it never prompts the user.

To check what a device actually installs: App bundle explorer → Downloads →
download a device-spec APK → `aapt2 dump permissions <apk>`.
