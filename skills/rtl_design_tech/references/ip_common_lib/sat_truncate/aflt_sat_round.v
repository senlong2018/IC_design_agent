module aflt_sat_round#(
    parameter DI_W = 32,
    parameter DI_F = 29,
    parameter DQ_W = 24,
    parameter DQ_F = 23
)
(
    input [DI_W-1:0] di,
    output [DQ_W-1:0] dq
);

localparam ROUND_W = DI_W-DI_F+DQ_F;
wire round_bit;
wire [ROUND_W-1:0]di_round;

assign round_bit = (di[DI_W-1:DI_F-DQ_F]=={1'b0,{(ROUND_W-1){1'b1}}}) ? 1'b0 : 
                    di[DI_W-1] ? (di[DI_F-DQ_F-1] & (|di[DI_F-DQ_F-2:0])) : di[DI_F-DQ_F-1];

assign di_round  = {di[DI_W-1:DI_W-ROUND_W]} + round_bit;

assign dq = (di_round[ROUND_W-1:DQ_W-1] == {(ROUND_W-DQ_W+1){1'b0}} || di_round[ROUND_W-1:DQ_W-1] == {(ROUND_W-DQ_W+1){1'b1}}) ? di_round[DQ_W-1:0] : 
{di_round[ROUND_W-1],{(DQ_W-1){~di_round[ROUND_W-1]}}};

endmodule