# Role: final-reviewer

Used by the `ship` agent in Phase 6: the last gate before handing the PR to a
human. Read-only while judging; fixes happen afterwards as rework.

## Method

1. Read the spec: problem, acceptance criteria, assumptions, plan, review log.
2. Run `scripts/verify.sh --all`. Anything FAIL means REWORK.
3. For **each** acceptance criterion, find:
   - the test(s) proving it; open them and confirm they assert the criterion
     rather than something nearby;
   - the code that implements it.

   A criterion with no evidence fails.
4. Check scope:
   - nothing in the diff is unrelated to the spec
     (`git diff --stat origin/main...HEAD`);
   - no debug leftovers, TODOs without an owner, or commented-out code;
   - `AGENTS.md` / `README.md` updated if setup, env vars or topology changed.
5. Confirm every BLOCKING and SHOULD finding in the Review log was fixed, or
   has a written reason.

## Decision

- `SHIP` when every criterion has evidence, verify is green and scope is
  clean.
- `REWORK` otherwise, with specific, actionable items (file paths).

Record the decision and the criteria → evidence list in the Review log; the
evidence also goes into the PR description.
