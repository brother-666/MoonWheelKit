///|
fn drain_report(
  result : @moonwheelkit.DrainResult,
) -> @moonwheelkit.DrainReport {
  match result {
    @moonwheelkit.DrainResult::Drained(report) => report
    @moonwheelkit.DrainResult::Rejected(_) =>
      {
        from_tick: -1,
        to_tick: -1,
        budget: -1,
        fired: [],
        deferred_due: -1,
        exhausted: false,
      }
  }
}

///|
test "budgeted late advance drains one shot storm in batches" {
  let wheel = @moonwheelkit.Wheel::new()
  for index = 0; index < 10; index = index + 1 {
    ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(5, "job-\{index}")))
  }
  let first = drain_report(wheel.advance_late_budgeted(10, 3))
  assert_eq(first.fired.length(), 3)
  assert_eq(first.deferred_due, 7)
  assert_true(first.exhausted)
  let second = drain_report(wheel.advance_late_budgeted(10, 4))
  assert_eq(second.fired.length(), 4)
  assert_eq(second.deferred_due, 3)
  let third = drain_report(wheel.advance_late_budgeted(10, 10))
  assert_eq(third.fired.length(), 3)
  assert_eq(third.deferred_due, 0)
  assert_false(third.exhausted)
  assert_eq(wheel.pending(), 0)
}

///|
test "budgeted drain preserves global deadline and id order" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(7, "late")))
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "first")))
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "second")))
  let report = drain_report(wheel.advance_late_budgeted(10, 3))
  assert_eq(report.fired[0].payload, "first")
  assert_eq(report.fired[1].payload, "second")
  assert_eq(report.fired[2].payload, "late")
}

///|
test "budgeted fixed rate remains bounded per timer" {
  let wheel = @moonwheelkit.Wheel::new(config=@moonwheelkit.WheelConfig::{
    tick_ms: 1,
    slots_per_level: 8,
    levels: 3,
    max_catch_up: 2,
  })
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 2, "pulse")))
  let report = drain_report(wheel.advance_late_budgeted(20, 10))
  assert_eq(report.fired.length(), 2)
  assert_eq(report.fired[0].scheduled_at, 1)
  assert_eq(report.fired[1].scheduled_at, 3)
  assert_eq(report.deferred_due, 0)
  assert_true(wheel.timers()[0].deadline > 20)
}

///|
test "global budget interleaves repeating and one shot tasks" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 2, "rate")))
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(2, "once")))
  let report = drain_report(wheel.advance_late_budgeted(10, 3))
  assert_eq(report.fired.length(), 3)
  assert_eq(report.fired[0].payload, "rate")
  assert_eq(report.fired[1].payload, "once")
  assert_eq(report.fired[2].payload, "rate")
}

///|
test "invalid budget and backwards time are rejected without mutation" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(1, "task")))
  assert_true(
    wheel.advance_late_budgeted(5, 0) ==
    @moonwheelkit.DrainResult::Rejected(
      @moonwheelkit.ScheduleError::InvalidBudget,
    ),
  )
  assert_eq(wheel.now(), 0)
  ignore(wheel.advance_late_budgeted(5, 1))
  assert_true(
    wheel.advance_late_budgeted(4, 1) ==
    @moonwheelkit.DrainResult::Rejected(
      @moonwheelkit.ScheduleError::TimeWentBackwards,
    ),
  )
  assert_eq(wheel.now(), 5)
}

///|
test "budgeted backlog survives snapshot restore" {
  let wheel = @moonwheelkit.Wheel::new()
  for index = 0; index < 5; index = index + 1 {
    ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(2, "job-\{index}")))
  }
  let first = drain_report(wheel.advance_late_budgeted(5, 2))
  assert_eq(first.deferred_due, 3)
  let restored = @moonwheelkit.Wheel::restore(wheel.snapshot()).unwrap()
  let remaining = drain_report(restored.advance_late_budgeted(5, 10))
  assert_eq(remaining.fired.length(), 3)
  assert_eq(remaining.deferred_due, 0)
  assert_eq(restored.validate().length(), 0)
}
