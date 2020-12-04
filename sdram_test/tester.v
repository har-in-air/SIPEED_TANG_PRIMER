// https://www.hackster.io/salvador-canas/a-practical-introduction-to-sdr-sdram-memories-using-an-fpga-8f5949
// modified HN for working with hex ascii input and output, 32bit data, 21bit address and 
// different uart interface

module tester(
  input wire i_clk,
  input wire i_rstn,
  
  input wire i_rx_done,
  input wire [7:0] i_rx_data,
  input wire i_tx_busy,
  output reg [7:0] o_tx_data,
  output reg o_tx_en,

  input wire i_sys_sdram_ready,
  input [31:0] i_sys_data_from_sdram,  
  output [31:0] o_sys_addr,
  output [31:0] o_sys_data_to_sdram,
  output reg [3:0] o_sys_write_str,
  output reg o_sys_data_valid
  );

parameter n_IMG_WORDS = 4;

localparam [3:0]
st_print_options		=   4'd0,  //  display user options
st_idle_and_receive	=   4'd1,  //  Wait till the user types something
st_receive_option		=   4'd2,  //  receiving user option
st_prompt_write_data	=   4'd3,  //  Prompt for data to write
st_receive_write_data	=   4'd4,  //  receiving write data
st_prompt_sdram_wr_addr=   4'd5,  //  Prompt for write address
st_receive_write_addr	=   4'd6,  //  receiving write address
st_data_write			=   4'd7,  //  generate write strobe
st_ack_data_write		=   4'd8,  //  Acknowledge data write operation complete
st_prompt_sdram_rd_addr	=   4'd9,  //  Prompt for read address
st_receive_read_addr	=   4'd10,  // receiving read address
st_print_read_data		=   4'd11, //  Display read data
st_capture_image = 4'd12,
st_download_image = 4'd13,
st_download_word = 4'd14;

reg [3:0] tst_state;
reg [7:0] rx_buffer;
reg [2:0] uart_tx_ready_cnt;
reg 		sys_read_rq;
reg [7:0] uart_tx_cnt;
reg [8:0] count;
  
reg [31:0] sdram_wr_data;
reg [31:0] sdram_wr_addr;
reg [31:0] sdram_rd_addr;

reg [15:0] sdram_word_count; //max value 76800/2 for 320x240

  
wire [7:0] hex_ascii_in;
reg [3:0] hex_bin_out;

reg [3:0] hex_bin_in;
reg [7:0] hex_ascii_out;

wire is_valid_hex_char;
  
assign hex_ascii_in = i_rx_data;
assign is_valid_hex_char = (hex_ascii_in > 8'd47 && hex_ascii_in < 8'd58) || (hex_ascii_in > 8'd64 && hex_ascii_in < 8'd71) || (hex_ascii_in > 8'd96 && hex_ascii_in < 8'd103);  

assign o_sys_addr = sys_read_rq ? sdram_rd_addr : (o_sys_write_str ? sdram_wr_addr : 0);						 
assign o_sys_data_to_sdram = o_sys_write_str ? sdram_wr_data : 8'hZZ;
 
 
always @(posedge i_clk)
if (!i_rstn)
	begin
    o_sys_write_str <= 4'h0;
    sys_read_rq <= 1'b0;
    o_sys_data_valid <= 1'b0;
    tst_state <= st_print_options;
    o_tx_en <= 1'b0;
    uart_tx_cnt <= 8'd0;
    uart_tx_ready_cnt <= 3'd0;
    end
