///|
pub fn Wheel::stats(self : Wheel) -> WheelStats {
  let mut pending = 0
  let mut cancelled = 0
  for _, timer in self.timers {
    match timer.state {
      TimerState::Pending => pending = pending + 1
      TimerState::Cancelled => cancelled = cancelled + 1
      TimerState::Fired => ()
    }
  }
  {
    now: self.current_tick,
    pending,
    cancelled,
    fired_total: self.fired_total,
    scheduled_total: self.scheduled_total,
    cascades_total: self.cascades_total,
    levels: self.config.levels,
    slots_per_level: self.config.slots_per_level,
  }
}

///|
pub fn Wheel::timers(self : Wheel) -> Array[TimerInfo] {
  let result : Array[TimerInfo] = []
  for _, timer in self.timers {
    result.push(timer.info())
  }
  let mut outer = 1
  while outer < result.length() {
    let mut inner = outer
    while inner > 0 && result[inner].id < result[inner - 1].id {
      let temporary = result[inner - 1]
      result[inner - 1] = result[inner]
      result[inner] = temporary
      inner = inner - 1
    }
    outer = outer + 1
  }
  result
}

///|
fn Wheel::live_entry_count(self : Wheel, timer : InternalTimer) -> Int {
  let mut count = 0
  for bucket in self.buckets {
    for entry in bucket {
      if entry.timer_id == timer.id &&
        entry.generation == timer.generation {
        count = count + 1
      }
    }
  }
  count
}

///|
pub fn Wheel::validate(self : Wheel) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if !self.config.is_valid() {
    issues.push({
      code: "INVALID_CONFIG",
      timer_id: 0,
      message: "wheel geometry must use positive tick, levels and slots",
    })
  }
  for _, timer in self.timers {
    if timer.deadline < 0 {
      issues.push({
        code: "NEGATIVE_DEADLINE",
        timer_id: timer.id,
        message: "timer deadline must be non-negative",
      })
    }
    if timer.repeat != RepeatMode::Once && timer.period <= 0 {
      issues.push({
        code: "INVALID_PERIOD",
        timer_id: timer.id,
        message: "repeating timer period must be positive",
      })
    }
    if timer.state == TimerState::Pending {
      let entries = self.live_entry_count(timer)
      if entries != 1 {
        issues.push({
          code: "LIVE_ENTRY_COUNT",
          timer_id: timer.id,
          message: "pending timer must have exactly one live bucket entry",
        })
      }
    }
  }
  issues
}

///|
pub fn Wheel::compact(self : Wheel) -> MaintenanceReport {
  let pending : Array[InternalTimer] = []
  let remove_ids : Array[Int] = []
  for id, timer in self.timers {
    if timer.state == TimerState::Pending {
      pending.push(timer)
    } else {
      remove_ids.push(id)
    }
  }
  let mut old_entries = 0
  for bucket in self.buckets {
    old_entries = old_entries + bucket.length()
    bucket.clear()
  }
  for id in remove_ids {
    ignore(self.timers.remove(id))
  }
  for timer in pending {
    self.place(timer)
  }
  {
    removed_terminal_timers: remove_ids.length(),
    removed_stale_entries: old_entries - pending.length(),
    retained_pending_timers: pending.length(),
  }
}

///|
fn json_escape(value : String) -> String {
  let out = StringBuilder()
  for ch in value {
    match ch {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}

///|
fn repeat_name(value : RepeatMode) -> String {
  match value {
    RepeatMode::Once => "once"
    RepeatMode::FixedDelay => "fixed_delay"
    RepeatMode::FixedRate => "fixed_rate"
  }
}

///|
fn state_name(value : TimerState) -> String {
  match value {
    TimerState::Pending => "pending"
    TimerState::Cancelled => "cancelled"
    TimerState::Fired => "fired"
  }
}

///|
pub fn TimerInfo::to_json(self : TimerInfo) -> String {
  "{\"id\":\{self.id},\"deadline\":\{self.deadline},\"period\":\{self.period},\"repeat\":\"\{repeat_name(self.repeat)}\",\"payload\":\"\{json_escape(self.payload)}\",\"state\":\"\{state_name(self.state)}\",\"generation\":\{self.generation},\"occurrence\":\{self.occurrence}}"
}

///|
pub fn FiredTask::to_json(self : FiredTask) -> String {
  "{\"timer_id\":\{self.timer_id},\"scheduled_at\":\{self.scheduled_at},\"observed_at\":\{self.observed_at},\"lateness\":\{self.lateness},\"occurrence\":\{self.occurrence},\"payload\":\"\{json_escape(self.payload)}\"}"
}

///|
pub fn WheelStats::to_json(self : WheelStats) -> String {
  "{\"now\":\{self.now},\"pending\":\{self.pending},\"cancelled\":\{self.cancelled},\"fired_total\":\{self.fired_total},\"scheduled_total\":\{self.scheduled_total},\"cascades_total\":\{self.cascades_total},\"levels\":\{self.levels},\"slots_per_level\":\{self.slots_per_level}}"
}

///|
pub fn AdvanceReport::to_json(self : AdvanceReport) -> String {
  let out = StringBuilder()
  out.write_string(
    "{\"from_tick\":\{self.from_tick},\"to_tick\":\{self.to_tick},\"scanned_ticks\":\{self.scanned_ticks},\"cascades\":\{self.cascades},\"fired\":[",
  )
  for index, task in self.fired {
    if index > 0 {
      out.write_char(',')
    }
    out.write_string(task.to_json())
  }
  out.write_string("]}")
  out.to_string()
}
