# AGENTS.md

Instructions for coding agents (GitHub Copilot cloud agent and others) working
in this repo.

## Stack

| Area | Path | Stack |
| --- | --- | --- |
| UI | `/ui` | Vite + React + Redux Toolkit |
| API | `/api` | C# / .NET 10 |
| Infra | Bicep / ACA manifests | Azure Container Apps, Entra ID, Azure SQL DB |
| Files | — | Blob access only via SAS URIs issued by the API's managed identity (file bytes never transit the API) |

`/ui` and `/api` don't exist yet; the first stories create them. CI and
`scripts/verify.sh` skip an area until it exists.

## How stories are delivered

Stories are delivered by the **`ship`** custom agent
(`.github/agents/ship.agent.md`) in one Copilot session per step. The human
commands are listed in `README.md`. Each story has a spec in
`docs/specs/<issue>-<slug>.md`; its `## Progress` checklist is the source of
truth for where the work is.

## Git / PR policy

- Work only on your PR's branch. Never merge, squash-merge or rebase-merge a
  PR; the human squash-merges after final review.
- Never rebase, amend or force-push. Bring in `main` with a merge commit.

## One check command: `scripts/verify.sh`

- Runs the same checks as CI (`ci-ui.yml`, `ci-api.yml`, `e2e-playwright.yml`)
  for what changed versus `origin/main`, and installs missing dependencies.
- Modes: no args (changed areas), `--all`, `--list`, or `<path>...`.
- Use it instead of per-area commands. **"Done" means `scripts/verify.sh --all`
  is green.**

## Rules

- Never skip, disable, delete or loosen a test to get green.
- Never commit secrets (Entra ID client secrets, SQL connection strings, SAS
  tokens, storage keys).
- Check new or bumped dependencies against the GitHub advisory database.
- The review checklist is `REVIEW.md`.