else 
    case (tst_state)
      st_print_options:
      	begin
        o_sys_write_str <= 4'h0;
        sys_read_rq <= 1'b0;
        o_sys_data_valid <= 1'b0;

        if (!i_tx_busy)
          uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
        else
          uart_tx_ready_cnt <= 3'd0;
          
        if (uart_tx_cnt < 8'd40) //last +1
          if (uart_tx_ready_cnt == 3'd7)
          	begin
            uart_tx_cnt <= uart_tx_cnt + 8'd1;
            o_tx_en <= 1'b1;
            case (uart_tx_cnt)
              0: o_tx_data <= "S";
              1: o_tx_data <= "D";
              2: o_tx_data <= "R";
              3: o_tx_data <= "A";
              4: o_tx_data <= "M";
              5: o_tx_data <= " ";
              6: o_tx_data <= "T";
              7: o_tx_data <= "E";
              8: o_tx_data <= "S";
              9: o_tx_data <= "T";
              10: o_tx_data <= "E";
              11: o_tx_data <= "R";
              12: o_tx_data <= 8'd13; // \r
              13: o_tx_data <= 8'd10; // \n
              14: o_tx_data <= "O";
              15: o_tx_data <= "p";
              16: o_tx_data <= "t";
              17: o_tx_data <= "i";
              18: o_tx_data <= "o";
              19: o_tx_data <= "n";
              20: o_tx_data <= "s";
              21: o_tx_data <= ":";
              22: o_tx_data <= " ";
              23: o_tx_data <= "1";
              24: o_tx_data <= "-";
              25: o_tx_data <= "W";
              26: o_tx_data <= "r";
              27: o_tx_data <= "i";
              28: o_tx_data <= "t";
              29: o_tx_data <= "e";
              30: o_tx_data <= ",";
              31: o_tx_data <= " ";
              32: o_tx_data <= "2";
              33: o_tx_data <= "-";
              34: o_tx_data <= "R";
              35: o_tx_data <= "e";
              36: o_tx_data <= "a";
              37: o_tx_data <= "d";
              38: o_tx_data <= 8'd13;
              39: o_tx_data <= 8'd10;
              default: o_tx_data <= 8'b0;
            endcase
          end
        else
          begin
            o_tx_en <= 1'b0;
          end
        else
          begin
            tst_state <= st_idle_and_receive;
            uart_tx_cnt <= 8'd0;
            o_tx_en <= 1'b0;
            uart_tx_ready_cnt <= 3'd0;
          end	
      end

      st_idle_and_receive: 
        begin 
          o_tx_en <= 1'b0;
          if (i_rx_done)
          begin
            o_tx_en <= 1'b0;
            rx_buffer <= i_rx_data;
            tst_state <= st_receive_option;
          end 
        end

      st_receive_option:
        begin
          o_tx_en <= 1'b1;
          if (rx_buffer == 8'h31)  // '1' = write
              tst_state <= st_prompt_write_data; 
          else if(rx_buffer == 8'h32)  // '2' = read
              tst_state <= st_prompt_sdram_rd_addr;
          else if(rx_buffer == 8'h33)  // '3' = capture image
          	 begin
          	 sdram_wr_data <= 32'habcd1234; // rgb565 yellow
	        o_sys_write_str <= 4'hF;
         	sys_read_rq <= 1'b0;
         	o_sys_data_valid <= 1'b1;
          	 sdram_wr_addr <= 32'b0;
          	 sdram_word_count <= 16'd0;
              tst_state <= st_capture_image;
              end
          else if(rx_buffer == 8'h34)  // '4' = download image
          	 begin
	         o_sys_write_str <= 4'h0;
         	 sys_read_rq <= 1'b1;
         	 o_sys_data_valid <= 1'b1;
          	 sdram_rd_addr <= 32'b0;
          	 sdram_word_count <= 16'd0;
              tst_state <= st_download_image;
              end
          else  
              tst_state <= st_receive_option;
        end


      st_prompt_write_data:
        begin
          if (!i_tx_busy)
            uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
          else
            uart_tx_ready_cnt <= 3'd0;
          if (uart_tx_cnt < 8'd27) //last +1
            if(uart_tx_ready_cnt == 3'd7)
              begin
              uart_tx_cnt <= uart_tx_cnt + 8'd1;
              o_tx_en <= 1'b1;
              case (uart_tx_cnt)
                0: o_tx_data <= "W";
                1: o_tx_data <= "R";
                2: o_tx_data <= "I";
                3: o_tx_data <= "T";
                4: o_tx_data <= "E";
                5: o_tx_data <= 8'd13;
                6: o_tx_data <= 8'd10;
                7: o_tx_data <= "E";
                8: o_tx_data <= "n";
                9: o_tx_data <= "t";
                10: o_tx_data <= "e";
                11: o_tx_data <= "r";
                12: o_tx_data <= " ";
                13: o_tx_data <= "3";
                14: o_tx_data <= "2";
                15: o_tx_data <= "-";
                16: o_tx_data <= "b";
                17: o_tx_data <= "i";
                18: o_tx_data <= "t";
                19: o_tx_data <= " ";
                20: o_tx_data <= "d";
                21: o_tx_data <= "a";
                22: o_tx_data <= "t";
                23: o_tx_data <= "a";
                24: o_tx_data <= ":";
                25: o_tx_data <= 8'd13;
                26: o_tx_data <= 8'd10;
                default: o_tx_data <= 8'b0;
              endcase
            end
          else
            begin
              o_tx_en <= 1'b0;
            end
          else
            begin
              tst_state <= st_receive_write_data;
              uart_tx_cnt <= 8'd0;
              o_tx_en <= 1'b0;
              uart_tx_ready_cnt <= 3'd0;
            end	
        end

      st_receive_write_data:
      	begin
        o_tx_en <= 1'b0;
        if (i_rx_done && (count == 7))// 32bits = 8 hex nybbles
          begin
            sdram_wr_data <= {sdram_wr_data[27:0], hex_bin_out}; // left shift register and insert lsbits
            count <= 0; 
            o_tx_data <= i_rx_data; // echo the entered char
            o_tx_en <= 1'b1;
            tst_state <= st_prompt_sdram_wr_addr; 
          end
        else if (i_rx_done) 
          begin
          	// valid characters are only 0..9,A..F
            if (is_valid_hex_char)
            	begin  
              sdram_wr_data <= {sdram_wr_data[27:0], hex_bin_out};
              count <= count + 1'b1; 
              o_tx_data <= i_rx_data; // echo the entered char
              o_tx_en <= 1'b1;
              tst_state <= st_receive_write_data;              
            end
            else           
              tst_state <= st_receive_write_data;              
          end
      end


      st_prompt_sdram_wr_addr:
        begin
          if (!i_tx_busy)
            uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
          else
            uart_tx_ready_cnt <= 3'd0;
          if (uart_tx_cnt < 8'd25) //last +1
            if(uart_tx_ready_cnt == 3'd7)
              begin
              uart_tx_cnt <= uart_tx_cnt + 8'd1;
              o_tx_en <= 1'b1;
              case(uart_tx_cnt)
                0: o_tx_data <= 8'd13;
                1: o_tx_data <= 8'd10;
                2: o_tx_data <= "E";
                3: o_tx_data <= "n";
                4: o_tx_data <= "t";
                5: o_tx_data <= "e";
                6: o_tx_data <= "r";
                7: o_tx_data <= " ";
                8: o_tx_data <= "2";
                9: o_tx_data <= "1";
                10: o_tx_data <= "-";
                11: o_tx_data <= "b";
                12: o_tx_data <= "i";
                13: o_tx_data <= "t";
                14: o_tx_data <= " ";
                15: o_tx_data <= "a";
                16: o_tx_data <= "d";
                17: o_tx_data <= "d";
                18: o_tx_data <= "r";
                19: o_tx_data <= "e";
                20: o_tx_data <= "s";
                21: o_tx_data <= "s";
                22: o_tx_data <= ":";
                23: o_tx_data <= 8'd13;
                24: o_tx_data <= 8'd10;
                default: o_tx_data <= 8'b0;
              endcase
            end
          else
            begin
              o_tx_en <= 1'b0;
            end
          else
            begin
              tst_state <= st_receive_write_addr;
              uart_tx_cnt <= 8'd0;
              o_tx_en <= 1'b0;
              uart_tx_ready_cnt <= 3'd0;
            end    
        end

      st_receive_write_addr:
      begin
        o_tx_en <= 1'b0;
        if (i_rx_done && (count == 5))// 21bit address requires 6nybbles
          begin
            sdram_wr_addr <= {sdram_wr_addr[27:0], hex_bin_out};
            count <= 0;  
            o_tx_data <= i_rx_data; // echo entered char
            o_tx_en <= 1'b1;
            tst_state <= st_data_write; 
          end
        else if (i_rx_done) 
          begin
            if (is_valid_hex_char)
            begin  
              sdram_wr_addr <= {sdram_wr_addr[27:0], hex_bin_out};
              count <= count + 1'b1; 
              o_tx_data <= i_rx_data; // echo entered char
              o_tx_en <= 1'b1;
              tst_state <= st_receive_write_addr;              
            end
            else         
              tst_state <= st_receive_write_addr;              
          end
      end

	  st_data_write :
        begin 		
         o_sys_write_str <= 4'hF;
         sys_read_rq <= 1'b0;
         o_sys_data_valid <= 1'b1;
         tst_state <= st_ack_data_write;
         uart_tx_cnt <= 8'd0;
         o_tx_en <= 1'b0;
         uart_tx_ready_cnt <= 3'd0;
		end
			  
      st_ack_data_write:
        begin 		
         o_sys_write_str <= 4'hF;
         sys_read_rq <= 1'b0;
         o_sys_data_valid <= 1'b1;
         if (i_sys_sdram_ready)
         	begin
         	if (!i_tx_busy)
            		uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
          	else
            		uart_tx_ready_cnt <= 3'd0;
          	if (uart_tx_cnt < 8'd18) //last +1
            		if(uart_tx_ready_cnt == 3'd7)
              		begin
              		uart_tx_cnt <= uart_tx_cnt + 8'd1;
              		o_tx_en <= 1'b1;
              		case(uart_tx_cnt)
                		0: o_tx_data <= 8'd13;
                		1: o_tx_data <= 8'd10;
                		2: o_tx_data <= "D";
                		3: o_tx_data <= "a";
                		4: o_tx_data <= "t";
                		5: o_tx_data <= "a";
                		6: o_tx_data <= " ";
                		7: o_tx_data <= "w";
                		8: o_tx_data <= "r";
                		9: o_tx_data <= "i";
                		10: o_tx_data <= "t";
                		11: o_tx_data <= "e";
                		12: o_tx_data <= " ";
                		13: o_tx_data <= "o";
                		14: o_tx_data <= "k";
                		15: o_tx_data <= "!";
                		16: o_tx_data <= 8'd13;
                		17: o_tx_data <= 8'd10;
                		default: o_tx_data <= 8'b0;
              		endcase
            			end
          		else
            			begin
              		o_tx_en <= 1'b0;
            			end
          	else
            		begin
              	tst_state <= st_print_options;
              	uart_tx_cnt <= 8'd0;
              	o_tx_en <= 1'b0;
              	uart_tx_ready_cnt <= 3'd0;
            		end
            end    
        end
        
      st_capture_image:
         begin 		
         o_sys_write_str <= 4'hF;
         sys_read_rq <= 1'b0;
         o_sys_data_valid <= 1'b1;
         if (sdram_word_count < n_IMG_WORDS) // each write word operation = 2 16bit pixels
         	begin
         	tst_state <= st_capture_image;
         	if (i_sys_sdram_ready)
				begin
				sdram_word_count <= sdram_word_count + 16'd1;
				sdram_wr_addr <= sdram_wr_addr + 32'd4;
				end
			end
         else
         	begin
         	tst_state <= st_print_options;
         	o_sys_write_str <= 4'h0;
            sys_read_rq <= 1'b0;
         	o_sys_data_valid <= 1'b0;
         	uart_tx_cnt <= 8'd0;
         	o_tx_en <= 1'b0;
         	uart_tx_ready_cnt <= 3'd0;
         	end
		end        
		
     st_download_image:
        	begin        
        	o_sys_write_str <= 4'h0;
        	sys_read_rq <= 1'b1;
        	o_sys_data_valid <= 1'b1;
        	if (sdram_word_count < n_IMG_WORDS) // each write word operation = 2 16bit pixels
        		begin
        		tst_state <= st_download_image;
   		  	if (i_sys_sdram_ready)
   		  		begin
		        	sys_read_rq <= 1'b0;
    		    		o_sys_data_valid <= 1'b0;
   		  		tst_state <= st_download_word;
   			    //o_ledr <= 1'b0; // magenta for download word
				//o_ledg <= 1'b1;
				//o_ledb <= 1'b0;
   		  		end
   		  	end
   		else
   			begin
   			tst_state <= st_print_options;
		    sys_read_rq <= 1'b0;
    			o_sys_data_valid <= 1'b0;
			//o_ledr <= 1'b0; // turn on red led for command prompt
			//o_ledg <= 1'b1;
			//o_ledb <= 1'b1;
         	uart_tx_cnt <= 8'd0;
         	o_tx_en <= 1'b0;
         	uart_tx_ready_cnt <= 3'd0;
   			end
		end
		
						
	  st_download_word :
		begin          
	    	uart_tx_ready_cnt <= i_tx_busy ? 3'd0 : uart_tx_ready_cnt + 3'd1;
        	if (uart_tx_cnt < 8'd4)
        		begin
        		tst_state <= st_download_word;
        		if (uart_tx_ready_cnt == 3'd7)
        			begin
        			uart_tx_cnt <= uart_tx_cnt + 8'd1;
        			o_tx_en <= 1'b1;
        			case(uart_tx_cnt)
        			0: o_tx_data <= i_sys_data_from_sdram[31:24];
        			1: o_tx_data <= i_sys_data_from_sdram[23:16];
        			2: o_tx_data <= i_sys_data_from_sdram[15:8];
        			3: o_tx_data <= i_sys_data_from_sdram[7:0];
        			//0: o_tx_data <= "a";
        			//1: o_tx_data <= "b";
        			//2: o_tx_data <= "c";
        			//3: o_tx_data <= "d";
                	default: o_tx_data <= 8'b0;
        			endcase
        			end
        		else
        			begin
        			o_tx_en <= 1'b0;
        			end
        		end
        	else
        		begin
			sdram_word_count <= sdram_word_count + 16'd1;
			sdram_rd_addr <= sdram_rd_addr + 32'd4;
            	uart_tx_cnt <= 8'd0;
            	o_tx_en <= 1'b0;
            	uart_tx_ready_cnt <= 3'd0;
		    //o_ledr <= 1'b1; // blue for download image
		    //o_ledg <= 1'b1; // blue for download image
		    //o_ledb <= 1'b0; // blue for download image
            	tst_state <= st_download_image;
            	end
       end		

      st_prompt_sdram_rd_addr:
        begin
          if (!i_tx_busy)
            uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
          else
            uart_tx_ready_cnt <= 3'd0;
          if (uart_tx_cnt < 8'd29) //last +1
            if(uart_tx_ready_cnt == 3'd7)
              begin
              uart_tx_cnt <= uart_tx_cnt + 8'd1;
              o_tx_en <= 1'b1;
              case(uart_tx_cnt)
                0: o_tx_data <= "R";
                1: o_tx_data <= "E";
                2: o_tx_data <= "A";
                3: o_tx_data <= "D";
                4: o_tx_data <= 8'd13;
                5: o_tx_data <= 8'd10;
                6: o_tx_data <= "E";
                7: o_tx_data <= "n";
                8: o_tx_data <= "t";
                9: o_tx_data <= "e";
                10: o_tx_data <= "r";
                11: o_tx_data <= " ";
                12: o_tx_data <= "2";
                13: o_tx_data <= "1";
                14: o_tx_data <= "-";
                15: o_tx_data <= "b";
                16: o_tx_data <= "i";
                17: o_tx_data <= "t";
                18: o_tx_data <= " ";
                19: o_tx_data <= "a";
                20: o_tx_data <= "d";
                21: o_tx_data <= "d";
                22: o_tx_data <= "r";
                23: o_tx_data <= "e";
                24: o_tx_data <= "s";
                25: o_tx_data <= "s";
                26: o_tx_data <= ":";
                27: o_tx_data <= 8'd13;
                28: o_tx_data <= 8'd10;                
                default: o_tx_data <= 8'b0;
              endcase
            end
          else
            begin
              o_tx_en <= 1'b0;
            end
          else
            begin
              tst_state <= st_receive_read_addr;
              uart_tx_cnt <= 8'd0;
              o_tx_en <= 1'b0;
              uart_tx_ready_cnt <= 3'd0;
            end	
        end

      st_receive_read_addr:
      begin
        o_tx_en <= 1'b0;
        if (i_rx_done && (count == 5))// 21 bit address requires 6 nybbles
          begin
            sdram_rd_addr <= {sdram_rd_addr[27:0], hex_bin_out};
            count <= 0;
            o_tx_data <= i_rx_data;
            o_tx_en <= 1'b1;
            tst_state <= st_print_read_data;
          end
        else if (i_rx_done) 
          begin
          	// only '0' and '1' are valid characters
            if (is_valid_hex_char) 
              begin
                sdram_rd_addr <= {sdram_rd_addr[27:0], hex_bin_out};
                count <= count + 1'b1; 
                o_tx_data <= i_rx_data;
                o_tx_en <= 1'b1;
                tst_state <= st_receive_read_addr;              
              end 
            else             
              tst_state <= st_receive_read_addr;              
          end

      end

      st_print_read_data:
        begin        
          o_sys_write_str <= 4'h0;
          o_sys_data_valid <= 1'b1;
          sys_read_rq <= 1'b1;
		  if (i_sys_sdram_ready)
		  	begin          
          	if (!i_tx_busy)
            		uart_tx_ready_cnt <= uart_tx_ready_cnt + 3'd1;
          	else
            		uart_tx_ready_cnt <= 3'd0;
          	if (uart_tx_cnt < 8'd23)
            		if (uart_tx_ready_cnt == 3'd7)
              		begin
              		uart_tx_cnt <= uart_tx_cnt + 8'd1;
              		o_tx_en <= 1'b1;
              		case(uart_tx_cnt)
                		0: o_tx_data <= 8'd13;
                		1: o_tx_data <= 8'd10;
                		2: o_tx_data <= "R";
                		3: o_tx_data <= "e";
                		4: o_tx_data <= "a";
                		5: o_tx_data <= "d";
                		6: o_tx_data <= " ";
                		7: o_tx_data <= "d";
                		8: o_tx_data <= "a";
                		9: o_tx_data <= "t";
                		10: o_tx_data <= "a";
                		11: o_tx_data <= ":";
                		12: begin o_tx_data <= " "; hex_bin_in <= i_sys_data_from_sdram[31:28]; end // hex_ascii_out available on next clock
                		13: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[27:24]; end
                		14: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[23:20]; end
                		15: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[19:16]; end
                		16: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[15:12]; end
                		17: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[11:8]; end
                		18: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[7:4]; end
                		19: begin o_tx_data <= hex_ascii_out; hex_bin_in <= i_sys_data_from_sdram[3:0]; end
                		20: o_tx_data <= hex_ascii_out;
                		21: o_tx_data <= 8'd13;
                		22: o_tx_data <= 8'd10;
                     default: o_tx_data <= 8'b0;
              		endcase
            			end
          		else
            			begin
              		o_tx_en <= 1'b0;
            			end
          		else
            		begin
              		tst_state <= st_print_options;
              		uart_tx_cnt <= 8'd0;
              		o_tx_en <= 1'b0;
              		uart_tx_ready_cnt <= 3'd0;
            		end
            	end    
        end 
    endcase
    

always @(posedge i_clk)
case(hex_ascii_in)
    8'd48 : hex_bin_out = 4'h0;
    8'd49 : hex_bin_out = 4'h1;
    8'd50 : hex_bin_out = 4'h2;
    8'd51 : hex_bin_out = 4'h3;
    8'd52 : hex_bin_out = 4'h4;
    8'd53 : hex_bin_out = 4'h5;
    8'd54 : hex_bin_out = 4'h6;
    8'd55 : hex_bin_out = 4'h7;
    8'd56 : hex_bin_out = 4'h8;
    8'd57 : hex_bin_out = 4'h9;
    8'd65 : hex_bin_out = 4'hA;
    8'd66 : hex_bin_out = 4'hB;
    8'd67 : hex_bin_out = 4'hC;
    8'd68 : hex_bin_out = 4'hD;
    8'd69 : hex_bin_out = 4'hE;
    8'd70 : hex_bin_out = 4'hF;
    8'd97 : hex_bin_out = 4'hA;
    8'd98 : hex_bin_out = 4'hB;
    8'd99 : hex_bin_out = 4'hC;
    8'd100 : hex_bin_out = 4'hD;
    8'd101 : hex_bin_out = 4'hE;
    8'd102 : hex_bin_out = 4'hF;
    default : hex_bin_out = 4'h0;
endcase    

always @(posedge i_clk)
case(hex_bin_in)
    4'h0 : hex_ascii_out = 8'd48;
    4'h1 : hex_ascii_out = 8'd49;
    4'h2 : hex_ascii_out = 8'd50;
    4'h3 : hex_ascii_out = 8'd51;
    4'h4 : hex_ascii_out = 8'd52;
    4'h5 : hex_ascii_out = 8'd53;
    4'h6 : hex_ascii_out = 8'd54;
    4'h7 : hex_ascii_out = 8'd55;
    4'h8 : hex_ascii_out = 8'd56;
    4'h9 : hex_ascii_out = 8'd57;
    4'hA : hex_ascii_out = 8'd65;
    4'hB : hex_ascii_out = 8'd66;
    4'hC : hex_ascii_out = 8'd67;
    4'hD : hex_ascii_out = 8'd68;
    4'hE : hex_ascii_out = 8'd69;
    4'hF : hex_ascii_out = 8'd70;
    default : hex_ascii_out = 8'd63;
endcase  


endmodule
