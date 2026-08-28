---
name: design_output reviewer
description: 审查此阶段是否有要求的输出
argument-hint: 确认输出内容完整
---

## Canonical 输出资产

| 输出资产 | 含义与用途 | 去向 |
|---|---|---|
| RTL Source Package（Source Tree / Top / Subsystem） | 可综合 Verilog/SystemVerilog 源码、目录结构、顶层和子系统层级。 | — |
| Filelist / Parameters / Macros / Build Config | 编译顺序、顶层、参数、宏、库路径及构建命令配置。 | — |
| Wrapper / CSR（ Control and Status Registers） RTL | 顶层封装、总线适配、寄存器地址译码及 CSR 读写逻辑。 | — |
| SVA / Assertion Set | 协议、状态机、安全性和关键功能性质的断言集合。 | — |
| UPF | 电源意图：电源域、开关、隔离、保留与电平转换定义。 | — |
| Initial SDC | 初版时序约束：时钟、IO delay、generated clock、false path、multicycle path 等。 | — |
| Register Description / CSR Schema | 面向 RTL、验证与软件的一致寄存器描述，可生成头文件和文档。 | — |

