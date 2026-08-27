
module clk_inv(
    input clk,
    output clk_inv_o
);

`ifdef FPGA
    assign clk_inv_o = !clk;
`else
    CLK_INV clk_inv_inst(
        .A(clk),
        .Q(clk_inv_o)
    );
`endif

endmodule