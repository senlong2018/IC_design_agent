//req_flag : 8'b1100_0011,1:participate compare  0:do not participate compare
//time_win : a martix DATA_NUM x DATA_WIDTH
//time_flag: indicate index of min num,if more than 1 value are equal,then small index will pull up
//for example:
//        time_win    req_flag   time_flag
// [0]        D         1         low
// [1]        B         1         low
// [2]        C         1         low
// [3]        E         1         low
// [4]        A         1         high
// [5]        F         1         low
// [6]        A         1         low
// [7]        B         1         low


module compare_min_index#(
    parameter DATA_NUM   = 8,
    parameter DATA_WIDTH = 4
)(
    input [DATA_NUM-1:0]   req_flag,
    input [DATA_WIDTH-1:0] time_win[0:DATA_NUM-1],
    output [DATA_NUM-1:0]  time_flag
);

wire [DATA_NUM-1:0] digit      [0:DATA_WIDTH-1];
wire [DATA_NUM-1:0] value_flag [0:DATA_WIDTH-1];

genvar row;
genvar column;
generate
    for(row = 0; row < DATA_WIDTH; row++) begin:row_inst
        for(column = 0; column < DATA_NUM; column++) begin:column_inst
            assign digit[row][column] = time_win[column][row];
        end
    end
endgenerate

assign value_flag[DATA_WIDTH-1] = (((~req_flag)|digit[DATA_WIDTH-1]) == {DATA_NUM{1'b1}}) ? req_flag : ~((~req_flag)|digit[DATA_WIDTH-1]);

genvar i;
generate
    for(i=0;i<DATA_WIDTH-1;i++) begin:value_flag_inst
        assign value_flag[i] = (((~value_flag[i+1]) | digit[i])=={DATA_NUM{1'b1}}) ? value_flag[i+1]:~((~value_flag[i+1]) | digit[i]);
    end
endgenerate

genvar j;
generate
    for(j=1;j<DATA_NUM;j++) begin:time_flag_inst
        assign time_flag[j] = value_flag[0][j] & (~(|value_flag[0][j-1:0]));
    end
endgenerate

assign time_flag[0] = value_flag[0][0];
endmodule