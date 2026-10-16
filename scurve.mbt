///|
/// Symmetric rest-to-rest S curve, at most seven constant-jerk phases.
pub fn plan_scurve(
  start : Double,
  target : Double,
  limits : Limits,
) -> Result[Profile, String] {
  match validate_input(start, target, limits) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let distance = (target - start).abs()
  if distance == 0.0 {
    return assemble(start, target, limits, Stationary, [])
  }
  let j = limits.jerk
  let a = limits.acceleration
  let v = limits.velocity
  let reaches_acceleration = v > a * (a / j)
  let mut tj = if reaches_acceleration { a / j } else { (v / j).sqrt() }
  let mut ta = if reaches_acceleration { (v / a - tj).max(0.0) } else { 0.0 }
  let at_velocity = v * (2.0 * tj + ta)
  let mut tv = 0.0
  if distance >= at_velocity {
    tv = (distance - at_velocity) / v
  } else if distance < 2.0 * j * tj * tj * tj {
    tj = @math.cbrt(distance / (2.0 * j))
    ta = 0.0
  } else {
    // Stable positive root of D/A=(tj+ta)*(2*tj+ta).
    let peak_a = j * tj
    let q = distance / peak_a
    ta = 2.0 * (q - 2.0 * tj * tj) / ((tj * tj + 4.0 * q).sqrt() + 3.0 * tj)
    ta = ta.max(0.0)
  }
  let peak_a = j * tj
  assemble(start, target, limits, SCurve, [
    (tj, 0.0, j),
    (ta, peak_a, 0.0),
    (tj, peak_a, -j),
    (tv, 0.0, 0.0),
    (tj, 0.0, -j),
    (ta, -peak_a, 0.0),
    (tj, -peak_a, j),
  ])
}
