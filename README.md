# MoonWheelKit

MoonWheelKit is a deterministic hierarchical timing wheel for MoonBit. It is
designed for systems that manage many deadlines while still requiring precise,
testable scheduling semantics.

## Planned capabilities

- configurable hierarchical wheel geometry
- one-shot, fixed-delay and fixed-rate timers
- stable ordering for timers sharing a deadline
- cancellation and rescheduling
- explicit virtual-time advancement
- snapshot, restoration, validation and diagnostics
- backend-neutral core with a small CLI demonstration

The implementation deliberately separates scheduling policy from wall-clock
integration. A server, browser, game loop or simulator can feed elapsed ticks
into the same engine without changing core behavior.
