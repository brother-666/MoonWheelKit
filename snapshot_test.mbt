///|
fn snapshot_report(
  result : @moonwheelkit.AdvanceResult,
) -> @moonwheelkit.AdvanceReport {
  match result {
    @moonwheelkit.AdvanceResult::Advanced(report) => report
    @moonwheelkit.AdvanceResult::Rejected(_) => {
      from_tick: -1,
      to_tick: -1,
      scanned_ticks: -1,
      cascades: -1,
      fired: [],
    }
  }
}

///|
test "snapshot restore preserves future firing order" {
  let original = @moonwheelkit.Wheel::new()
  ignore(original.schedule(@moonwheelkit.TimerSpec::once(10, "later")))
  ignore(original.schedule(@moonwheelkit.TimerSpec::once(6, "sooner")))
  ignore(original.advance_to(3))
  let restored = match @moonwheelkit.Wheel::restore(original.snapshot()) {
    Some(wheel) => wheel
    None => fail("valid snapshot should restore")
  }
  let expected = snapshot_report(original.advance_to(10)).fired
  let actual = snapshot_report(restored.advance_to(10)).fired
  assert_true(actual == expected)
  assert_true(restored.stats() == original.stats())
}

///|
test "snapshot restore preserves periodic occurrence counter" {
  let original = @moonwheelkit.Wheel::new()
  ignore(
    original.schedule(@moonwheelkit.TimerSpec::fixed_rate(1, 2, "pulse")),
  )
  ignore(original.advance_to(3))
  let restored = match @moonwheelkit.Wheel::restore(original.snapshot()) {
    Some(wheel) => wheel
    None => fail("valid periodic snapshot should restore")
  }
  let fired = snapshot_report(restored.advance_to(5)).fired
  assert_eq(fired.length(), 1)
  assert_eq(fired[0].occurrence, 3)
}

///|
test "snapshot JSON includes geometry and payload" {
  let wheel = @moonwheelkit.Wheel::new()
  ignore(wheel.schedule(@moonwheelkit.TimerSpec::once(4, "cache-expiry")))
  let json = wheel.snapshot().to_json()
  assert_true(json.contains("\"slots_per_level\":64"))
  assert_true(json.contains("\"payload\":\"cache-expiry\""))
}
