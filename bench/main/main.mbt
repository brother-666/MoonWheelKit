///|
fn main {
  let scheduler = @wheel.Wheel::new()
  let timer_count = 10000
  let horizon = 4096
  let mut index = 0
  while index < timer_count {
    let deadline = (index * 37) % horizon + 1
    ignore(
      scheduler.schedule(
        @wheel.TimerSpec::once(deadline, "benchmark-payload"),
      ),
    )
    index = index + 1
  }
  let fired = match scheduler.advance_to(horizon) {
    @wheel.AdvanceResult::Advanced(report) => report.fired.length()
    @wheel.AdvanceResult::Rejected(_) => -1
  }
  println(
    "scheduled=\{timer_count} fired=\{fired} pending=\{scheduler.pending()} horizon=\{horizon}",
  )
  println("stats=" + scheduler.stats().to_json())
  println("validation_issues=\{scheduler.validate().length()}")
}
