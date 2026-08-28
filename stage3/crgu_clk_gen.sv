// 作者          : Codex
// 文件名        : crgu_clk_gen.sv
// 功能描述      : 为八个固定时钟域生成独立的 FPGA 门控时钟。

module crgu_clk_gen (
    input  logic       pll_100m_i,    // 100 MHz PLL 根时钟
    input  logic       pll_lock_i,    // PLL 锁定指示，高有效
    input  logic       rc_25m_i,      // 25 MHz RC 根时钟
    input  logic [7:0] mod_clk_en_i,  // 各模块静态功能门控使能，高有效
    input  logic       scan_en_i,     // 扫描门控旁路使能，高有效
    output logic [7:0] mod_clk_o      // 八路门控后的模块时钟
);

    logic [3:0] pll_func_en; // 0 至 3 号模块的 PLL 功能门控使能
    logic [3:0] pll_scan_en; // 0 至 3 号模块的 PLL 扫描门控使能
    logic [3:0] rc_func_en;  // 4 至 7 号模块的 RC 功能门控使能
    logic [3:0] rc_scan_en;  // 4 至 7 号模块的 RC 扫描门控使能

    assign pll_func_en = mod_clk_en_i[3:0] & {4{pll_lock_i}};
    assign pll_scan_en = {4{scan_en_i & pll_lock_i}};
    assign rc_func_en  = mod_clk_en_i[7:4];
    assign rc_scan_en  = {4{scan_en_i}};

    // ------------------------------------------------------------------------
    // PLL 时钟域：pll_lock 同时约束功能与扫描门控，禁止失锁时开钟。
    // ------------------------------------------------------------------------
    genvar pll_idx;
    generate
        for (pll_idx = 0; pll_idx < 4; pll_idx = pll_idx + 1) begin : gen_pll_clk_gate
            clk_gate clk_gate_inst (
                .E   (pll_func_en[pll_idx]),
                .SE  (pll_scan_en[pll_idx]),
                .CK  (pll_100m_i),
                .ECK (mod_clk_o[pll_idx])
            );
        end
    endgenerate

    // ------------------------------------------------------------------------
    // RC 时钟域：扫描模式旁路功能门控。
    // ------------------------------------------------------------------------
    genvar rc_idx;
    generate
        for (rc_idx = 0; rc_idx < 4; rc_idx = rc_idx + 1) begin : gen_rc_clk_gate
            clk_gate clk_gate_inst (
                .E   (rc_func_en[rc_idx]),
                .SE  (rc_scan_en[rc_idx]),
                .CK  (rc_25m_i),
                .ECK (mod_clk_o[rc_idx + 4])
            );
        end
    endgenerate

endmodule
