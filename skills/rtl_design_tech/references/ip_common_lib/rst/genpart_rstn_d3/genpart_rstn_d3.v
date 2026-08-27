module genpart_rstn(
  input clk       ,
  input rstn_i    ,
  input sw_reset  ,
  input scan_rstn ,
  input scan_mode ,
  output rstn_o   
);
  wire rstn_initial_src;
  wire rstn_initial_scan;
  wire rstn_sync;

assign rstn_initial_src = rstn_i && ~(sw_reset);

genpart_ckmux rstn_src_mux_inst(
  .clkin0(rstn_initial_src     ),
  .clkin1(scan_rstn            ),
  .sel   (scan_mode            ),
  .clkout(rstn_initial_scan    )
);

sync_reset_n_d3 resetn_source_inst(
  .clk   (clk              ),
  .rstn_a(rstn_initial_scan),
  .rstn_s(rstn_sync        )
);

genpart_ckmux rstn_mux_inst(
  .clkin0(rstn_sync       ),
  .clkin1(scan_rstn       ),
  .sel   (scan_mode       ),
  .clkout(rstn_o          )
);

endmodule
