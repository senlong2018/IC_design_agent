//Attention ! sel is static
module genpart_ckmux2(
    input clkin0,
    input clkin1,
    input sel   ,
    output clkout
);

`ifdef FPGA
    assign clk_out = sel ? clkin1 : clkin0;
`else
    CLKMUX clk_mux_inst(
        .A(clkin0),
        .B(clkin1),
        .S(sel   ),
        .Q(clkout)
    );
`endif

endmodule

module genpart_ckmux3(
    input clkin0,
    input clkin1,
    input clkin2,
    input [1:0]sel   ,
    output clkout
);

`ifdef FPGA
    assign clkout = (sel==2'b00) ? clkin0 : 
                     (sel==2'b01) ? clkin1 :
                                    clkin2 ;
`else
    wire int_clkout0_1;
    CLKMUX clk_mux_inst0(
        .A(clkin0),
        .B(clkin1),
        .S(sel[0]   ),
        .Q(int_clkout0_1)
    );
    CLKMUX clk_mux_inst1(
        .A(int_clkout0_1),
        .B(clkin2),
        .S(sel[1]   ),
        .Q(clkout)
    );    
`endif

endmodule

module genpart_ckmux4(
    input clkin0     ,
    input clkin1     ,
    input clkin2     ,
    input clkin3     ,
    input [1:0]sel   ,
    output clkout    
);

`ifdef FPGA
    assign clk_out = (sel==2'b00) ? clkin0 : 
                     (sel==2'b01) ? clkin1 :
                     (sel==2'b10) ? clkin2 :
                                    clkin3 ;
`else
    wire int_clkout0_1;
    wire int_clkout2_3;

    CLKMUX clk_mux_inst0(
        .A(clkin0       ),
        .B(clkin1       ),
        .S(sel[0]       ),
        .Q(int_clkout0_1)
    );

    CLKMUX clk_mux_inst1(
        .A(clkin2       ),
        .B(clkin3       ),
        .S(sel[0]       ),
        .Q(int_clkout2_3)
    );

    CLKMUX clk_mux_inst2(
        .A(int_clkout0_1),
        .B(int_clkout2_3),
        .S(sel[1]       ),
        .Q(clk_out      )
    );

`endif

endmodule