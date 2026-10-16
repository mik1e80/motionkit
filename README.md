# motionkit

纯 MoonBit 静止到静止运动轨迹库。输入起终位置及速度、加速度、加加速度上限，计算分段轨迹，按时间查询位置、速度、加速度和 jerk。

只处理起终点速度和加速度为零的离线点到点轨迹。不是 Ruckig 的移植，不提供任意初末状态、碰撞规避、在线重规划、机床实时控制或完整 CNC 功能。

源码版本 0.1.0，[GitHub 仓库](https://github.com/mik1e80/motionkit)，尚未发布 Mooncakes 或提交参赛报名。核心仅使用 MoonBit core。需要 moonc 0.10.15 或更新版本。

## 解决的问题

滑台或机器人仿真需要从当前位置平滑移动到目标位置。仅对位置做插值，不能自动说明速度、加速度和 jerk 是否超限。motionkit 根据上限构造轨迹，并输出时间和运动学状态，适合离线规划、参数试算、教学及控制软件的上游计算。

与 DXFKIT 的文件读取、STLKIT 的网格处理和 CAD 草图几何求解不同，本库处理的是**位置随时间的变化**，不依赖这三个项目的运行时代码。

## 已实现范围

| 能力 | 接口与边界 |
| --- | --- |
| S 曲线 | `plan_scurve()`，对称、至多七个常 jerk 阶段；支持未达到加速度上限、无匀速和有匀速分支 |
| 梯形基线 | `plan_trapezoid()`，含三角速度退化情况；只限制速度和加速度，阶段交界的 jerk 不受限 |
| 任意时刻查询 | `Profile::sample()`；负时间和非有限时间报错，结束之后保持终点且导数为零 |
| 多轴同步 | `synchronize()`；拉长较短 S 曲线，使各轴同一时刻结束；可指定最短总时长 |
| 采样与导出 | `sample_grid()` 包含起终点；`to_csv()` 导出固定数值列，便于绘图或外部复核 |
| 反向及零位移 | 反向运动保持带符号导数；零位移轨迹保持静止 |

S 曲线的位置、速度、加速度连续；jerk 为分段常数，阶段交界可跳变。阶段交界返回右侧值，最终时刻返回静止状态。这里的“平滑”不表示 jerk 连续。

## 使用与复现

获取源码后在项目根目录执行：

```sh
git clone https://github.com/mik1e80/motionkit.git
cd motionkit
moon test
moon run cmd/demo
moon run cmd/demo --target js
moon run cmd/csv > trajectory.csv
```

自建滑台案例使用毫米和秒：移动 100mm，上限 40mm/s、80mm/s²、320mm/s³。S 曲线时长应为 3.25s，梯形基线为 3s。三轴示例另验证反向移动和静止轴在同一结束时刻达到目标。它们是可解析核对的仿真案例，不是实机试验记录。

其他 MoonBit 项目可在 `moon.pkg` 中导入 `"mik1e80/motionkit" @motion`。发布前在共同父目录创建 `moon.work`，例如 `members = ["motionkit", "my_app"]`，在消费方 `moon.mod` 声明 `import { "mik1e80/motionkit@0.1.0" }`；workspace 使用本地源码，不依赖 Mooncakes 中已经存在该版本。

公开接口示例随 [README.mbt.md](README.mbt.md) 的测试执行。完整技术解释见 [ARCHITECTURE](docs/ARCHITECTURE.md)。

## 数值和资源边界

- 所有输入必须有限；位置绝对值不超过 `1e9`，非零实际位移在 `[1e-6,1e6]`。
- 三项运动上限均在 `[1e-6,1e6]`。单位由调用方统一选择，时间单位与运动上限必须一致；不会自动换算毫米或角度。
- 总时长不超过 `1e9`，非零阶段时长至少 `1e-12`，且累计时间可表示；不满足时返回错误。上述输入范围内的极端组合仍可能被拒绝。
- 构造后对积分终点、阶段端点速度和加速度进行数值复核；使用 Double 及相对 / 绝对余量，不是精确算术证明。
- 世界位置由起点加相对位移构成，大偏移下的小位移受浮点分辨率影响。
- 多轴为 1..32 轴，网格采样为 1..10000 个时间区间；零位移网格只返回一条样本。
- 多轴只同步结束时间，各轴独立放慢，**不保证笛卡尔直线轨迹**、相同阶段时刻或整体时间最优。
- 不支持非零初末速度 / 加速度、路点串接、转角前瞻、碰撞、动力学、硬件接口或硬实时保证。结果不作为设备安全或加工认证。

## 验证

```sh
moon fmt --check
moon check --target all --deny-warn
moon build
moon test --target wasm
moon test --target wasm-gc
moon test --target js
moon test --target native
python scripts/check_release.py
```

常规测试不需要 Python。发布检查脚本需要 Python 3.10+ 标准库：检查真正的发布 ZIP 和完整许可，解包后由独立消费方在四个后端调用公开接口，再运行实际 CSV 示例、核对列、样本数、有限性、上限及解析终点。它只执行 `moon package`，不发布到注册表。

测试包括各时长分支的解析结果、160 组参数 / 方向构型、逐段 Simpson 速度积分与总位移对照、相位内部中心差分、加速度连续性，以及同步导数的时间幂缩放。测试集合通过不代表任意数值输入或硬件都可靠。

## 同类项目与差异

2026-10-16 使用 Mooncakes 搜索 ruckig、trapezoidal、trajectory、motion profile、jerk，并读取 `walkzzz/embit@0.1.2` 的轨迹源码。检索不是生态穷尽证明。

| 项目 | 已核对能力 | 本项目的范围 |
| --- | --- | --- |
| [Ruckig](https://github.com/pantor/ruckig) | 成熟的 jerk 受限轨迹生成，支持任意初末状态和更多功能 | 需求参照；本库只提供静止到静止的对称分段曲线，不声称移植、功能等价或全局时间最优 |
| [walkzzz/embit](https://github.com/toadium/embit) 0.1.2 | `embit-control` 已有线性、三次和五次位置轨迹，约束结构含速度、加速度和采样间隔 | 存在运动规划交集；本库单独提供 jerk 上限、分段相位和位置 / 速度 / 加速度 / jerk 查询 |
| CAD / DXF / STL 项目 | 草图关系或模型文件与几何 | 本库按时间计算运动，不解析这些文件，也不是从它们拆出的模块 |

本项目独立按运动学公式实现，采用 [Apache-2.0](LICENSE)。来源、参考许可证与范围见 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)。[验收对照](docs/ACCEPTANCE.md) 明确远端公开、报名、注册表发布等尚未完成事项，不将源码完成等同于已经通过验收。
