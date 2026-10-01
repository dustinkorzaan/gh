# gh

User stories are delivered by one GitHub Copilot cloud agent, **`ship`**
(`.github/agents/ship.agent.md`). Within one session it plans, waits for your
approval, then writes acceptance tests, implements, verifies, peer-reviews and
final-reviews (up to 3 rounds each) until the PR is ready for your review. You
squash-merge.

No PAT or extra secrets are needed: every session starts from something you
do (assigning the issue or an `@copilot` comment).

## Commands

| When | Where | What you do |
|---|---|---|
| **Story** | Issues → New → *User Story* | Fill in summary, acceptance criteria and areas |
| **Start** (plan and interview) | Issue → Assignees → **Copilot**, agent **`ship`** | Optional prompt: `--quick` (small single-area change) or `--hands-off` (no questions or approval wait; assumptions recorded). Copilot opens a draft PR with the spec, then stops with questions or "plan ready for approval" |
| **Answer** (only if it asked) | PR comment | `@copilot answers: 1) … 2) …` |
| **Approve** | PR comment | `@copilot approved` or `@copilot approved, but <tweak>`. The rest of the loop runs in this session |
| **Continue** (session stopped, e.g. around an hour) | PR comment | `@copilot continue` |
| **Sync** (after another PR merged into `main`) | PR comment | `@copilot sync`, or `@copilot sync --light` to skip the overlap scan and re-review on a clean merge |
| **Rework** (after your review, or CI red) | Review comments, then a PR comment | `@copilot rework` |
| **Merge** | PR | **Squash and merge** (only you; agents never merge) |

```
Assign issue → Copilot, agent "ship"   start: plan / interview
@copilot answers: …                    answer interview questions
@copilot approved                      go: runs the full loop
@copilot continue                      resume after a pause
@copilot sync                          bring in main after other merges
@copilot sync --light                  same, skips overlap scan/re-review
@copilot rework                        fix your review comments / red CI
Squash and merge                       you, after final review
```

When the agent hands over, the PR description starts with
**✅ Ready for human review**, or **⚠️ Needs triage** if a gate hit its
3-round cap (details under *Open issues* in the spec).

With several story PRs open, merge them one at a time and `@copilot sync` the
next one after each merge.

## How it fits together

| File | Purpose |
|---|---|
| `.github/agents/ship.agent.md` | The agent: phases, commands, hard rules |
| `docs/agents/*.md` | Checklists for each phase: planner, test-author, implementer, peer-reviewer, final-reviewer, sync |
| `.github/copilot-instructions.md` | Makes every `@copilot` session on a story PR follow `ship` |
| `AGENTS.md` | Stack, git policy, rules |
| `.github/instructions/*.instructions.md` | UI and API conventions |
| `REVIEW.md` | Review checklist |
| `docs/specs/` | One spec per story; its **Progress** checklist is how sessions resume |
| `scripts/verify.sh` | The one check command; same checks as CI |
| `.github/workflows/copilot-setup-steps.yml` | Installs Node, .NET and dependencies for the agent |
| `.github/workflows/ci-*.yml`, `e2e-playwright.yml`, `codeql.yml` | CI |

## One-time repo settings

1. **Settings → Copilot → Coding agent:** enable it for this repo.
2. **Settings → Actions → General:** let workflows run on Copilot's PRs
   without manual approval (otherwise CI waits for an "Approve and run"
   click every push).
3. **Settings → General → Pull Requests:** allow squash merging (optionally
   disable merge commits and rebase merging).
4. Optional: a ruleset that requests Copilot code review automatically, as a
   second opinion for your final review.
