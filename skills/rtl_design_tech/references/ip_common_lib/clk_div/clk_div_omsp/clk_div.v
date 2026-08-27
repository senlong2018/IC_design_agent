module clk_div#(
    parameter WIDTH = 8,
    parameter CNT_RST = 0,
    parameter CLK_RST = 0
)(
    input clk,
    input rstn,
    input [WIDTH-1:0]div_dat,

    output clk_div_o
);

reg [WIDTH-1:0]div_cnt;
reg clk_div;

wire [WIDTH-1:0]div_dat_real;
assign div_dat_real = (div_dat==0 || div_dat==1) ? 'd2 : div_dat;

//counter
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        div_cnt <= CNT_RST;
    else if(div_cnt >= (div_dat - 'd1))
        div_cnt <= {WIDTH{1'b0}};
    else
        div_cnt <= div_cnt + 'd1;
end

//clk_div gen
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        clk_div <= CLK_RST;
    else if(div_cnt < (div_dat_real >> 1)) 
        clk_div <= CLK_RST; //clk_div output delay about 3 clk when rstn release
    else                 //if clk_div <= ~CLK_RST, then clk_div will delay about 1 clk when rstn release
        clk_div <= ~CLK_RST;
end

clk_buf clk_buf_inst(.clkin ( clk_div ),.clkout  ( clk_div_o  ));

endmodule