# 两个 32-bit IEEE 754 单精度浮点数浮点乘法器设计文档

| 项目 | 内容 |
| --- | --- |
| 模块名称 | `fp32_mul` |
| 运算格式 | IEEE 754 binary32（FP32，单精度） |
| 基本功能 | 计算 `result = a × b`，并输出 IEEE 754 异常标志 |
| 默认舍入模式 | RNE：Round to Nearest, ties to Even（就近舍入，偶数舍入） |
| 面向对象 | 数字 IC 架构、RTL、综合、验证和评审人员 |

## 1. 设计目标与范围

### 1.1 设计目标

设计一个可综合的 FP32 浮点乘法器，接收两个符合 IEEE 754 binary32 格式的操作数，产生一个 FP32 结果及异常标志。设计应支持正常数、零、非规格化数（subnormal）、无穷大（Infinity）和 NaN，并能够在默认 RNE 舍入模式下得到符合 IEEE 754 语义的结果。

### 1.2 功能范围

- 输入：两个 32-bit FP32 操作数 `a`、`b`。
- 输出：一个 32-bit FP32 结果 `result`。
- 支持：normal、zero、subnormal、`+/-Inf`、quiet NaN（qNaN）和 signaling NaN（sNaN）的分类与处理。
- 支持：默认 RNE 舍入；可选扩展其他 IEEE 754 舍入模式。
- 输出建议异常标志：`invalid`、`overflow`、`underflow`、`inexact`。
- 支持单次请求/响应握手，也可按目标频率实现为固定延迟流水线。

### 1.3 非目标与边界

- 本模块只实现乘法，不实现加、减、除、开方或 FMA。
- 不要求支持 IEEE 754 十进制浮点格式。
- 不要求实现异常陷阱（trap）；异常仅以状态标志输出。
- 若项目不需要严格支持 subnormal，可配置为 FTZ/DAZ（Flush-to-Zero / Denormals-Are-Zero）；该模式会偏离严格 IEEE 754 结果，必须由系统架构明确批准。

## 2. IEEE 754 FP32 格式说明

### 2.1 位域定义

```text
31             30                         23 22                         0
+----------------+---------------------------+----------------------------+
| sign (S, 1 bit)| exponent (E, 8 bits)      | fraction (F, 23 bits)       |
+----------------+---------------------------+----------------------------+
```

偏置指数 `Bias = 127`。

| 编码条件 | 数值含义 |
| --- | --- |
| `E = 1...254` | 规格化数：`(-1)^S × (1.F) × 2^(E-127)` |
| `E = 0, F != 0` | 非规格化数：`(-1)^S × (0.F) × 2^(-126)` |
| `E = 0, F = 0` | 有符号零：`+0` 或 `-0` |
| `E = 255, F = 0` | `+Inf` 或 `-Inf` |
| `E = 255, F != 0` | NaN；`F[22]=1` 通常表示 qNaN，`F[22]=0` 表示 sNaN |

### 2.2 内部统一表示

有限数可在拆包后统一为：

```text
value = (-1)^sign × significand × 2^unbiased_exp
```

对 normal：`significand = {1'b1, fraction[22:0]}`，为 24 bit；`unbiased_exp = E - 127`。

对 subnormal：`significand = {1'b0, fraction[22:0]}`，初始指数为 `-126`；在进入乘法前或乘法后需要左规，得到内部规格化尾数和相应调整后的指数。

## 3. 顶层模块功能和接口定义

建议采用 ready/valid 接口，以支持流水线反压；若系统无反压需求，`in_ready` 可固定为 1，`out_ready` 可固定为 1。

```systemverilog
module fp32_mul #(
  parameter bit SUPPORT_SUBNORMAL = 1'b1,
  parameter bit FTZ               = 1'b0,
  parameter int PIPE_STAGES       = 4
) (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        in_valid,
  output logic        in_ready,
  input  logic [31:0] in_a,
  input  logic [31:0] in_b,
  input  logic [1:0]  in_rm,       // 00: RNE；其余为可选扩展

  output logic        out_valid,
  input  logic        out_ready,
  output logic [31:0] out_result,
  output logic        out_invalid,
  output logic        out_overflow,
  output logic        out_underflow,
  output logic        out_inexact
);
```

