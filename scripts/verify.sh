#!/usr/bin/env bash
# The one check command for humans and agents. Runs the same checks as CI
# (ci-ui.yml, ci-api.yml, e2e-playwright.yml) for the areas that changed,
# installs missing dependencies on demand, and prints a PASS/FAIL/SKIPPED
# summary.
#
# Usage:
#   scripts/verify.sh              # checks for everything changed vs origin/main (default)
#   scripts/verify.sh --all        # every check CI runs
#   scripts/verify.sh --list [...] # print the checks that would run, run nothing
#   scripts/verify.sh <path>...    # checks for the given paths only
#
# Exit code: 0 when nothing FAILed, 1 otherwise.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

LOG_DIR="$(git rev-parse --git-dir)/verify-logs"
mkdir -p "$LOG_DIR"

mode="changed"
list_only=false
paths=()
for arg in "$@"; do
  case "$arg" in
    --all) mode="all" ;;
    --changed) mode="changed" ;;
    --list) list_only=true ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) mode="paths"; paths+=("$arg") ;;
  esac
done

has_ui() { [ -f ui/package.json ]; }
has_api() {
  shopt -s globstar nullglob
  local found=(api/*.sln api/**/*.csproj)
  shopt -u globstar nullglob
  [ "${#found[@]}" -gt 0 ]
}
has_e2e() { [ -f ui/playwright.config.ts ] || [ -f ui/playwright.config.js ]; }

# Which paths changed: committed vs the merge-base with origin/main, plus
# staged, unstaged and untracked files. Falls back to --all without origin/main.
changed_files() {
  if ! git rev-parse -q --verify origin/main >/dev/null; then
    git fetch -q origin main 2>/dev/null || true
  fi
  if ! base="$(git merge-base HEAD origin/main 2>/dev/null)"; then
    echo "::all::"
    return
  fi
  {
    git diff --name-only "$base"
    git diff --name-only --cached
    git ls-files --others --exclude-standard
  } | sort -u
}

if [ "$mode" = "paths" ]; then
  files="$(printf '%s\n' "${paths[@]}")"
elif [ "$mode" = "changed" ]; then
  files="$(changed_files)"
  [ "$files" = "::all::" ] && mode="all"
fi

want_ui=false want_api=false want_e2e=false want_shell=false
if [ "$mode" = "all" ]; then
  want_ui=true want_api=true want_e2e=true want_shell=true
else
  grep -qE '^ui(/|$)' <<<"$files" && want_ui=true && want_e2e=true
  # CI runs E2E on api/** changes too: an API contract change can break the UI.
  grep -qE '^api(/|$)' <<<"$files" && want_api=true && want_e2e=true
  grep -qE '\.sh$' <<<"$files" && want_shell=true
  grep -qE '^\.github/workflows/ci-ui\.yml$' <<<"$files" && want_ui=true
  grep -qE '^\.github/workflows/ci-api\.yml$' <<<"$files" && want_api=true
  grep -qE '^\.github/workflows/e2e-playwright\.yml$' <<<"$files" && want_e2e=true
fi

results=()
failed=false

# run_check <name> <command...>: runs the command with output in a log file.
run_check() {
  local name="$1"; shift
  local log="$LOG_DIR/${name//[^a-zA-Z0-9_-]/_}.log"
  echo "==> $name"
  if "$@" >"$log" 2>&1; then
    results+=("PASS     $name")
  else
    results+=("FAIL     $name  (log: $log)")
    failed=true
    echo "---- last 40 lines of $log ----"
    tail -n 40 "$log"
    echo "-------------------------------"
  fi
}

skip() { results+=("SKIPPED  $1 ($2)"); }

ui_deps() {
  if [ ! -d ui/node_modules ]; then
    (cd ui && npm ci)
  fi
}

ui_test() {
  (cd ui &&
    node -e "const s=require('./package.json').scripts||{}; process.exit(s.test?0:1)" ||
    { echo "ui/package.json has no \"test\" script; CI fails without one." >&2; exit 1; }
    npm test -- --run)
}

api_test() {
  local output exit_code
  output="$(cd api && dotnet test --no-build --configuration Release 2>&1)"
  exit_code=$?
  echo "$output"
  [ "$exit_code" -ne 0 ] && return "$exit_code"
  if grep -qiE 'no test (is available|matches|source files)|Total tests: 0\b' <<<"$output"; then
    echo "dotnet test reported zero tests; CI fails on that." >&2
    return 1
  fi
}

e2e_run() {
  # Chromium is the only browser playwright.config.ts uses. Install it only if
  # the exact builds this Playwright version needs are missing, so later verify
  # rounds skip the slow download and apt step.
  local dirs dir installed=false
  dirs="$(cd ui && npx playwright install --dry-run chromium 2>/dev/null |
    awk '/Install location:/ {print $3}')"
  if [ -n "$dirs" ]; then
    installed=true
    while read -r dir; do [ -d "$dir" ] || installed=false; done <<<"$dirs"
  fi
  if $installed; then
    echo "Playwright Chromium already installed; skipping install."
  else
    (cd ui && npx playwright install --with-deps chromium >/dev/null 2>&1 || npx playwright install chromium)
  fi
  (cd ui && npx playwright test)
}

shell_check() {
  local f rc=0
  while IFS= read -r f; do
    bash -n "$f" || rc=1
  done < <(git ls-files '*.sh')
  return "$rc"
}

if $list_only; then
  echo "Checks that would run:"
  $want_ui && echo "  ui: npm ci, lint, build, test"
  $want_api && echo "  api: dotnet restore, build, test"
  $want_e2e && echo "  e2e: playwright test"
  $want_shell && echo "  shell: bash -n on *.sh"
  exit 0
fi

if $want_ui; then
  if has_ui; then
    run_check "ui:install" ui_deps
    run_check "ui:lint" bash -c 'cd ui && npm run lint --if-present'
    run_check "ui:build" bash -c 'cd ui && npm run build --if-present'
    run_check "ui:test" ui_test
  else
    skip "ui" "ui/package.json not found yet"
  fi
fi

if $want_api; then
  if has_api; then
    run_check "api:restore" bash -c 'cd api && dotnet restore'
    run_check "api:build" bash -c 'cd api && dotnet build --no-restore --configuration Release'
    run_check "api:test" api_test
  else
    skip "api" "no .sln/.csproj under api/ yet"
  fi
fi

if $want_e2e; then
  if ! has_ui; then
    skip "e2e" "ui/package.json not found yet"
  elif has_e2e; then
    has_ui && [ ! -d ui/node_modules ] && run_check "ui:install" ui_deps
    run_check "e2e:playwright" e2e_run
  else
    results+=("FAIL     e2e:playwright  (ui/ exists but no playwright.config.ts|js; CI fails on that)")
    failed=true
  fi
fi

$want_shell && run_check "shell:syntax" shell_check

echo
echo "verify summary ($mode):"
if [ "${#results[@]}" -eq 0 ]; then
  echo "  nothing to check for the changed files"
else
  printf '  %s\n' "${results[@]}"
fi

$failed && exit 1
exit 0
