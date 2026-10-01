# Shell UI and Shell API

- **Status:** draft
- **Issue / PR:** #3 / current PR
- **Mode:** interactive

## Progress

- [x] Spec and plan written
- [ ] Approved (for rev 1, by @<user>, <date>, tweaks: <none>)
- [ ] Acceptance tests written (rev 1)
- [ ] Implementation (rev 1 Plan tasks)
- [ ] Verify gate green (rev 1)
- [ ] Peer review clean (rev 1)
- [ ] Final review: SHIP (rev 1)
- [ ] PR description updated, ready for human review

## Problem

The repository has CI scaffolding but no application yet. The first shell needs a .NET API and React UI so contributors can run and test an end-to-end hello-world experience, with CI checks that can be required on pull requests.

## Goals

- Create the API under `api/gh-api/` with its tests under `api/gh-api.tests/`, targeting .NET 10.
- Create a Vite, React, and Redux Toolkit UI under `ui/` that displays a greeting returned by the API.
- Provide runnable API, UI, and cross-stack tests, and expose named build-and-test checks in GitHub Actions.

## Non-goals

- Authentication, persistence, blob storage, Azure infrastructure, and deployment.
- Production hosting configuration beyond what is needed to run and test the local shell.

## Acceptance criteria

1. **AC1:** Given the API is running, when a client requests `GET /api/gh-api/hello`, then it receives HTTP 200 with JSON containing `message: "Hello, world!"`; the API and its xUnit test project are under the requested paths and target .NET 10.
2. **AC2:** Given the UI is running, when the API returns the greeting, then the UI renders `Hello, world!`; while waiting it renders a loading state, and when the request fails it renders an error state.
3. **AC3:** Given the UI and API are started together, when the Playwright shell test loads the UI, then it observes the greeting returned by the running API.
4. **AC4:** Given a pull request changes the UI or API, when the applicable build-and-test workflow completes, then its terminal job is named `gh-build-and-test-success` and the job succeeds only when that area's build and tests pass.
5. **AC5 (rev 1):** Given the repository workflows are inspected, then `.github/workflows/codeql.yml` is absent and the README no longer lists it as a workflow.
6. **AC6 (rev 1):** Given the API test project is inspected, then the empty generated `UnitTest1.cs` is absent and the actual hello-endpoint tests remain runnable.

## Affected areas

- [x] ui (`/ui`)  - [x] api (`/api`)  - [ ] infra  - [x] workflows / docs

Contracts that apply (see `REVIEW.md`): API contract ↔ RTK; auth, data, and blobs are n/a for this shell.

## Assumptions

- The issue explicitly requests .NET 10, so that requirement supersedes the current .NET 8 references in repository guidance and CI; update those references alongside the API.
- The named terminal job is added to each existing area-specific CI workflow, keeping their current path filters and allowing each applicable check to be selected as required in GitHub.
- The vague issue criteria are split into testable API, UI, cross-stack, and CI criteria above. The existing Playwright workflow and `scripts/verify.sh` require a runnable Playwright config once `/ui` exists.
- The issue marks infra as affected, but a hello-world shell does not need infrastructure, authentication, persistence, or blob changes.
- The rev 1 request calls `.github/workflows/codeql.yml` a duplicate, but it is a distinct CodeQL static-analysis workflow; the API/UI workflows only build and test. Removing it disables this repository's PR/push and scheduled CodeQL analysis, so rev 1 requires explicit approval with that effect made clear.

## Plan

- [x] 1. Add the .NET 10 API and xUnit acceptance tests: `api/gh-api/`, `api/gh-api.tests/`, and any solution/configuration files under `api/`. Expose the hello endpoint and verify its HTTP response with `scripts/verify.sh api`.
- [x] 2. Add the Vite/React/Redux Toolkit UI and its acceptance test: `ui/` and `ui/src/`. Fetch the API response and render loading, success, and error states; verify with `scripts/verify.sh ui`.
- [x] 3. Add the Playwright config and cross-stack acceptance test: `ui/playwright.config.ts` and `ui/e2e/`. Start the API and UI for the test and verify that the UI renders the live API greeting with `scripts/verify.sh ui`.
- [x] 4. Update .NET version guidance and CI: `AGENTS.md`, `.github/instructions/api.instructions.md`, `.github/workflows/ci-api.yml`, `.github/workflows/copilot-setup-steps.yml`, and `.github/workflows/ci-ui.yml`. Name each area's terminal build/test job `gh-build-and-test-success`; verify with `scripts/verify.sh --all`.
- [ ] **rev 1**
  - [ ] 1. Remove `.github/workflows/codeql.yml` and its README workflow-list entry; verify no CodeQL workflow remains and run `scripts/verify.sh --all`.
  - [ ] 2. Delete the empty generated `api/gh-api.tests/UnitTest1.cs`; confirm the meaningful `HelloEndpointTests.cs` remains and run `scripts/verify.sh api`.

### Acceptance test files

- `api/gh-api.tests/HelloEndpointTests.cs`
- `ui/src/Hello.test.tsx`
- `ui/e2e/hello.spec.ts`

## Revisions

| Rev | Request (verbatim) | Starting sha | Approved |
|---|---|---|---|
| 1 | "delete .github/workflows/codeql.yml (duplicate)"; "delete api/gh-api.tests/UnitTest1.cs" | f1aeace | |

## Review log

| Round | Gate | Findings | Resolution (commit / reason) |
|---|---|---|---|
| Implementation | UI acceptance test | RTK Query starts the fetch asynchronously after render; test initially resolved before the mocked request handler was installed. | Wait for request initiation while asserting loading remains visible; acceptance behavior unchanged. |
| 1 | Verify | `scripts/verify.sh --all` passed all UI, API, Playwright, and shell checks. | Clean on first round. |
| 1 | Peer review | BLOCKING: 460 generated files under API `bin/` and `obj/` were tracked. | Removed generated outputs from the index; `.gitignore` excludes them. |
| 1 (post-fix) | Verify | `scripts/verify.sh --all` passed after generated artifacts were removed. | Clean. |
| 2 | Peer review | No significant issues found; artifact cleanup confirmed. | Clean. |
| 1 | Final review | SHIP — AC1: `HelloEndpointTests` asserts the endpoint status and JSON; AC2: `Hello.test.tsx` asserts loading, success, and error with `Hello.tsx`/`helloApi.ts` implementation; AC3: `hello.spec.ts` observes the live API response and greeting; AC4: CI jobs are named `gh-build-and-test-success` and run the area checks. Final `scripts/verify.sh --all` passed; generated outputs are not tracked. | Code is ready; handover awaits PR description update. |

## Open issues

The implementation passed final review, but the PR description still needs the handover update. `gh pr edit` could not authenticate because this session has no authenticated GitHub CLI host; the PR description could not be changed here.
