# Implementation evidence

## Implemented

- configurable multi-level timing wheel
- generation-based cancellation and rescheduling
- exact and late virtual-time advancement
- one-shot, fixed-delay and fixed-rate timers
- bounded fixed-rate catch-up
- deterministic deadline ordering
- logical snapshot and restoration
- statistics, invariant validation, JSON reporting and compaction
- CLI scenario and deterministic 10,000-timer workload

## Verification commands

```text
moon check
moon test
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon run cmd/main
moon run bench/main
```

At the time this document was added, the suite contained 21 deterministic
tests. CI repeats the backend matrix on every push and pull request.

## Traceability

Public changes should be organized as feature-sized commits. Issues describe
behavior or evidence gaps, pull requests link implementation to those issues,
and `CHANGELOG.md` records release-facing changes. `docs/TRACKING.md` provides
ready-to-use issue titles for the next milestones.
