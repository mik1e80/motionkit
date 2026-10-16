///|
pub(all) struct Limits {
  velocity : Double
  acceleration : Double
  jerk : Double
} derive(Debug)

///|
pub(all) struct State {
  position : Double
  velocity : Double
  acceleration : Double
  jerk : Double
} derive(Debug)

///|
pub(all) enum ProfileKind {
  Stationary
  Trapezoid
  SCurve
} derive(Debug)

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
fn valid_limit(x : Double) -> Bool {
  finite(x) && x >= 1.0e-6 && x <= 1.0e6
}

///|
fn validate_input(start : Double, target : Double, limits : Limits) -> Result[Unit, String] {
  if !finite(start) || !finite(target) || start.abs() > 1.0e9 || target.abs() > 1.0e9 {
    return Err("Positions must be finite and within +/-1e9")
  }
  if !valid_limit(limits.velocity) || !valid_limit(limits.acceleration) || !valid_limit(limits.jerk) {
    return Err("Velocity, acceleration and jerk limits must be within [1e-6,1e6]")
  }
  let distance = (target - start).abs()
  if distance != 0.0 && (distance < 1.0e-6 || distance > 1.0e6) {
    return Err("Nonzero travel must be within [1e-6,1e6]")
  }
  Ok(())
}
