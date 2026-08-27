
module addsub #(
    parameter WIDTH1 = 25,
    parameter WIDTH2 = 25,
    parameter WIDTH3 = 26 //WIDTH3=max(WIDTH1,WIDTH2)+1,防止加减法结果溢出
)(
    input        [WIDTH1-1:0] a, //被加数/被减数
    input        [WIDTH2-1:0] b, //加数/减数
    input                     cin, //进位输入，cin=0为加法，cin=1为减法
    output logic [WIDTH3-1:0] co //和/差输出
);
    wire [WIDTH2-1:0] tp_b; 
    assign tp_b = cin ? ~b : b; //若为减法，则将减数取反
    assign co = a + tp_b + cin; //加法/减法运算

endmodule