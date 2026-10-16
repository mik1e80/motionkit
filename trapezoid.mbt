///|
/// Acceleration-bounded baseline. Jerk is unbounded at acceleration jumps.
pub fn plan_trapezoid(
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
  let acceleration = limits.acceleration
  let peak = limits.velocity.min((distance * acceleration).sqrt())
  let ramp = peak / acceleration
  let cruise = ((distance - peak * ramp) / peak).max(0.0)
  assemble(start, target, limits, Trapezoid, [
    (ramp, acceleration, 0.0),
    (cruise, 0.0, 0.0),
    (ramp, -acceleration, 0.0),
  ])
}
