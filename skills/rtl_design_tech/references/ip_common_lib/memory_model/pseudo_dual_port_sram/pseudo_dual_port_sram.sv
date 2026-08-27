module pseudo_dual_port_sram#(
    parameter write_throuth = 0,
    parameter WIDTH = 8,
    parameter DEPTH = 1024
)(
    input                    clk2x, //2x frequency,clk2x = 2*clk1x
    input                    wea,   //write enable,low active,from clk1x
    input [$clog2(DEPTH)-1:0]aa,    //write addr,from clk1x
    input [WIDTH-1:0]        d,     //write data,from clk1x

    input                    reb,   //read enable,low active,from clk1x
    input [$clog2(DEPTH)-1:0]ab,    //read addr,from clk1x
    output logic [WIDTH-1:0] q      //read data,from clk1x
);

logic [$clog2(DEPTH)-1:0] addr;
logic [WIDTH-1:0]         data_in;
logic ce;
logic we;

logic [WIDTH-1:0]data_out;
logic wr_rd_collision;
logic only_rd;
logic wa_cnt;

assign only_rd = wea && !reb;
assign wr_rd_collision = !wea && !reb;

always@(posedge clk2x) begin
    if(!wea)
        wa_cnt <= wa_cnt + 'd1;
    else
        wa_cnt <= 'd0;
end

always@(*)begin
    we = (wa_cnt=='d1); //write always be second
end

always@(*) begin
    if(wr_rd_collision || only_rd)
        ce = 1'b0;
    else if(wa_cnt=='d1)
        ce = 1'b0;          //sp sram work when cs=0
    else
        ce = 1'b1;
end

assign addr = we ? aa : ab;
assign data_in = d;
always@(posedge clk2x)begin
    q <= data_out;
end


memory_wrapper#(
    .write_throuth   ( write_throuth ),
    .DEPTH           ( DEPTH         ),
    .WIDTH           ( WIDTH         )
)memory_wrapper_inst(
    .clk             ( clk2x           ),
    .addr            ( addr            ),
    .data_in         ( data_in         ),
    .ce              ( ce              ),
    .we              ( we              ),
    .data_out        ( data_out        )
);


endmodule