接口约定：

- 当 `in_valid && in_ready` 为 1 时，模块采样一次输入事务。
- 当 `out_valid && out_ready` 为 1 时，输出事务完成。
- `out_*` 标志与对应 `out_result` 同周期有效。
- 第一版可规定仅接受 `in_rm = RNE`；对其他编码输出 RNE 结果，或增加 `unsupported_rm` 状态供系统诊断。

## 4. 正常数乘法算法

本节描述两个 normal 操作数的主数据路径。特殊值优先级高于该路径，见第 5 节。

### 4.1 符号计算

```text
sign_r = sign_a XOR sign_b
```

### 4.2 指数计算

对于拆包得到的有偏指数 `Ea`、`Eb`：

```text
exp_sum = Ea + Eb - Bias
        = Ea + Eb - 127
```

实现时建议使用带符号的扩展指数，保留规格化、非规格化和舍入可能产生的进位/借位。内部指数建议至少 11 bit 有符号表示。

### 4.3 24×24 尾数乘法

normal 操作数的隐含位为 1：

```text
sig_a = {1'b1, frac_a};  // 24 bit，数值范围 [1, 2)
sig_b = {1'b1, frac_b};  // 24 bit，数值范围 [1, 2)
product = sig_a * sig_b; // 48 bit，二进制小数点位于 product[46] 与 product[45] 之间
```

由于两个尾数均位于 `[1, 2)`，乘积位于 `[1, 4)`，故：

- `product[47] = 1`：乘积位于 `[2, 4)`，需右移一位且指数加 1；
- `product[47] = 0`：乘积位于 `[1, 2)`，不需要右移。

### 4.4 规格化与 G/R/S 位生成

正常乘积的候选保留尾数为 24 bit（含隐含位），并生成 GRS 舍入信息。

```text
if (product[47]) begin
    sig_keep = product[47:24];
    guard    = product[23];
    round    = product[22];
    sticky   = |product[21:0];
    exp_norm = exp_sum + 1;
end else begin
    sig_keep = product[46:23];
    guard    = product[22];
    round    = product[21];
    sticky   = |product[20:0];
    exp_norm = exp_sum;
end
```

`sig_keep[23]` 应为 1。normal × normal 不会产生左规需求；涉及 subnormal 时需要通用左规器，见第 5 节。

### 4.5 默认 RNE 舍入

RNE 的增量条件：

```text
round_up_rne = guard && (round || sticky || sig_keep[0])
```

含义如下：

- 被截断部分小于半个 ULP：不进位；
- 大于半个 ULP：进位；
- 恰好半个 ULP（`guard=1, round=0, sticky=0`）：仅当当前保留结果为奇数（`sig_keep[0]=1`）时进位，使结果末位为偶数。

```text
sig_rounded = sig_keep + round_up_rne
```

若舍入发生溢出，例如 `1.111...111 + 1` 变为 `10.000...000`，则右移尾数一位并令 `exp_norm = exp_norm + 1`。

### 4.6 打包

当最终结果为 normal 时：

```text
exp_field  = exp_final + 127;
frac_field = sig_final[22:0];  // 去掉隐含 1
result     = {sign_r, exp_field[7:0], frac_field};
```

打包前必须完成指数范围判断、溢出处理、下溢/非规格化结果处理和舍入后的二次溢出检查。

## 5. 特殊值处理

特殊值路径应在主乘法路径前分类并优先仲裁，避免非法操作进入普通计算。

### 5.1 分类信号

```text
is_zero = (exp == 8'h00) && (frac == 23'h0)
is_sub  = (exp == 8'h00) && (frac != 23'h0)
is_inf  = (exp == 8'hFF) && (frac == 23'h0)
is_nan  = (exp == 8'hFF) && (frac != 23'h0)
is_snan = is_nan && (frac[22] == 1'b0)
```

