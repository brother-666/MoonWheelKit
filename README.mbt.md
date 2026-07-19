# MoonWheelKit

MoonWheelKit is a backend-neutral hierarchical timing wheel and deterministic
virtual-time scheduler for MoonBit.

## Install

```bash
moon add brother-666/moonwheelkit
```

Import the package as `import "brother-666/moonwheelkit" @wheel`.

The core library does not read the system clock. Applications explicitly
advance virtual time, which makes timer-heavy services, simulations and tests
repeatable across native, JavaScript, WebAssembly and Wasm-GC backends.

For recovery storms, `advance_late_budgeted(target, max_fires)` bounds total
emissions across all due timers. Remaining due work stays pending and can be
drained by calling the method again at the same target tick.

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

```moonbit nocheck
match wheel.advance_late_budgeted(1000, 256) {
  @moonwheelkit.DrainResult::Drained(report) => {
    println(report.to_json())
    if report.exhausted {
      // Continue draining at tick 1000 in a later event-loop turn.
    }
  }
  @moonwheelkit.DrainResult::Rejected(_) => ()
}
```

See `README.md` for scheduling semantics, architecture, ecosystem comparison
and reproducible verification commands.
