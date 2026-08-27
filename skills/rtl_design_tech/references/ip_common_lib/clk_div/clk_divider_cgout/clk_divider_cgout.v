module clk_divider_cgout#(
    parameter WIDTH = 10
)
(
    input clk,
    input rst_n,
    input [WIDTH-1:0]div_factor,
    input [WIDTH-1:0]div_phase,

    output wire div_clk,
    output reg div_en
);

reg [WIDTH-1:0]div_cnt;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        div_cnt[WIDTH-1:0] <= {(WIDTH){1'b0}};
    else if((div_cnt+1'b1) == div_factor)
        div_cnt[WIDTH-1:0] <= {(WIDTH){1'b0}};
    else
        div_cnt[WIDTH-1:0] <= div_cnt + 1'b1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        div_en <= 1'b0;
    else if(div_cnt==div_phase)
        div_en <= 1'b1;
    else    
        div_en <= 1'b0;
end

clk_gate u_cg_divider_n50duty(
    .E  (div_en),
    .SE (1'b0),
    .CK (clk),
    .ECK(div_clk)
);

endmodule