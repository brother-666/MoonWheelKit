///|
pub fn Wheel::snapshot(self : Wheel) -> TimerSnapshot {
  {
    now: self.current_tick,
    next_id: self.next_id,
    next_sequence: self.next_sequence,
    fired_total: self.fired_total,
    scheduled_total: self.scheduled_total,
    cascades_total: self.cascades_total,
    config: self.config,
    timers: self.timers(),
  }
}

///|
fn snapshot_has_duplicate_ids(snapshot : TimerSnapshot) -> Bool {
  let seen : Map[Int, Bool] = {}
  for timer in snapshot.timers {
    if seen.contains(timer.id) {
      return true
    }
    seen[timer.id] = true
  }
  false
}

///|
pub fn Wheel::restore(snapshot : TimerSnapshot) -> Wheel? {
  if !snapshot.config.is_valid() ||
    snapshot.now < 0 ||
    snapshot.next_id < 1 ||
    snapshot.next_sequence < 1 ||
    snapshot_has_duplicate_ids(snapshot) {
    return None
  }
  let wheel = Wheel::new(config=snapshot.config)
  wheel.current_tick = snapshot.now
  wheel.next_id = snapshot.next_id
  wheel.next_sequence = snapshot.next_sequence
  wheel.fired_total = snapshot.fired_total
  wheel.scheduled_total = snapshot.scheduled_total
  wheel.cascades_total = snapshot.cascades_total
  for info in snapshot.timers {
    if info.id <= 0 ||
      (info.deadline < snapshot.now && info.state == TimerState::Pending) ||
      (info.repeat != RepeatMode::Once && info.period <= 0) {
      return None
    }
    let timer = InternalTimer::{
      id: info.id,
      deadline: info.deadline,
      period: info.period,
      repeat: info.repeat,
      payload: info.payload,
      state: info.state,
      sequence: info.sequence,
      generation: info.generation,
      occurrence: info.occurrence,
    }
    wheel.timers[info.id] = timer
    if timer.state == TimerState::Pending {
      wheel.place(timer)
    }
  }
  Some(wheel)
}

///|
pub fn TimerSnapshot::to_json(self : TimerSnapshot) -> String {
  let out = StringBuilder()
  out.write_string(
    "{\"now\":\{self.now},\"next_id\":\{self.next_id},\"next_sequence\":\{self.next_sequence},\"fired_total\":\{self.fired_total},\"scheduled_total\":\{self.scheduled_total},\"cascades_total\":\{self.cascades_total},\"config\":{\"tick_ms\":\{self.config.tick_ms},\"slots_per_level\":\{self.config.slots_per_level},\"levels\":\{self.config.levels},\"max_catch_up\":\{self.config.max_catch_up}},\"timers\":[",
  )
  for index, timer in self.timers {
    if index > 0 {
      out.write_char(',')
    }
    out.write_string(timer.to_json())
  }
  out.write_string("]}")
  out.to_string()
}
