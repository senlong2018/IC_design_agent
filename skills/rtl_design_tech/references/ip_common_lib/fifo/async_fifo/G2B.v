module G2B#(
    parameter WIDTH = 3
)
(
    input [WIDTH-1:0]din,
    output [WIDTH-1:0]dout
);
    genvar i;
generate
    for(i=0;i<WIDTH;i=i+1) begin : GRAY2BIN
        assign dout[i] = ^{din[WIDTH-1:i]};
    end
endgenerate
endmodule