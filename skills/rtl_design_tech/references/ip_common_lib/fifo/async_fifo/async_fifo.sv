module async_fifo#(
    //NOTE:buffer_depth is 16,address width is 4,LOG_DEPTH must be 5
    //NOTE:buffer_depth is 32,address width is 5,LOG_DEPTH must be 6
    parameter DW        = 32,
    parameter DEPTH     = 16,
    parameter REG_OUT   = 0
)
(
    input                             wclk           ,
    input                             wrst_n         ,
    input                             rclk           ,
    input                             rrst_n         ,
    input                             clr_i          ,
    
    input                             debug_pos      ,
    output logic [$clog2(DEPTH) :0]   status_elements,

    input                             din_req        ,
    input [DW-1:0]                    data_i         ,
    output logic[$clog2(DEPTH) :0]    element_w      ,
    output logic                      fifo_wfull     ,

    input                             dout_req       ,
    output logic                      dout_en        ,
    output logic [DW-1:0]             data_o         ,
    output logic [$clog2(DEPTH) :0]   element_r      ,
    output logic                      fifo_rempty    ,
    output logic                      fifo_overflow  ,
    output logic                      fifo_underflow

);

parameter LOG_DEPTH = $clog2(DEPTH) + 1;


logic [LOG_DEPTH:0] waddr;
logic [LOG_DEPTH:0] raddr;
logic [LOG_DEPTH:0] waddr_nxt;
logic [LOG_DEPTH:0] raddr_nxt;
logic [LOG_DEPTH:0] waddr_gry_nxt;
logic [LOG_DEPTH:0] raddr_gry_nxt;
logic [LOG_DEPTH:0] waddr_gry;
logic [LOG_DEPTH:0] raddr_gry;

logic [LOG_DEPTH:0] waddr_gry_rsync1;
logic [LOG_DEPTH:0] waddr_gry_rsync2;
logic [LOG_DEPTH:0] waddr_bin_rsync2;


logic [LOG_DEPTH:0] raddr_gry_wsync1;
logic [LOG_DEPTH:0] raddr_gry_wsync2;
logic [LOG_DEPTH:0] raddr_bin_wsync2;

logic [LOG_DEPTH:0]element_pre_w;
logic [LOG_DEPTH:0]element_pre_r;

logic clr_w_d;
logic clr_w;
logic clr_r_d;
logic clr_r;

logic [DW-1:0]buf_array[DEPTH-1:0];

logic [LOG_DEPTH-2:0]wptr;
logic [LOG_DEPTH-2:0]rptr;
logic                din_en;

//-----------------------------------------------
//      logic
//-----------------------------------------------
assign din_en = din_req & (~fifo_wfull);
assign dout_en = dout_req & (~fifo_rempty);
assign wptr = waddr[LOG_DEPTH-2:0];
assign rptr = raddr[LOG_DEPTH-2:0];
assign waddr_nxt = waddr + 1'b1;
assign raddr_nxt = raddr + 1'b1;

//output ports
generate
    if(REG_OUT == 0)        
        assign data_o = buf_array[rptr]; //directly output
    else begin
        //register output
        always_ff@(posedge rclk, negedge rrst_n) begin
            if(rrst_n==1'b0)    data_o <= {DW{1'b0}};
            else if(dout_en)    data_o <= buf_array[rptr];
    end
end
endgenerate

//signal sync
always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0) {clr_w,clr_w_d} <= 2'h0;
    else               {clr_w,clr_w_d} <= {clr_w_d,clr_i};
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0) {clr_r,clr_r_d} <= 2'h0;
    else               {clr_r,clr_r_d} <= {clr_r_d,clr_i};
end

