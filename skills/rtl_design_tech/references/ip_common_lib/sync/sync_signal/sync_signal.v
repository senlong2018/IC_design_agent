module sync_signal(
    input scan_mode,
    input scan_rstn,
    input clk1,
    input rst1n,
    input clk2,
    input rst2n,
    input pul1,
    output pul2
);

wire rstn_pre;
wire rstn;
wire rstn_sync1;
wire rstn_sync2;
wire rstn_sync1_scan;
wire rstn_sync2_scan;
reg togg;
assign rstn_pre = rst1n && rst2n;
assign rstn = scan_mode ? scan_rstn : rstn_pre;

sync_reset_n rstn_sync1_inst(
    .clk    ( clk1       ),
    .rstn_a ( rstn       ),
    .rstn_s ( rstn_sync1 )
);

sync_reset_n rstn_sync2_inst(
    .clk    ( clk2       ),
    .rstn_a ( rstn       ),
    .rstn_s ( rstn_sync2 )
);

assign rstn_sync1_scan = scan_mode ? scan_rstn : rstn_sync1;
assign rstn_sync2_scan = scan_mode ? scan_rstn : rstn_sync2;

always@(posedge clk1 or negedge rstn_sync1_scan) begin
    if(!rstn_sync1_scan)
        togg <= 1'b0;
    else 
        togg <= pul1 ? !togg : togg;
end

genpart_sync#(
    .edge_type_p      ( 2'h3 ),
    .rstval_p         ( 1'b0 )
)u_sync_togg(
    .clk_i            ( clk2             ),
    .rst_an_i         ( rstn_sync2_scan  ),
    .d_i              ( togg             ),
    .q_o              (                  ),
    .edge_o           ( pul2             )
);


endmodule