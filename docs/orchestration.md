# Multi-agent orchestration pipeline

This repo automates delivery of user stories through a fixed pipeline:

```
plan interview --(human approval)--> [ implement -> test -> review ] x up to 3 -> ready for final human review
```

A human only does two things: approve the plan once, and do the final PR
review/merge. Everything in between is driven by agents using the tools
below.

## Stack

| Area | Path | Stack |
| --- | --- | --- |
| UI | `/ui` | Vite + React + Redux Toolkit |
| API | `/api` | C# |
| Infra | Bicep/ACA manifests | Azure Container Apps, Entra ID, Azure SQL DB |
| Files | — | Blob access only via SAS URIs issued by the API's managed identity (binaries never transit the API) |

## Stages and the tools that drive them

### 1. Plan interview & approval

- A user story is filed with `.github/ISSUE_TEMPLATE/user_story.yml`
  (`stage:interview`), tagging affected areas (`area:ui` / `area:api` /
  `area:infra`) via checkboxes. GitHub issue forms only record checkbox
  state as text in the issue body, not as real labels, so
  `.github/workflows/sync-area-labels.yml` runs on every issue
  open/edit and applies/removes the matching `area:*` labels — everything
  downstream (the orchestrator's label mirroring, the E2E workflow's
  `area:ui` gate) depends on those labels actually existing.
- A **Planner agent** session uses the **GitHub MCP server**
  (`issue_read`, `list_issues`) to read the story and posts a draft
  implementation plan as an issue comment, moving the issue to
  `stage:planned`.
- A human reviews the plan and adds the `approved-plan` label. **Nothing is
  implemented before this label is present.**
- `.github/workflows/orchestrator.yml` (`release-approved-plan` job) reacts
  to that label — but only if the user who applied it has at least
  `maintain` repository permission (checked via `gh api
  repos/{owner}/{repo}/collaborators/{user}/permission` against
  `github.actor`). Branch protection can't restrict who is allowed to apply
  an issue label, so this check is what actually enforces "only a
  maintainer can release a plan into the loop" — a label alone isn't
  sufficient authorization for privileged automation (branch/PR creation,
  agent assignment). If the permission check itself fails, the job skips
  rather than risk acting without authorization.
- It also skips if the issue already has an `iteration-N` label — that
  means this issue was already released once, and `approved-plan` being
  removed and re-applied (e.g. by mistake) must not reset iteration state
  back to `iteration-1` next to whatever iteration is actually in progress.
- Otherwise, it does all of the following automatically — no manual branch
  or PR creation is required:
  1. Removes `stage:interview`/`stage:planned` and adds
     `stage:implementing` + `iteration-1` on the issue.
  2. Creates a working branch named `story/<issue-number>` off the
     repository's default branch (via the Git Data API: an empty commit on
     top of the default branch's tip, so the branch is one commit ahead and
     a PR can be opened immediately, before any real changes exist).
  3. Opens a **draft PR** from that branch back to the default branch,
     titled from the issue title, with `Closes #<issue>` populated from
     `.github/PULL_REQUEST_TEMPLATE.md`. This step — and the branch-creation
     step before it — are idempotent: if a PR or branch for this issue
     already exists (e.g. the workflow re-ran), the existing one is reused
     instead of creating a duplicate.
  4. Mirrors the issue's `area:*` labels onto the new PR, and adds
     `stage:implementing` + `iteration-1` to the PR too — from this point
     on, `handle-review-verdict` (below) manages the PR's labels, since the
     PR (not the issue) is what carries the pipeline state through
     implement/test/review.
  5. Assigns the issue to the Copilot coding agent to start work on that
     branch, then **verifies the assignment actually took effect** by
     re-reading the issue's assignee list — the GitHub issues API silently
     ignores an assignee login it can't add (e.g. because `GITHUB_TOKEN`
     lacks the scope to assign the coding-agent bot), so a successful `gh`
     exit code alone is not proof anyone was actually assigned.
  - If branch creation, PR creation, or assignment fails/doesn't take
    effect at any point, it backs out `stage:implementing` and applies
    `stage:blocked` instead — the label state never claims progress that
    didn't actually happen. **Recovering from `stage:blocked` is a fully
    manual step**: fix the underlying problem (create the branch/PR/
    assignment by hand), then manually remove `stage:blocked` and add
    `stage:implementing` yourself — no workflow listens for those label
    changes to auto-resume the loop.
  - **Caveat on assignment:** starting the actual Copilot coding agent on a
    pre-created branch is not guaranteed to work via `gh issue edit
    --add-assignee` with the default `GITHUB_TOKEN`. Reliably invoking the
    coding agent on a specific branch with plan context requires assigning
    it via a PAT-scoped `POST /repos/{owner}/{repo}/issues/{n}/assignees`
    call carrying an `agent_assignment` payload (`base_branch`,
    `custom_instructions` seeded from the approved plan) — this needs a
    dedicated PAT secret, which is not yet configured in this repo. Treat
    the current assignment step as best-effort until that PAT is added;
    `stage:blocked` is the expected outcome until then unless a maintainer
    is also manually assigning/running the coding agent out of band.
  - **Caveat on PR creation:** if your Copilot coding agent is configured
    to open its own PR automatically upon issue assignment, that can
    produce a second PR alongside the one this workflow creates. Disable
    that auto-PR behavior (or point the agent at the pre-created branch) to
    avoid duplicates.

