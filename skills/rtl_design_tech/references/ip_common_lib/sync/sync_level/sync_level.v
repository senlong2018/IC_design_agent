module sync_level#(
    parameter rstval_p = 0
)(
    input clk,
    input rstn,

    input data_in,
    output data_out
);

reg [1:0]data_sync;
always@(posedge clk or negedge rstn) begin
    if(!rstn)
        data_sync <= {2{rstval_p}};
    else
        data_sync <= {data_sync[0],data_in};
end

assign data_out = data_sync[1];

endmodule
