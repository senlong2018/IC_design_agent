//clk_wr and clk_rd must be sync clk
//clk_rd must ca sample wr_addr,means din_valid can be valid only once
module ping_pong_buffer#(
    parameter DATA_WIDTH = 12
)
(
    input clk_wr,
    input rstn_wr,
    input [DATA_WIDTH-1:0]din,
    input din_valid,

    input clk_rd,
    input rstn_rd,
    output logic [DATA_WIDTH-1:0]dout,
    output logic dout_valid
);

logic [DATA_WIDTH-1:0]buffer0;
logic [DATA_WIDTH-1:0]buffer1;
logic wr_addr;
logic rd_addr;

always @(posedge clk_wr or negedge rstn_wr) begin
    if(!rstn_wr)
        wr_addr <= 1'b0;
    else if(din_valid)
        wr_addr <= !wr_addr;
end

always @(posedge clk_wr or negedge rstn_wr) begin
    if(!rstn_wr)
        buffer0 <= {(DATA_WIDTH){1'b0}};
    else if(din_valid && !wr_addr)
        buffer0 <= din;
end

always @(posedge clk_wr or negedge rstn_wr) begin
    if(!rstn_wr)
        buffer1 <= {(DATA_WIDTH){1'b0}};
    else if(din_valid && wr_addr)
        buffer1 <= din;
end

logic read_enable;
logic wr_addr_d;
always @(posedge clk_rd or negedge rstn_rd) begin
    if(!rstn_rd)
        wr_addr_d <= 1'b0;
    else
        wr_addr_d <= wr_addr;
end

assign read_enable = wr_addr ^ wr_addr_d;

always @(posedge clk_rd or negedge rstn_rd) begin
    if(!rstn_rd)
        rd_addr <= 1'b0;
    else if(read_enable)
        rd_addr <= !rd_addr;
end


always @(posedge clk_rd or negedge rstn_rd) begin
    if(!rstn_rd)
        dout <= {DATA_WIDTH{1'b0}};
    else if(read_enable && !rd_addr)
        dout <= buffer0;
    else if(read_enable && rd_addr)
        dout <= buffer1;
end

always @(posedge clk_rd or negedge rstn_rd) begin
    if(!rstn_rd)
        dout_valid <= 1'b0;
    else 
        dout_valid <= read_enable;
end

endmodule