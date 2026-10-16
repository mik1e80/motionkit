# 来源与第三方说明

项目自身实现、示例和测试采用 Apache-2.0，完整条款见 LICENSE。没有复制第三方机器人模型、控制器、轨迹文件或求解器源码；没有外部运行时包依赖。

| 项目 / 资料 | 许可与链接 | 使用范围 |
| --- | --- | --- |
| MoonBit core | Apache-2.0，[原许可](https://github.com/moonbitlang/core/blob/main/LICENSE)，个别文件另有声明，以原项目为准 | 工具链导入 math、debug 及基础集合；源码包不包含 core 实现文件 |
| Ruckig Community | MIT，[仓库](https://github.com/pantor/ruckig)、[许可](https://github.com/pantor/ruckig/blob/main/LICENSE) | 成熟需求、接口能力和范围参照；没有复制、移植或链接其源码及测试，不声称 Ruckig 兼容 |
| Embit | Apache-2.0，[仓库](https://github.com/toadium/embit)、[许可](https://github.com/toadium/embit/blob/main/LICENSE) | 阅读 Mooncakes `walkzzz/embit@0.1.2` 的 control.mbt、trajectory.mbt 作生态比较，没有引入其实现或机器人框架 |
| GitHub Actions checkout / setup-python | MIT，[checkout 许可](https://github.com/actions/checkout/blob/main/LICENSE)、[setup-python 许可](https://github.com/actions/setup-python/blob/main/LICENSE) | CI 引用，不复制工具实现 |

数值实现使用常加加速度积分、对称 S 曲线的代数关系和时间缩放链式法则；推导见 docs/ARCHITECTURE.md。不是新算法的原创性声明。测试数据由本项目构造，未收录第三方数据集。

发布验证沿用同一作者 CAD 项目已使用的“真实 ZIP + 本地 workspace 消费”验证方式，属于开发工具实践；本库运行时代码和运动学功能不依赖 CAD、DXFKIT 或 STLKIT。Python 脚本仅用标准库，不进入库的运行时。
