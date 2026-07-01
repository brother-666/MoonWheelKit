# Scheduling semantics

## Time model

Time is a non-negative integer tick. `tick_ms` is metadata that lets an
integration map ticks to milliseconds; the core does not sleep or consult a
wall clock. Time can stay still, move forward exactly, or jump forward in late
mode. Moving backwards is rejected.

## Deadline ordering

Events are returned in deadline order. Equal deadlines use stable timer
identifier order, which is the creation order for a wheel instance. This rule
is observable and covered by tests.

## One-shot timers

A one-shot timer becomes `Fired` after its event is emitted. A zero-delay timer
is drained by `advance_by(0)`, allowing deterministic microtask-style tests
without inventing an extra tick.

## Fixed delay

The next deadline is `observation time + period`. A late observation therefore
shifts future executions and emits at most one event for that advance.

## Fixed rate

The next deadline is `previous scheduled deadline + period`. Exact advancement
preserves cadence. Late advancement emits no more than `max_catch_up`
occurrences and then skips the remaining backlog to the first future deadline.
This avoids an unbounded burst after a long pause.

## Cancellation and rescheduling

Cancellation is idempotent only for the first successful call. Rescheduling a
pending timer preserves its identifier and creation sequence while incrementing
its generation. Stale bucket references are harmless and can later be removed
by `compact`.

## Snapshot contract

A snapshot records wheel geometry, virtual time, counters and all timer states.
Restoration rejects invalid geometry, duplicate identifiers, overdue pending
timers and invalid periodic configuration. A restored wheel produces the same
future event sequence as the source snapshot.
