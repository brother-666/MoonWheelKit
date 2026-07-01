///|
pub(all) enum RepeatMode {
  Once
  FixedDelay
  FixedRate
} derive(Debug, Eq)

///|
pub(all) enum TimerState {
  Pending
  Cancelled
  Fired
} derive(Debug, Eq)

///|
pub(all) enum ScheduleError {
  InvalidDelay
  InvalidPeriod
  InvalidConfiguration
  UnknownTimer
  TimeWentBackwards
  SnapshotMismatch
} derive(Debug, Eq)

///|
pub(all) enum TimerResult {
  Accepted(Int)
  Rejected(ScheduleError)
} derive(Debug, Eq)

///|
pub(all) enum AdvanceResult {
  Advanced(AdvanceReport)
  Rejected(ScheduleError)
} derive(Debug, Eq)

///|
pub(all) struct WheelConfig {
  tick_ms : Int
  slots_per_level : Int
  levels : Int
  max_catch_up : Int
} derive(Debug, Eq)

///|
pub fn WheelConfig::standard() -> WheelConfig {
  { tick_ms: 1, slots_per_level: 64, levels: 4, max_catch_up: 32 }
}

///|
pub fn WheelConfig::is_valid(self : WheelConfig) -> Bool {
  self.tick_ms > 0 &&
  self.slots_per_level >= 2 &&
  self.levels >= 1 &&
  self.max_catch_up >= 1
}

///|
pub(all) struct TimerSpec {
  delay : Int
  period : Int
  repeat : RepeatMode
  payload : String
} derive(Debug, Eq)

///|
pub fn TimerSpec::once(delay : Int, payload : String) -> TimerSpec {
  { delay, period: 0, repeat: RepeatMode::Once, payload }
}

///|
pub fn TimerSpec::fixed_delay(
  delay : Int,
  period : Int,
  payload : String,
) -> TimerSpec {
  { delay, period, repeat: RepeatMode::FixedDelay, payload }
}

///|
pub fn TimerSpec::fixed_rate(
  delay : Int,
  period : Int,
  payload : String,
) -> TimerSpec {
  { delay, period, repeat: RepeatMode::FixedRate, payload }
}

///|
pub(all) struct TimerInfo {
  id : Int
  deadline : Int
  period : Int
  repeat : RepeatMode
  payload : String
  state : TimerState
  sequence : Int
  generation : Int
  occurrence : Int
} derive(Debug, Eq)

///|
pub(all) struct FiredTask {
  timer_id : Int
  scheduled_at : Int
  observed_at : Int
  lateness : Int
  occurrence : Int
  payload : String
} derive(Debug, Eq)

///|
pub(all) struct AdvanceReport {
  from_tick : Int
  to_tick : Int
  scanned_ticks : Int
  cascades : Int
  fired : Array[FiredTask]
} derive(Debug, Eq)

///|
pub(all) struct WheelStats {
  now : Int
  pending : Int
  cancelled : Int
  fired_total : Int
  scheduled_total : Int
  cascades_total : Int
  levels : Int
  slots_per_level : Int
} derive(Debug, Eq)

///|
pub(all) struct TimerSnapshot {
  now : Int
  next_id : Int
  next_sequence : Int
  fired_total : Int
  scheduled_total : Int
  cascades_total : Int
  config : WheelConfig
  timers : Array[TimerInfo]
} derive(Debug, Eq)

///|
pub(all) struct ValidationIssue {
  code : String
  timer_id : Int
  message : String
} derive(Debug, Eq)

///|
pub(all) struct MaintenanceReport {
  removed_terminal_timers : Int
  removed_stale_entries : Int
  retained_pending_timers : Int
} derive(Debug, Eq)
