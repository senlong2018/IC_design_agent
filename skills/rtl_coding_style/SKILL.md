---
name: RTL_coding_style
description: Senior digital engineer Verilog/SystemVerilog coding standard. Use when writing or reviewing synthesizable RTL, modules, FSMs, pipelines, FIFOs, or submodule instantiations. Enforces SystemVerilog syntax, one-signal-per-always_ff, flat else-if style, and signal comments.
argument-hint: Describe the RTL module or feature to implement or review
---

# RTL Coding Style

本规范用于编写和审查可综合的 Verilog/SystemVerilog RTL。项目已有更严格规范时，以项目规范为准。

## 适用场景

- 编写、重构或审查 Verilog / SystemVerilog RTL。
- 实现 FPGA / ASIC 模块、FSM、流水线、FIFO、寄存器或子模块实例化。

## 基本原则

1. 只使用可综合语法；禁止 `initial`、`#delay`、`$display` 等仿真专用语法进入综合 RTL。
2. 统一使用 SystemVerilog：信号优先使用 `logic`，时序逻辑使用 `always_ff`，复杂组合逻辑使用 `always_comb`。
3. 每个内部信号必须带行尾中文注释，说明含义、用途和有效时机。
4. 位宽必须覆盖实际取值范围且避免无意义冗余。例如计数范围为 `0` 到 `1499` 时使用 `[10:0]`。
5. 所有信号、变量和端口名使用小写，且不得以数字开头。

## 模块与端口

1. 使用 ANSI 风格端口声明，一行一个端口。
2. 端口统一使用 `logic` 类型；输入、输出分别使用 `_i`、`_o` 后缀。
3. 每个端口必须有中文行尾注释。
4. 模块输出由寄存器逻辑驱动；不要把复杂组合逻辑直接作为模块输出。
5. 一个 `.sv` / `.v` 文件只包含一个 `module`；文件名与模块名完全一致，并全部小写。

```systemverilog
module fifo_cut (
    input  logic       clk,       // 时钟
    input  logic       rst_n,     // 异步复位，低有效
    input  logic [7:0] din_i,     // 输入数据
    output logic [7:0] dout_o     // 输出数据
);

    // 模块逻辑

endmodule
```

## 时序逻辑

1. 所有触发器使用上升沿触发，复位采用低有效异步复位：`@(posedge clk or negedge rst_n)`。
2. 每个 `always_ff` 块只驱动一个信号。相互关联的多个寄存器分别使用独立时序块。
3. 条件必须是扁平的 `if` / `else if` / `else` 链；禁止在同一个 `else` 分支内出现多个独立的 `if` 来驱动同一信号。
4. `else if` 必须另起一行，不与前一条 `end` 同行。
5. `always_ff` 自身必须使用 `begin` / `end`；分支内只有一条语句时可省略分支的 `begin` / `end`。

```systemverilog
// 写侧字节计数器 cnt_wr
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_wr <= '0;
    else if (din_vld_i && end_condition)
        cnt_wr <= '0;
    else if (din_vld_i)
        cnt_wr <= cnt_wr + 11'd1;
end
```

下例禁止使用，因为两个独立条件会在同一周期争夺 `signal_a` 的赋值优先级：

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        signal_a <= 1'b0;
    else begin
        if (cond_1)
            signal_a <= 1'b1;
        if (cond_2)
            signal_a <= 1'b0;
    end
end
```

应改为：

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        signal_a <= 1'b0;
    else if (cond_1)
        signal_a <= 1'b1;
    else if (cond_2)
        signal_a <= 1'b0;
end
```

当高优先级条件共享前提时，使用清晰的嵌套层次，避免重复条件：

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dest_wmask_o <= 4'b0000;
    else if (src_rd_d1) begin
        if (is_last_word_d1)
            dest_wmask_o <= last_word_wmask;
        else
            dest_wmask_o <= 4'b1111;
    end
    else
        dest_wmask_o <= 4'b0000;
end
```

## 组合逻辑

| 场景 | 使用方式 |
| --- | --- |
| 简单组合表达式 | `assign` |
| 多分支组合逻辑 | `always_comb` |
| 时序逻辑 | `always_ff` |
| 锁存器（极少使用） | `always_latch` |

1. 禁止使用 `always @(posedge ...)` 和 `always @(*)`。
2. 单一简单表达式优先使用 `assign`，不要额外包装 `always_comb`。
3. `always_comb` 必须含有 `begin` / `end`，并为所有赋值路径提供默认值或完整 `else` / `default`，避免推导 latch。
4. `case` 必须包含 `default` 分支。

```systemverilog
assign dfifo_wr_req = din_vld_i && !dfifo_full;
assign dfifo_rd_req = rd_active || rd_start_pulse;

always_comb begin
    case (cur_st)
        IDLE:    nxt_st = start_i ? RUN : IDLE;
        RUN:     nxt_st = done_i  ? DONE : RUN;
        DONE:    nxt_st = IDLE;
        default: nxt_st = IDLE;
    endcase
end
```

## 状态机

1. 状态用 `enum logic` 定义，使仿真波形可直接显示状态名。
2. 状态转移使用 `case` 并提供 `default`。
3. 状态名表达功能即可，不使用冗余前缀；例如用 `IDLE`，不用 `ST_IDLE`。
4. 避免使用 `cur_st == xxx && nxt_st == yyy` 标记跳转点，以免把 `nxt_st` 引入不必要的组合逻辑。

```systemverilog
typedef enum logic [1:0] {
    IDLE,
    START,
    RUN,
    DONE
} state_t;

