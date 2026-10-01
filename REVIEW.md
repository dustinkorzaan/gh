# REVIEW.md

The review checklist for every change to this repo. The `ship` agent uses it
in its peer-review and final-review phases; human reviewers use it too. Each
item is a rule; breaking one is a **BLOCKING** finding unless marked
otherwise.

## Correctness and tests

- [ ] Every behaviour change has a test that fails without the change (xUnit in `api/`, the unit runner in `ui/`, Playwright for cross-stack flows).
- [ ] Every acceptance criterion in the spec has a test that asserts it.
- [ ] No test was skipped, disabled, deleted or loosened to get green.
- [ ] `scripts/verify.sh --all` is green.
- [ ] Async code awaits its work, flows `CancellationToken`, and disposes streams and responses. No `.Result` or `.Wait()`.
- [ ] Null, empty and failure paths from external calls (SQL, Blob Storage, Entra ID) are handled with a useful error, not a crash.

## Cross-stack contracts

- [ ] **API contract:** request/response shapes used by the UI's RTK Query/slices match the API's DTOs, including status codes and error bodies.
- [ ] **Files:** blob access only via short-lived, least-privilege SAS URIs issued by the API with its managed identity. File bytes never transit the API, and no endpoint proxies uploads or downloads.
- [ ] **Auth:** Entra ID tokens are validated server-side on every protected endpoint, with the right scopes/roles. The UI never makes authorization decisions on its own.
- [ ] **Data:** EF Core model changes include a migration; queries translate to SQL (no client-side evaluation of large sets, no N+1).
- [ ] **UI state:** RTK slices/selectors are correct and memoized where needed; loading and error states are rendered.

## Configuration, infra and ops

- [ ] Each new env var or setting appears everywhere it's needed: app config (`appsettings*.json` / `.env.example`), infra (Bicep/ACA), and `AGENTS.md` or the README.
- [ ] Missing optional config degrades gracefully instead of crashing at startup.

## Security

- [ ] No secrets, keys, tokens, SAS URIs or connection strings are committed. Samples use obvious placeholders.
- [ ] New dependencies have no known vulnerabilities.
- [ ] No new unauthenticated endpoint exposes user data.

## Scope and docs

- [ ] The diff contains only what the spec asks for: no drive-by refactors, debug leftovers, or commented-out code.
- [ ] `AGENTS.md` / `README.md` are updated when setup, env vars or topology change.
- [ ] *(SHOULD)* Names, comment density and idioms match the surrounding code.
