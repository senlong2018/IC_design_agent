// 作者          : Codex
// 文件名        : crgu_rst_gen.sv
// 功能描述      : 为八个固定时钟域生成异步断言、同步释放的本地复位。

module crgu_rst_gen (
    input  logic       pll_100m_i,       // 100 MHz PLL 根时钟
    input  logic       pll_lock_i,       // PLL 锁定指示，高有效
    input  logic       rc_25m_i,         // 25 MHz RC 根时钟
    input  logic       global_arst_n_i,  // 全局异步复位，低有效
    output logic [7:0] mod_rst_n_o       // 八路模块本地复位，低有效
);

    // ------------------------------------------------------------------------
    // PLL 时钟域：每路独立等待 PLL 连续锁定，并在第 5 个时钟边沿后释放复位。
    // ------------------------------------------------------------------------
    genvar pll_idx;
    generate
        for (pll_idx = 0; pll_idx < 4; pll_idx = pll_idx + 1) begin : gen_pll_rst
            crgu_pll_lock_release crgu_pll_lock_release_inst (
                .pll_clk_i           (pll_100m_i),
                .global_arst_n_i     (global_arst_n_i),
                .pll_lock_i          (pll_lock_i),
                .pll_rst_release_n_o (mod_rst_n_o[pll_idx])
            );
        end
    endgenerate

    // ------------------------------------------------------------------------
    // RC 时钟域：每路使用 RC 根时钟完成本地复位同步释放。
    // ------------------------------------------------------------------------
    genvar rc_idx;
    generate
        for (rc_idx = 0; rc_idx < 4; rc_idx = rc_idx + 1) begin : gen_rc_rst
            sync_reset_n sync_reset_n_inst (
                .clk    (rc_25m_i),
                .rstn_a (global_arst_n_i),
                .rstn_s (mod_rst_n_o[rc_idx + 4])
            );
        end
    endgenerate

endmodule
