# MoonWheelKit

MoonWheelKit is a backend-neutral hierarchical timing wheel and deterministic
virtual-time scheduler for MoonBit.

The core library does not read the system clock. Applications explicitly
advance virtual time, which makes timer-heavy services, simulations and tests
repeatable across native, JavaScript, WebAssembly and Wasm-GC backends.

```moonbit nocheck
///|
test "schedule with deterministic virtual time" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "expire")))
  match wheel.advance_to(3) {
    @moonwheelkit.AdvanceResult::Advanced(report) => {
      assert_eq(report.fired.length(), 1)
      assert_eq(report.fired[0].payload, "expire")
    }
    @moonwheelkit.AdvanceResult::Rejected(_) =>
      fail("forward advance should succeed")
  }
}
```

See `README.md` for scheduling semantics, architecture, ecosystem comparison
and reproducible verification commands.
