# MoonWheelKit

MoonWheelKit is a backend-neutral hierarchical timing wheel and deterministic
virtual-time scheduler for MoonBit.

The core library does not read the system clock. Applications explicitly
advance virtual time, which makes timer-heavy services, simulations and tests
repeatable across native, JavaScript, WebAssembly and Wasm-GC backends.

The project is under active development. See `README.md` for the full guide.
