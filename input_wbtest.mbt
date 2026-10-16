///|
test "input boundaries reject nonfinite or unsupported scales" {
  let limits : Limits = { velocity: 2.0, acceleration: 3.0, jerk: 4.0 }
  assert_true(validate_input(0.0, 1.0, limits) is Ok(_))
  assert_true(validate_input(3.0, 3.0, limits) is Ok(_))
  assert_true(validate_input(0.0 / 0.0, 1.0, limits) is Err(_))
  assert_true(validate_input(0.0, 1.0e7, limits) is Err(_))
  assert_true(validate_input(0.0, 1.0e-8, limits) is Err(_))
  assert_true(validate_input(0.0, 1.0, { ..limits, velocity: -1.0 }) is Err(_))
}
