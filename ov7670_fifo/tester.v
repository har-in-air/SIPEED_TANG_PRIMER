module tester(
    input   wire i_clk,
    input   wire i_rstn,

    // uart interface
    input   wire i_rx_done,
    input   wire [7:0] i_rx_data,
    input   wire i_tx_busy,
    output  reg [7:0] o_tx_data,
    output  reg o_tx_en,

    // camfifo interface
    input   wire i_fifo_busy,
    output  reg o_capture_start,
    output  reg o_read_start,
    input   wire i_fifo_rrst_done,
    output  reg o_fifo_rd_byte_str,
    input   wire i_data_ready,
    input   wire [7:0] i_data_from_fifo
  );

localparam [3:0]
fsm_idle	        = 4'd0,
fsm_process_cmd     = 4'd1,  
fsm_capture_image    = 4'd2,
fsm_ack_capture      = 4'd3,
fsm_wt_download_image   = 4'd4,
fsm_request_byte     = 4'd5,
fsm_download_byte    = 4'd6,
fsm_tx_idle          = 4'd7;

reg [3:0] fsm_state = fsm_idle;
reg [7:0] uart_rx_buffer;
reg [2:0] tx_idle_count;
  
 
always @(posedge i_clk)
if (!i_rstn)
	begin
    o_capture_start <= 0;
    o_read_start <= 0;
    o_fifo_rd_byte_str <= 0;
    fsm_state <= fsm_idle;
    o_tx_en <= 1'b0;
    end
else 
    case (fsm_state)
    fsm_idle: 
        begin 
        o_capture_start <= 0;
        o_read_start <= 0;
        o_fifo_rd_byte_str <= 0;
        o_tx_en <= 1'b0;
        if (i_rx_done)
            begin
            uart_rx_buffer <= i_rx_data;
            fsm_state <= fsm_process_cmd;
            end 
        end

    fsm_process_cmd:
        begin
        if(uart_rx_buffer == 8'h31)  // '1' = capture image
            begin
            if (~i_fifo_busy)
                begin
                o_capture_start <= 1;
                fsm_state <= fsm_capture_image;
                end
            end
        else 
        if(uart_rx_buffer == 8'h32)  // '2' = download image
            begin
            if (~i_fifo_busy)
                begin
                o_read_start <= 1;
                fsm_state <= fsm_wt_download_image;
                end
            end
		end
   
    fsm_capture_image:
        begin
        o_capture_start <= 0; 		
        if (~i_fifo_busy)
            fsm_state <= fsm_ack_capture;
        end        
		
    fsm_ack_capture :
        begin
        o_tx_data <= "1"; // send '1' to acknowledge capture complete
        o_tx_en <= 1'b1;
        fsm_state <= fsm_idle;
        end
        
    fsm_wt_download_image :
    		begin
    		o_read_start <= 0;
        if (i_fifo_rrst_done)
            fsm_state <= fsm_request_byte;
        end
        
	fsm_request_byte :
	    if (i_fifo_busy) // image not completely read
	        begin
	        o_fifo_rd_byte_str <= 1;
	        fsm_state <= fsm_download_byte;	
	        end
        else
            begin
            fsm_state <= fsm_idle;
            end
				
    fsm_download_byte :
        begin 
        o_fifo_rd_byte_str <= 0;
        if (i_data_ready)
            begin         
            o_tx_data <= i_data_from_fifo;
            o_tx_en <= 1'b1;
            tx_idle_count <= 3'd0;
            fsm_state <= fsm_tx_idle;
            end
        end
        
        
    fsm_tx_idle :
        begin
        o_tx_en <= 1'b0;
        tx_idle_count <= i_tx_busy ? 3'd0 : tx_idle_count + 3'd1;
        if (tx_idle_count == 3'd3)
            fsm_state <= fsm_request_byte;
        else        		
            fsm_state <= fsm_tx_idle;
        end

    default :
        fsm_state <= fsm_idle;
        
    endcase
    

endmodule
