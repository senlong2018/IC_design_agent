
module clk_div_odd_duty50#(
    parameter WIDTH = 8,
    parameter CLK_RST = 0
)(
    input clk,
    input rstn,
    input [WIDTH-1:0]div_dat,

    output clk_div_o
);

reg [WIDTH-1:0]div_cnt_pos;
reg [WIDTH-1:0]div_cnt_neg;
reg clk_div_pos;
reg clk_div_neg;

wire clk_inv;

clk_inv clk_inv_inst(.clk ( clk ),.clk_inv  ( clk_inv  ));

//counter in posedge
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        div_cnt_pos <= {WIDTH{1'b0}};
    else if(div_cnt_pos >= (div_dat - 'd1))
        div_cnt_pos <= {WIDTH{1'b0}};
    else
        div_cnt_pos <= div_cnt_pos + 'd1;
end

//clk_div_pos gen
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        clk_div_pos <= CLK_RST;
    else if(div_dat==0 || div_dat==1)
        clk_div_pos <= CLK_RST;
    else if(div_cnt_pos <= (div_dat >> 1))
        clk_div_pos <= CLK_RST;
    else
        clk_div_pos <= ~CLK_RST;
end


//counter in negedge
always @(posedge clk_inv or negedge rstn) begin
    if(!rstn)
        div_cnt_neg <= {WIDTH{1'b0}};
    else if(div_cnt_neg >= (div_dat - 'd1))
        div_cnt_neg <= {WIDTH{1'b0}};
    else
        div_cnt_neg <= div_cnt_neg + 'd1;
end

//clk_div_neg gen
always @(posedge clk_inv or negedge rstn) begin
    if(!rstn)
        clk_div_neg <= CLK_RST;
    else if(div_dat==0 || div_dat==1)
        clk_div_neg <= CLK_RST;
    else if(div_cnt_neg <= (div_dat >> 1))
        clk_div_neg <= CLK_RST;
    else
        clk_div_neg <= ~CLK_RST;
end

assign clk_div_o = clk_div_pos || clk_div_neg; //需要确认是 || 还是 &&

endmodule