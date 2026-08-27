---
name: RTL_design_tech
description: RTL design techniques and best practices for architecture, module partitioning, counters, FSMs, FIFOs, pipelines, handshakes, clock-domain crossings, and area/timing/power tradeoffs.
argument-hint: Describe the RTL design problem, architecture, constraints, and open decisions
---

# RTL 设计技巧与最佳实践

本规范用于 RTL 架构设计、模块拆分和设计审查。目标是让设计在功能、时序、面积、功耗和可验证性之间取得可解释的平衡。

## 1. 模块划分

### 核心原则

1. 一个清晰功能对应一个模块；不要将无关控制和数据通路混在同一模块。
2. 相同架构、相同时钟域、紧密耦合的数据通路可归入同一模块。
3. 模块划分后，必须明确每个端口、数据流向、时钟域和复位域。
4. 模块职责应单一、可独立仿真、便于定位问题。

| 信号名 | 含义 |
| --- | --- |
| `clk` | 时钟 |
| `rst_n` | 低有效复位 |
| `en` | 使能 |
| `vld` | 数据有效 |
| `data` | 数据总线 |
| `err` | 报文或事务错误 |
| `sop` / `eop` | 报文起始 / 结束 |
| `rdy` | 接收方准备好 |

### 常用交互架构

**直接交互**：下游处理速率稳定且不低于上游时可直接传递数据。

```text
模块 A -- data --> 模块 B
```

**ready 反压交互**：下游可能暂停接收时，使用 `valid` / `ready` 或等价 `rdy` 信号。

```text
A -- data, valid --> B
A <-- ready ------ B
```

**FIFO 解耦**：跨时钟域、速率不匹配或需要缓冲时，使用 FIFO；读写控制只通过 FIFO 状态和存储的数据交互。

```text
A --写--> FIFO --读--> B
```

**请求—应答交互**：请求端必须等待处理完成或返回数据后才能继续使用。

```text
A ---- req ----> B
A <--- ack ----- B
A <--- data ---- B
```

## 2. 计数器设计

计数器是控制时序的骨架。先设计计数器，再让其余控制信号与计数器严格对齐。

### 设计规则

1. 每个计数器明确初值、加一条件和结束值。
2. 计数器初值为 `0`，结束后回到 `0`。
3. 取某个计数点或判断结束时，必须同时满足加一条件。
4. 结束条件采用 `add_cnt && (cnt == LAST - 1)` 形式；`LAST` 是总拍数或元素个数。
5. 信号直接根据计数器定义特殊点，禁止通过另一个输出信号间接对齐。
6. 命名使用 `add_cnt_xxx`、`end_cnt_xxx` 和 `cnt_xxx`。
7. 范围限制优先使用明确的 `==`、`<`、`<=`，并检查边界值。

```systemverilog
// 传输拍数计数器 cnt_word
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_word <= '0;
    else if (add_cnt_word) begin
        if (end_cnt_word)
            cnt_word <= '0;
        else
            cnt_word <= cnt_word + 1'b1;
    end
end

assign add_cnt_word = transfer;
assign end_cnt_word = add_cnt_word && (cnt_word == WORD_NUM - 1);
assign word_sop     = add_cnt_word && (cnt_word == '0);
assign word_eop     = end_cnt_word;
```

### 设计步骤

1. 明确功能和预期波形。
2. 画出计数范围、加一条件和复位路径。
3. 定义开始、结束和特殊计数点。
4. 完成计数器后再编写与其对齐的功能逻辑。
5. 检查零长度、单元素、最大值和中断/暂停场景。

## 3. 状态机设计

当操作顺序不固定、跳转条件复杂或需要恢复路径时，使用 FSM。FSM 的目的是清晰地产生控制输出，而非替代简单计数器。

### 四段式模板

1. 状态寄存器：同步更新当前状态。
2. 下一状态组合逻辑：仅描述转移。
3. 转移条件：用 `assign` 单独命名，并带当前状态限定。
4. 输出逻辑：输出寄存化；一个 `always_ff` 块只驱动一个输出信号。

