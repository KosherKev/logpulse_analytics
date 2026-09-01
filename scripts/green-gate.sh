#!/usr/bin/env bash
# green-gate.sh — the verification gate, one shape for every repo.
#
# Copy this file to <repo>/scripts/green-gate.sh and commit it. Once it is committed,
# a routine, a cloud session, a remote-control session and you at a terminal all run
# exactly the same check, and "did the gate pass" stops depending on who ran it.
#
# Policy (decided 2026-08-31):
#   - Runs whatever verification the repo actually has. Never invents a step.
#   - Missing test coverage is a GAP, not a failure: the gate still passes on lint and
#     build, and prints the gap so it stays visible instead of being forgotten.
#   - Missing lint or format is a GAP too. Same treatment.
#   - A step that exists and fails is a FAILURE. Exit 1.
#   - --strict turns gaps into failures. Use it once a repo should have no gaps left.
#
# Exit codes:  0 pass (gaps allowed)   1 a real step failed   2 nothing to verify
#
# Last line of output is machine-readable, for routines to grep:
#   GATE: PASS|FAIL repo=<name> ran=<steps> gaps=<gaps>

set -uo pipefail

STRICT=0
[ "${1:-}" = "--strict" ] && STRICT=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

# A bare basename is ambiguous across a multi-repo project — Texify/frontend and
# Imep/frontend are both "frontend". Use <Project>/<app-role>, which is the identifier
# the repo conventions actually use; those deliberately diverge from GitHub repo names,
# so the remote is the wrong thing to key on. Drop the parent when it's just a container.
BASE="$(basename "$REPO_ROOT")"
PARENT="$(basename "$(dirname "$REPO_ROOT")")"
case "$PARENT" in
  dev|GitHub|src|repos|code|Documents|"$(basename "$HOME")"|/) REPO_NAME="$BASE" ;;
  *) REPO_NAME="$PARENT/$BASE" ;;
esac

RAN=()
GAPS=()
FAILED=()

