# Roadmap

## 0.2 - Integration layer

- clock adapter trait for embedding real or simulated clocks
- batch scheduling and cancellation APIs
- optional typed payload wrapper
- snapshot parser with versioned schema
- property tests for ordering and restoration

## 0.3 - Performance evidence

- heap and sorted-array reference schedulers
- dated benchmark results for Native, JavaScript, Wasm and Wasm-GC
- clustered and long-tail deadline workloads
- reduced diagnostic validation cost for very large wheels
- memory accounting for live and stale bucket references

## 0.4 - Scheduling policies

- coalescing windows for energy-sensitive applications
- per-timer catch-up policy
- deadline groups and bulk cancellation tokens
- optional jitter policy with injected deterministic random source

## 1.0 criteria

- stable public API and snapshot schema
- documented migration policy
- cross-backend differential tests
- reproducible performance report
- at least two independent integration examples

The roadmap describes intended work, not completed functionality.
