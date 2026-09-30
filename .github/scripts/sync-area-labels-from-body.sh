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

# Restrict matching to the "Affected areas" section only (from its heading
# up to the next "### " heading or end of body) — otherwise a checked
# acceptance-criteria item like "- [x] API returns a SAS URL" would be
# mistaken for the areas checkbox. Full option-text prefix match (not just
# the bare word) so a criterion starting with "ui"/"api"/"infra" can't be
# mistaken for the checkbox either. Both "- [x]" and "- [X]" are accepted,
# since GitHub renders a checked issue-form checkbox as either case.
areas_section="$(awk '
  /^### Affected areas/ { in_section = 1; next }
  /^### / { in_section = 0 }
  in_section { print }
' <<<"$body")"

for entry in "ui:ui (\`/ui\`" "api:api (\`/api\`" "infra:infra (Bicep"; do
  area="${entry%%:*}"
  prefix="${entry#*:}"
  label="area:$area"
  if grep -qF -- "- [x] $prefix" <<<"$areas_section" || grep -qF -- "- [X] $prefix" <<<"$areas_section"; then
    if ! grep -qx "$label" <<<"$current_labels"; then
      gh issue edit "$issue" --repo "$repo" --add-label "$label"
    fi
  else
    if grep -qx "$label" <<<"$current_labels"; then
      gh issue edit "$issue" --repo "$repo" --remove-label "$label"
    fi
  fi
done
