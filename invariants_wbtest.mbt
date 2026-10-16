///|
test "160 scaled directed profiles obey limits and integral displacement" {
  for i = 0; i < 160; i = i + 1 {
    let limits : Limits = {
      velocity: [0.05, 1.0, 5.0, 100.0][i % 4],
      acceleration: [0.1, 2.0, 20.0][i % 3],
      jerk: [0.2, 4.0, 100.0, 1000.0][i / 3 % 4],
    }
    let direction = if i % 2 == 0 { 1.0 } else { -1.0 }
    let start = (i - 80).to_double() * 100.0
    let target = start + direction * [0.001, 0.1, 1.0, 10.0, 1000.0][i % 5]
    let p = match plan_scurve(start, target, limits) {
      Ok(p) => p
      Err(e) => fail("Case \{i}: \{e}")
    }
    let grid = p.sample_grid(100).unwrap()
    let mut previous = start
    for sample in grid {
      let s = sample.state
      assert_true(
        finite(s.position) &&
        finite(s.velocity) &&
        finite(s.acceleration) &&
        finite(s.jerk),
      )
      assert_true(direction * (s.position - previous) >= -1.0e-8)
      assert_true(s.velocity.abs() <= limits.velocity * (1.0 + 1.0e-8))
      assert_true(s.acceleration.abs() <= limits.acceleration * (1.0 + 1.0e-8))
      assert_true(s.jerk.abs() <= limits.jerk * (1.0 + 1.0e-8))
      previous = s.position
    }
    // Simpson integration of the public quadratic velocity is exact per phase,
    // independent of the position polynomial used by Profile::sample.
    let times = p.phase_times()
    let mut displacement = 0.0
    for k = 0; k + 1 < times.length(); k = k + 1 {
      let t0 = times[k]
      let t1 = times[k + 1]
      let v0 = p.sample(t0).unwrap().velocity
      let vm = p.sample((t0 + t1) / 2.0).unwrap().velocity
      let v1 = p.sample(t1).unwrap().velocity
      displacement = displacement + (t1 - t0) * (v0 + 4.0 * vm + v1) / 6.0
    }
    near(
      displacement,
      target - start,
      tol=1.0e-8 * (target - start).abs().max(1.0),
    )
  }
}

///|
test "public derivatives agree with finite differences inside every phase" {
  let p = plan_scurve(-3.0, 17.0, {
    velocity: 4.0,
    acceleration: 2.0,
    jerk: 4.0,
  }).unwrap()
  let times = p.phase_times()
  for i = 0; i + 1 < times.length(); i = i + 1 {
    let t = (times[i] + times[i + 1]) / 2.0
    let h = 1.0e-4
    let minus = p.sample(t - h).unwrap()
    let center = p.sample(t).unwrap()
    let plus = p.sample(t + h).unwrap()
    near(
      (plus.position - minus.position) / (2.0 * h),
      center.velocity,
      tol=2.0e-8,
    )
    near(
      (plus.velocity - minus.velocity) / (2.0 * h),
      center.acceleration,
      tol=1.0e-8,
    )
    near(
      (plus.acceleration - minus.acceleration) / (2.0 * h),
      center.jerk,
      tol=1.0e-8,
    )
  }
}

///|
test "S curve phase joins are continuous through acceleration" {
  let p = plan_scurve(0.0, 20.0, {
    velocity: 4.0,
    acceleration: 2.0,
    jerk: 4.0,
  }).unwrap()
  for segment in p.segments {
    let end = advance(segment.state, segment.jerk, segment.duration)
    let joined = p.sample(segment.start_time + segment.duration).unwrap()
    near(end.position, joined.position)
    near(end.velocity, joined.velocity)
    near(end.acceleration, joined.acceleration)
  }
}

///|
test "numeric duration limits and defensive phase lists are enforced" {
  let limits : Limits = { velocity: 1.0e-6, acceleration: 1.0, jerk: 1.0, }
  assert_true(plan_scurve(0.0, 1.0e6, limits) is Err(_))
  assert_true(plan_trapezoid(0.0, 1.0e6, limits) is Err(_))
  let p = plan_scurve(0.0, 1.0, { ..limits, velocity: 1.0, }).unwrap()
  let times = p.phase_times()
  times[0] = 100.0
  near(p.phase_times()[0], 0.0)
}
