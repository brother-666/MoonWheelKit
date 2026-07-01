# Related work and project boundary

Search date: 2026-06-30.

## MoonBit ecosystem review

The following packages were reviewed before defining the scope:

- [`moonbitlang/async`](https://mooncakes.io/docs/moonbitlang/async) provides an
  asynchronous runtime, event-loop timers, `sleep`, timeout and retry behavior.
  It intentionally exposes real runtime time. MoonWheelKit instead provides a
  reusable data structure with explicit virtual time, hierarchy inspection,
  deterministic snapshots and bounded late catch-up.
- [`peter-jerry-ye/async`](https://mooncakes.io/docs/peter-jerry-ye/async)
  provides promises, an event loop, channels and I/O. MoonWheelKit is not
  another async runtime and has no promise or I/O layer.
- [`f4ah6o/mhx`](https://mooncakes.io/docs/f4ah6o/mhx) includes UI-oriented
  delay, throttle and debounce behavior. MoonWheelKit targets backend-neutral
  scheduling infrastructure rather than browser interaction policy.
- [`dowdiness/moondsp`](https://mooncakes.io/docs/dowdiness/moondsp) includes
  domain-specific audio scheduling. MoonWheelKit has no audio model and exposes
  generic timer payloads and restoration semantics.

Searches for `timing wheel`, `hierarchical timer`, `virtual time scheduler`,
`cron` and `delayed task` did not identify a published Mooncakes package whose
documented purpose matches this library's combination of hierarchical buckets,
generation-based invalidation, deterministic virtual time and snapshot replay.
This is a dated review, not a claim that future packages cannot overlap.

## Deliberate non-goals

- no replacement for `moonbitlang/async`
- no operating-system clock or thread management
- no cron expression parser
- no distributed consensus or durable storage format
- no promise/future abstraction

Integrations can build these concerns around the deterministic core.
