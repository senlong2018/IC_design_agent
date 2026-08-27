
module sp_sram#(
    parameter write_throuth = 0,
    parameter depth_p       = 16,
    parameter width_p       = 8
)
(
    input                      clk_i,
    input [$clog2(depth_p)-1:0]addr_i,
    input [width_p-1:0]        wdata_i,
    input                      ena_i,
    input                      wean_i,
    output reg [width_p-1:0]   rdata_o
);

parameter addrwidth_p   = $clog2(depth_p);

reg [width_p-1:0] mem [depth_p-1:0];
always@(posedge clk_i) begin
    if(ena_i) begin
        if(wean_i)begin
            mem[addr_i] <= wdata_i;
            if(write_throuth==1)
                rdata_o <= wdata_i;
        end
        else
            rdata_o     <= mem[addr_i];
    end
end

endmodule