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

## Cutting a release

1. Bump `version:` in `pubspec.yaml`. Play requires the version code (the
   `+N` part) to be **strictly higher** than any previously uploaded build,
   so always increment `N`; bump the name part (`1.0.0`) as you see fit.
2. Merge that to `main` through a PR as usual.
3. Tag and push:

   ```bash
   git checkout main && git pull
   git tag v1.0.0 && git push origin v1.0.0
   ```

   The tag push runs the Release workflow: analyze + tests, then a signed
   `.aab` and `.apk`, uploaded as the workflow artifact
   `arrow-<name>-<code>` and attached to a GitHub Release named
   "Arrow 1.0.0 (1)".

   To build without tagging (a dry run, or an internal-testing upload), use
   **Actions → Release → Run workflow**; the optional inputs override the
   version name/code for that build only.

4. Download the artifact. It contains:

   | File                                | Use                                              |
   |-------------------------------------|--------------------------------------------------|
   | `arrow-<v>.aab`                     | Upload this to Play Console                      |
   | `arrow-<v>.apk`                     | Same signed build as an APK, for a device check  |
   | `arrow-<v>-mapping.txt`             | R8 mapping — upload under App bundle explorer → Downloads → "Upload ReTrace mapping file" so native/Kotlin crash reports are readable |
   | `arrow-<v>-dart-symbols.zip`        | Dart obfuscation symbols; keep with the release (`flutter symbolize -d`) |

5. In Play Console: Release → Testing (internal) or Production → Create new
   release → upload the `.aab` → release notes → review → roll out.

## Building locally instead

`flutter build appbundle --release` works on any machine that has
`android/key.properties` (copy `android/key.properties.example`, point
`storeFile` at the `.jks`). Without that file the build silently falls back
to **debug signing**, which Play rejects — so the workflow above is the
recommended path. Cloud (Claude Code on the web) sessions never have the key
and can only verify that the release build compiles.
