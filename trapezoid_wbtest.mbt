///|
fn near(
  actual : Double,
  expected : Double,
  tol~ : Double = 1.0e-8,
) -> Unit raise {
  assert_true((actual - expected).abs() <= tol)
}

///|
test "trapezoid analytic cruise and triangular branches" {
  let limits : Limits = { velocity: 2.0, acceleration: 1.0, jerk: 4.0, }
  let cruise = plan_trapezoid(0.0, 10.0, limits).unwrap()
  near(cruise.duration(), 7.0)
  near(cruise.sample(2.0).unwrap().position, 2.0)
  near(cruise.sample(3.0).unwrap().velocity, 2.0)
  let triangle = plan_trapezoid(0.0, 1.0, limits).unwrap()
  near(triangle.duration(), 2.0)
  near(triangle.sample(1.0).unwrap().position, 0.5)
}

///|
test "negative travel and completed holds preserve endpoints" {
  let p = plan_trapezoid(5.0, -5.0, {
    velocity: 2.0,
    acceleration: 1.0,
    jerk: 1.0,
  }).unwrap()
  near(p.sample(0.0).unwrap().position, 5.0)
  assert_true(p.sample(1.0).unwrap().velocity < 0.0)
  near(p.sample(100.0).unwrap().position, -5.0)
  assert_true(p.sample(-1.0) is Err(_))
  assert_true(p.sample(1.0 / 0.0) is Err(_))
}
