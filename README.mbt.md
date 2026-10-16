# motionkit

静止到静止的运动轨迹。当前功能与边界见 README.md；源码尚未发布到 Mooncakes。

仅支持初末速度、加速度为零的离线点到点轨迹，不是任意状态或实机控制器。`plan_scurve` 限制 jerk；`plan_trapezoid` 的加速度会跳变，不能满足有限 jerk 上限。不要从它在阶段内部采样的 jerk=0 推断整体 jerk 有界。

`Profile::bounds()` 返回解析速度 / 加速度峰值及 `JerkBound`：`Finite(value)` 表示有限峰值，`Unbounded` 明确表示存在加速度跳变。`SyncPlan::bounds()` 返回缩放后的逐轴峰值，不是简单复制用户输入上限。

位置绝对值最多 1e9，非零位移 1e-6..1e6，运动上限 1e-6..1e6；还要求坐标精度满足行程需求、累计时间可准确表示各阶段，故范围内的极端组合仍可能返回错误。完整条件及可运行反例见 [GitHub 边界案例](https://github.com/mik1e80/motionkit/blob/main/docs/FAILURE_CASES.md)。

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
test "trapezoid cannot claim a finite jerk bound" {
  let limits : @motion.Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0, }
  let baseline = @motion.plan_trapezoid(0.0, 20.0, limits).unwrap()
  assert_true(baseline.bounds().jerk is Unbounded)
  let smooth = @motion.plan_scurve(0.0, 20.0, limits).unwrap()
  assert_true(smooth.bounds().jerk is Finite(4.0))
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
