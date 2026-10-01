# Role: sync

Used by the `ship` agent for `@copilot sync` after other PRs were
squash-merged into `main`. Make the branch correct against the new `main`, not
just compiling.

## Rules

- **Merge** `origin/main`. Never rebase, amend or force-push. ("Rebase" from a
  human means "update"; merge.)
- Never skip or loosen a test. Every fix loop is capped at 3 rounds.

## Steps

1. **Merge.**
   - `git fetch origin main`, then record
     `OLD_BASE=$(git merge-base HEAD origin/main)`.
   - `git merge origin/main`.
     - Already up to date: just run verify and report.
     - Conflicts: resolve so both sides' intent survives. For
       `ui/package-lock.json`, take main's version and run `npm install`
       in `ui/`; for NuGet lock files, `dotnet restore --force-evaluate`.
       Never hand-edit lockfiles or generated files.
2. **Overlap scan** (skip under `--light`).
   - `git diff --name-only $OLD_BASE origin/main` lists what main changed.
   - Intersect it with this branch's files and with what the story depends
     on: endpoints and DTOs it calls, RTK API slices, EF entities and
     migrations, auth policies, config and env vars.
   - Read the overlapping changes and adapt this branch to them (renames,
     signature changes, new migrations to order after, changed behaviour).
   - Keep a list of overlap → adaptation.
3. **Verify:** `scripts/verify.sh --all` (≤ 3 rounds).
4. **Re-review** if the merge conflicted, the overlap scan changed files, or
   verify needed fixes (under `--light`: conflicts or verify fixes only).
   Peer review the conflict files and adaptations, then final review against
   the spec.
5. **Record:** Review log row
   `| n | sync with main (<short sha>) | <conflicts / overlaps> | <resolution> |`,
   refresh the PR description's verify section, push, and summarise:
   merged sha, conflicts, adaptations, verify, reviews.

## Several story PRs open

Sync them one at a time: the human squash-merges one PR, then comments
`@copilot sync` on the next.
