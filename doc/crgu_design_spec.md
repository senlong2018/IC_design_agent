# 通用 CRGU（Clock and Reset Generation Unit）设计方案

| 项目 | 内容 |
| --- | --- |
| 模块名称 | `crgu` |
| 中文名称 | 时钟与复位生成单元 |
| 适用范围 | SoC、子系统、IP 或数字模块级时钟/复位控制 |
| 核心能力 | 时钟分频、时钟 MUX、时钟门控、异步复位/同步释放 |
| 文档用途 | 架构、RTL、DFT、STA、低功耗及验证评审基线 |

## 1. 设计目标与范围

定义crgu module的端口，有2个时钟源，pll_100M和rc_25M，有3个复位源，cmd_reset,POR和PAD_RSTN，输出8个子模块的时钟和对应复位，每个子模块都可以软复位;


  - 接口矛盾：示例接口只起到示范作用，不代表真实的设计。
  - 时钟规格缺失：
  pll_100M、rc_25M 的准确端口：就是pll_100M和rc_25M；
  有效条件: POR拉高后，时钟稳定；
  默认选择：这2个时钟是时钟源；
  允许切换关系：不存在切换这件事儿；
  切换完成/失败行为：不存在切换这件事儿；

  - 分频规格缺失：8 个域分别使用哪个源、目标频率/分频值范围、div_value 编码（N 还是 N-1）、更新时机与非法值处理未定义。
  
  - 复位规格缺失：三种复位的极性、作用域、优先级、同步释放周期数，以及软复位是否异步断言均未定义。
  - 门控与复位联动缺失：门控关闭时，如何保证复位同步释放期间强制开钟，尚未定义。
  - 控制接口缺失：配置是 APB/AHB/AXI-Lite 还是静态输入；寄存器地址、复位值、读写属性、更新握手和状态/错误清除机制均未定义。
  - DFT/功耗/异常规格缺失：扫描模式约束、scan_enable 的时序、低功耗需求，以及源时钟失效、非法配置、复位期间配置请求等边界行为未定义。
  - 模块责任不完整：仅列出 clk_gen、rst_gen、crgu，但未定义各自接口、时钟域归属、实例化的公共 IP 参数与职责边界。
  - 性能与验证基线缺失：目标频率、延迟/切换时间、资源约束，以及必须覆盖的测试场景和断言未定义。


### 1.1 设计目标

- 基于一个或多个稳定输入时钟，生成所需的工作时钟。
- 支持整数分频，默认支持偶数分频；可选支持奇数分频和占空比校正。
- 支持多个候选时钟源之间的无毛刺切换。
- 支持每个时钟域独立的时钟门控（clock gating）。
- 支持外部或上电复位的异步断言（asynchronous assertion）。
- 支持每个时钟域在本地时钟下的同步释放（synchronous deassertion）。
- 输出复位、时钟和状态信号，便于软件、DFT、验证和系统集成使用。

### 1.2 范围边界

- 本文档描述数字 CRGU 的通用实现。PLL、DLL、OSC、外部晶振和模拟锁定环路不在 RTL 实现范围内。
- 时钟源必须已经满足输入频率、占空比和抖动要求；CRGU 不修复不稳定或停止抖动的输入时钟。
- 跨时钟域数据传输（CDC）不由 CRGU 自动解决；CRGU 只提供时钟和复位控制。数据 CDC 仍需由握手、异步 FIFO 或同步器实现。
- 门控时钟应优先通过工艺库 ICG（Integrated Clock Gating）单元实现，而不是 RTL 组合逻辑直接相与。

## 2. 总体架构

建议按“时钟生成、时钟选择、时钟门控、复位同步、寄存器配置/状态”分层实现。

```text
                       +---------------------------+
clk_src0 ------------->|                           |----> clk_div0 --+
clk_src1 ------------->|  时钟选择 / 分频单元       |                 |
pll_lock --------------|                           |                 v
                       +---------------------------+          +-------------+
                                                            -->|  无毛刺 MUX  |--+
clk_srcN ----------------------------------------------------->|             |  |
                                                               +-------------+  v
                                                                            +---------+
clk_enable_cfg -----------------------------------------------------------> |   ICG   | ---> clk_domain
scan_enable --------------------------------------------------------------> |         |
                                                                            +---------+

por_n / ext_reset_n ----+                                                  +--------------------+
                         +------------------------------------------------>| reset synchronizer | ---> rst_domain_n
clk_domain -------------+                                                  | (async assert,    |
                                                                            |  sync deassert)   |
                                                                            +--------------------+
```

对每个输出域 `domain[i]`，推荐结构为：

```text
候选源时钟 -> 分频（如需要） -> 无毛刺 MUX -> ICG -> domain_clk[i]
                                                   |
全局异步复位 -------------------------------------> 本地 reset synchronizer -> domain_rst_n[i]
```

**重要约束：**复位同步器的时钟必须是目标域实际运行的时钟，通常为 `domain_clk[i]`；如果该时钟可能被门控关闭，需要制定“复位释放期间强制开钟”的机制，见第 7.4 节。

## 3. 顶层接口建议

以下为可按项目裁剪的接口示例。寄存器控制接口可以替换为 APB、AHB、AXI-Lite 或直接静态绑定位。

```systemverilog
module crgu #(
  parameter int NUM_CLK_SRC = 2,
  parameter int NUM_DOMAIN  = 4,
  parameter int RST_SYNC_FF = 2
) (
  // Always-on clocks and reset
  input  logic [NUM_CLK_SRC-1:0] clk_src,
  input  logic                   por_n,          // global active-low async reset
  input  logic                   ext_reset_n,    // external active-low async reset
  input  logic [NUM_CLK_SRC-1:0] clk_src_valid,  // e.g. PLL lock/clock-good

  // Static or register-programmed controls
  input  logic [NUM_DOMAIN-1:0]                    clk_en,
  input  logic [NUM_DOMAIN-1:0][$clog2(NUM_CLK_SRC)-1:0] clk_sel,
  input  logic [NUM_DOMAIN-1:0][15:0]              div_value,
  input  logic [NUM_DOMAIN-1:0]                    sw_reset_req,
  input  logic                                      scan_enable,

  // Domain outputs
  output logic [NUM_DOMAIN-1:0]                    clk_out,
  output logic [NUM_DOMAIN-1:0]                    rst_out_n,

  // Status / fault reporting
  output logic [NUM_DOMAIN-1:0]                    clk_switch_busy,
  output logic [NUM_DOMAIN-1:0]                    clk_switch_error,
  output logic [NUM_DOMAIN-1:0]                    clk_running
);
```

接口原则：

- `por_n` 和 `ext_reset_n` 是异步复位源；有效时必须立即把所有相关域置于复位状态。
- `clk_sel` 和 `div_value` 不能无约束地在运行时直接切换，应经过安全更新协议。
- `scan_enable` 在 DFT 扫描测试期间旁路功能门控，使时钟可控地传入扫描链。
- `clk_src_valid` 用于阻止选择未锁定 PLL、无效外部时钟或已失效的候选源。

## 4. 时钟分频设计

使用rtl_design_tech/ip_common_lib/clk_div下的IP;


## 5. 时钟 MUX 设计

使用rtl_design_tech/ip_common_lib/clk_mux下的IP;


## 6. 时钟门控设计

使用rtl_design_tech/ip_common_lib/clk_gate下的IP;

## 7. 复位设计：异步复位、同步释放

使用rtl_design_tech/ip_common_lib/rst下的IP;


## 9. RTL 设计准则

### 9.1 模块划分建议

分成clk_gen,rst_gen以及最终顶层CRGU;

