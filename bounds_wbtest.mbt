///|
test "trapezoid cannot present its zero sampled jerk as a finite bound" {
  let limits : Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let p = plan_trapezoid(0.0, 20.0, limits).unwrap()
  assert_eq(p.sample(0.1).unwrap().jerk, 0.0)
  assert_true(p.bounds().jerk is Unbounded)
  near(p.bounds().velocity, 4.0)
  near(p.bounds().acceleration, 2.0)
}

///|
test "S curve analytic peaks and stationary bounds describe actual coverage" {
  let limits : Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let p = plan_scurve(0.0, 20.0, limits).unwrap()
  let bounds = p.bounds()
  near(bounds.velocity, 4.0)
  near(bounds.acceleration, 2.0)
  assert_true(bounds.jerk is Finite(4.0))
  let short = plan_scurve(0.0, 0.001, limits).unwrap().bounds()
  assert_true(short.velocity < limits.velocity)
  assert_true(short.acceleration < limits.acceleration)
  let stationary = plan_scurve(3.0, 3.0, limits).unwrap().bounds()
  assert_eq(stationary.velocity, 0.0)
  assert_eq(stationary.acceleration, 0.0)
  assert_true(stationary.jerk is Finite(0.0))
}

///|
test "synchronized bounds scale derivatives rather than copying limits" {
  let limits : Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let p = plan_scurve(0.0, 20.0, limits).unwrap()
  let group = synchronize(
    [
      { start: 0.0, target: 20.0, limits, },
      { start: 1.0, target: 1.0, limits, },
    ],
    minimum_duration=15.0,
  ).unwrap()
  let ratio = p.duration() / group.duration()
  let bounds = group.bounds()
  near(bounds[0].velocity, 4.0 * ratio)
  near(bounds[0].acceleration, 2.0 * ratio * ratio)
  match bounds[0].jerk {
    Finite(j) => near(j, 4.0 * ratio * ratio * ratio)
    Unbounded => fail("S curve lost finite jerk coverage")
  }
  assert_true(bounds[1].jerk is Finite(0.0))
}
