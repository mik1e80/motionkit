///|
pub(all) struct Sample {
  time : Double
  state : State
}

///|
/// Include both endpoints; 1..10000 equal time intervals, bounded allocation.
pub fn Profile::sample_grid(
  self : Profile,
  intervals : Int32,
) -> Result[Array[Sample], String] {
  if intervals < 1 || intervals > 10000 {
    return Err("Intervals must be within 1..10000")
  }
  if self.duration() == 0.0 {
    return Ok([{ time: 0.0, state: self.sample(0.0).unwrap(), }])
  }
  let out = []
  for i = 0; i <= intervals; i = i + 1 {
    let time = self.duration() * (i.to_double() / intervals.to_double())
    match self.sample(time) {
      Ok(state) => out.push({ time, state, })
      Err(e) => return Err(e)
    }
  }
  Ok(out)
}

///|
/// Numeric CSV; no file system or locale dependency. No caller-supplied labels.
pub fn Profile::to_csv(
  self : Profile,
  intervals~ : Int32 = 100,
) -> Result[String, String] {
  let samples = match self.sample_grid(intervals) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let out = StringBuilder()
  out.write_string("time,position,velocity,acceleration,jerk\n")
  for sample in samples {
    let s = sample.state
    out.write_string(
      "\{sample.time},\{s.position},\{s.velocity},\{s.acceleration},\{s.jerk}\n",
    )
  }
  Ok(out.to_string())
}
