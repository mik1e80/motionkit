///|
pub(all) struct AxisMove {
  start : Double
  target : Double
  limits : Limits
}

///|
pub struct SyncPlan {
  priv profiles : Array[Profile]
  priv total : Double
}

///|
pub fn SyncPlan::duration(self : SyncPlan) -> Double {
  self.total
}

///|
pub fn SyncPlan::axis_count(self : SyncPlan) -> Int32 {
  self.profiles.length()
}

///|
/// Synchronize finish times by slowing shorter independent S curves.
/// This is not straight-line path synchronization or collision checking.
pub fn synchronize(
  axes : Array[AxisMove],
  minimum_duration~ : Double = 0.0,
) -> Result[SyncPlan, String] {
  if axes.length() == 0 || axes.length() > 32 {
    return Err("Expected 1..32 axes")
  }
  if !finite(minimum_duration) ||
    minimum_duration < 0.0 ||
    minimum_duration > 1.0e9 {
    return Err("Minimum duration must be finite within [0,1e9]")
  }
  let profiles = []
  let mut total = minimum_duration
  for i, axis in axes {
    match plan_scurve(axis.start, axis.target, axis.limits) {
      Ok(p) => {
        total = total.max(p.duration())
        profiles.push(p)
      }
      Err(e) => return Err("Axis \{i}: \{e}")
    }
  }
  Ok({ profiles, total, })
}

///|
pub fn SyncPlan::sample(
  self : SyncPlan,
  time : Double,
) -> Result[Array[State], String] {
  if !finite(time) || time < 0.0 {
    return Err("Time must be finite and nonnegative")
  }
  let out = []
  for p in self.profiles {
    let rate = if self.total > 0.0 { p.duration() / self.total } else { 0.0 }
    let local_time = if time >= self.total { p.duration() } else { time * rate }
    match p.sample(local_time) {
      Err(e) => return Err(e)
      Ok(s) =>
        out.push({
          position: s.position,
          velocity: s.velocity * rate,
          acceleration: s.acceleration * rate * rate,
          jerk: s.jerk * rate * rate * rate,
        })
    }
  }
  Ok(out)
}