say()  { printf '\n\033[1m▸ %s\033[0m\n' "$*"; }
gap()  { GAPS+=("$1"); printf '  \033[33m○ gap:\033[0m %s\n' "$2"; }
ok()   { RAN+=("$1");  printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { FAILED+=("$1"); printf '  \033[31m✗ %s\033[0m\n' "$1"; }

run_step() { # run_step <name> <command...>
  local name="$1"; shift
  if "$@"; then ok "$name"; else bad "$name"; fi
}

# ─────────────────────────────── Flutter ───────────────────────────────
if [ -f pubspec.yaml ]; then
  say "Flutter gate — $REPO_NAME"

  # Severity policy (2026-08-31): warnings and errors fail; infos are reported and pass.
  # `flutter analyze` treats infos as fatal by default, which on a real repo meant 114
  # style infos — mostly avoid_print in scratch files — burying 3 genuine warnings.
  # A gate that is red for reasons nobody will act on trains you to ignore it.
  [ -f analysis_options.yaml ] || gap "analyze" "no analysis_options.yaml — analyzer on defaults only"

  INFO_COUNT=$(flutter analyze 2>/dev/null | grep -cE '^\s*info •' || true)
  run_step "flutter analyze (warnings+errors)" flutter analyze --no-fatal-infos
  if [ "${INFO_COUNT:-0}" -gt 0 ]; then
    printf '  \033[2m· %s analyzer infos not blocking (run `flutter analyze` to see them)\033[0m\n' "$INFO_COUNT"
  fi

  # --output=none is load-bearing: without it dart format REWRITES the tree.
  # A gate reports; it never edits.
  run_step "dart format (check)" dart format --output=none --set-exit-if-changed .

  TEST_COUNT=$(find test -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TEST_COUNT" -eq 0 ]; then
    gap "test" "no test files at all — this repo has no verification signal"
  elif [ "$TEST_COUNT" -eq 1 ] && [ -f test/widget_test.dart ] \
       && grep -q 'Counter increments smoke test' test/widget_test.dart 2>/dev/null; then
    gap "test" "only the default Flutter template test — this is not coverage"
    run_step "flutter test" flutter test
  else
    run_step "flutter test ($TEST_COUNT files)" flutter test
  fi

  if [ "${GATE_BUILD:-0}" = "1" ]; then
    run_step "flutter build apk --debug" flutter build apk --debug
  else
    printf '  \033[2m· build skipped (set GATE_BUILD=1 to include)\033[0m\n'
  fi

# ──────────────────────────────── Node ─────────────────────────────────
elif [ -f package.json ]; then
  say "Node gate — $REPO_NAME"

  [ -d node_modules ] || {
    printf '  \033[31m✗ node_modules missing — run your install first\033[0m\n'
    echo "GATE: FAIL repo=$REPO_NAME ran= gaps=deps-missing"
    exit 1
  }

  has() { node -e "process.exit(require('./package.json').scripts?.['$1']?0:1)" 2>/dev/null; }

  # test — a script that is only a stub counts as absent
  if has test && node -e "
      const s=require('./package.json').scripts.test||'';
      process.exit(/no test specified|exit 1/.test(s)?0:1)" 2>/dev/null; then
    gap "test" "test script is a stub, not a real suite"
  elif has test; then
    run_step "test" npm test --silent
  else
    gap "test" "no test script — no verification signal from tests"
  fi

  if has lint; then run_step "lint" npm run lint --silent
  else gap "lint" "no lint script"; fi

  # A format script is usually `prettier --write .`, which rewrites the tree.
  # The gate must never edit, so a --write script is checked with --check instead.
  have_prettier() { npx --no-install prettier --version >/dev/null 2>&1; }
  FMT_SCRIPT=$(node -e "console.log(require('./package.json').scripts?.format||'')" 2>/dev/null)
  if [ -n "$FMT_SCRIPT" ] && [[ "$FMT_SCRIPT" == *"--write"* ]]; then
    # A missing tool is a gap, not a format failure — don't report one as the other.
    if have_prettier; then run_step "format (check, not write)" npx --no-install prettier --check .
    else gap "format" "format script exists but prettier is not installed here"; fi
  elif has format; then
    run_step "format" npm run format --silent
  elif [ -f .prettierrc ] || [ -f .prettierrc.json ] || [ -f prettier.config.js ] \
       || [ -f .prettierrc.js ] || [ -f .prettierrc.cjs ]; then
    run_step "format (check)" npx --no-install prettier --check .
  else
    gap "format" "no format script or prettier config"
  fi

  # type check — a real signal where TypeScript exists but no script exposes it
  if [ -f tsconfig.json ]; then
    if has typecheck; then run_step "typecheck" npm run typecheck --silent
    else run_step "tsc --noEmit" npx --no-install tsc --noEmit; fi
  fi

  if has build; then run_step "build" npm run build --silent
  else gap "build" "no build script"; fi

else
  echo "Nothing to verify: no pubspec.yaml and no package.json in $REPO_ROOT" >&2
  echo "GATE: FAIL repo=$REPO_NAME ran= gaps=unrecognised-project"
  exit 2
fi

# ─────────────────────────────── Verdict ───────────────────────────────
join() { local IFS=,; echo "${*:-none}"; }

echo
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '\033[31mGATE FAILED\033[0m — %s\n' "$(join "${FAILED[@]}")"
  echo "GATE: FAIL repo=$REPO_NAME ran=$(join ${RAN[@]+"${RAN[@]}"}) gaps=$(join ${GAPS[@]+"${GAPS[@]}"})"
  exit 1
fi

if [ ${#GAPS[@]} -gt 0 ]; then
  if [ "$STRICT" = "1" ]; then
    printf '\033[31mGATE FAILED (strict)\033[0m — unresolved gaps: %s\n' "$(join "${GAPS[@]}")"
    echo "GATE: FAIL repo=$REPO_NAME ran=$(join ${RAN[@]+"${RAN[@]}"}) gaps=$(join "${GAPS[@]}")"
    exit 1
  fi
  printf '\033[32mGATE PASSED\033[0m with gaps: %s\n' "$(join "${GAPS[@]}")"
  printf '\033[2mA gap means this repo cannot prove something. It is not a pass for that thing.\033[0m\n'
else
  printf '\033[32mGATE PASSED\033[0m — no gaps\n'
fi

echo "GATE: PASS repo=$REPO_NAME ran=$(join ${RAN[@]+"${RAN[@]}"}) gaps=$(join ${GAPS[@]+"${GAPS[@]}"})"
exit 0
