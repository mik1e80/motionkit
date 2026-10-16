///|
fn require_near(value : Double, expected : Double) -> Unit {
  if (value - expected).abs() > 1.0e-7 {
    abort("Unexpected analytic result")
  }
}

///|
fn main {
  // Units here are millimeters and seconds, selected by this example.
  let limits : @motion.Limits = {
    velocity: 40.0,
    acceleration: 80.0,
    jerk: 320.0,
  }
  let profile = @motion.plan_scurve(0.0, 100.0, limits).unwrap()
  let baseline = @motion.plan_trapezoid(0.0, 100.0, limits).unwrap()
  require_near(profile.sample(profile.duration()).unwrap().position, 100.0)
  for sample in profile.sample_grid(200).unwrap() {
    let s = sample.state
    if s.velocity.abs() > 40.000001 ||
      s.acceleration.abs() > 80.000001 ||
      s.jerk.abs() > 320.000001 {
      abort("Sample exceeds motion limits")
    }
  }
  println(
    "100mm slide: S curve duration=\{profile.duration()}s; trapezoid=\{baseline.duration()}s",
  )
  println("S curve phases: \{profile.phase_times().length() - 1}")
  let group = @motion.synchronize([
    { start: 0.0, target: 100.0, limits, },
    { start: 20.0, target: -5.0, limits, },
    { start: 3.0, target: 3.0, limits, },
  ]).unwrap()
  let finish = group.sample(group.duration()).unwrap()
  require_near(finish[0].position, 100.0)
  require_near(finish[1].position, -5.0)
  require_near(finish[2].position, 3.0)
  println(
    "Three axes finish together in \{group.duration()}s; targets verified",
  )
  if @motion.plan_scurve(0.0, 1.0, { ..limits, jerk: 0.0, }) is Ok(_) {
    abort("Invalid jerk limit was accepted")
  }
  println("Invalid limit rejected; offline kinematics only, no machine control")
}
