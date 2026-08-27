
module div_norounding #(
    parameter DIV_WIDTH1 = 39, //被除数位宽
    parameter DIV_WIDTH2 = 20 //除数位宽
)(
    input                         clk,
    input                         rst_n,
    input                         flag_valid, //输入数据有效信号
    input        [DIV_WIDTH1-1:0] A, //被除数
    input        [DIV_WIDTH2-1:0] B, //除数
    output logic                  flag_end, //输出数据有效信号
    output logic [DIV_WIDTH1-1:0] Q //商输出
);

localparam RG_B_WIDTH = DIV_WIDTH2 + 'd2; 
localparam CNT_WIDTH  = $clog2(DIV_WIDTH1) + 'd1; 
localparam END_CNT    = DIV_WIDTH1 + 'd1; 
localparam RG_P_WIDTH = DIV_WIDTH2 + 'd1; 

logic [CNT_WIDTH-1:0] cnt; //除数寄存器
logic [DIV_WIDTH1-1:0] rg_a; //除数寄存器
wire [RG_P_WIDTH:0] nxt_p;
logic [RG_P_WIDTH:0] rg_p;
logic [RG_P_WIDTH:0] rg_b;
logic flag_sub;
logic over;
logic busy;

assign Q = rg_a;
assign flag_end = over;
wire flag_a;

assign flag_a = ~nxt_p[RG_P_WIDTH]; //判断被除数是否大于除数，若大于则进行减法运算

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        flag_sub <= 1'b0;
    else if(flag_valid) 
        flag_sub <= 1'b1;
    else
        flag_sub <= ~nxt_p[RG_P_WIDTH];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        busy <= 1'b0;
    else if(flag_valid) 
        busy <= 1'b1;
    else if(cnt == END_CNT)
        busy <= 1'b0;
    else
        busy <= busy;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt <= {CNT_WIDTH{1'b0}};
    else if(flag_valid) 
        cnt <= 'd1;
    else if(cnt == END_CNT)
        cnt <= {CNT_WIDTH{1'b0}};
    else if(busy)
        cnt <= cnt + 'd1;
    else
        cnt <= {CNT_WIDTH{1'b0}};
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        over <= 1'b0;
    else if(cnt == DIV_WIDTH1)
        over <= 1'b1;
    else
        over <= 1'b0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rg_a <= {DIV_WIDTH1{1'b0}};
        rg_p <= {RG_P_WIDTH{1'b0}};
    end
    else if(flag_valid) begin
        rg_a <= {A[DIV_WIDTH1-2:0],1'b0};
        rg_p <= { {RG_P_WIDTH{1'b0}},A[DIV_WIDTH1-1] } ;
    end
    else if(cnt != 'd0) begin
        rg_a <= {rg_a[DIV_WIDTH1-2:0],flag_a};
        rg_p <= {nxt_p[DIV_WIDTH2:0],rg_a[DIV_WIDTH1-1]};
    end
    else begin
        rg_a <= rg_a;
        rg_p <= rg_p;           
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rg_b <= {RG_B_WIDTH{1'b0}};
    else if(flag_valid)
        rg_b <= {2'd0,B};
    else
        rg_b <= rg_b;
end

addsub#(
    .WIDTH1 ( RG_B_WIDTH ),
    .WIDTH2 ( RG_B_WIDTH ),  
    .WIDTH3 ( RG_B_WIDTH ) //WIDTH3=max(WIDTH1,WIDTH2)+1,这里没有加1有什么深意？
)u_div_addsub_inst(
    .a      ( rg_p      ),
    .b      ( rg_b      ),
    .cin    ( flag_sub  ),
    .co     ( nxt_p     )
);


endmodule