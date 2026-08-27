//时钟buffer模块
//一般用于给中后端定位时钟节点
module clk_buf (
    input       clkin,
    output logic clkout
);
    `ifdef FPGA
        assign clkout = clkin;
    `else
        BUFG bufg_inst (
            .I(clkin),
            .O(clkout)
        );
    `endif
endmodule