///|
test "S curve analytic jerk acceleration and cruise branches" {
  let limits : Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let p = plan_scurve(0.0, 20.0, limits).unwrap()
  near(p.duration(), 7.5)
  near(p.sample(0.5).unwrap().acceleration, 2.0)
  near(p.sample(2.5).unwrap().velocity, 4.0)
  near(p.sample(3.75).unwrap().position, 10.0)
  let short = plan_scurve(0.0, 1.0, {
    velocity: 10.0,
    acceleration: 10.0,
    jerk: 4.0,
  }).unwrap()
  near(short.duration(), 2.0)
  near(short.sample(1.0).unwrap().position, 0.5)
  let middle = plan_scurve(0.0, 2.0, limits).unwrap()
  near(middle.duration(), 0.5 + 17.0.sqrt() / 2.0)
}

///|
test "velocity capped jerk triangular and stationary cases" {
  let limits : Limits = { velocity: 1.0, acceleration: 100.0, jerk: 1.0, }
  let p = plan_scurve(10.0, 0.0, limits).unwrap()
  near(p.duration(), 12.0)
  near(p.sample(1.0).unwrap().velocity, -0.5)
  let stationary = plan_scurve(3.0, 3.0, limits).unwrap()
  assert_true(stationary.kind() is Stationary)
  near(stationary.duration(), 0.0)
  near(stationary.sample(0.0).unwrap().position, 3.0)
}
