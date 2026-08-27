module dpram_blk#(
    parameter MEM_WIDTH = 16,
    parameter MEM_DEPTH = 64
)
(
    input                        wclk ,
    input                        we   ,
    input [$clog2(MEM_DEPTH)-1:0]waddr,
    input [MEM_WIDTH        -1:0]wdata,

    input                        rclk ,
    input                        re   ,
    input [$clog2(MEM_DEPTH)-1:0]raddr,
    output logic  [MEM_WIDTH-1:0]rdata
);

logic [MEM_WIDTH-1:0]mem[MEM_DEPTH-1:0];

always@(posedge wclk)begin
    if(we)
        mem[waddr] <= wdata;
end

logic  [MEM_WIDTH-1:0]rdata_d0;
logic  [MEM_WIDTH-1:0]rdata_d1;

always@(posedge rclk)begin
    if(re)
        rdata_d0 <= mem[raddr];
end

always@(posedge rclk)begin
    rdata_d1 <= rdata_d0;
end

always@(posedge rclk)begin
    rdata <= rdata_d1;
end

endmodule