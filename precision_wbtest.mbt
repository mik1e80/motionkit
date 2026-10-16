///|
test "long cruise must not hide unresolved microsecond braking phases" {
  let limits : Limits = { velocity: 1.0e-6, acceleration: 1.0e6, jerk: 1.0e6, }
  assert_true(plan_scurve(0.0, 100.0, limits) is Err(_))
}

///|
test "large world offset cannot pretend to resolve small travel" {
  let limits : Limits = { velocity: 2.0, acceleration: 3.0, jerk: 4.0, }
  assert_true(plan_scurve(1.0e8, 1.0e8 + 0.001, limits) is Err(_))
  assert_true(plan_trapezoid(1.0e8, 1.0e8 + 0.001, limits) is Err(_))
  assert_true(plan_scurve(0.0, 0.001, limits) is Ok(_))
  assert_true(plan_scurve(1.0e9, 1.0e9, limits) is Ok(_))
}

///|
test "nonfinite limits and time fail across public planning and synchronization" {
  let limits : Limits = { velocity: 2.0, acceleration: 3.0, jerk: 4.0, }
  for bad in [0.0 / 0.0, 1.0 / 0.0, -1.0 / 0.0] {
    for
      invalid in [
        { ..limits, velocity: bad, },
        { ..limits, acceleration: bad, },
        { ..limits, jerk: bad, },
      ] {
      assert_true(plan_scurve(0.0, 1.0, invalid) is Err(_))
      assert_true(plan_trapezoid(0.0, 1.0, invalid) is Err(_))
      assert_true(
        synchronize([{ start: 0.0, target: 1.0, limits: invalid, }]) is Err(_),
      )
    }
    assert_true(plan_scurve(bad, 1.0, limits) is Err(_))
    assert_true(plan_trapezoid(0.0, bad, limits) is Err(_))
    let p = plan_scurve(0.0, 1.0, limits).unwrap()
    assert_true(p.sample(bad) is Err(_))
    let sync = synchronize([{ start: 0.0, target: 1.0, limits, }]).unwrap()
    assert_true(sync.sample(bad) is Err(_))
    assert_true(
      synchronize([{ start: 0.0, target: 1.0, limits, }], minimum_duration=bad)
      is Err(_),
    )
  }
}