### 5.2 特殊值结果优先级

| 优先级 | 条件 | 输出结果 | 标志 |
| --- | --- | --- | --- |
| 1 | 任一输入为 sNaN | 安静化后的 NaN | `invalid=1` |
| 2 | 任一输入为 qNaN | 传播的 qNaN | 全部 0 |
| 3 | `(Inf × 0)` 或 `(0 × Inf)` | 默认 qNaN | `invalid=1` |
| 4 | 任一输入为 Inf | 带异或符号的 Inf | 全部 0 |
| 5 | 任一输入为 0 | 带异或符号的零 | 全部 0 |
| 6 | 其余有限非零数 | 进入有限数乘法路径 | 由计算决定 |

建议默认 qNaN 常量为 `32'h7FC0_0000`。若实现 NaN payload 传播，推荐按确定性规则选择一个输入 NaN 的 payload，并强制 `fraction[22]=1` 安静化；应在架构规范中固定“优先 a 还是优先 b”。

### 5.3 Subnormal 支持策略

严格 IEEE 754 模式下，subnormal 不能直接按 normal 的隐含 1 处理。

1. 将 subnormal 的尾数初始化为 `{1'b0, fraction}`，指数初始化为 `-126`。
2. 使用前导零计数器（LZC）将尾数左移至最高有效位到达内部隐含位位置，同时将实际指数减去左移量。
3. 与另一个有限非零操作数按统一有限数路径相乘。
4. 结果指数过小但未小到零时，右移形成 subnormal，并将所有移出的位折叠到 sticky 位后再做一次舍入。

`SUPPORT_SUBNORMAL=0` 或 `FTZ=1` 时，可将 subnormal 输入按零处理，或将 subnormal 输出冲零；该选择必须在接口文档和验证参考模型中保持一致。

## 6. 舍入模式

### 6.1 默认模式：RNE

默认必须支持 RNE（Round to Nearest, ties to Even），编码建议为 `in_rm = 2'b00`。这是大多数通用计算场景的 IEEE 754 默认模式。

### 6.2 可选扩展模式

| 编码建议 | 模式 | `round_up` 的典型条件（正负号由 `sign_r` 表示） |
| --- | --- | --- |
| `00` | RNE：就近，偶数舍入 | `G && (R || S || LSB)` |
| `01` | RTZ：向零舍入 | `0` |
| `10` | RUP：向 +∞ 舍入 | `!sign_r && (G || R || S)` |
| `11` | RDN：向 -∞ 舍入 | `sign_r && (G || R || S)` |

可选支持 RNA（ties to Away）。无论哪种模式，只要被丢弃部分非零，即 `G || R || S = 1`，应置 `inexact=1`；发生 invalid 时，`inexact` 一般不因 NaN 操作而置位。

## 7. 异常标志建议

| 标志 | 建议置位条件 | 备注 |
| --- | --- | --- |
| `invalid` | sNaN 输入，或 `Inf × 0` / `0 × Inf` | 输出 qNaN |
| `overflow` | 舍入后指数超出最大有限 normal 范围 | 结果取 Inf 或最大有限数，取决于舍入模式与符号 |
| `underflow` | 结果微小（tiny），且发生不精确 | 推荐采用 IEEE 754 “tininess after rounding” 判定 |
| `inexact` | 任意有效数位在舍入、右移或下溢处理中被丢弃 | 通常与 overflow 同时置位 |

### 7.1 Overflow 结果选择

RNE 下，溢出结果为带符号 Inf：

```text
result = {sign_r, 8'hFF, 23'h0}
```

若扩展定向舍入，则应遵循：朝结果绝对值增大的方向取 Inf；朝零方向取同符号最大有限数（`exp=254, frac=all 1`）。例如正数在 RDN/RTZ 溢出时应输出 `+max_finite`，负数在 RUP/RTZ 溢出时应输出 `-max_finite`。

### 7.2 Underflow 判定

