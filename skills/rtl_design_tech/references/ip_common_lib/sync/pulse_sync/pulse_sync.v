//src_sig must be a signal pulse
module pulse_sync(
    input  scan_mode,
    input  scan_rstn,
    input  src_clk,
    input  src_rstn,
    input  dst_clk,
    input  dst_rstn,
    input  src_sig,
    output dst_sig
);

reg src_sig_d;
wire dst_sig_sync;
reg dst_sig_sync_d;
wire ack_from_dst;
wire rstn_pre = src_rstn & dst_rstn;
wire rstn = scan_mode ? scan_rstn : rstn_pre;

wire rstn_sync_src;
wire rstn_sync_dst;

sync_reset_n sync_src(
    .clk    ( src_clk       ),
    .rstn_a ( rstn          ),
    .rstn_s ( rstn_sync_src )
);

sync_reset_n sync_dst(
    .clk    ( dst_clk       ),
    .rstn_a ( rstn          ),
    .rstn_s ( rstn_sync_dst )
);

wire rstn_sync_src_scan = scan_mode ? scan_rstn : rstn_sync_src;
wire rstn_sync_dst_scan = scan_mode ? scan_rstn : rstn_sync_dst;

always@(posedge src_clk or negedge rstn_sync_src_scan)begin
    if(!rstn_sync_src_scan)
        src_sig_d <= 1'b0;
    else if(ack_from_dst)
        src_sig_d <= 1'b0;
    else if(src_sig)
        src_sig_d <= 1'b1;
end

sync_level u_dst_sig_sync(
    .clk       ( dst_clk            ),
    .rstn      ( rstn_sync_dst_scan ),
    .data_in   ( src_sig_d          ),
    .data_out  ( dst_sig_sync       )
);

always@(posedge dst_clk or negedge rstn_sync_dst_scan) begin
    if(!rstn_sync_dst_scan)
        dst_sig_sync_d <= 1'b0;
    else
        dst_sig_sync_d <= dst_sig_sync;
end

sync_level u_ack_from_dst_sync(
    .clk       ( src_clk            ),
    .rstn      ( rstn_sync_src_scan ),
    .data_in   ( dst_sig_sync       ),
    .data_out  ( ack_from_dst       )
);

assign dst_sig = dst_sig_sync && !dst_sig_sync_d;


endmodule