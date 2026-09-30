<!--
  Auto-generated/updated by the orchestrator workflow as the implement /
  test / review loop progresses. See docs/orchestration.md for the full
  pipeline description. Humans: the only action required from you is the
  final review once `stage:ready-for-human` is applied.
-->

## Story

Closes #<!-- issue number -->

## Pipeline status

- [ ] Plan approved (`approved-plan` label present on the story issue)
- [ ] Iteration 1: implement → test → review
- [ ] Iteration 2: implement → test → review (only if iteration 1 review failed)
- [ ] Iteration 3: implement → test → review (only if iteration 2 review failed)
- [ ] Ready for final human review (`stage:ready-for-human`)

## Test & verify results (latest iteration)

| Check | Status |
| --- | --- |
| UI CI (`ci-ui.yml`) | |
| API CI (`ci-api.yml`) | |
| CodeQL | |
| Playwright E2E (if `area:ui`) | |
| Automated code review (`parallel_validation`) | |
| Peer review agent | |

## Notes for the human reviewer

This PR stopped automated iteration because either:
- peer review passed and CI is green, or
- the 3-iteration cap was reached without a clean pass.

See the `stage:*` / `iteration-*` labels and the comment history for details.
