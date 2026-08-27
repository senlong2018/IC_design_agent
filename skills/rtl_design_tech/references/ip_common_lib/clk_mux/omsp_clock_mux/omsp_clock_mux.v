module omsp_clock_mux(
    input scan_mode,
    input scan_rstn,

    input clk_in0,
    input clk_in1,
    input resetn,

    input select,
    output clk_out
);

wire rstn_clk0;
wire rstn_clk1;

genpart_rstn genpart_rstn_rstn_clk0(
    .clk        ( clk_in0    ),
    .rstn_i     ( resetn     ),
    .sw_reset   ( 1'b0       ),  //1:reset  0:not reset
    .scan_rstn  ( scan_rstn  ),
    .scan_mode  ( scan_mode  ),
    .rstn_o     ( rstn_clk0  )
);

genpart_rstn genpart_rstn_rstn_clk1(
    .clk        ( clk_in1    ),
    .rstn_i     ( resetn     ),
    .sw_reset   ( 1'b0       ),  //1:reset  0:not reset
    .scan_rstn  ( scan_rstn  ),
    .scan_mode  ( scan_mode  ),
    .rstn_o     ( rstn_clk1  )
);

reg in0_select_s,in0_select_ss;
reg in1_select_s,in1_select_ss;
wire in0_select;
wire in1_select;
wire in0_enable;
wire in1_enable;
wire clk_in0_inv;
wire clk_in1_inv;

//complex feedback logic
always@(posedge clk_in0_inv or negedge rstn_clk0) begin
    if(!rstn_clk0)
        in0_select_s <= 1'b0;
    else
        in0_select_s <= in0_select;        
end

always@(posedge clk_in0 or negedge rstn_clk0) begin
    if(!rstn_clk0)
        in0_select_ss <= 1'b0;
    else
        in0_select_ss <= in0_select_s;        
end
assign in1_select = !in0_select_ss && select;

always@(posedge clk_in1_inv or negedge rstn_clk1) begin
    if(!rstn_clk1)
        in1_select_s <= 1'b0;
    else
        in1_select_s <= in1_select;
end

always@(posedge clk_in1 or negedge rstn_clk1) begin
    if(!rstn_clk1)
        in1_select_ss <= 1'b0;
    else
        in1_select_ss <= in1_select_s;
end
assign in0_select = !in1_select_ss && !select;

//final clk_out

assign in0_enable = in0_select_ss || scan_mode;
assign in1_enable = in1_select_ss && !scan_mode;


`ifdef FPGA
    BUFGCTRL #(
        .INIT_OUT(0),
        .PRESELECT_I0("FALSE"),
        .PRESELECT_I1("FALSE")
    )
    dtc_clk_tmux_pre(
        .O(clk_out),
        .CE0(1'b1),
        .CE1(1'b1),
        .I0(clk_in0),
        .I1(clk_in1),
        .IGNORE0(1'b1),
        .IGNORE1(1'b1),        
        .S0(~select),
        .S1(select)
    );

`else
    wire clk_out_pre;
    wire clk_in0_inv_p,clk_in1_inv_p;
    wire clk_out_p;
    wire gated_clk_in0;
    wire gated_clk_in1;

    inv_cell inv_cell_u0(.in(clk_in0),.out(clk_in0_inv_p));
    inv_cell inv_cell_u1(.in(clk_in1),.out(clk_in1_inv_p));

    nand2_cell nand2_cell_u0(.in0(clk_in0_inv),.in1(in0_enable),.out(gated_clk_in0));
    nand2_cell nand2_cell_u1(.in0(clk_in1_inv),.in1(in1_enable),.out(gated_clk_in1));

    and2_cell and2_cell_u0(.in0(gated_clk_in0),.in1(gated_clk_in1),.out(clk_out_pre));
    buffer_cell buffer_cell_u0(.in(clk_out_pre),.out(clk_out_p));

    mux2_cell mux2_cell_u0(.in0(clk_in0_inv_p),.in1(clk_in0),.sel(scan_mode),.out(clk_in0_inv));
    mux2_cell mux2_cell_u1(.in0(clk_in1_inv_p),.in1(clk_in1),.sel(scan_mode),.out(clk_in1_inv));
    mux2_cell mux2_cell_u2(.in0(clk_out_p),.in1(clk_in0),.sel(scan_mode),.out(clk_out));

`endif

endmodule