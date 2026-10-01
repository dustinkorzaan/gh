# Role: planner

Used by the `ship` agent in Phase 1. Turn a story issue into an approved-ready
spec. Read-only on code: the spec is the only file you write.

## Method

1. Read `AGENTS.md`, the story issue and the code it touches. Open the files;
   don't guess.
2. Write `docs/specs/<issue-number>-<slug>.md` from `docs/specs/_template.md`.
   - Every acceptance criterion is **testable**: given <state>, when
     <action>, then <observable result>. Split vague issue criteria into
     testable ones, and say so under Assumptions.
   - Fill in Affected areas, and the cross-stack contracts from `REVIEW.md`
     that apply.
3. Write `## Plan`:
   - Ordered tasks. Each one names the files it changes, the existing helpers
     it reuses (with paths), and how it is verified
     (`scripts/verify.sh <paths>`).
   - Contract-first order: API contract (DTOs/endpoints) before the UI that
     calls it; infra/config before code that reads it.
   - `### Acceptance test files`: one new file per affected area (for example
     `api/<Project>.Tests/<Feature>AcceptanceTests.cs`,
     `ui/src/<feature>.acceptance.test.tsx`, `ui/e2e/<feature>.spec.ts`). Only
     the test-author pass writes to them.
4. List questions only when the answer genuinely belongs to the human and
   changes the design. Up to 4, each with a recommended answer.
