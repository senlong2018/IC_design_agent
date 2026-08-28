// 作者          : Codex
// 文件名        : CRGU.sv
// 功能描述      : 双时钟源、八输出域的时钟与复位生成单元顶层。

module CRGU (
    input  logic       pll_100M,   // 100 MHz PLL 时钟源
    input  logic       pll_lock,   // PLL 锁定指示，高有效
    input  logic       rc_25M,     // 25 MHz RC 时钟源
    input  logic       cmd_reset,  // 命令全局异步复位，高有效
    input  logic       POR,        // 上电全局异步复位，高有效
    input  logic       PAD_RSTN,   // PAD 全局异步复位，低有效
    input  logic [7:0] mod_clk_en, // 各模块静态功能门控使能，高有效
    input  logic       scan_en,    // 扫描模式门控旁路使能，高有效
    output logic [7:0] mod_clk,    // 八路模块门控时钟
    output logic [7:0] mod_rst_n   // 八路模块本地复位，低有效
);

    logic global_arst_n; // 合成后的全局异步复位，低有效

    assign global_arst_n = PAD_RSTN & ~POR & ~cmd_reset;

    crgu_clk_gen crgu_clk_gen_inst (
        .pll_100m_i   (pll_100M),
        .pll_lock_i   (pll_lock),
        .rc_25m_i     (rc_25M),
        .mod_clk_en_i (mod_clk_en),
        .scan_en_i    (scan_en),
        .mod_clk_o    (mod_clk)
    );

    crgu_rst_gen crgu_rst_gen_inst (
        .pll_100m_i      (pll_100M),
        .pll_lock_i      (pll_lock),
        .rc_25m_i        (rc_25M),
        .global_arst_n_i (global_arst_n),
        .mod_rst_n_o     (mod_rst_n)
    );

endmodule
