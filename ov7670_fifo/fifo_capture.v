`include "params.vh"

module fifo_capture(
    input wire i_clk,
    input wire i_rstn,
    
    // internal interface to tester module
    input wire i_capture_start,
    input wire i_read_start,
    input wire i_rd_byte_str,
    output reg o_fifo_busy,
    output reg o_fifo_rrst_done,
    output reg [7:0] o_data,
    output reg o_data_rdy,

    // external interface to CAMFIFO module
    input wire i_vsync,
    input wire [7:0] i_fifo_data, // fifo read data
    output reg o_fifo_rck, // fifo read clock
    output reg o_fifo_wen, // fifo write enable
    output reg o_fifo_rrstn // fifo read pointer reset
);


localparam [3:0]
fsm_idle	          = 4'd0,  
fsm_wait_vsync_start  = 4'd1,  
fsm_wait_vsync_end	  = 4'd2,  
fsm_capture           = 4'd3,
fsm_read_reset        = 4'd4,
fsm_read_image        = 4'd5,
fsm_read_byte         = 4'd6;


reg [3:0] fsm_state = fsm_idle;
reg [1:0] wen_delay;
reg [2:0] rrst_counter;
reg [17:0] byte_counter;

always @(posedge i_clk)
begin
    if (~i_rstn)
        begin
        fsm_state <= fsm_idle;
        end
    else
        begin        
        case (fsm_state)
        fsm_idle :  
            begin
            o_fifo_wen <= 0;
            o_fifo_rrstn <= 1;
            o_fifo_rck <= 1;

            o_fifo_rrst_done <= 0;
            o_fifo_busy <= 0;
            if (i_capture_start)
                begin
                o_fifo_busy <= 1;
                fsm_state <= fsm_wait_vsync_start;               
                end
            else
            if (i_read_start)
                begin
                o_fifo_busy <= 1;
                o_fifo_rck <= 1;
                o_fifo_rrstn <= 1;
                rrst_counter <= 3'd0;
                fsm_state <= fsm_read_reset;
                end
            end
                             
        fsm_wait_vsync_start : 
            if (~i_vsync)
                fsm_state <= fsm_wait_vsync_end;

        fsm_wait_vsync_end : 
            if (i_vsync)
                begin
                fsm_state <= fsm_capture;
                wen_delay <= 2'd0;
                end

        fsm_capture : 
            begin
            if (wen_delay < 2'd2)
                wen_delay <= wen_delay + 2'd1; // vsync connected to fifo_wrst. Wait for wrst to execute before capture
            else
                o_fifo_wen <= 1; // camera module has a nand gate that enables fifo writes only during active line                     
            if (~i_vsync)
                begin
                o_fifo_busy <= 0; // signal capture complete
                o_fifo_wen <= 0;
                fsm_state <= fsm_idle;
                end
            end
            
         fsm_read_reset :
            begin
            rrst_counter <= rrst_counter + 3'd1;
            case (rrst_counter)
            3'd0 : o_fifo_rrstn <= 0;
            3'd1 : o_fifo_rck <= 0;
            3'd2 : o_fifo_rck <= 1;
            3'd3 : o_fifo_rck <= 0;
            3'd4 : o_fifo_rck <= 1;
            3'd5 : o_fifo_rck <= 0;
            3'd6 : o_fifo_rrstn <= 1;
            3'd7 : begin
            		  o_fifo_rck <= 1;
                   byte_counter <= 18'd0;
                   o_fifo_rrst_done <= 1;
                   fsm_state <= fsm_read_image;
                   end
            default : fsm_state <= fsm_idle;
            endcase 
            end                        
                         
         fsm_read_image :
         	begin
            o_data_rdy <= 0;
            if (byte_counter < `n_IMAGE_BYTES)
                begin
                if (i_rd_byte_str)
                    begin
                    o_fifo_rck <= 0;
                    fsm_state <= fsm_read_byte;
                    end
                end
            else
                begin
                fsm_state <= fsm_idle;
                o_fifo_busy <= 0; // signal read complete
                end
            end
              
         fsm_read_byte :
             begin
             o_data <= i_fifo_data;
             o_fifo_rck <= 1;
             o_data_rdy <= 1;
             byte_counter <= byte_counter + 18'd1;
             fsm_state <= fsm_read_image;
             end
         
         default :
            fsm_state <= fsm_idle;
            
        endcase
                 
        end
end

endmodule
