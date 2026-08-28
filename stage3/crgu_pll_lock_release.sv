// 作者          : Codex
// 文件名        : crgu_pll_lock_release.sv
// 功能描述      : 对 PLL 域总复位同步释放后进行三周期限定，生成 PLL 域复位释放许可。

module crgu_pll_lock_release (
    input  logic       pll_clk_i,             // PLL 100 MHz 根时钟
    input  logic       global_arst_n_i,       // 全局异步复位，低有效
    input  logic       pll_lock_i,            // PLL 锁定指示，高有效且无异步抖动
    output logic       pll_rst_release_n_o    // PLL 域复位释放许可，低有效阻止释放
);

    localparam logic [1:0] PLL_LOCK_WAIT_CYCLES = 2'd3; // 两级同步释放后的等待周期数，总释放延迟为五周期

    logic       pll_arst_n;        // PLL 域总异步复位，低有效
    logic       pll_rst_sync_n;    // PLL 域同步释放后的复位，低有效
    logic [1:0] cnt_pll_lock_wait; // PLL 连续锁定周期计数器

    assign pll_arst_n = global_arst_n_i & pll_lock_i;

    sync_reset_n sync_reset_n_inst (
        .clk    (pll_clk_i),
        .rstn_a (pll_arst_n),
        .rstn_s (pll_rst_sync_n)
    );

    // ------------------------------------------------------------------------
    // PLL 锁定等待计数器：由 pll_100M 域同步释放后的复位清零。
    // ------------------------------------------------------------------------
    always_ff @(posedge pll_clk_i or negedge pll_rst_sync_n) begin
        if (!pll_rst_sync_n)
            cnt_pll_lock_wait <= 2'd0;
        else if (cnt_pll_lock_wait < PLL_LOCK_WAIT_CYCLES)
            cnt_pll_lock_wait <= cnt_pll_lock_wait + 1'b1;
    end

    // ------------------------------------------------------------------------
    // 释放许可：由 pll_100M 域同步释放后的复位清零；第 3 个连续锁定边沿后变高。
    // ------------------------------------------------------------------------
    always_ff @(posedge pll_clk_i or negedge pll_rst_sync_n) begin
        if (!pll_rst_sync_n)
            pll_rst_release_n_o <= 1'b0;
        else if (cnt_pll_lock_wait == PLL_LOCK_WAIT_CYCLES - 1'b1)
            pll_rst_release_n_o <= 1'b1;
        else
            pll_rst_release_n_o <= 1'b0;
    end

endmodule
