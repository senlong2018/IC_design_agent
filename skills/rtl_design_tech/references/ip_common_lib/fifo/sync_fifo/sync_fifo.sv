module sync_fifo#(
    parameter DW    = 4,    
    parameter DEPTH = 128,
    parameter REG_OUT = 0
)
(
    input                         aclk,
    input                         arst_n,
    input                         clr_i,

    input                         din_req,
    input [DW-1:0]                data_i,
    output logic                  fifo_wfull,

    input                         dout_req,
    output logic                  dout_en,
    output logic [DW-1:0]         data_o,
    output logic                  fifo_rempty,
    output logic [$clog2(DEPTH):0]fifo_cnt
);

parameter AW = $clog2(DEPTH);

logic [AW:0] waddr;
logic [AW:0] raddr;
logic [AW:0] waddr_nxt;
logic [AW:0] raddr_nxt;

logic [DW-1:0]buf_array[DEPTH-1:0];
logic [AW-1:0]wptr;
logic [AW-1:0]rptr;
logic         din_en;

//-------------------------------------
//        logic
//-------------------------------------
assign din_en = din_req & (~fifo_wfull);
assign dout_en = dout_req & (~fifo_rempty);
assign wptr    =  waddr[AW-1:0];
assign rptr    =  raddr[AW-1:0];
assign waddr_nxt = waddr + 1'h1;
assign raddr_nxt = raddr + 1'h1;

generate
    if(REG_OUT == 0)        
        assign data_o = buf_array[rptr]; //directly output
    else begin
        //register output
        always_ff@(posedge aclk, negedge arst_n) begin
            if(arst_n==1'b0)    data_o <= {DW{1'b0}};
            else if(dout_en)    data_o <= buf_array[rptr];
    end
end
endgenerate

always_ff@(posedge aclk, negedge arst_n) begin
    if(arst_n==1'b0) waddr <= {(AW+1){1'b0}};
    else if(clr_i)   waddr <= {(AW+1){1'b0}};
    else if(din_en)  waddr <= waddr_nxt;
end

always_ff@(posedge aclk, negedge arst_n) begin
    if(arst_n==1'b0)  raddr <= {(AW+1){1'b0}};
    else if(clr_i)    raddr <= {(AW+1){1'b0}};
    else if(dout_en)  raddr <= raddr_nxt;
end

//write full and read empty
assign fifo_wfull = (fifo_cnt == DEPTH);
assign fifo_rempty = (fifo_cnt == {(AW+1){1'b0}});

always_ff@(posedge aclk, negedge arst_n) begin
    if(arst_n==1'b0) fifo_cnt <= {(AW+1){1'b0}};
    else if(clr_i)   fifo_cnt <= {(AW+1){1'b0}};
    else begin
        case({din_en,dout_en})
            2'b10: fifo_cnt <= fifo_cnt + 1'h1;
            2'b01: fifo_cnt <= fifo_cnt - 1'h1;
            default: fifo_cnt <= fifo_cnt;
        endcase
    end
end

//buffer array write
integer i;
always_ff@(posedge aclk, negedge arst_n)begin:buffers_sequential
    if(arst_n == 1'b0) begin
        for(i=0;i<DEPTH;i=i+1)
            buf_array[i] <= 0;
    end
    else if(din_en)
        buf_array[wptr] <= data_i;
end


endmodule
