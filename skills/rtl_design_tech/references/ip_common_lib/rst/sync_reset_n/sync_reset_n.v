module sync_reset_n(
  input clk,
  input rstn_a,
  output wire rstn_s
);
  reg [1:0]data_sync;
  always@(posedge clk or negedge rstn_a)
  begin
    if(~rstn_a)
      data_sync <= 2'b00;
    else
       data_sync <= {data_sync[0],1'b1};
  end

  assign rstn_s = data_sync[1];
endmodule
