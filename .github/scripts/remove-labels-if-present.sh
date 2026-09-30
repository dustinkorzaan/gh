#!/usr/bin/env bash
# Shared helper for .github/workflows/orchestrator.yml.
#
# Removes $2.. labels from a GitHub issue or PR, but only the ones that are
# actually present in $CURRENT_LABELS (newline-separated label names) — this
# avoids `gh issue/pr edit --remove-label` failing when a label is already
# absent.
#
# Usage:
#   CURRENT_LABELS="$labels" ./remove-labels-if-present.sh issue 123 label-a label-b
#
# Requires GH_TOKEN and REPO to be set in the environment (as used by `gh`).
set -euo pipefail

kind="$1" # "issue" or "pr"
number="$2"
shift 2

for label in "$@"; do
  if grep -qx "$label" <<<"${CURRENT_LABELS:-}"; then
    gh "$kind" edit "$number" --repo "$REPO" --remove-label "$label"
  fi
done
