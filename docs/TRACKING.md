# Public development tracking

The following issues can be created in the public repository. Each issue should
link its pull request and close only after tests and documentation are updated.

## Suggested issues

1. `feat: add clock adapter trait without platform dependencies`
   - define adapter boundary and monotonicity rules
   - provide a manual clock reference adapter
   - test backward and duplicate clock observations

2. `test: add model-based randomized scheduler comparison`
   - build a simple sorted-array oracle
   - generate deterministic operation traces
   - compare event order, cancellation and snapshots

3. `perf: publish dated four-backend benchmark snapshot`
   - record compiler, CPU, OS and build mode
   - measure uniform, clustered and long-tail workloads
   - preserve raw commands and output

4. `feat: add versioned snapshot parser`
   - define schema version and compatibility rules
   - reject malformed and unsupported snapshots
   - add round-trip and migration fixtures

5. `docs: add async runtime integration example`
   - keep the core dependency-free
   - show how an external event loop advances the wheel
   - document cancellation ownership

## Pull request checklist

- issue linked and behavior stated
- public API change documented
- default, JS, Wasm and Wasm-GC tests pass
- deterministic ordering preserved
- benchmark claim includes reproducible evidence
- changelog updated when user-visible behavior changes

## Release evidence

For each release, attach the CI run URL, commit hash, test count, benchmark
snapshot path and MoonBit compiler version to the release notes.
