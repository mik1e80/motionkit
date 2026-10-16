///|
test "grid includes endpoints rejects excessive allocation and handles zero travel" {
  let limits : Limits = { velocity: 2.0, acceleration: 3.0, jerk: 4.0, }
  let p = plan_scurve(4.0, 7.0, limits).unwrap()
  let grid = p.sample_grid(20).unwrap()
  assert_eq(grid.length(), 21)
  near(grid[0].time, 0.0)
  near(grid[20].time, p.duration())
  near(grid[20].state.position, 7.0)
  assert_true(p.sample_grid(0) is Err(_))
  assert_true(p.sample_grid(10001) is Err(_))
  assert_eq(
    plan_scurve(2.0, 2.0, limits).unwrap().sample_grid(10).unwrap().length(),
    1,
  )
}

///|
test "CSV export has one numeric row per sample and fixed schema" {
  let p = plan_scurve(0.0, 1.0, { velocity: 2.0, acceleration: 3.0, jerk: 4.0, }).unwrap()
  let csv = p.to_csv(intervals=2).unwrap()
  assert_true(csv.has_prefix("time,position,velocity,acceleration,jerk\n"))
  assert_eq(csv.split("\n").collect().length(), 5)
  assert_true(p.to_csv(intervals=10001) is Err(_))
}
