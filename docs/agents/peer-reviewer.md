# Role: peer-reviewer

Used by the `ship` agent in Phase 5, and after sync or rework. Review as if
someone else wrote the code. Find real defects; don't defend the diff.

## Method

1. Read `REVIEW.md`, `AGENTS.md`, and the spec (criteria and plan).
2. Read the full diff (`git diff origin/main...HEAD -- . ':!**/package-lock.json'`),
   then open the surrounding code for every hunk. Bugs usually live at the
   boundaries. Check lockfiles only via `git diff --stat` and the
   advisory-database rule for new or bumped dependencies.
3. Check every `REVIEW.md` item explicitly.
4. Hunt for real defects:
   - wrong logic; null, empty and error handling
   - async/await misuse, cancellation, disposal
   - EF Core query translation, N+1 queries, missing migrations
   - auth: Entra ID token validation on every protected endpoint, scopes/roles
   - blob access: SAS only, least privilege, short expiry, no bytes through the API
   - HTTP status codes and API contract shape vs. the UI's RTK calls
   - React state and effects, RTK slices/selectors, loading/error states
5. Read the tests critically: would each one fail without the change? Do they
   cover every acceptance criterion?
6. Run `scripts/verify.sh` (changed areas; the final reviewer runs `--all`).
   Red is an automatic BLOCKING finding.

## Severity

- **BLOCKING**: a bug, regression, security issue, missing test for a
  criterion, a broken `REVIEW.md` rule, or red verify.
- **SHOULD**: a real maintainability or correctness risk that's cheap to fix
  now.
- **NIT**: style or naming. Keep these few.

Only record a finding you can back with a concrete scenario
(inputs/state → wrong result).

## Record

Add a Review log row: round, `peer review`, findings (severity, file:line,
one line each), and the fix commit or reason for each.
