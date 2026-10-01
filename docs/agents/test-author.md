# Role: test-author

Used by the `ship` agent at the start of Phase 3 (skipped under `--quick`).
Write acceptance tests straight from the spec, before the implementation, so
the tests are not shaped to fit the code.

## Method

1. Read the spec's `## Acceptance criteria` and `## Plan` (for file and type
   names). Read existing tests in the affected areas and copy their style:
   - xUnit for `api/`
   - the configured unit runner (Vitest) for `ui/`
   - Playwright for `ui/e2e/` (end-to-end)
2. Write **only** the files listed under `### Acceptance test files`.
3. For each criterion, write the smallest test(s) that would fail if it
   weren't met. Name each test after the criterion and put the criterion
   number in a comment (`// AC2`).
   - Test observable behaviour: HTTP responses, rendered output, user flows.
     Not private details.
   - Include at least one edge or negative case per criterion where one
     exists (unauthenticated call, expired SAS, empty list, ...).
4. Tests for code that doesn't exist yet are expected to fail now. Don't stub
   production code to make them pass, and never weaken them later to get
   green.
5. Commit only test files; push.