### 2. Implement / execute

- The **Implementer agent** (Copilot coding agent session) makes the actual
  code changes with the standard runtime tools (`bash`, `edit`, `create`,
  `view`), scoped to whichever of `/ui`, `/api` (or infra) the plan calls
  for, pushing commits to the `story/<issue-number>` branch that
  `release-approved-plan` already created.
- Before adding/bumping any dependency, run
  `runtime-tools-gh-advisory-database` for that ecosystem (`npm` for `/ui`,
  `nuget` for `/api`).
- Before every commit, run `runtime-tools-secret_scanning` — this stack
  touches Entra ID client config, Azure SQL connection strings, and
  SAS/Blob settings, so this check is not optional.
- The agent uses the **GitHub MCP server** to update the existing draft PR
  (description, review-thread replies) and keep the `stage:*` /
  `iteration-N` labels and the PR checklist
  (`.github/PULL_REQUEST_TEMPLATE.md`) in sync with progress. It does not
  need to create the PR itself — that already happened in stage 1.

### 3. Test & verify

- `.github/workflows/ci-ui.yml` — path-filtered on `ui/**`, runs
  `npm ci && npm run lint && npm run build && npm test`.
- `.github/workflows/ci-api.yml` — path-filtered on `api/**`, runs
  `dotnet restore && dotnet build && dotnet test`.
- `.github/workflows/codeql.yml` — CodeQL analysis for
  `javascript-typescript` and `csharp`, each as its own job that only runs
  when that stack is actually present in the repo (`ui/package.json` /
  `api/*.sln`|`*.csproj`) — `codeql-action/init` fails outright if it finds
  no source for the configured language, which would otherwise block the
  green-CI gate for e.g. a UI-only story with no `/api` tree yet.
- `.github/workflows/e2e-playwright.yml` — runs **only** on PRs labeled
  `area:ui`, using the **Playwright MCP server** (or `npx playwright test`
  in CI) to exercise the running app end-to-end, including the
  request-SAS-URL -> upload-directly-to-Blob -> download-via-SAS round trip.
  This is the only check that can prove the "API never sees the file bytes"
  contract holds across both stacks — a unit test on either side alone
  can't.
- Before/while reading results, the agent uses the **GitHub MCP server**
  (`actions_list` / `actions_get` / `get_job_logs`) to pull the *actual* CI
  run status instead of trusting a local `npm test`/`dotnet test` run.

### 4. Peer review

- First pass: `parallel_validation` (Code Review + CodeQL) runs as a cheap,
  automated reviewer before spending a full review iteration.
