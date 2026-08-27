module clk_div_fixed#(
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

//counter
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        div_cnt <= CNT_RST;
    else if(div_cnt == div_dat - 'd1)
        div_cnt <= {WIDTH{1'b0}};
    else
        div_cnt <= div_cnt + 'd1;
end

//clk_div gen
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        clk_div <= CLK_RST;
    else if(div_dat==0 || div_dat==1)
        clk_div <= CLK_RST;
    else if(div_cnt < (div_dat >> 1))
        clk_div <= CLK_RST;
    else
        clk_div <= ~CLK_RST;
end

assign clk_div_o = clk_div;

endmodule