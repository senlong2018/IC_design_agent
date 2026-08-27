module memory_wrapper#(
    parameter write_throuth = 0,
    parameter DEPTH = 32,
    parameter WIDTH = 36
)
(
    input                    clk,
    input [$clog2(DEPTH)-1:0]addr,
    input [WIDTH-1:0]        data_in,
    input                    ce,
    input                    we,
    output logic [WIDTH-1:0] data_out
);

`ifdef FPGA
sp_sram#(
    .write_throuth       ( write_throuth  ),
    .depth_p             ( DEPTH          ),
    .width_p             ( WIDTH          )
)sp_sram_inst(
    .clk_i               ( clk        ),
    .addr_i              ( addr       ),
    .wdata_i             ( data_in    ),
    .ena_i               ( ce         ),
    .wean_i              ( we         ),
    .rdata_o             ( data_out   )
);

`else
//VENDOR SP sram model instinate here.
`endif
endmodule