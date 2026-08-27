---
name: design_doc reviewer
description: 审查DE提供的设计方案.md，要求设计方案必须包含如下内容；
argument-hint: 
---


| 输入项 | 含义 |
|---|---|
| **Functional Specification** | 功能规格。定义芯片或模块“要实现什么功能”； |
| **Interface / Address / Register Specification Package** | 接口、地址、寄存器规格包，模块端口列表； |
| **Clock & Reset Specification** | 时钟与复位规格，定义时钟源和复位源； |
| **Power Specification** | 电源规格（如果有）。定义电源域、是否有低功耗模式、Clock Gating、及上下电行为。 |
| **Interrupt / Error / Exception Specification** | 中断：定义触发条件、优先级、屏蔽方式、状态记录、清除方式；错误/异常：发生后的处理行为。 |
| **Debug / Security Specification** | 调试与安全规格。定义 Debug 访问、Trace、诊断能力、权限控制、安全状态、访问保护及非法访问处理规则。 |
| **Boundary / Corner Behavior Definition** | 边界和特殊场景行为定义。例如满/空、溢出、非法输入、并发事件、极限值、Reset 过程中访问等特殊情况。 |
| **模块上下游** | 说明模块的上下游。 |
| **HW / SW Partition** | 软硬件划分。明确哪些功能由 RTL 硬件实现，哪些功能由 Firmware/Software 实现，以及软硬件之间的控制边界。 |
| **Dataflow / Control-flow Package** | 数据流/控制流定义（如果有）。描述业务数据如何在模块之间流动，以及命令、状态、握手、调度等控制信息如何传播。 |
| **Memory Architecture** | 存储架构（如果有）。定义 SRAM、ROM、Cache、Buffer 等存储资源如何组织，包括容量、端口、带宽、访问方式、共享关系等。 |
| **Interconnect Architecture + Interface / Bandwidth Table** | 互联架构及接口/带宽表。定义模块之间采用 AXI、AHB、APB、NoC、Stream 等何种互联，以及位宽、频率、带宽、吞吐率等要求。 |
| **Address / Memory Mapping** | 地址/内存映射。定义寄存器、Memory、外设等在系统地址空间中的地址范围和映射关系。 |
| **Clock / Power Domain Definition** | 时钟域/电源域划分。规定每个模块属于哪个 Clock Domain、Power Domain，以及哪些接口存在 CDC、RDC 或跨电源域问题。 |
| **Resource Budget** | 资源预算。规定某模块允许使用的 SRAM、FIFO、计算单元、总线资源、带宽等资源额度。 |
| **Performance Model / Analysis Report** | 性能模型和分析报告(如果有)。分析系统吞吐率、延迟、带宽、并发度、利用率和瓶颈，为流水线、FIFO、并行度等设计提供依据。 |
| **Preliminary PPA Budget** | 初步 PPA 预算。为模块分配 **Power、Performance、Area** 目标，例如最高功耗、目标频率、面积上限。 |