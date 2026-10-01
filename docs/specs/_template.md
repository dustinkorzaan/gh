# <Title>

- **Status:** draft | approved | in-progress | shipped | needs-triage
- **Issue / PR:** #<issue> / #<pr>
- **Mode:** interactive | hands-off | quick

## Progress

The `ship` agent ticks each item only after it is finished and pushed. A new
session resumes from the first unticked item.

- [ ] Spec and plan written
- [ ] Approved (by @<user>, <date>, tweaks: <none>)
- [ ] Acceptance tests written
- [ ] Implementation (all Plan tasks ticked)
- [ ] Verify gate green
- [ ] Peer review clean
- [ ] Final review: SHIP
- [ ] PR description updated, ready for human review

## Problem

<What is wrong or missing, for whom, and why now. 2-5 sentences.>

## Goals

- <outcome>

## Non-goals

- <explicitly out of scope>

## Acceptance criteria

Each criterion is testable: given <state>, when <action>, then <observable result>.

1. **AC1:** ...
2. **AC2:** ...

## Affected areas

- [ ] ui (`/ui`)  - [ ] api (`/api`)  - [ ] infra  - [ ] workflows / docs

Contracts that apply (see `REVIEW.md`): <API contract ↔ RTK, SAS-only blobs, Entra ID auth, or "n/a">

## Assumptions

<Decisions made without asking. Each one says what was assumed and why.>

## Plan

<Ordered tasks: files, reused helpers, verification. Tick each when pushed.>

- [ ] 1. ...

### Acceptance test files

- <path>

## Review log

| Round | Gate | Findings | Resolution (commit / reason) |
|---|---|---|---|

## Open issues

<Anything still failing or deferred after 3 rounds, with the next step. Empty when shipped.>
