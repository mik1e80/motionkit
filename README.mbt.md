# motionkit

静止到静止的运动轨迹。当前功能与边界见 README.md；源码尚未发布到 Mooncakes。

公开接口示例随测试执行：

```mbt check
///|
test "S curve slide has analytic duration and endpoint" {
  let limits : @motion.Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let p = @motion.plan_scurve(0.0, 20.0, limits).unwrap()
  assert_true((p.duration() - 7.5).abs() < 1.0e-8)
  assert_true((p.sample(3.75).unwrap().position - 10.0).abs() < 1.0e-8)
  assert_eq(p.sample(7.5).unwrap().velocity, 0.0)
}
```

```mbt check
///|
test "multiple axes share a finish time" {
  let limits : @motion.Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let plan = @motion.synchronize([
    { start: 0.0, target: 20.0, limits, },
    { start: 0.0, target: -1.0, limits, },
  ]).unwrap()
  let done = plan.sample(plan.duration()).unwrap()
  assert_eq(done[0].position, 20.0)
  assert_eq(done[1].position, -1.0)
}
```
