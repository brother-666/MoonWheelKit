///|
fn accepted_id(result : @moonwheelkit.TimerResult) -> Int {
  match result {
    @moonwheelkit.TimerResult::Accepted(id) => id
    @moonwheelkit.TimerResult::Rejected(_) => -1
  }
}

///|
fn report_of(
  result : @moonwheelkit.AdvanceResult,
) -> @moonwheelkit.AdvanceReport {
  match result {
    @moonwheelkit.AdvanceResult::Advanced(report) => report
    @moonwheelkit.AdvanceResult::Rejected(_) =>
      { from_tick: -1, to_tick: -1, scanned_ticks: -1, cascades: -1, fired: [] }
  }
}

///|
test "new wheel starts empty at tick zero" {
  let wheel = @moonwheelkit.Wheel::new()
  assert_eq(wheel.now(), 0)
  assert_eq(wheel.pending(), 0)
}

///|
test "one shot timer fires at exact deadline" {
  let wheel = @moonwheelkit.Wheel::new()
  let id = accepted_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(5, "expire")),
  )
  assert_true(id > 0)
  assert_eq(report_of(wheel.advance_by(4)).fired.length(), 0)
  let report = report_of(wheel.advance_by(1))
  assert_eq(report.fired.length(), 1)
  assert_eq(report.fired[0].timer_id, id)
  assert_eq(report.fired[0].scheduled_at, 5)
  assert_eq(report.fired[0].observed_at, 5)
  assert_eq(report.fired[0].lateness, 0)
  assert_eq(report.fired[0].payload, "expire")
  assert_eq(wheel.pending(), 0)
}

///|
test "zero delay timer is drained without moving time" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(0, "ready")))
  let report = report_of(wheel.advance_by(0))
  assert_eq(report.scanned_ticks, 0)
  assert_eq(report.fired.length(), 1)
  assert_eq(report.fired[0].payload, "ready")
}

///|
test "timers with same deadline preserve creation order" {
  let wheel = @moonwheelkit.Wheel::new()
  let first = accepted_id(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "a")))
  let second = accepted_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(3, "b")),
  )
  let third = accepted_id(wheel.schedule(@moonwheelkit.TimerSpec::once(3, "c")))
  let fired = report_of(wheel.advance_to(3)).fired
  assert_eq(fired.length(), 3)
  assert_eq(fired[0].timer_id, first)
  assert_eq(fired[1].timer_id, second)
  assert_eq(fired[2].timer_id, third)
}

///|
test "cancel invalidates stale bucket entry" {
  let wheel = @moonwheelkit.Wheel::new()
  let id = accepted_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(8, "cancel")),
  )
  assert_true(wheel.cancel(id))
  assert_false(wheel.cancel(id))
  assert_eq(report_of(wheel.advance_to(8)).fired.length(), 0)
  match wheel.get(id) {
    Some(info) => assert_true(info.state == @moonwheelkit.TimerState::Cancelled)
    None => fail("cancelled timer remains inspectable")
  }
}

///|
test "reschedule invalidates original placement" {
  let wheel = @moonwheelkit.Wheel::new()
  let id = accepted_id(
    wheel.schedule(@moonwheelkit.TimerSpec::once(10, "move")),
  )
  assert_true(
    wheel.reschedule(id, 2) == @moonwheelkit.TimerResult::Accepted(id),
  )
  let fired = report_of(wheel.advance_to(10)).fired
  assert_eq(fired.length(), 1)
  assert_eq(fired[0].scheduled_at, 2)
}

///|
test "invalid scheduling arguments are rejected" {
  let wheel = @moonwheelkit.Wheel::new()
  assert_true(
    wheel.schedule(@moonwheelkit.TimerSpec::once(-1, "bad")) ==
    @moonwheelkit.TimerResult::Rejected(
      @moonwheelkit.ScheduleError::InvalidDelay,
    ),
  )
  assert_true(
    wheel.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 0, "bad")) ==
    @moonwheelkit.TimerResult::Rejected(
      @moonwheelkit.ScheduleError::InvalidPeriod,
    ),
  )
}

///|
test "virtual time cannot move backwards" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.advance_to(5))
  assert_true(
    wheel.advance_to(4) ==
    @moonwheelkit.AdvanceResult::Rejected(
      @moonwheelkit.ScheduleError::TimeWentBackwards,
    ),
  )
  assert_eq(wheel.now(), 5)
}
