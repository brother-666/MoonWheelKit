# Architecture

## Design goal

MoonWheelKit separates timer policy from operating-system time. The wheel only
accepts integer ticks and never reads a clock, starts a thread or performs I/O.
This gives every backend the same observable sequence for the same schedule and
advance operations.

## Data path

1. `TimerSpec` is validated and assigned a monotonically increasing identifier.
2. The timer is stored once in the central timer table.
3. A bucket receives a lightweight `(timer_id, generation)` reference.
4. Cancellation and rescheduling increment the generation instead of searching
   every bucket.
5. A bucket scan ignores references whose generation no longer matches.
6. Diagnostics can rebuild all buckets and discard stale references.

This indirection keeps mutation local and makes cancellation independent of
bucket length.

## Hierarchy

With `S` slots per level, level `L` represents a slot width of `S^L` ticks.
The scheduler chooses the lowest level whose range contains the deadline.
Higher levels cascade into lower levels when their span boundary is crossed.

The default geometry uses 64 slots and four levels, covering increasingly
coarse ranges while keeping near deadlines in the first level.

## Advancement modes

- `advance_to` processes every logical tick and is appropriate when exact
  per-tick observation matters.
- `advance_late_to` jumps to a target, reports lateness, and performs bounded
  fixed-rate catch-up without scanning the skipped interval.

Both operations are deterministic. The second mode models an event loop that
was paused, overloaded or restored after downtime.

## Complexity

| Operation | Expected cost |
| --- | --- |
| Schedule | O(levels), bounded by configured hierarchy |
| Cancel | O(1) table lookup and generation increment |
| Reschedule | O(levels), old reference becomes stale |
| Exact advance | O(elapsed ticks + visited entries) |
| Late advance | O(number of tracked timers + emitted catch-up events) |
| Snapshot | O(number of tracked timers) |
| Validation | O(timers × bucket references), intentionally diagnostic |

The validation path favors clear evidence over hot-path performance.