state_t cur_st; // 当前状态
state_t nxt_st; // 下一状态
```

## 流水线拍数

拍数按时钟边沿间隔定义：从事件 A 所在边沿到事件 B 所在边沿，周期数为两个时间点的间隔，而不是时间点数量。设计说明中应明确每一级的输入、寄存和输出关系。

```text
T+0: src_rd=1，发起地址 A 的读请求
T+1: SRAM 返回 src_rdata
T+2: 锁存 src_rdata 至 src_rdata_lat
T+3: dest_wr_o=1，写入目标端
```

流水线级数表示流水线启动后可并行推进的阶段数量。减少级数前，应确认时序、数据有效标志和 RAM 读延迟仍正确。

## generate 与 for 循环

### generate

`generate for` 用于生成重复硬件实例，循环变量必须是 `genvar`，每个生成块必须带唯一标签。`generate if` / `generate case` 的分支也必须带标签。生成条件只能使用 `parameter`、`localparam` 或 `genvar`，不能依赖运行时信号。

```systemverilog
genvar i;
generate
    for (i = 0; i < NUM_CH; i = i + 1) begin : gen_channel
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n)
                data_out[i] <= '0;
            else if (ch_en[i])
                data_out[i] <= data_in[i];
        end
    end
endgenerate
```

### always 块内的 for

组合逻辑中的 `for` 用于重复赋值；循环变量使用 `integer` 或 `int`，循环边界必须是编译期常量。不要在 `always_ff` 内用 `for` 批量生成意图不清晰的时序逻辑；此类重复寄存器应优先使用 `generate for` 加独立 `always_ff`。

```systemverilog
integer k;
always_comb begin
    for (k = 0; k < 4; k = k + 1) begin
        byte_swap[k * 8 +: 8] = data_in[(3 - k) * 8 +: 8];
    end
end
```

## 代码组织与实例化

模块结构顺序如下：参数、内部信号声明、`assign` 组合逻辑、子模块实例化、`always` 块。每个逻辑块前添加分隔注释，标明其生成的信号和用途。

1. `localparam` 定义常量时，以注释说明取值原因。
2. 未使用的子模块端口留空连接，不额外声明无用的 `wire` / `logic`。
3. 命名端口的端口名和连接括号应对齐。
4. 实例端口只连接独立信号；复杂逻辑先用 `assign` 生成中间信号，再接入实例。
5. common cell / IP 直接实例化 common lib 中的 cell / IP，不自行搭建等价电路。

```systemverilog
assign crc_clr = (rg_crc_select == 2'b00) ? crc_d32_clr : 1'b0;
assign crc_en  = (rg_crc_select == 2'b00) ? crc_d32_en  : 1'b0;

crc32_standard_d32 crc32_standard_d32_inst (
    .clk       (hclk),
    .rst_n     (hresetn),
    .crc_clr   (crc_clr),
    .lfsr_load (d32_load),
    .crc_en    (crc_en),
    .data_in   (entry_data_q),
    .crc_done  (std_d32_crc_done),
    .crc_out   (std_d32_crc_out),
    .crc_state (std_d32_crc_state)
);
```

## 命名、常量与结构

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 时钟 | 有意义的时钟名 | `hclk`、`pclk`、`clk_200m` |
| 低有效复位 | `rst_<名称>_n` 或 `rst_<名称>_b` | `rst_sys_n` |
| 低有效信号 | 后缀 `_n` 或 `_b` | `cs_b`、`wr_n` |
| 有效/使能 | 后缀 `_vld`、`_en` 或 `_req` | `din_vld`、`dout_en` |
| 报文边界 | 后缀 `_sop`、`_eop` | `din_sop` |
| 标志 | `flag_xxx` | `flag_zero` |
| 计数器 | `cnt_xxx` | `cnt_wr` |
| FIFO | `xxx_fifo_yyy` 或 `fifo_xxx` | `fifo_empty` |
| 内部寄存器 | `rg_<寄存器名>` | `rg_i2c_master_en` |
| 延时信号 | `_dly1`、`_dly2` 或 `_d1`、`_d2` | `din_dly1`、`flag_d2` |

1. 子模块文件命名为 `<ip_name>_<function>.v`，例如 `i2c_master_reg.v`；避免过短缩写以防 IP 重名。
2. 实例名使用 `<module_name>_inst` 或 `<module_name>_inst0`；多实例时增加编号。
3. `define` 和 `parameter` 定义的常量名全部大写，优先使用 `parameter`；IP 自用常量优先在顶层使用 `localparam`。
4. 使用系统寄存器的 IP，在顶层用 `parameter` 定义 base address 和 address width。
5. 包含 memory 的 IP 应定义 `FPGA` / `RTL_SIM` 宏区分 ASIC、FPGA 和 RTL 仿真；memory 放在 IP 顶层，并通过 memory wrapper 与 core 隔离，以便插入MBIST。
6. AHB/APB 等总线接口模块实例化在 IP 顶层，便于替换。
7. 寄存器以 `rg_xx` 命名；寄存器模块输出注释需说明每个 bit 的含义；寄存器定义尽量按 byte 对齐。

```systemverilog
localparam integer DFIFO_W = 12;   // dfifo 数据位宽
localparam integer DFIFO_D = 2048; // dfifo 深度
parameter  logic [31:0] BASE_ADDR = 32'h0000_0000;
parameter  integer      ADDR_WIDTH = 12;
```

## 文件头注释

每个 RTL 文件开头必须包含：

```systemverilog
// 作者          : John
// 文件名        : example_module.sv
// 功能描述      : 本模块功能的精炼总结
```
