# External clock integration

MoonWheelKit deliberately does not own a wall clock. A host event loop, game
frame, simulation or test harness observes time and advances the wheel.

## Manual clock

Tests can keep a logical tick and advance only when the scenario requires it:

```moonbit
let wheel = @moonwheelkit.Wheel::new()
ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(20, "timeout")))

// The test controls observation precisely.
let result = wheel.advance_to(20)
```

The host must never pass a value below `wheel.now()`. Repeated observations of
the same tick are valid and can drain newly scheduled zero-delay work.

## Real event loop

A real-clock adapter should:

1. capture a monotonic start time;
2. convert elapsed duration to integer ticks using `tick_ms`;
3. call `advance_to` when every intermediate tick matters;
4. call `advance_late_to` after suspension or known overload;
5. execute returned `FiredTask` values outside the wheel;
6. feed any resulting schedule or cancellation operations back into the wheel.

The wheel returns data and never invokes user callbacks. This prevents callback
reentrancy from mutating buckets during a scan and gives the integration layer
clear ownership of error handling.

## Cancellation ownership

Keep each returned timer id with the operation that owns it. Cancelling a timer
after it fired returns `false`; cancellation should therefore be treated as a
best-effort state transition, not proof that external work was never started.

For structured concurrency, an adapter can maintain a group-to-timer-id map and
cancel each pending id when the group closes. Group policy remains outside the
core so that browser, native and simulation hosts can choose different
lifecycle models without changing scheduling semantics.

## Clock discontinuities

Wall clocks can move backwards after synchronization. Do not feed wall-clock
timestamps directly into the wheel. Use a monotonic elapsed-time source where
available. If a host resumes after a long pause, `advance_late_to` records
lateness and limits fixed-rate catch-up to `max_catch_up`.

This adapter boundary keeps platform time and I/O outside the backend-neutral
package while preserving deterministic behavior inside it.
