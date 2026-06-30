# MoonWheelKit contributor notes

- Keep the scheduler core independent of platform clocks, threads and I/O.
- Express all time values as non-negative integer ticks.
- Preserve deterministic ordering by deadline and insertion sequence.
- Add regression tests for every semantic change.
- Run `moon check`, `moon test`, `moon test --target js`, `moon test --target wasm`
  and `moon test --target wasm-gc` before publishing.
