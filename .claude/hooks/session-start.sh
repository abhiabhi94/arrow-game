#!/bin/bash
# SessionStart hook for Claude Code on the web (cloud sessions only).
#
# Installs the pinned Flutter SDK (see .flutter-version — same pin as CI),
# fetches pub deps, regenerates l10n and makes sure the headless-Chromium
# screenshot harness (tool/screenshot.mjs) can run. Idempotent: the container
# state is cached after the hook completes, so re-runs are quick.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
FLUTTER_VERSION="$(tr -d '[:space:]' < "$PROJECT_DIR/.flutter-version")"
FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"
FLUTTER_ARCHIVE="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# --- Flutter SDK -----------------------------------------------------------
if [ -x "$FLUTTER_HOME/bin/flutter" ] \
   && grep -q "\"$FLUTTER_VERSION\"" "$FLUTTER_HOME/bin/cache/flutter.version.json" 2>/dev/null; then
  echo "[session-start] Flutter $FLUTTER_VERSION already at $FLUTTER_HOME"
else
  echo "[session-start] Installing Flutter $FLUTTER_VERSION to $FLUTTER_HOME"
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  curl -fsSL "$FLUTTER_ARCHIVE" | tar -xJ -C "$(dirname "$FLUTTER_HOME")"
fi
git config --global --add safe.directory "$FLUTTER_HOME" >/dev/null 2>&1 || true
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --no-analytics --enable-web >/dev/null
flutter precache --web >/dev/null

# --- Project deps ----------------------------------------------------------
cd "$PROJECT_DIR"
flutter pub get
flutter gen-l10n

# --- Screenshot harness (Playwright + Chromium) ----------------------------
# The web image ships playwright + a matching Chromium under /opt/pw-browsers;
# install them only if missing so the hook also works on a bare image.
NODE_GLOBAL="$(npm root -g)"
if ! NODE_PATH="$NODE_GLOBAL" node -e "require('playwright')" >/dev/null 2>&1; then
  echo "[session-start] Installing playwright"
  npm install -g playwright@1.56.1 >/dev/null
fi
if [ -z "${PLAYWRIGHT_BROWSERS_PATH:-}" ] || [ ! -d "$PLAYWRIGHT_BROWSERS_PATH" ]; then
  echo "[session-start] Installing Chromium for playwright"
  NODE_PATH="$NODE_GLOBAL" npx playwright install chromium >/dev/null
fi

# --- Persist env for the session ------------------------------------------
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"$FLUTTER_HOME/bin:\$PATH\""
    echo "export NODE_PATH=\"$NODE_GLOBAL\""
  } >> "$CLAUDE_ENV_FILE"
fi

flutter --version | head -1
echo "[session-start] Ready. Screenshots: flutter build web --debug --no-web-resources-cdn && node tool/screenshot.mjs --levels 1,7,20 --settings --hint"
