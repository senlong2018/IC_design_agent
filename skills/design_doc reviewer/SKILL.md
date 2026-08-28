---
name: design_doc reviewer
description: 审查 DE 提供的设计方案，确认其内容是否包含以下规定的内容；
argument-hint: 确认设计方案的内容
---

# 设计文档审查资产清单

本阶段将已形成的 Specification、System Architecture、Microarchitecture 与 Golden Model 转换为可综合的数字硬件实现。输入资产定义“实现必须是什么”，输出资产证明“已经实现了什么、如何构建、如何验证、如何集成”。

## Canonical 输入资产

### 基础规格与约束

| 输入资产 | 含义与审查用途 |
|---|---|
| Memory / IO Library Package | 工艺库、SRAM 宏、IO 单元等可用硬宏的接口、时序、功耗与实例化规则；决定 RTL 是否可合法实例化特定宏。 |
| Interface / Address / Register Specification Package | 外部接口协议、地址空间、寄存器定义、字段读写属性和副作用。 |
| Clock & Reset Specification | 时钟频率、来源、相位关系、复位极性、同步/异步属性和释放顺序。 |
| Power Specification | 电源域、隔离、保留、掉电恢复和功耗状态要求。 |
| Interrupt / Error / Exception Specification | 中断源、错误码、上报路径、优先级、屏蔽和清除机制。 |
| DFT Specification | 扫描、测试模式、测试时钟、MBIST 与测试模式下功能限制。 |
| Debug / Security Specification | 调试可见性、访问权限、锁定策略和安全状态下的行为。 |
| Software Programming / HW-SW Interface Specification | 软件驱动的初始化、配置、轮询/中断与错误恢复流程。 |

### 系统架构

| 输入资产 | 含义与审查用途 |
|---|---|
| HW / SW Partition | 界定功能由硬件还是软件承担，避免重复或遗漏。 |
| Chip Block Diagram + Module Inventory / Responsibility | 芯片级连接关系、模块清单及各模块责任边界。 |
| Memory Architecture | 存储层级、容量、端口、仲裁、缓存一致性与访问属性。 |
| Interconnect Architecture + Interface / Bandwidth Table | 总线拓扑、协议转换、带宽、突发长度和背压能力。 |
| Address / Memory Mapping | 各寄存器、SRAM、外设和窗口的地址范围及属性。 |
| Clock / Power Domain Definition | 模块位于哪些时钟域和电源域，以及跨域边界。 |
| System Architecture Specification | 系统级功能、使用场景、性能目标、复位与异常恢复策略。 |
| Dataflow / Control-flow Package | 数据路径、控制路径。 |

### 微架构

| 输入资产 | 含义与审查用途 |
|---|---|
| Microarchitecture Specification | 模块内部结构、时序、状态机、资源共享和实现规则。 |
| Datapath + Numerical Rule Package | 数据位宽、算术精度、舍入、饱和、溢出及字节序规则。 |
| Control / FSM / Priority-Arbitration Rule Package | FSM 状态、仲裁优先级、公平性及冲突处理规则。 |
| Pipeline Definition + Timing Diagram | 各流水级功能、延迟、valid/ready 时序和旁路条件。 |
| Signal-level Interface Definition | 信号名称、方向、位宽、复位值、时序语义和组合/时序要求。 |
| Buffer / FIFO Specification | FIFO 深度、入出队规则、满空阈值、旁路和溢出/下溢行为。 |
| Register / Internal Control Map | 内部状态寄存器、控制寄存器、计数器和可观测性定义。 |
| Clock / Reset / CDC Rules | 微架构级时钟门控、复位覆盖、跨时钟同步、握手和数据稳定性规则。 |
| Error / Exception / Boundary Behavior | 非法输入、边界地址、超时、乱序返回、复位中事务等行为。 |

### 评估与 Golden Model

| 输入资产 | 含义与审查用途 |
|---|---|
| Performance / Resource Estimate | 面积、频率、功耗、吞吐和缓存深度等预算，用于约束实现取舍。 |
| Optional RTL Skeleton | 可选的模块层级、端口框架或编码骨架；只作为起点，不可替代规格。 |
| Algorithm / Functional Reference Model Package | 描述功能正确性的高层参考模型及其接口。 |
| Bit-true Model | 精确到 bit 的参考模型，用于验证位宽、截断、舍入与溢出行为。 |

### 静态检查、动态验证与变更

| 输入资产 | 含义与审查用途 |
|---|---|
| Lint Report | 现有代码的静态编码问题报告。 |
| CDC / RDC Report Package | 时钟域/复位域跨越检查报告及豁免。 |
| Low-power Static Check Report | UPF 与 RTL 一致性、隔离/保留/电源状态相关静态检查结果。 |
| X-propagation Report | 未初始化、非法状态或低功耗转换导致 X 扩散的分析结果。 |
| Structural Check Report | 模块连接、驱动、层级、时钟和结构类检查结果。 |
| Static Violation Database | 全部静态问题及状态、责任人、优先级、修复记录。 |
| Waiver List | 经正式评审允许保留的告警及其理由、范围、责任人和到期条件。 |
| Simulation Log + Waveform | 仿真命令、结果和关键波形，是动态行为正确性的直接证据。 |
| Scoreboard + Assertion Result | 数据比对和断言检查结果，证明功能及协议性质。 |
| Failure / Bug Database | 已发现问题、根因、影响、状态、修复版本和回归结果。 |
| Formal Proof Report | 对形式属性的证明结果、覆盖范围、假设和未证明项。 |
| Formal Counterexample Database | 形式验证失败时的反例轨迹，用于定位规格或 RTL 问题。 |
| Design Re-spin Change Request | 流片返修或重大设计变更请求，定义变更原因、影响和验证要求。 |