```systemverilog
typedef enum logic [1:0] {
    IDLE,
    S1,
    S2
} state_t;

state_t cur_st; // 当前状态
state_t nxt_st; // 下一状态

// 1. 状态寄存器
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cur_st <= IDLE;
    else
        cur_st <= nxt_st;
end

// 2. 状态转移
always_comb begin
    nxt_st = cur_st;
    case (cur_st)
        IDLE:    if (idle_to_s1) nxt_st = S1;
        S1:      if (s1_to_s2)   nxt_st = S2;
        S2:      if (s2_to_idle) nxt_st = IDLE;
        default:                  nxt_st = IDLE;
    endcase
end

// 3. 转移条件
assign idle_to_s1 = (cur_st == IDLE) && start_i;
assign s1_to_s2   = (cur_st == S1)   && step_done_i;
assign s2_to_idle = (cur_st == S2)   && done_i;

// 4. 输出逻辑
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        busy_o <= 1'b0;
    else if (cur_st == IDLE)
        busy_o <= 1'b0;
    else
        busy_o <= 1'b1;
end
```

### 状态机规则

- 第二段必须有 `nxt_st = cur_st` 默认值和 `default` 分支。
- 状态转移条件命名为 `状态1_to_状态2`，并在 `assign` 中限定 `cur_st`。
- 输出优先使用 `cur_st` 等寄存器值，不要直接用 `nxt_st` 等组合值驱动外部接口。
- 合并语义、退出条件和输出完全相同的状态，避免无意义细分。

## 4. FIFO 设计

1. 优先使用 show-ahead（FWFT）读模式：读请求有效时，当拍输出数据有效。使用前须确认 IP 的具体时序定义。
2. 读、写控制隔离：写侧不依赖读数据或读状态决定写行为，读侧不依赖写数据或写控制决定读行为；两侧只通过 FIFO 数据和状态通信。
3. 写请求必须检查满标志：`wr_req = condition && !fifo_full`。
4. 读请求必须检查空标志，且优先用组合逻辑产生：`rd_req = condition && !fifo_empty`。
5. 处理报文时，将 `sop`、`eop`、错误标志等元数据与数据一起写入 FIFO。
6. 读写时钟不同必须使用异步 FIFO；相同且无相位风险时可使用同步 FIFO。
7. FIFO 宽度应包含数据和必要的 sideband；深度按峰值速率差、最长阻塞时间和突发长度估算。

```systemverilog
assign fifo_wr_req = in_vld_i && !fifo_full;
assign fifo_rd_req = out_rdy_i && !fifo_empty;
```

设计时依次确认：FIFO 个数与职责、读状态、读写启动/结束条件、清空条件、IP 参数（宽度/深度/模式）及满空边界行为。

## 5. 时钟域、复位与 CDC

1. 一个 `always_ff` 块内所有信号必须属于同一时钟域。
2. 一个触发器的时钟和异步复位必须满足库和项目的复位策略；跨域复位采用“异步断言、同步释放”。
3. 单比特控制信号跨域使用同步器；脉冲跨域使用握手、toggle 或脉冲展宽；多比特数据跨域使用异步 FIFO 或带稳定窗口的握手。
4. 组合逻辑直接送入同步器可能把毛刺采样为有效事件；注意 CDC reconvergence，不要将独立同步后的相关信号直接比较或重汇聚。
5. 边沿检测脉冲宽度为一个目标时钟周期，适合用作启动条件或使能脉冲；不可用于保证异步窄脉冲不丢失。

```systemverilog
logic sig_d1; // 一级同步寄存器
logic sig_d2; // 二级同步寄存器

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sig_d1 <= 1'b0;
    else
        sig_d1 <= sig_async_i;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sig_d2 <= 1'b0;
    else
        sig_d2 <= sig_d1;
end

assign sig_posedge = sig_d1 && !sig_d2;
assign sig_negedge = !sig_d1 && sig_d2;
```

## 6. 握手与反压

数据在 `valid && ready` 同时为高的时钟沿传输。

```systemverilog
assign data_transfer = data_valid && data_ready;
```

