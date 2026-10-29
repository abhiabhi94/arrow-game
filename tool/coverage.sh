#!/usr/bin/env bash
# Coverage gate. Runs the test suite with coverage and fails if hand-written
# line coverage falls below the threshold (default 98.5%).
#
# Excluded from the denominator:
#   - generated localizations (lib/l10n/app_localizations*.dart)
#   - the app bootstrap (lib/main.dart)
#   - platform-only glue marked with `// coverage:ignore` in source
#     (real audio backend, isolate/timer wiring, provider defaults)
#
# Usage: tool/coverage.sh [threshold]
set -euo pipefail

THRESHOLD="${1:-98.5}"
cd "$(dirname "$0")/.."

# Quiet when green; a failure prints the failing tests (CI has nothing else
# to go on).
# Every core: the default is half of them, and the level deals are
# split over several files (test/engine/levels_*_test.dart) to run side
# by side.
flutter test --coverage --reporter failures-only --concurrency="$(getconf _NPROCESSORS_ONLN)"

python3 - "$THRESHOLD" <<'PY'
import sys
threshold = float(sys.argv[1])
EXCLUDE = ('app_localizations', '/main.dart')
cov = tot = 0
keep = True
for line in open('coverage/lcov.info'):
    line = line.strip()
    if line.startswith('SF:'):
        keep = not any(x in line[3:] for x in EXCLUDE)
    elif line.startswith('DA:') and keep:
        _, hits = line[3:].split(',')
        tot += 1
        cov += 1 if int(hits) > 0 else 0
pct = 100 * cov / tot if tot else 0.0
status = 'PASS' if pct >= threshold else 'FAIL'
print(f'[{status}] coverage {cov}/{tot} = {pct:.1f}%  (threshold {threshold:g}%)')
sys.exit(0 if pct >= threshold else 1)
PY
