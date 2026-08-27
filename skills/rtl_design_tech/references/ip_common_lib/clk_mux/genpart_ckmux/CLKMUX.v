module CLKMUX(
    input A,
    input B,
    input S,
    output Q
);

assign Q = S ? B : A;
endmodule