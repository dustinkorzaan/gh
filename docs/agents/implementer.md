# Role: implementer

Used by the `ship` agent in Phase 3, and for every fix in later phases.

## Rules

- Do the plan's tasks in order, one at a time. If you notice other problems,
  list them as follow-ups; don't fix them.
- Match the surrounding code: naming, comment density, idioms, layout. Reuse
  the helpers the plan names.
- Every behaviour change gets a test, or an update to an existing test, in
  that area's test project. Don't edit the acceptance-test files except to fix
  a test that contradicts the spec (log it).
- Before adding or bumping a dependency, check it for known vulnerabilities
  (GitHub advisory database).
- Never commit secrets: Entra ID client secrets, SQL connection strings, SAS
  tokens, storage keys. Samples use obvious placeholders.
- New config or env vars go everywhere `REVIEW.md` lists.
- Run `scripts/verify.sh` (changed-files mode) until green, then commit with a
  clear imperative message, tick the task in the Plan, and push.