//address increase
always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0) waddr <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_w)     waddr <= {(LOG_DEPTH+1){1'b0}};
    else if(din_en)    waddr <= waddr_nxt;
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0) raddr <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_r)     raddr <= {(LOG_DEPTH+1){1'b0}};
    else if(dout_en)   raddr <= raddr_nxt;
end

always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0) waddr_gry <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_w)     waddr_gry <= {(LOG_DEPTH+1){1'b0}};
    else if(din_en)    waddr_gry <= waddr_gry_nxt;
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0) raddr_gry <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_r)     raddr_gry <= {(LOG_DEPTH+1){1'b0}};
    else if(dout_en)   raddr_gry <= raddr_gry_nxt;
end

//bin to gray
assign waddr_gry_nxt = (waddr_nxt>>1) ^ waddr_nxt;
assign raddr_gry_nxt = (raddr_nxt>>1) ^ raddr_nxt;

//gray to bin
assign raddr_bin_wsync2[LOG_DEPTH] = raddr_gry_wsync2[LOG_DEPTH];
assign waddr_bin_rsync2[LOG_DEPTH] = waddr_gry_rsync2[LOG_DEPTH];
generate
    genvar ii;
    for(ii=0;ii<LOG_DEPTH;ii=ii+1)begin
        assign raddr_bin_wsync2[ii] = raddr_bin_wsync2[ii+1] ^ raddr_gry_wsync2[ii];
        assign waddr_bin_rsync2[ii] = waddr_bin_rsync2[ii+1] ^ waddr_gry_rsync2[ii];
    end
endgenerate

//gray code sync between 2-clock domains
always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0) begin
        raddr_gry_wsync1 <= {(LOG_DEPTH+1){1'b0}};
        raddr_gry_wsync2 <= {(LOG_DEPTH+1){1'b0}};
    end
    else begin
        raddr_gry_wsync1 <= raddr_gry;
        raddr_gry_wsync2 <= raddr_gry_wsync1;
    end
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0)begin
        waddr_gry_rsync1 <= {(LOG_DEPTH+1){1'b0}};
        waddr_gry_rsync2 <= {(LOG_DEPTH+1){1'b0}};
    end
    else begin
        waddr_gry_rsync1 <= waddr_gry;
        waddr_gry_rsync2 <= waddr_gry_rsync1;
    end
end

//elements in buffer
assign element_pre_w = (waddr[LOG_DEPTH:0]-raddr_bin_wsync2[LOG_DEPTH:0]);
assign element_pre_r = (waddr_bin_rsync2[LOG_DEPTH:0]-raddr[LOG_DEPTH:0]);

always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0) element_w <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_w)     element_w <= {(LOG_DEPTH+1){1'b0}};
    else               element_w <= din_en ? (element_w+1'b1) : {1'b0,element_pre_w[LOG_DEPTH-1:0]};
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0) element_r <= {(LOG_DEPTH+1){1'b0}};
    else if(clr_r)     element_r <= {(LOG_DEPTH+1){1'b0}};
    else               element_r <= dout_en ? (element_r-1'b1) : {1'b0,element_pre_r[LOG_DEPTH-1:0]};
end


//write full and read empty
assign fifo_wfull = (element_w == DEPTH);
assign fifo_rempty = (element_r == {(LOG_DEPTH+1){1'b0}});

//debug logic
always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0)  status_elements <={(LOG_DEPTH+1){1'b0}};
    else if(debug_pos)  status_elements <= element_r;
end

//buffer array write
integer loop1;
always_ff@(posedge wclk,negedge wrst_n)begin:buffers_sequential
    if(wrst_n == 1'b0)begin
        for(loop1=0;loop1<DEPTH;loop1=loop1+1)
            buf_array[loop1] <= 0;
    end
    else if(din_en)
        buf_array[wptr] <= data_i;
end

always_ff@(posedge wclk,negedge wrst_n)begin
    if(wrst_n == 1'b0)
        fifo_overflow <= 1'b0;
    else if(din_req & fifo_wfull)
        fifo_overflow <= 1'b1;
end

always_ff@(posedge rclk,negedge rrst_n)begin
    if(rrst_n == 1'b0)
        fifo_underflow <= 1'b0;
    else if(dout_req & fifo_rempty)
        fifo_underflow <= 1'b1;
end

endmodule
