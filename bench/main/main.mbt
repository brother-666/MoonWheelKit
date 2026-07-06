///|
fn main {
  let scheduler = @wheel.Wheel::new()
  let timer_count = 10000
  let horizon = 4096
  let mut index = 0
  while index < timer_count {
    let deadline = index * 37 % horizon + 1
    ignore(
      scheduler.schedule(@wheel.TimerSpec::once(deadline, "benchmark-payload")),
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

  let storm = @wheel.Wheel::new()
  for index = 0; index < timer_count; index = index + 1 {
    ignore(storm.schedule(@wheel.TimerSpec::once(10, "storm-\{index}")))
  }
  let mut batches = 0
  let mut drained = 0
  let mut deferred = timer_count
  while deferred > 0 {
    match storm.advance_late_budgeted(1000, 256) {
      @wheel.DrainResult::Drained(report) => {
        batches = batches + 1
        drained = drained + report.fired.length()
        deferred = report.deferred_due
      }
      @wheel.DrainResult::Rejected(_) => break
    }
  }
  println("storm_scheduled=\{timer_count}")
  println("storm_budget=256")
  println("storm_batches=\{batches}")
  println("storm_drained=\{drained}")
  println("storm_deferred=\{deferred}")
  println("storm_validation_issues=\{storm.validate().length()}")
}
