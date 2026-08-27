---
name: design_doc reviewer
description: 审查DE提供的设计方案.md，要求设计方案必须包含如下内容；
argument-hint: 
---


Canonical 输入资产	来源
[S02-O06] Memory / IO Library Package
[S02-O07] IP Registry + IP Deliverable Manifest	S02
[S03-O04] Interface / Address / Register Specification Package
[S03-O05] Clock & Reset Specification
[S03-O06] Power Specification
[S03-O07] Interrupt / Error / Exception Specification
[S03-O08] DFT Specification
[S03-O09] Debug / Security Specification
[S03-O10] Software Programming / HW-SW Interface Specification
[S03-O13] Structured Spec Package（Requirement DB / Interface & Register Schema / Clock-Reset & Constraint Table / Behavior Rule / Req→Verification）
[S03-O14] Open Issue List
[S03-O15] Spec Baseline / Version Manifest	S03
[S04-O02] HW / SW Partition
[S04-O03] Chip Block Diagram + Module Inventory / Responsibility
[S04-O05] Memory Architecture
[S04-O06] Interconnect Architecture + Interface / Bandwidth Table
[S04-O07] Address / Memory Mapping
[S04-O08] Clock / Power Domain Definition	S04
[S04-O01] System Architecture Specification
[S04-O04] Dataflow / Control-flow Package
[S04-O12] Architecture Decision / Open Issue Log	S04
[参考]
[S05-O01] Microarchitecture Specification
[S05-O02] Datapath + Numerical Rule Package
[S05-O03] Control / FSM / Priority-Arbitration Rule Package
[S05-O04] Pipeline Definition + Timing Diagram
[S05-O05] Signal-level Interface Definition
[S05-O06] Buffer / FIFO Specification
[S05-O07] Register / Internal Control Map
[S05-O08] Clock / Reset / CDC Rules
[S05-O09] Error / Exception / Boundary Behavior
[S05-O13] Microarchitecture Version Manifest	S05
[S05-O10] Performance / Resource Estimate	S05
[参考]
[S05-O12] Optional RTL Skeleton	S05
[可选]
[S06-O01] Algorithm / Functional Reference Model Package
[S06-O02] Bit-true Model
[S06-O09] Model Configuration
[S06-O10] Model Validation + Version / Coverage Manifest	S06
[参考]
[S08-O01] Lint Report
[S08-O02] CDC / RDC Report Package
[S08-O03] Low-power Static Check Report
[S08-O04] X-propagation Report
[S08-O05] Structural Check Report
[S08-O06] Static Violation Database
[S08-O07] Waiver List	S08
[反馈]
[S09-O06] Simulation Log + Waveform
[S09-O07] Scoreboard + Assertion Result
[S09-O10] Failure / Bug Database	S09
[反馈]
[S10-O02] Formal Proof Report
[S10-O03] Formal Counterexample Database	S10
[反馈]
[S25-O08] Design Re-spin Change Request	S25
[条件反馈]

Canonical 输出资产	去向
[S07-O01] RTL Source Package（Source Tree / Top / Subsystem）
[S07-O02] Filelist / Parameters / Macros / Build Config	S08 / S09 / S10 / S11 / S12 / S13
[S07-O03] Wrapper / CSR RTL	S08 / S09 / S11 / S12
[S07-O04] SVA / Assertion Set	S09 / S10
[S07-O05] UPF	S08 / S11 / S12 / S14 / S16 / S20
[S07-O06] Initial SDC	S08 / S11 / S12 / S14
[S07-O07] Register Description / CSR Schema	S09 / S24
[S07-O08] RTL Design Documentation	S08 / S09[参考] / S13[参考]
[S07-O09] Unit-level Verification Environment	S09
[S07-O10] Simulation / Synthesis / Regression Configuration	S09 / S10[参考] / S12
[S07-O11] IP Integration Manifest	S12[参考] / S14[参考] / S21[Gate]
[S07-O12] Clock / Reset Map	S08 / S09[参考] / S11[参考] / S14[参考]
[S07-O13] RTL Dependency Graph	S08[参考] / S09[参考] / S12[参考]
[S07-O14] RTL Known Issue List	S08 / S09 / S21[Gate] / S24[参考]
[S07-O15] RTL Release Manifest	S08 / S09 / S10 / S11 / S12 / S13 / S21[Gate]