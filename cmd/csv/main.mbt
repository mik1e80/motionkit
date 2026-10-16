///|
fn main {
  let p = @motion.plan_scurve(0.0, 100.0, {
    velocity: 40.0,
    acceleration: 80.0,
    jerk: 320.0,
  }).unwrap()
  println(p.to_csv(intervals=200).unwrap())
}
