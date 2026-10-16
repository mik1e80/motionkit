///|
/// Unbounded denotes acceleration jumps, not a zero or unchecked jerk bound.
pub(all) enum JerkBound {
  Finite(Double)
  Unbounded
} derive(Debug)

///|
pub extend JerkBound with @debug.Debug::{to_repr}

///|
pub(all) struct KinematicBounds {
  velocity : Double
  acceleration : Double
  jerk : JerkBound
} derive(Debug)

///|
pub extend KinematicBounds with @debug.Debug::{to_repr}

///|
/// Analytic extrema of this constructed profile, independent of grid density.
/// Trapezoid jerk is unbounded at acceleration jumps even if samples show zero.
pub fn Profile::bounds(self : Profile) -> KinematicBounds {
  let mut velocity = 0.0
  let mut acceleration = 0.0
  let mut jerk = 0.0
  for segment in self.segments {
    let end = advance(segment.state, segment.jerk, segment.duration)
    velocity = velocity
      .max(segment.state.velocity.abs())
      .max(end.velocity.abs())
    acceleration = acceleration
      .max(segment.state.acceleration.abs())
      .max(end.acceleration.abs())
    jerk = jerk.max(segment.jerk.abs())
  }
  {
    velocity,
    acceleration,
    jerk: if self.kind is Trapezoid {
      Unbounded
    } else {
      Finite(jerk)
    },
  }
}

///|
pub fn SyncPlan::bounds(self : SyncPlan) -> Array[KinematicBounds] {
  self.profiles.map(p => {
    let bounds = p.bounds()
    let rate = if self.total > 0.0 { p.duration() / self.total } else { 0.0 }
    {
      velocity: bounds.velocity * rate,
      acceleration: bounds.acceleration * rate * rate,
      jerk: match bounds.jerk {
        Finite(j) => Finite(j * rate * rate * rate)
        Unbounded => Unbounded
      },
    }
  })
}
