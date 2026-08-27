//use clk_gt to save power,clk_gt can sample togg for sure,because clk_gt will delay 2 clk2 cycle 
//sync_signal_reuse have no delay

module sync_complex_signal#(
    parameter PUL_WIDTH = 1
)(
    input scan_mode,
    input scan_enable,
    input scan_rstn,
    input clk1,
    input rst1n,
    input clk2,
    input rst2n,
    input [PUL_WIDTH-1:0]pul1,
    output [PUL_WIDTH-1:0]pul2
);

wire rstn_pre;
wire rstn;
wire rstn_sync1;
wire rstn_sync2;
wire rstn_sync1_scan;
wire rstn_sync2_scan;
reg [PUL_WIDTH-1:0]togg;

wire pul1_clk;
reg togg_gate;
reg togg_gate_sync;
wire pul2_clk;
reg pul2_clk_dly;
wire clk2_gate_en;
wire clk2_gt;

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

//add clock gate to clk2 to save power

assign pul1_clk = |pul1;
always@(posedge clk1 or negedge rstn_sync1_scan) begin
    if(!rstn_sync1_scan)
        togg_gate <= 1'b0;
    else if(pul1_clk)
        togg_gate <= !togg_gate;
end


genpart_sync#(
    .edge_type_p      ( 2'h3 ),
    .rstval_p         ( 1'b0 )
)genpart_sync_togg_gate(
    .clk_i            ( clk2            ),
    .rst_an_i         ( rstn_sync2_scan ),
    .d_i              ( togg_gate       ),
    .q_o              ( togg_gate_sync  ),
    .edge_o           ( pul2_clk        )
);

always@(posedge clk2 or negedge rstn_sync2_scan) begin
    if(!rstn_sync2_scan)
        pul2_clk_dly <= 1'b0;
    else
        pul2_clk_dly <= pul2_clk;
end 

assign clk2_gate_en = pul2_clk || pul2_clk_dly;

clk_gate clk_gate_clk2_gt(
    .E    ( clk2_gate_en ),
    .SE   ( scan_enable  ),
    .CK   ( clk2         ),
    .ECK  ( clk2_gt      )
);

reg [PUL_WIDTH-1:0]togg_d0;
reg [PUL_WIDTH-1:0]togg_d1;

genvar i;
generate
for(i=0; i<PUL_WIDTH; i=i+1) begin:togg_inst
    always@(posedge clk1 or negedge rstn_sync1_scan) begin
        if(!rstn_sync1_scan)
            togg[i] <= 1'b0;
        else 
            togg[i] <= pul1[i] ? !togg[i] : togg[i];
    end
    
    //clk_gt can sample togg for sure,because clk_gt will delay 2 clk2 cycle
    always@(posedge clk2_gt or negedge rstn_sync2_scan) begin
        if(!rstn_sync2_scan)
            togg_d0[i] <= 1'b0;
        else
            togg_d0[i] <= togg[i];
    end

    always@(posedge clk2_gt or negedge rstn_sync2_scan) begin
        if(!rstn_sync2_scan)
            togg_d1[i] <= 1'b0;
        else
            togg_d1[i] <= togg_d0[i];
    end

assign pul2[i] = togg_d0[i] ^ togg_d1[i];
end

endgenerate

endmodule