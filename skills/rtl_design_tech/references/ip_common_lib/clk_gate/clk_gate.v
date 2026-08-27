

module clk_gate(
    input E,
    input SE,
    input CK,
    output ECK
);
`ifdef FPGA
    wire en_in = SE | E;
    reg latch_en;
    always@(*) begin
        if(CK==1'b0) latch_en = en_in;
    end
    assign ECK = CK & latch_en;

`else
    CLK_GATE u_clk_gate(.E(E),.SE(SE),.CK(CK),.ECK(ECK));
`endif
endmodule