推荐在最终舍入后判断：结果为 subnormal 或零，并且 `inexact=1`，则置 `underflow=1`。这样可避免“舍入前很小但舍入后恢复为最小 normal”时错误置 underflow。

## 8. 关键数据通路位宽

| 信号 | 建议位宽 | 说明 |
| --- | ---: | --- |
| 输入/输出 | 32 | IEEE 754 binary32 |
| 拆包符号 | 1 | `sign_a`、`sign_b` |
| 原始指数 | 8 | FP32 exponent field |
| 内部有符号指数 | 11 | 覆盖解偏置、LZC 调整、右规、舍入进位和范围判断；10 bit 也可行，11 bit更稳妥 |
| 有效尾数 | 24 | 含隐含位：`{hidden, fraction[22:0]}` |
| 尾数乘积 | 48 | `24 × 24` 的完整无符号乘积 |
| 舍入尾数 | 24 + GRS | 推荐至少 27 bit `{sig_keep[23:0], guard, round, sticky}`；实现中可使用 48 bit 保留到末级 |
| subnormal 右移路径 | 48 或更宽 | 需保留所有被移出位并归约为 sticky |
| LZC 计数 | 5 | 对最多 24-bit 有效尾数计数 0～23 |

注意：不要在乘法后过早截断低位。为正确完成 RNE，至少必须保存 Guard、Round、Sticky；对于 subnormal 右移，sticky 必须包含所有此前和本次移出的非零位。

## 9. 推荐流水线划分

推荐 4 级流水线。具体寄存器位置应基于标准单元库、目标频率和乘法器综合映射结果调整。

```text
S0：输入寄存 / 拆包 / 分类 / 特殊值预判
          |
S1：有限数预规格化（subnormal LZC）/ 符号与指数预加
          |
S2：24×24 尾数乘法（可映射到 Booth/Wallace 或工艺乘法宏）
          |
S3：规格化 / GRS 生成 / 舍入 / 异常与结果打包
          |
输出寄存
```

建议：

- 高频目标下，将 `S2` 拆成部分积压缩与最终进位传播两级，形成 5 级或更多流水。
- 低频/面积优先场景可使用单周期组合实现，但 24×24 乘法器、LZC、可变移位和舍入加法的组合路径通常较长。
- 特殊值结果仍应按主流水延迟对齐，避免旁路导致乱序。
- 每一级随数据携带 `valid`、符号、指数、分类/异常预信息和舍入模式。

## 10. RTL 模块划分与伪代码

### 10.1 推荐子模块

```text
fp32_unpack        // 拆分 S/E/F，生成 normal/subnormal/zero/inf/nan/snan 分类
fp32_special_case  // 特殊值仲裁、NaN 选择与 quiet 化
fp32_pre_norm      // subnormal 左规，输出统一有限数尾数和无偏指数
mul24x24           // 24×24 无符号尾数乘法器
fp32_norm_round    // 规格化、GRS、舍入、subnormal 输出处理
fp32_pack          // 写回 S/E/F，产生 overflow/underflow/inexact
fp32_mul           // 流水控制、旁路选择和顶层接口
```

### 10.2 核心伪代码

```systemverilog
// S0: unpack and classify
ua = unpack(in_a);
ub = unpack(in_b);
special = resolve_special(ua, ub);

// S1: finite, non-zero operands only
if (!special.hit) begin
  {sig_a, exp_a} = normalize_finite(ua); // sig_a in [1,2)
  {sig_b, exp_b} = normalize_finite(ub);
  sign_r = ua.sign ^ ub.sign;
  exp_r  = exp_a + exp_b;
end

// S2: significand multiply
prod = sig_a * sig_b;                    // 48 bit

// S3: normalize, round and pack
if (prod[47]) begin
  sig_keep = prod[47:24];
  {g, r, s} = {prod[23], prod[22], |prod[21:0]};
  exp_r = exp_r + 1;
end else begin
  sig_keep = prod[46:23];
  {g, r, s} = {prod[22], prod[21], |prod[20:0]};
end

discarded = g | r | s;
round_up = select_round_up(in_rm, sign_r, sig_keep[0], g, r, s);
{carry, sig_round} = sig_keep + round_up;
if (carry) begin
  sig_round = {1'b1, 23'b0};
  exp_r = exp_r + 1;
end

finite_out = pack_with_range_check(sign_r, exp_r, sig_round, discarded);
out = special.hit ? special.result : finite_out.result;
flags = special.hit ? special.flags : finite_out.flags;
```