- Second pass: a **Reviewer agent** reads the diff via the **GitHub MCP
  server** (`pull_request_read` with `get_diff`, `get_review_comments`,
  `get_reviews`) and submits a structured review (`approved` or
  `changes_requested`), checking stack-specific concerns:
  - UI: RTK slice/selector correctness, API contract shape.
  - API: Entra ID token validation happens server-side, EF Core/SQL access
    patterns, and that blob access only ever issues SAS URIs — no binary
    proxying through API endpoints.
- `.github/workflows/orchestrator.yml` (`handle-review-verdict` job) reacts
  to the submitted review. It checks out the repository's **default branch**
  rather than the implicit ref for a `pull_request_review` event (which
  defaults to the PR head) before running any repo scripts, so a PR can
  never smuggle in a modified copy of `.github/scripts/remove-labels-if-present.sh`
  and have it run with this job's `issues`/`pull-requests: write` permissions.
  - It first checks the reviewer's repository permission via `gh api
    repos/{owner}/{repo}/collaborators/{user}/permission` and ignores the
    review entirely unless it's at least `write` — a read/triage-only
    account's verdict must not be able to drive privileged label
    transitions. If the permission check itself can't be made (e.g. token
    scope limits), it fails safe: skip the verdict rather than act without
    authorization.
  - `approved` → first requires an unambiguous `iteration-N` label on the
    PR (skips otherwise — an approval on a PR the orchestrator isn't
    tracking must not move it to `stage:ready-for-human`), then checks the
    PR's status-check rollup (`gh pr view --json statusCheckRollup`),
    **excluding this orchestrator workflow's own check run** from that
    rollup (it is itself still "in progress" for the exact commit being
    evaluated, which would otherwise make the rollup perpetually `PENDING`
    and this branch unreachable). Only if the remaining checks are
    actually green does it label the PR `stage:ready-for-human` and **stop
    the loop**. If CI is still pending or failing, it leaves the PR in
    `stage:reviewing` and comments that the review passed but CI must
    complete before the loop can stop.
  - `changes_requested` → increments the iteration label (`iteration-1` ->
    `iteration-2` -> `iteration-3`) and loops back to Implement, unless the
    cap has already been reached.
  - At `iteration-3` with `changes_requested` → stops the loop anyway,
    labels `stage:ready-for-human`, and flags in a comment that the
    3-iteration cap was hit without a clean review, so a human can triage.

### 5. Stop conditions

The loop always stops when **either**:
1. Peer review passes and CI is green, or
2. 3 iterations have been completed without a passing review.

In both cases the PR ends up labeled `stage:ready-for-human` — the only
state a human needs to watch for. **The orchestrator never merges a PR**;
final approval and merge are always a human action.

If the orchestrator receives a `changes_requested` review but can't find an
`iteration-N` label on the PR, or finds more than one (labels are supposed
to be mutually exclusive, but nothing prevents drift), it stops immediately
and labels the PR `stage:blocked` instead of guessing an iteration number —
this needs human triage before the loop can safely continue.

### Manual override

Add the `stage:paused` label to a PR or issue at any time to halt the
orchestrator; it must take no action while that label is present.

### Securing the approval gate

Applying the `approved-plan` label directly triggers privileged automation
(branch/PR creation, assigning the Copilot coding agent, starting
iteration 1). Since branch protection can't restrict who is allowed to
apply an issue label, `release-approved-plan` enforces this itself: it
checks `github.actor`'s repository permission and only proceeds for
`maintain`/`admin` — a `triage`/`write`-level contributor applying the
label has no effect. If you need a different permission bar, adjust the
`case` statement in that job.

## Label reference

See `.github/labels.yml` (kept in sync by `.github/workflows/label-sync.yml`,
which pins `micnncim/action-label-syncer` to a commit SHA and sets
`prune: false` so syncing the manifest never deletes unrelated repo labels
like `bug`/`enhancement`) for the full set of `stage:*`, `iteration-*`, and
`area:*` labels used above.
