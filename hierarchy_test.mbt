///|
fn hierarchy_id(result : @moonwheelkit.TimerResult) -> Int {
  match result {
    @moonwheelkit.TimerResult::Accepted(id) => id
    @moonwheelkit.TimerResult::Rejected(_) => -1
  }
}

///|
fn hierarchy_report(
  result : @moonwheelkit.AdvanceResult,
) -> @moonwheelkit.AdvanceReport {
  match result {
    @moonwheelkit.AdvanceResult::Advanced(report) => report
    @moonwheelkit.AdvanceResult::Rejected(_) =>
      { from_tick: -1, to_tick: -1, scanned_ticks: -1, cascades: -1, fired: [] }
  }
}

///|
test "second level cascades timer into near wheel" {
  let wheel = @moonwheelkit.Wheel::new(config=@moonwheelkit.WheelConfig::{
    tick_ms: 1,
    slots_per_level: 4,
    levels: 3,
    max_catch_up: 8,
  })
  let id = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(6, "level-one")),
  )
  let report = hierarchy_report(wheel.advance_to(6))
  assert_eq(report.fired.length(), 1)
  assert_eq(report.fired[0].timer_id, id)
  assert_true(report.cascades >= 1)
}

///|
test "top level cascade handles distant deadline" {
  let wheel = @moonwheelkit.Wheel::new(config=@moonwheelkit.WheelConfig::{
    tick_ms: 1,
    slots_per_level: 4,
    levels: 3,
    max_catch_up: 8,
  })
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(22, "level-two")))
  let report = hierarchy_report(wheel.advance_to(22))
  assert_eq(report.fired.length(), 1)
  assert_eq(report.fired[0].scheduled_at, 22)
  assert_true(report.cascades >= 2)
}

///|
test "fixed delay timer schedules from observation time" {
  let wheel = @moonwheelkit.Wheel::new()
  let id = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::fixed_delay(2, 3, "poll")),
  )
  let first = hierarchy_report(wheel.advance_to(2)).fired
  assert_eq(first.length(), 1)
  assert_eq(first[0].occurrence, 1)
  let second = hierarchy_report(wheel.advance_to(5)).fired
  assert_eq(second.length(), 1)
  assert_eq(second[0].timer_id, id)
  assert_eq(second[0].occurrence, 2)
  assert_eq(second[0].scheduled_at, 5)
}

///|
test "fixed rate timer preserves cadence" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 2, "heartbeat")))
  let report = hierarchy_report(wheel.advance_to(7))
  assert_eq(report.fired.length(), 4)
  assert_eq(report.fired[0].scheduled_at, 1)
  assert_eq(report.fired[1].scheduled_at, 3)
  assert_eq(report.fired[2].scheduled_at, 5)
  assert_eq(report.fired[3].scheduled_at, 7)
}

///|
test "cancel repeating timer after first occurrence" {
  let wheel = @moonwheelkit.Wheel::new()
  let id = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 1, "pulse")),
  )
  assert_eq(hierarchy_report(wheel.advance_to(1)).fired.length(), 1)
  assert_true(wheel.cancel(id))
  assert_eq(hierarchy_report(wheel.advance_to(5)).fired.length(), 0)
}

///|
test "compaction removes stale and terminal entries" {
  let wheel = @moonwheelkit.Wheel::new()
  let cancelled = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(20, "cancelled")),
  )
  let pending = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(30, "pending")),
  )
  ignore(wheel.reschedule(pending, 25))
  ignore(wheel.cancel(cancelled))
  let report = wheel.compact()
  assert_eq(report.removed_terminal_timers, 1)
  assert_true(report.removed_stale_entries >= 2)
  assert_eq(report.retained_pending_timers, 1)
  assert_eq(wheel.validate().length(), 0)
}

///|
test "stats distinguish pending cancelled and fired" {
  let wheel = @moonwheelkit.Wheel::new()
  let cancel_id = hierarchy_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(9, "cancel")),
  )
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(2, "fire")))
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(12, "wait")))
  ignore(wheel.cancel(cancel_id))
  ignore(wheel.advance_to(2))
  let stats = wheel.stats()
  assert_eq(stats.pending, 1)
  assert_eq(stats.cancelled, 1)
  assert_eq(stats.fired_total, 1)
  assert_eq(stats.scheduled_total, 3)
  assert_eq(wheel.validate().length(), 0)
}

///|
test "late advance reports one shot lateness without scanning ticks" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "deadline")))
  let report = hierarchy_report(wheel.advance_late_to(10))
  assert_eq(report.scanned_ticks, 0)
  assert_eq(report.fired.length(), 1)
  assert_eq(report.fired[0].scheduled_at, 3)
  assert_eq(report.fired[0].observed_at, 10)
  assert_eq(report.fired[0].lateness, 7)
}

///|
test "late fixed delay emits once and delays from observation" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::fixed_delay(2, 3, "worker")))
  let fired = hierarchy_report(wheel.advance_late_to(10)).fired
  assert_eq(fired.length(), 1)
  assert_eq(wheel.timers()[0].deadline, 13)
}

///|
test "late fixed rate catch up is bounded" {
  let wheel = @moonwheelkit.Wheel::new(config=@moonwheelkit.WheelConfig::{
    tick_ms: 1,
    slots_per_level: 8,
    levels: 3,
    max_catch_up: 3,
  })
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 2, "ticker")))
  let fired = hierarchy_report(wheel.advance_late_to(20)).fired
  assert_eq(fired.length(), 3)
  assert_eq(fired[0].scheduled_at, 1)
  assert_eq(fired[1].scheduled_at, 3)
  assert_eq(fired[2].scheduled_at, 5)
  assert_true(wheel.timers()[0].deadline > 20)
  assert_eq(wheel.validate().length(), 0)
}