说明：实际 RTL 中，`pack_with_range_check` 必须在指数过小的情形执行右移、GRS 重算与二次舍入，不能仅截断后直接写 `exp=0`。

## 11. 时序与综合注意事项

- **尾数乘法器是关键路径核心**：明确综合器是否可将 `a * b` 映射到高效乘法结构/硬宏；必要时使用经过验证的 `mul24x24` 宏或分层实现。
- **可变移位器不可忽略**：subnormal 输入左规和输出右规需要 barrel shifter；面积或频率紧张时，可分别流水。
- **Sticky 归约树应平衡**：宽位 `OR` 归约可能形成扇入路径，可分层归约或与移位器合并实现。
- **指数必须有符号扩展**：避免在 `Ea + Eb - 127`、左规调整和舍入进位处发生无符号回绕。
- **旁路时序对齐**：NaN/Inf/zero 的特殊值不应以零周期绕过主流水，除非接口明确支持可变延迟并带标签重排。
- **复位策略**：数据寄存器可不必全部复位；至少复位 valid 寄存器以清空流水中的无效事务。
- **功耗优化**：当特殊值命中时，可门控后续 LZC、乘法和移位逻辑；门控必须满足低功耗方法学和时钟门控检查要求。
- **X 传播检查**：仿真中不要仅依赖 `casez` 掩盖未知态；对非法舍入码、含 X 输入的仿真策略应单独规定。

## 12. 验证计划与典型测试向量

### 12.1 验证方法

- 建立参考模型：推荐使用 SoftFloat、Python/NumPy（需注意宿主平台设置）或 SystemVerilog DPI 的 IEEE 754 软件模型。
- 采用 bit-accurate 比较：结果 32 bit 与四个异常标志均需比较，不只比较十进制打印值。
- 随机测试覆盖 normal、边界指数、全尾数范围、所有符号组合、subnormal 和 NaN payload。
- 定向测试覆盖每种特殊值优先级、规格化分支、RNE 半 ULP 边界、指数上/下溢和流水反压。
- 用 SVA 检查接口稳定性：`out_valid && !out_ready` 时，输出数据和 flags 必须保持稳定；每个被接受的输入应在固定延迟后恰好产生一个输出。

### 12.2 典型测试向量

下表假设默认 RNE 且严格支持 subnormal；`invalid/overflow/underflow/inexact` 顺序记为 `I/O/U/X`。

| 名称 | A | B | 期望结果 | Flags (I/O/U/X) | 覆盖点 |
| --- | --- | --- | --- | --- | --- |
| 基本正常数 | `3FC00000`（1.5） | `40200000`（2.5） | `40700000`（3.75） | `0000` | 基本尾数乘法 |
| 负数乘正数 | `C0000000`（-2.0） | `40400000`（3.0） | `C0C00000`（-6.0） | `0000` | 符号异或 |
| 乘积需右规 | `3FC00000`（1.5） | `3FC00000`（1.5） | `40100000`（2.25） | `0000` | `product[47]=1` |
| 正零 | `00000000`（+0） | `C0A00000`（-5.0） | `80000000`（-0） | `0000` | 有符号零 |
| 无穷大 | `7F800000`（+Inf） | `C0000000`（-2.0） | `FF800000`（-Inf） | `0000` | Inf 符号 |
| 非法无穷乘零 | `7F800000`（+Inf） | `00000000`（+0） | `7FC00000`（qNaN） | `1000` | invalid |
| qNaN 传播 | `7FC12345` | `3F800000`（1.0） | qNaN（payload 依规范） | `0000` | NaN 传播 |
| sNaN 静默化 | `7F812345` | `3F800000`（1.0） | qNaN（payload 依规范） | `1000` | sNaN/invalid |
| 正溢出 | `7F7FFFFF`（max finite） | `40000000`（2.0） | `7F800000`（+Inf） | `0101` | overflow + inexact |
| 最小 normal 的平方 | `00800000` | `00800000` | `00000000` | `0011` | 下溢至零，需严格参考模型确认 |
| 最小 subnormal × 1 | `00000001` | `3F800000`（1.0） | `00000001` | `0000` | subnormal 保持 |

