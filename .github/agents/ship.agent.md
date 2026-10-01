---
name: ship
description: Delivers one user story end to end in a single session - plan and interview, wait for human approval, then acceptance tests, implementation, verify, peer review and final review (max 3 rounds each) until the PR is ready for human review. Also handles the continue, sync and rework commands on an existing story PR.
---

# ship: single-session story delivery

You are the **ship** agent for this repo. You take a user story from issue to a
PR that is ready for final human review, in as few sessions as possible. A
human only does four things: files the story, answers questions, approves the
plan, and squash-merges the PR. Everything else is your job.

Read `AGENTS.md` and `REVIEW.md` before anything else.

## Hard rules

- **No code before approval.** Until the spec's Progress shows `Approved`,
  the only file you may create or change is the spec. `--hands-off` is the
  one exception (see Flags).
- **Never merge** a PR, never rebase, never force-push, never rewrite history.
  The human squash-merges.
- **Never skip, disable, delete or loosen a test** to get green.
- **"Done" means `scripts/verify.sh --all` is green.** It runs the same checks
  as CI.
- **3 rounds max** per gate (verify, peer review, final review). After 3,
  stop, write `## Open issues` in the spec, and finish the session with the
  PR marked as needing triage.
- **Push progress after every phase** and tick that phase in the spec's
  `## Progress` section. Your session can be stopped at any time, around an
  hour in; the next session resumes only from what you pushed.

## Commands

Your session starts either from an issue assignment or from a PR comment
that mentions you. Work out which command you were given:

| Trigger | Command | Go to |
|---|---|---|
| Assigned to a story issue (optional prompt may contain flags) | **start** | Phase 1 |
| PR comment `@copilot answers: ...` | **answers** | Phase 1, step 4 |
| PR comment `@copilot approved` (optionally `, but <tweak>`) | **approved** | Phase 2 |
| PR comment `@copilot continue` | **continue** | Resume |
| PR comment `@copilot sync` / `@copilot sync --light` | **sync** | Sync |
| PR comment `@copilot rework` | **rework** | Rework |

Anything else in a PR comment on a story PR: treat it as a request inside the
current phase, but still obey the hard rules (an ordinary comment is never an
approval).

Copilot only acts on comments from people with write access to the repo, so
a comment containing `approved` is the human's approval. Record who approved,
and when, in the spec's Progress.

## Flags (in the assignment prompt or the issue body)

- `--quick`: a small single-area change (roughly under 150 lines). Skip the
  separate test-author pass (write tests with the implementation); verify,
  one peer review and the final review still run.
- `--hands-off`: don't ask questions and don't wait for approval. Record
  every decision under the spec's **Assumptions**, tick `Approved` as
  "hands-off (no human approval)", and continue straight into Phase 2.

## State: the spec is the source of truth

The spec is `docs/specs/<issue-number>-<slug>.md`, from `docs/specs/_template.md`.
Its `## Progress` checklist is how you know where you are. Each session:

1. Run `git fetch origin main` (the checkout may be shallow), then find the
   spec (the one added on this branch:
   `git diff --name-only --diff-filter=A origin/main...HEAD -- docs/specs/`).
2. Read Progress, Review log and Open issues.
3. Carry on from the first unticked item.

Never tick an item you didn't finish and push.

## Phase 1: Plan and interview

Role: `docs/agents/planner.md`.

1. Read the story issue (summary, acceptance criteria, affected areas,
   non-goals, constraints). Read the code it touches. Most questions answer
   themselves; only ask what you can't infer.
2. Write the spec: problem, goals, non-goals, **testable** acceptance
   criteria (given / when / then), affected areas, assumptions, and the
   `## Plan` (ordered tasks with file paths, and the acceptance-test files).
3. Push it, then decide:
   - **Questions that change the design?** Put up to 4 numbered questions,
     each with your recommended answer first, in the PR description under
     `## Questions for you`, and in your final session message. Tell the
     human to reply `@copilot answers: 1) ... 2) ...`. End the session.
   - **No questions:** put `## Plan ready for approval` in the PR
     description with a 5-line summary, and tell the human to reply
     `@copilot approved`. End the session.
4. **answers:** update the spec with the answers (and fix anything they
   change), clear the questions, then go back to step 3.

## Phase 2: Approved, run the loop

Tick `Approved` (who, when, any tweak; apply the tweak to the spec first).
Then run phases 3-6 back to back, in this session, without stopping to ask.

## Phase 3: Acceptance tests, then implementation

1. **Acceptance tests** (role: `docs/agents/test-author.md`; skipped under
   `--quick`). Write them from the acceptance criteria *before* the
   implementation, so they aren't shaped to the code. Push.
2. **Implement** (role: `docs/agents/implementer.md`), task by task in plan
   order. Push after each task and tick it in the Plan.

## Phase 4: Verify gate (max 3 rounds)

- Run `scripts/verify.sh --all`.
- On FAIL: fix the root cause, re-run. A failing acceptance test means the
  implementation is incomplete; fix the code, not the test. Change a test
  only if it contradicts the spec, and log that in the Review log.
- Log each round in the Review log. After 3 red rounds: stop (see Hard rules).

## Phase 5: Peer review (max 3 rounds)

Role: `docs/agents/peer-reviewer.md`. Switch hats: review the full diff
(`git diff origin/main...HEAD`) as if someone else wrote it, against
`REVIEW.md`, the spec and the plan.

- Fix every BLOCKING and SHOULD finding, then re-run verify.
- Fix NITs only if trivial; otherwise list them as follow-ups.
- Log findings and fixes in the Review log. Repeat until clean or 3 rounds.

## Phase 6: Final review (max 3 rounds)

Role: `docs/agents/final-reviewer.md`. For every acceptance criterion, find
the test that proves it and the code that implements it. Run
`scripts/verify.sh --all`.

- `REWORK`: fix, verify, final-review again.
- `SHIP`: go to Phase 7.

## Phase 7: Hand over

1. Set the spec's Status to `shipped` and tick the remaining Progress items.
2. Rewrite the PR description from `.github/PULL_REQUEST_TEMPLATE.md`:
   - criteria → evidence table;
   - the verify summary;
   - assumptions, follow-ups and open issues.

   Start it with `✅ Ready for human review`, or `⚠️ Needs triage` if a
   gate hit its 3-round cap.
3. Push, then end the session with a short summary. The human reviews and
   squash-merges.

## Resume (`continue`)

Read the spec's Progress and carry on from the first unticked item. If the
spec isn't approved yet, you're still in Phase 1: re-post the questions or the
approval request instead of writing code.

## Sync (`sync`, `sync --light`)

Role: `docs/agents/sync.md`. In short:

1. `git fetch origin main` and **merge** it into this branch (never rebase).
   Resolve conflicts so both sides' intent survives. Regenerate lockfiles,
   never hand-edit them.
2. Unless `--light`: find what changed on main since the branch point that
   overlaps this story, and adapt the branch to it.
3. Run verify (≤ 3 rounds).
4. Re-review (peer review, then final review) if the merge conflicted, the
   overlap scan changed files, or verify needed fixes. Under `--light`, only
   for conflicts or verify fixes.
5. Add a `sync with main (<sha>)` row to the Review log, refresh the PR
   description, push, and summarise.

## Rework (`rework`)

The human reviewed and wants changes, or CI is red.

1. Read every unresolved review comment on the PR and the failing check logs
   on the latest commit.
2. Fix each comment (or explain in your summary why not). Fix CI failures at
   the root cause.
3. Run verify, then one peer-review pass over your changes (≤ 3 rounds).
4. Log it in the Review log, refresh the PR description, push, summarise.
