///|
struct BucketEntry {
  timer_id : Int
  generation : Int
}

///|
struct InternalTimer {
  id : Int
  mut deadline : Int
  period : Int
  repeat : RepeatMode
  payload : String
  mut state : TimerState
  sequence : Int
  mut generation : Int
  mut occurrence : Int
}

///|
pub struct Wheel {
  config : WheelConfig
  mut current_tick : Int
  mut next_id : Int
  mut next_sequence : Int
  timers : Map[Int, InternalTimer]
  buckets : Array[Array[BucketEntry]]
  mut fired_total : Int
  mut scheduled_total : Int
  mut cascades_total : Int
}

///|
fn int_pow(base : Int, exponent : Int) -> Int {
  let mut result = 1
  let mut index = 0
  while index < exponent {
    result = result * base
    index = index + 1
  }
  result
}

///|
fn Wheel::flat_index(self : Wheel, level : Int, slot : Int) -> Int {
  level * self.config.slots_per_level + slot
}

///|
fn Wheel::level_span(self : Wheel, level : Int) -> Int {
  int_pow(self.config.slots_per_level, level)
}

///|
fn Wheel::select_level(self : Wheel, deadline : Int) -> Int {
  let delta = if deadline > self.current_tick {
    deadline - self.current_tick
  } else {
    0
  }
  let mut level = 0
  while level + 1 < self.config.levels {
    let range = self.level_span(level) * self.config.slots_per_level
    if delta < range {
      return level
    }
    level = level + 1
  }
  level
}

///|
fn Wheel::place(self : Wheel, timer : InternalTimer) -> Unit {
  let level = self.select_level(timer.deadline)
  let span = self.level_span(level)
  let slot = (timer.deadline / span) % self.config.slots_per_level
  self.buckets[self.flat_index(level, slot)].push({
    timer_id: timer.id,
    generation: timer.generation,
  })
}

///|
pub fn Wheel::new(config? : WheelConfig = WheelConfig::standard()) -> Wheel {
  let buckets : Array[Array[BucketEntry]] = []
  let mut index = 0
  while index < config.levels * config.slots_per_level {
    buckets.push([])
    index = index + 1
  }
  {
    config,
    current_tick: 0,
    next_id: 1,
    next_sequence: 1,
    timers: {},
    buckets,
    fired_total: 0,
    scheduled_total: 0,
    cascades_total: 0,
  }
}

///|
pub fn Wheel::now(self : Wheel) -> Int {
  self.current_tick
}

///|
pub fn Wheel::config(self : Wheel) -> WheelConfig {
  self.config
}

///|
pub fn Wheel::schedule(self : Wheel, spec : TimerSpec) -> TimerResult {
  if !self.config.is_valid() {
    return TimerResult::Rejected(ScheduleError::InvalidConfiguration)
  }
  if spec.delay < 0 {
    return TimerResult::Rejected(ScheduleError::InvalidDelay)
  }
  if spec.repeat != RepeatMode::Once && spec.period <= 0 {
    return TimerResult::Rejected(ScheduleError::InvalidPeriod)
  }
  let id = self.next_id
  self.next_id = id + 1
  let timer = InternalTimer::{
    id,
    deadline: self.current_tick + spec.delay,
    period: spec.period,
    repeat: spec.repeat,
    payload: spec.payload,
    state: TimerState::Pending,
    sequence: self.next_sequence,
    generation: 1,
    occurrence: 0,
  }
  self.next_sequence = self.next_sequence + 1
  self.timers[id] = timer
  self.place(timer)
  self.scheduled_total = self.scheduled_total + 1
  TimerResult::Accepted(id)
}

///|
fn InternalTimer::info(self : InternalTimer) -> TimerInfo {
  {
    id: self.id,
    deadline: self.deadline,
    period: self.period,
    repeat: self.repeat,
    payload: self.payload,
    state: self.state,
    sequence: self.sequence,
    generation: self.generation,
    occurrence: self.occurrence,
  }
}

///|
pub fn Wheel::get(self : Wheel, id : Int) -> TimerInfo? {
  match self.timers.get(id) {
    Some(timer) => Some(timer.info())
    None => None
  }
}

///|
pub fn Wheel::cancel(self : Wheel, id : Int) -> Bool {
  match self.timers.get(id) {
    Some(timer) =>
      if timer.state == TimerState::Pending {
        timer.state = TimerState::Cancelled
        timer.generation = timer.generation + 1
        true
      } else {
        false
      }
    None => false
  }
}

///|
pub fn Wheel::reschedule(self : Wheel, id : Int, delay : Int) -> TimerResult {
  if delay < 0 {
    return TimerResult::Rejected(ScheduleError::InvalidDelay)
  }
  match self.timers.get(id) {
    Some(timer) =>
      if timer.state == TimerState::Pending {
        timer.deadline = self.current_tick + delay
        timer.generation = timer.generation + 1
        self.place(timer)
        TimerResult::Accepted(id)
      } else {
        TimerResult::Rejected(ScheduleError::UnknownTimer)
      }
    None => TimerResult::Rejected(ScheduleError::UnknownTimer)
  }
}

///|
pub fn Wheel::pending(self : Wheel) -> Int {
  let mut count = 0
  for _, timer in self.timers {
    if timer.state == TimerState::Pending {
      count = count + 1
    }
  }
  count
}

///|
fn fired_before(left : FiredTask, right : FiredTask) -> Bool {
  if left.scheduled_at != right.scheduled_at {
    left.scheduled_at < right.scheduled_at
  } else {
    left.timer_id < right.timer_id
  }
}

