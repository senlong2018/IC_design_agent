module clk_div_omsp#(
    parameter WIDTH = 8,
    parameter CNT_RST = 0,
    parameter CLK_RST = 0
)(
    input scan_mode,
    input scan_rstn,
    input clk,
    input rstn,    
    input [WIDTH-1:0]div_dat,

    output clk_div_o
);

wire clk_div;
wire select;
wire clk_buf_o;

clk_div#(
    .WIDTH   ( WIDTH ),
    .CNT_RST ( CNT_RST ),
    .CLK_RST ( CLK_RST )
)clk_div_inst(
    .clk        ( clk      ),
    .rstn       ( rstn     ),
    .div_dat    ( div_dat  ),
    .clk_div_o  ( clk_div  )
);

assign select = !((div_dat==0) || (div_dat==1));
clk_buf clk_buf_inst(.clkin ( clk ),.clkout  ( clk_buf_o  ));


omsp_clock_mux u_omsp_clock_mux(
    .scan_mode ( scan_mode ),
    .scan_rstn ( scan_rstn ),
    .clk_in0   ( clk_buf_o ),    
    .clk_in1   ( clk_div   ),
    .resetn    ( rstn      ),
    .select    ( select    ),
    .clk_out   ( clk_div_o )
);


endmodule