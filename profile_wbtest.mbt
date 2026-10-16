///|
test "constant jerk integrates the cubic exactly" {
  let s : State = {
    position: 1.0,
    velocity: 2.0,
    acceleration: 3.0,
    jerk: 0.0,
  }
  let out = advance(s, 6.0, 2.0)
  assert_eq(out.position, 19.0)
  assert_eq(out.velocity, 20.0)
  assert_eq(out.acceleration, 15.0)
}
