module sync_level_multi#(
    parameter WIDTH = 2,
    parameter rstval_p = 0
)(
    input scan_enable,
    input clk,
    input rstn,

    input data_in,
    output data_out
);
wire sync_en_pre;
wire sync_en;
wire clk_gt;
assign sync_en_pre = |(data_in ^ data_out);

sync_level sync_level_inst(
    .clk(clk),
    .rstn(rstn),
    .data_in(sync_en_pre),
    .data_in(sync_en)
);

clk_gate clk_gate_inst(
    .E  ( sync_en  ),
    .SE ( scan_enable ),
    .CK ( clk ),
    .ECK  ( clk_gt  )
);

genvar i;
generate
for(i=0; i<WIDTH; i=i+1) begin:sync_blk
    sync_level#( .rstval_p(rstval_p) 
    )sync_level_inst(
        .clk(clk_gt),
        .rstn(rstn),        
        .data_in(data_in[i]),
        .data_out(data_out[i])
    );  
end
endgenerate


endmodule