说明：涉及 subnormal 边界和 tie 的向量，建议由冻结的 bit-accurate 参考模型自动生成并纳入回归，不应只依赖人工十六进制推导。

### 12.3 覆盖率目标

- 功能覆盖：每种操作数分类及其两两组合；四种符号组合；normal 乘积的两种规格化分支。
- 舍入覆盖：`GRS` 的所有关键组合，特别是 `< half`、`= half + even`、`= half + odd`、`> half`。
- 异常覆盖：每个 flag 单独发生以及 `overflow+inexact`、`underflow+inexact`、`invalid` 的组合。
- 接口覆盖：连续输入、气泡、输出反压、复位穿过流水各级。
- 代码覆盖：语句、分支、条件、FSM/切换覆盖达到项目门槛；对不可达分支提供审查豁免说明。

## 13. 设计假设与可配置项

### 13.1 默认设计假设

- 输入 `in_a`、`in_b` 已是 IEEE 754 binary32 位模式，无需对字节序做转换。
- 默认严格处理 subnormal，采用 gradual underflow。
- 默认舍入模式为 RNE。
- underflow 使用“舍入后微小且不精确（tininess after rounding）”策略。
- qNaN payload 传播规则由架构文档固定；建议优先传播 `a`，无 NaN payload 可用时输出 `32'h7FC0_0000`。
- 乘法器延迟固定，所有输入类型均经相同数量的流水级。

### 13.2 建议参数化项

| 参数 | 作用 | 默认建议 |
| --- | --- | --- |
| `PIPE_STAGES` | 流水深度 | 4 |
| `SUPPORT_SUBNORMAL` | 是否支持严格 subnormal 输入/输出 | 1 |
| `FTZ` | subnormal 输出是否冲零 | 0 |
| `DAZ` | subnormal 输入是否按零处理 | 0 |
| `ROUNDING_MODES` | 支持的舍入模式集合 | 仅 RNE 或 RNE+RTZ+RUP+RDN |
| `NAN_PROPAGATION` | NaN payload 选择策略 | `A_PRIORITY` |
| `TININESS_DETECTION` | underflow 判定时机 | `AFTER_ROUNDING` |
| `USE_MULTIPLIER_MACRO` | 是否实例化工艺乘法器宏 | 依工艺/综合策略 |

## 14. 评审检查清单

- 特殊值优先级是否确保 sNaN、qNaN、`Inf×0` 均正确处理？
- normal、subnormal 和零是否使用正确的隐含位和无偏指数？
- 48-bit 乘积的二进制小数点位置、`product[47]` 右规判定及 GRS 切片是否一致？
- RNE tie-to-even 是否使用保留尾数最低位，而非无条件进位？
- 舍入进位导致指数增长时，是否重新执行 overflow 检查？
- subnormal 输出右移时，sticky 是否覆盖全部被丢弃位？
- overflow 与 underflow 是否按选定舍入和 tininess 策略正确置旗？
- 特殊值旁路与普通数据路径是否具有相同的接口时序和流水延迟？
- 验证参考模型是否与 NaN payload、FTZ/DAZ、tininess 等实现选项完全一致？

---

本设计文档可作为 RTL 微架构规格的基线。进入编码前，应由架构、设计和验证共同冻结：NaN payload 规则、subnormal/FTZ/DAZ 策略、支持的舍入模式、流水级数以及异常标志语义。
