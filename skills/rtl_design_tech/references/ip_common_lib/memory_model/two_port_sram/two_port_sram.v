//Description:
//write side can only write,read side can only read
//can not write and read same addr at the same time
module two_port_sram#(
    parameter DATA_WIDTH = 32,
    parameter DATA_DEPTH = 256
)(
    input                             wclk,
    input                             we,
    input [$clog2(DATA_DEPTH)-1:0]    waddr,
    input [DATA_WIDTH-1:0]            data_in,
    
    input                             rclk,
    input                             re,
    input [$clog2(DATA_DEPTH)-1:0]    raddr,
    output reg [DATA_WIDTH-1:0]       data_out
);

reg [DATA_WIDTH-1:0]mem[DATA_DEPTH-1:0];

//memory write operations
always@(posedge wclk) begin
    if(we)
        mem[waddr] <= data_in;
end

//memory read operations
always@(posedge rclk) begin
    if(re)
        data_out <= mem[raddr];
end

endmodule