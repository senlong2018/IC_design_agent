
module clk_div_apb#(
    parameter WIDTH = 8,
    parameter CNT_RST = 0,
    parameter CLK_RST = 0
)(
    input clk,
    input rstn,
    input [WIDTH-1:0]div_dat,

    output clk_div_o,
    output clk_en
);

reg [WIDTH-1:0]div_cnt;
reg clk_div;
reg div_dat0;
wire nodiv_en;

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
    else if(div_cnt < (div_dat >> 1))
        clk_div <= CLK_RST;
    else
        clk_div <= ~CLK_RST;
end

//handle div_dat is 0 or 1
always @(posedge clk or negedge rstn) begin
    if(!rstn)
        div_dat0 <= 1'b1;
    else if(div_dat=='d0 || div_dat=='d1)
        div_dat0 <= 1'b1;
    else
        div_dat0 <= 1'b0;
end

assign nodiv_en = div_dat0;
assign clk_en = (div_cnt == {WIDTH{1'b0}});

clk_div_cell u_clk_div_cell(
    .clk      ( clk      ),
    .clk_div  ( clk_div  ),
    .nodiv_en ( nodiv_en ),
    .clk_div_o( clk_div_o  )
);


endmodule