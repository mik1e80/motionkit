///|
fn rejected(name : String, result : Result[@motion.Profile, String]) -> Unit {
  match result {
    Err(e) => println("\{name}: rejected: \{e}")
    Ok(_) => abort("Boundary example unexpectedly succeeded: \{name}")
  }
}

///|
fn main {
  let limits : @motion.Limits = { velocity: 2.0, acceleration: 3.0, jerk: 4.0, }
  rejected(
    "nonfinite input",
    @motion.plan_scurve(0.0, 1.0, { ..limits, jerk: 0.0 / 0.0, }),
  )
  rejected(
    "long cruise with unresolved short braking",
    @motion.plan_scurve(0.0, 100.0, {
      velocity: 1.0e-6,
      acceleration: 1.0e6,
      jerk: 1.0e6,
    }),
  )
  rejected(
    "large offset with small travel",
    @motion.plan_scurve(1.0e8, 1.0e8 + 0.001, limits),
  )
  let relative = @motion.plan_scurve(0.0, 0.001, limits).unwrap()
  if relative.sample(relative.duration()).unwrap().position != 0.001 {
    abort("Relative-coordinate control case failed")
  }
  println("Relative-coordinate control: accepted")
  let baseline = @motion.plan_trapezoid(0.0, 10.0, limits).unwrap()
  match baseline.bounds().jerk {
    Unbounded =>
      println(
        "Trapezoid baseline: jerk unbounded, cannot certify the supplied jerk limit",
      )
    Finite(_) => abort("Unexpected finite jerk claim")
  }
}
