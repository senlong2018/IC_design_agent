module B2G#(
    parameter WIDTH = 3
)
(
    input [WIDTH-1:0]din,
    output reg [WIDTH-1:0]dout
);

always@(*) begin
    dout = (din>>1) ^ din;
end

endmodule