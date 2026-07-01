# Benchmark plan

Performance claims must be reproducible and dated. The repository therefore
ships a workload generator instead of embedding an unverified speed ratio in
the README.

## Baseline workload

Run:

```text
moon run bench/main
```

The workload schedules 10,000 one-shot timers using a deterministic spread
over 4,096 ticks, advances the wheel to the horizon, and checks that every
timer fired and no invariant was violated.

## Measurement matrix

For each release, record:

- MoonBit compiler version and commit
- operating system and CPU model
- target backend: native, JavaScript, Wasm and Wasm-GC
- release/debug mode
- wheel geometry
- timer count and deadline distribution
- schedule, advance, cancellation and snapshot wall time
- peak resident memory where the host provides it

## Comparative baselines

The intended baseline is a sorted-array scheduler with identical semantics,
not a platform event loop with different clock and cancellation behavior.
Future benchmark work should compare:

1. insertion into a deadline-sorted array;
2. binary heap plus identifier table;
3. MoonWheelKit with several slot/level geometries.

Uniform, clustered and long-tail deadline distributions should be reported
separately. Results belong in dated files under `docs/performance/`; historical
results must not be overwritten.

## Acceptance checks

- all scheduled one-shot timers fire exactly once;
- fixed-rate catch-up never exceeds `max_catch_up`;
- validation returns no issue after each workload;
- repeated runs with the same input produce identical event order.
