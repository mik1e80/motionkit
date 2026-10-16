///|
priv struct Segment {
  start_time : Double
  duration : Double
  state : State
  jerk : Double
}

///|
pub struct Profile {
  priv start : Double
  priv target : Double
  priv direction : Double
  priv segments : Array[Segment]
  priv total : Double
  priv kind : ProfileKind
  priv limits : Limits
}

///|
fn advance(s : State, jerk : Double, t : Double) -> State {
  {
    position: s.position +
    t * (s.velocity + t * (s.acceleration / 2.0 + t * jerk / 6.0)),
    velocity: s.velocity + t * (s.acceleration + t * jerk / 2.0),
    acceleration: s.acceleration + t * jerk,
    jerk,
  }
}

///|
pub fn Profile::duration(self : Profile) -> Double {
  self.total
}

///|
pub fn Profile::kind(self : Profile) -> ProfileKind {
  self.kind
}

///|
pub fn Profile::start(self : Profile) -> Double {
  self.start
}

///|
pub fn Profile::target(self : Profile) -> Double {
  self.target
}

///|
pub fn Profile::limits(self : Profile) -> Limits {
  self.limits
}

///|
pub fn Profile::phase_times(self : Profile) -> Array[Double] {
  let times = self.segments.map(s => s.start_time)
  times.push(self.total)
  times
}

///|
/// Piecewise right-continuous acceleration/jerk. Times after completion hold target.
pub fn Profile::sample(self : Profile, time : Double) -> Result[State, String] {
  if !finite(time) || time < 0.0 {
    return Err("Time must be finite and nonnegative")
  }
  if time >= self.total {
    return Ok({
      position: self.target,
      velocity: 0.0,
      acceleration: 0.0,
      jerk: 0.0,
    })
  }
  for segment in self.segments {
    if time < segment.start_time + segment.duration {
      let s = advance(segment.state, segment.jerk, time - segment.start_time)
      return Ok({
        position: self.start + self.direction * s.position,
        velocity: self.direction * s.velocity,
        acceleration: self.direction * s.acceleration,
        jerk: self.direction * s.jerk,
      })
    }
  }
  Err("Time could not be resolved at phase boundary")
}

///|
fn assemble(
  start : Double,
  target : Double,
  limits : Limits,
  kind : ProfileKind,
  phases : Array[(Double, Double, Double)],
) -> Result[Profile, String] {
  let segments = []
  let mut state : State = {
    position: 0.0,
    velocity: 0.0,
    acceleration: 0.0,
    jerk: 0.0,
  }
  let mut total = 0.0
  for (duration, acceleration, jerk) in phases {
    if !finite(duration) || duration < 0.0 || duration > 1.0e9 {
      return Err("Phase duration outside numeric range")
    }
    if duration == 0.0 {
      continue
    }
    if duration < 1.0e-12 || total + duration == total {
      return Err("Phase too short to represent reliably")
    }
    state = { ..state, acceleration, jerk, }
    segments.push({ start_time: total, duration, state, jerk, })
    let end = advance(state, jerk, duration)
    for value in [state, end] {
      if !finite(value.position) ||
        !finite(value.velocity) ||
        !finite(value.acceleration) ||
        value.velocity < -1.0e-8 ||
        value.velocity > limits.velocity * (1.0 + 1.0e-9) ||
        value.acceleration.abs() > limits.acceleration * (1.0 + 1.0e-9) {
        return Err("Computed phase exceeds kinematic limits or numeric range")
      }
    }
    if kind is SCurve && jerk.abs() > limits.jerk * (1.0 + 1.0e-9) {
      return Err("Computed jerk exceeds limit")
    }
    state = end
    total = total + duration
  }
  if !finite(total) || total > 1.0e9 {
    return Err("Trajectory duration exceeds 1e9")
  }
  let distance = (target - start).abs()
  if (state.position - distance).abs() > 1.0e-9 * distance.max(1.0) ||
    state.velocity.abs() > 1.0e-9 * limits.velocity.max(1.0) ||
    (
      kind is SCurve &&
      state.acceleration.abs() > 1.0e-9 * limits.acceleration.max(1.0)
    ) {
    return Err("Integrated trajectory does not reach rest target accurately")
  }
  Ok({
    start,
    target,
    direction: if target >= start {
      1.0
    } else {
      -1.0
    },
    segments,
    total,
    kind,
    limits,
  })
}
