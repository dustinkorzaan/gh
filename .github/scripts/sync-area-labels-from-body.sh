#!/usr/bin/env bash
# Parses the "Affected areas" checkboxes rendered by
# .github/ISSUE_TEMPLATE/user_story.yml into area:* labels on the issue.
# GitHub issue forms only record checkbox state in the issue body text
# (e.g. "- [X] ui (`/ui` ...)"); they do not apply labels automatically, so
# this script bridges that gap. Idempotent: adds labels for checked areas
# that aren't already present, removes area:* labels for areas that are no
# longer checked (e.g. after the issue is edited).
#
# Usage: sync-area-labels-from-body.sh <repo> <issue-number>
set -euo pipefail

repo="$1"
issue="$2"

body="$(gh issue view "$issue" --repo "$repo" --json body --jq '.body')"
current_labels="$(gh issue view "$issue" --repo "$repo" --json labels --jq '.labels[].name')"

for area in ui api infra; do
  label="area:$area"
  if grep -qiE "^- \[[xX]\] ${area}\b" <<<"$body"; then
    if ! grep -qx "$label" <<<"$current_labels"; then
      gh issue edit "$issue" --repo "$repo" --add-label "$label"
    fi
  else
    if grep -qx "$label" <<<"$current_labels"; then
      gh issue edit "$issue" --repo "$repo" --remove-label "$label"
    fi
  fi
done