///|
fn sort_fired(tasks : Array[FiredTask]) -> Unit {
  let mut outer = 1
  while outer < tasks.length() {
    let mut inner = outer
    while inner > 0 && fired_before(tasks[inner], tasks[inner - 1]) {
      let temporary = tasks[inner - 1]
      tasks[inner - 1] = tasks[inner]
      tasks[inner] = temporary
      inner = inner - 1
    }
    outer = outer + 1
  }
}

///|
fn Wheel::emit_timer(
  self : Wheel,
  timer : InternalTimer,
  output : Array[FiredTask],
) -> Unit {
  let scheduled = timer.deadline
  timer.occurrence = timer.occurrence + 1
  output.push({
    timer_id: timer.id,
    scheduled_at: scheduled,
    observed_at: self.current_tick,
    lateness: self.current_tick - scheduled,
    occurrence: timer.occurrence,
    payload: timer.payload,
  })
  self.fired_total = self.fired_total + 1
  match timer.repeat {
    RepeatMode::Once => timer.state = TimerState::Fired
    RepeatMode::FixedDelay => {
      timer.deadline = self.current_tick + timer.period
      timer.generation = timer.generation + 1
      self.place(timer)
    }
    RepeatMode::FixedRate => {
      timer.deadline = scheduled + timer.period
      timer.generation = timer.generation + 1
      self.place(timer)
    }
  }
}

///|
fn Wheel::process_level_zero(self : Wheel, output : Array[FiredTask]) -> Unit {
  let slot = self.current_tick % self.config.slots_per_level
  let bucket = self.buckets[self.flat_index(0, slot)]
  let entries = bucket.copy()
  bucket.clear()
  for entry in entries {
    match self.timers.get(entry.timer_id) {
      Some(timer) =>
        if timer.state == TimerState::Pending &&
          timer.generation == entry.generation {
          if timer.deadline <= self.current_tick {
            self.emit_timer(timer, output)
          } else {
            self.place(timer)
          }
        }
      None => ()
    }
  }
}

///|
fn Wheel::cascade_level(self : Wheel, level : Int) -> Bool {
  let span = self.level_span(level)
  if self.current_tick % span != 0 {
    return false
  }
  let slot = (self.current_tick / span) % self.config.slots_per_level
  let bucket = self.buckets[self.flat_index(level, slot)]
  let entries = bucket.copy()
  bucket.clear()
  for entry in entries {
    match self.timers.get(entry.timer_id) {
      Some(timer) =>
        if timer.state == TimerState::Pending &&
          timer.generation == entry.generation {
          self.place(timer)
        }
      None => ()
    }
  }
  self.cascades_total = self.cascades_total + 1
  true
}

///|
fn Wheel::process_current_tick(
  self : Wheel,
  output : Array[FiredTask],
) -> Int {
  let mut cascades = 0
  let mut level = self.config.levels - 1
  while level >= 1 {
    if self.cascade_level(level) {
      cascades = cascades + 1
    }
    level = level - 1
  }
  self.process_level_zero(output)
  cascades
}

///|
pub fn Wheel::advance_to(self : Wheel, target : Int) -> AdvanceResult {
  if target < self.current_tick {
    return AdvanceResult::Rejected(ScheduleError::TimeWentBackwards)
  }
  let from_tick = self.current_tick
  let output : Array[FiredTask] = []
  let mut cascades = 0
  if target == self.current_tick {
    cascades = self.process_current_tick(output)
  } else {
    while self.current_tick < target {
      self.current_tick = self.current_tick + 1
      cascades = cascades + self.process_current_tick(output)
    }
  }
  sort_fired(output)
  AdvanceResult::Advanced({
    from_tick,
    to_tick: target,
    scanned_ticks: target - from_tick,
    cascades,
    fired: output,
  })
}

///|
pub fn Wheel::advance_by(self : Wheel, delta : Int) -> AdvanceResult {
  if delta < 0 {
    AdvanceResult::Rejected(ScheduleError::TimeWentBackwards)
  } else {
    self.advance_to(self.current_tick + delta)
  }
}

///|
fn Wheel::rebuild_live_buckets(self : Wheel) -> Unit {
  for bucket in self.buckets {
    bucket.clear()
  }
  for _, timer in self.timers {
    if timer.state == TimerState::Pending {
      self.place(timer)
    }
  }
}

///|
pub fn Wheel::advance_late_to(self : Wheel, target : Int) -> AdvanceResult {
  if target < self.current_tick {
    return AdvanceResult::Rejected(ScheduleError::TimeWentBackwards)
  }
  let from_tick = self.current_tick
  self.current_tick = target
  let output : Array[FiredTask] = []
  for _, timer in self.timers {
    if timer.state != TimerState::Pending || timer.deadline > target {
      continue
    }
    match timer.repeat {
      RepeatMode::Once | RepeatMode::FixedDelay =>
        self.emit_timer(timer, output)
      RepeatMode::FixedRate => {
        let mut caught_up = 0
        while timer.deadline <= target &&
          caught_up < self.config.max_catch_up {
          self.emit_timer(timer, output)
          caught_up = caught_up + 1
        }
        if timer.deadline <= target {
          let missed = (target - timer.deadline) / timer.period + 1
          timer.deadline = timer.deadline + missed * timer.period
          timer.generation = timer.generation + 1
        }
      }
    }
  }
  self.rebuild_live_buckets()
  sort_fired(output)
  AdvanceResult::Advanced({
    from_tick,
    to_tick: target,
    scanned_ticks: 0,
    cascades: 0,
    fired: output,
  })
}