- `valid` 拉高后，在完成握手前必须保持；数据也必须保持稳定。
- `valid` 不应依赖 `ready` 生成，以避免组合环路。
- `ready` 可以依赖 `valid`，但会增加组合路径，通常不推荐。
- 反压时冻结所有相关数据、标志和计数器；不能只暂停数据而继续推进控制通路。

## 7. 流水线设计

流水线通过寄存器切分长组合路径，以面积和延迟换取更高频率。

1. 每级组合延迟尽量均衡，避免单级成为关键路径。
2. 数据与其 `valid`、地址、mask、SOP/EOP 等控制信号必须逐级同步打拍。
3. 使用 `_d1`、`_d2` 等后缀明确拍数。
4. 下游反压时，所有流水级必须按相同使能冻结，避免丢数、重数或控制失配。
5. 在功能和时序允许时，合并可同拍完成的操作以减少气泡，但必须重新验证数据对齐。

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pipe_data_d1 <= 'd0;
        pipe_vld_d1  <= 1'b0;
    end
    else if (pipe_en) begin
        pipe_data_d1 <= pipe_data;
        pipe_vld_d1  <= pipe_vld;
    end
end
```

## 8. 健壮性检查

1. FIFO 写操作检查满标志，读操作检查空标志。
2. 复位值与信号无效态或安全态一致；`valid`、`enable`、`request` 一般复位为 `0`，FSM 复位到 `IDLE`。
3. 禁止声明未使用信号。
4. 禁止组合逻辑环路和多驱动；一个信号只能由一个 `always` 块或一个 `assign` 驱动。
5. 模块对外输入尽量寄存后再使用，对外输出尽量寄存，以降低毛刺、时序和 CDC 风险。未连到顶层的内部子模块是否组合输出可按时序需求处理。

## 9. 面积、时序与功耗优化

### 面积

- 不会并行工作的功能可复用算术单元、比较器或状态机资源。
- 紧密排列的数据地址优先使用线性计数器，替代行列双计数器和额外边界判断。
- 使用 `parameter` / `localparam` 参数化位宽和深度，避免复制相似模块。

```systemverilog
always_comb begin
    case (mode)
        MODE_A:  adder_result = operand_a + operand_b;
        MODE_B:  adder_result = operand_c + operand_d;
        default: adder_result = '0;
    endcase
end
```

### 时序

- 关键路径过长时，在合适位置插入寄存器；同时调整所有相关控制信号的延迟。
- 可提前计算的比较、地址或选择信号在前一拍预计算。
- 高扇出控制信号使用寄存器复制或由综合约束控制扇出；不要让一个控制信号直接驱动大量触发器。

### 功耗

- 对通用模块使用经过签核的 common-cell clock gate，不自行搭建门控时钟电路。
- 宽位数据寄存器（通常 ≥8 bit）不更新时应使用时钟使能或门控，降低无效翻转。
- 数据无效时保持数据总线稳定或置为已定义值，减少动态功耗；不要为了省功耗破坏有效数据保持规则。
- 含软复位/旁路逻辑时，检查综合后的门控使能极性和旁路期间的实际功耗，避免反向增加翻转。
 例如：

  if (bypass_i)
      data_q <= '0;
  else if (data_en)
      data_q <= data_i;

  功能上没问题，但 bypass_i=1 时每拍仍有时钟到达寄存器，且输入组合逻辑、复位选择逻辑可能仍在翻转，造成额外动态功耗。
  若希望 bypass 时真正省电，门控使能应表达“仅在非 bypass 且需要更新时开时钟”：


## 10. 设计输出要求

进行架构或 RTL 设计审查时，应输出：

1. 模块职责、接口、时钟/复位域和数据流。
2. 关键计数器、状态机、FIFO、握手与流水线对齐关系。
3. 已识别的 CDC、满空边界、反压、复位、时序、面积和功耗风险。
4. 可执行的修改建议及需要由设计工程师确认的阻塞项。

只输出结论、依据、实现说明和下一步动作，不输出内部隐藏推理。
