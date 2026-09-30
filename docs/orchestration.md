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
  `area:infra`).
- A **Planner agent** session uses the **GitHub MCP server**
  (`issue_read`, `list_issues`) to read the story and posts a draft
  implementation plan as an issue comment, moving the issue to
  `stage:planned`.
- A human reviews the plan and adds the `approved-plan` label. **Nothing is
  implemented before this label is present.**
- `.github/workflows/orchestrator.yml` (`release-approved-plan` job) reacts
  to that label and does all of the following automatically — no manual
  branch or PR creation is required:
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
     branch.
  - If branch creation, PR creation, or assignment fails at any point, it
    backs out `stage:implementing` and applies `stage:blocked` instead — the
    label state never claims progress that didn't actually happen.
  - **Caveat:** if your Copilot coding agent is configured to open its own
    PR automatically upon issue assignment, that can produce a second PR
    alongside the one this workflow creates. Disable that auto-PR behavior
    (or point the agent at the pre-created branch) to avoid duplicates.

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
  `javascript-typescript` and `csharp`.
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
  to the submitted review:
  - It first checks the reviewer's repository permission via `gh api
    repos/{owner}/{repo}/collaborators/{user}/permission` and ignores the
    review entirely unless it's at least `write` — a read/triage-only
    account's verdict must not be able to drive privileged label
    transitions. If the permission check itself can't be made (e.g. token
    scope limits), it fails safe: skip the verdict rather than act without
    authorization.
  - `approved` → checks the PR's status-check rollup (`gh pr view --json
    statusCheckRollup`); only if CI is actually green does it label the PR
    `stage:ready-for-human` and **stop the loop**. If CI is still pending or
    failing, it leaves the PR in `stage:reviewing` and comments that the
    review passed but CI must complete before the loop can stop.
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
(assigning the Copilot coding agent, starting iteration 1). Restrict who can
apply it — e.g. via a ruleset/branch-protection rule limiting label
management to maintainers, or a required-reviewers rule on the story issue —
so the gate can't be bypassed by an arbitrary contributor.

## Label reference

See `.github/labels.yml` (kept in sync by `.github/workflows/label-sync.yml`)
for the full set of `stage:*`, `iteration-*`, and `area:*` labels used above.
