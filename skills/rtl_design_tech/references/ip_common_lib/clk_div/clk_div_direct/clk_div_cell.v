module clk_div_cell(
    input clk,
    input clk_div,
    input nodiv_en,
    output clk_div_o
);

wire dtc_clk_div_buf;

`ifdef FPGA
    assign clk_div_o = nodiv_en ? clk : clk_div;
`else
    CLK_BUF clk_div_buf(.A(clk_div),.Q(dtc_clk_div_buf));
    CLK_MUX divck_o_buf(.A(dtc_clk_div_buf),.B(clk),.S(nodiv_en),.Q(clk_div_o));
`endif

endmodule