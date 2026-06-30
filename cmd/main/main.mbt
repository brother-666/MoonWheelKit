///|
fn accepted_id(result : @wheel.TimerResult) -> Int {
  match result {
    @wheel.TimerResult::Accepted(id) => id
    @wheel.TimerResult::Rejected(_) => -1
  }
}

///|
fn print_advance(label : String, result : @wheel.AdvanceResult) -> Unit {
  match result {
    @wheel.AdvanceResult::Advanced(report) =>
      println(label + "=" + report.to_json())
    @wheel.AdvanceResult::Rejected(_) =>
      println(label + "_error=rejected")
  }
}

///|
fn main {
  let scheduler = @wheel.Wheel::new(config=@wheel.WheelConfig::{
    tick_ms: 10,
    slots_per_level: 8,
    levels: 4,
    max_catch_up: 4,
  })

  let session = accepted_id(
    scheduler.schedule(@wheel.TimerSpec::once(12, "session-expiry")),
  )
  ignore(
    scheduler.schedule(
      @wheel.TimerSpec::fixed_rate(2, 5, "metrics-heartbeat"),
    ),
  )
  let retry = accepted_id(
    scheduler.schedule(@wheel.TimerSpec::once(20, "retry-deadline")),
  )

  println("session_timer=\{session}")
  println("retry_timer=\{retry}")
  print_advance("tick_2", scheduler.advance_to(2))

  ignore(scheduler.reschedule(retry, 6))
  print_advance("tick_8", scheduler.advance_to(8))

  ignore(scheduler.cancel(session))
  print_advance("late_tick_30", scheduler.advance_late_to(30))

  println("stats=" + scheduler.stats().to_json())
  println("snapshot=" + scheduler.snapshot().to_json())
  println("validation_issues=\{scheduler.validate().length()}")
}
