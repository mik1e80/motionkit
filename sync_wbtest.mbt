///|
test "synchronization stretches derivatives by time powers" {
  let limits : Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let short = plan_scurve(0.0, 1.0, limits).unwrap()
  let group = synchronize(
    [
      { start: 0.0, target: 1.0, limits, },
      { start: 10.0, target: -10.0, limits, },
      { start: 3.0, target: 3.0, limits, },
    ],
    minimum_duration=10.0,
  ).unwrap()
  near(group.duration(), 10.0)
  assert_eq(group.axis_count(), 3)
  let ratio = short.duration() / group.duration()
  let source = short.sample(0.25).unwrap()
  let synced = group.sample(0.25 / ratio).unwrap()[0]
  near(synced.position, source.position)
  near(synced.velocity, source.velocity * ratio)
  near(synced.acceleration, source.acceleration * ratio * ratio)
  near(synced.jerk, source.jerk * ratio * ratio * ratio)
  let finished = group.sample(10.0).unwrap()
  near(finished[0].position, 1.0)
  near(finished[1].position, -10.0)
  near(finished[2].position, 3.0)
}

///|
test "synchronization rejects invalid axes and handles all stationary" {
  let limits : Limits = { velocity: 1.0, acceleration: 1.0, jerk: 1.0, }
  assert_true(synchronize([]) is Err(_))
  assert_true(
    synchronize([{ start: 0.0, target: 1.0, limits, }], minimum_duration=-1.0)
    is Err(_),
  )
  let group = synchronize([{ start: 2.0, target: 2.0, limits, }]).unwrap()
  near(group.duration(), 0.0)
  near(group.sample(0.0).unwrap()[0].position, 2.0)
  assert_true(group.sample(-1.0) is Err(_))
}
