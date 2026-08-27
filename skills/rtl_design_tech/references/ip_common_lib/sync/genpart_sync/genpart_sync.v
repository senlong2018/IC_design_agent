module genpart_sync#(
 parameter  [1:0]edge_type_p = 2'h0,
 parameter       rstval_p    = 1'b0
)(
  input clk_i,
  input rst_an_i,
  input d_i,
  output q_o,
  output reg edge_o
);

`include "time_def.vh"
  reg firststage_sync_line_r;
  reg sync_line_r;
  wire d_s;
  assign d_s = d_i;

  always@(posedge clk_i or negedge rst_an_i) begin:proc_sync
    if(rst_an_i == 1'b0) begin
      firststage_sync_line_r <= #`dly {rstval_p};
      sync_line_r            <= #`dly {rstval_p};
    end else begin
      firststage_sync_line_r <= #`dly d_s;
      sync_line_r            <= #`dly firststage_sync_line_r;
    end
  end

  assign q_o =  sync_line_r;

  //Edge Detection
  wire q_s;
  reg  q_r;
  assign q_s = sync_line_r;
  
  always@(posedge clk_i or negedge rst_an_i) begin:proc_stage
    if(rst_an_i == 1'b0) begin
      q_r <= #`dly {rstval_p};
    end else begin
      q_r <= #`dly q_s;
    end
  end

  always@(*) begin:proc_edge
    case(edge_type_p)
      2'd3:edge_o = q_r ^ q_s; //any edge
      2'd2:edge_o = q_r & ~q_s; //falling edge
      2'd1:edge_o = ~q_r & q_s; //rising edge
      default:edge_o = 1'b0; //no egde
    endcase
  end

endmodule
