# gh

This repository runs a GitHub-native multi-agent orchestration loop:
a human writes a user story issue, approves the drafted plan, and
GitHub Actions workflows then drive implement -> test & verify -> peer
review for up to 3 iterations before handing the PR back to a human for
final review and merge.

See [`docs/orchestration.md`](docs/orchestration.md) for the full pipeline
description, the label taxonomy, and known limitations.
